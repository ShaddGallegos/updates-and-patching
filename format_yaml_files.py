#!/usr/bin/env python3
"""
Updates and Patching Directory YAML Formatter
Fixes all YAML formatting issues in the updates-and-patching directory
"""

import os
import re
import yaml
from pathlib import Path

class UpdatesPatchingYAMLFormatter:
    def __init__(self, root_dir):
        self.root_dir = Path(root_dir)
        self.processed_files = 0
        self.fixed_files = 0
        self.failed_files = []
        
    def find_yaml_files(self):
        """Find all YAML files in the directory tree"""
        yaml_files = []
        for ext in ['*.yml', '*.yaml']:
            yaml_files.extend(self.root_dir.rglob(ext))
        return [f for f in yaml_files if not f.name.endswith('.backup')]
    
    def is_ansible_playbook(self, content):
        """Detect if this is an Ansible playbook"""
        return bool(re.search(r'^\s*-?\s*(hosts|name|tasks|roles|vars|gather_facts):', content, re.MULTILINE))
    
    def fix_playbook_structure(self, content):
        """Fix Ansible playbook structure issues"""
        lines = content.split('\n')
        fixed_lines = []
        i = 0
        
        while i < len(lines):
            line = lines[i]
            stripped = line.strip()
            
            # Skip empty lines and comments
            if not stripped or stripped.startswith('#'):
                fixed_lines.append(line)
                i += 1
                continue
            
            # Document start
            if stripped == '---':
                fixed_lines.append('---')
                i += 1
                continue
            
            # Play definition (- name: ... or - hosts: ...)
            if re.match(r'^-?\s*(name|hosts):', stripped):
                play_match = re.match(r'^-?\s*(name|hosts):\s*(.+)', stripped)
                if play_match:
                    key, value = play_match.groups()
                    fixed_lines.append(f'- {key}: {value}')
                else:
                    fixed_lines.append(f'- {stripped[1:].strip() if stripped.startswith("-") else stripped}')
                i += 1
                
                # Process play-level attributes
                while i < len(lines) and lines[i].strip():
                    next_line = lines[i]
                    next_stripped = next_line.strip()
                    
                    # Break if we hit another play
                    if re.match(r'^-?\s*(name|hosts):', next_stripped):
                        break
                    
                    # Play-level attributes
                    if ':' in next_stripped and not next_stripped.startswith('-'):
                        attr_match = re.match(r'^([^:]+):\s*(.*)$', next_stripped)
                        if attr_match:
                            attr_name, attr_value = attr_match.groups()
                            if attr_name.strip() in ['hosts', 'gather_facts', 'become', 'vars', 'vars_prompt', 'tasks', 'handlers', 'roles']:
                                if attr_value:
                                    fixed_lines.append(f'  {attr_name.strip()}: {attr_value}')
                                else:
                                    fixed_lines.append(f'  {attr_name.strip()}:')
                                    i += 1
                                    
                                    # Handle multi-line structures
                                    if attr_name.strip() in ['vars', 'vars_prompt', 'tasks', 'handlers']:
                                        while i < len(lines):
                                            sub_line = lines[i]
                                            sub_stripped = sub_line.strip()
                                            
                                            if not sub_stripped:
                                                fixed_lines.append('')
                                                i += 1
                                                continue
                                            
                                            # Break if we hit a new section
                                            if (re.match(r'^-?\s*(name|hosts):', sub_stripped) or
                                                (sub_stripped.endswith(':') and not sub_stripped.startswith('-') and 
                                                 sub_stripped.split(':')[0].strip() in ['hosts', 'gather_facts', 'become', 'vars', 'tasks', 'handlers', 'roles'])):
                                                break
                                            
                                            # List items
                                            if sub_stripped.startswith('-'):
                                                fixed_lines.append(f'    {sub_stripped}')
                                                i += 1
                                                
                                                # Handle task/handler sub-items
                                                while i < len(lines):
                                                    subsub_line = lines[i]
                                                    subsub_stripped = subsub_line.strip()
                                                    
                                                    if not subsub_stripped:
                                                        fixed_lines.append('')
                                                        i += 1
                                                        continue
                                                    
                                                    if (subsub_stripped.startswith('-') or
                                                        re.match(r'^-?\s*(name|hosts):', subsub_stripped) or
                                                        subsub_stripped.split(':')[0].strip() in ['hosts', 'gather_facts', 'become', 'vars', 'tasks', 'handlers']):
                                                        break
                                                    
                                                    fixed_lines.append(f'      {subsub_stripped}')
                                                    i += 1
                                            else:
                                                # Variable definitions
                                                fixed_lines.append(f'    {sub_stripped}')
                                                i += 1
                                    continue
                            else:
                                fixed_lines.append(f'  {next_stripped}')
                        else:
                            fixed_lines.append(f'  {next_stripped}')
                    else:
                        fixed_lines.append(f'  {next_stripped}')
                    i += 1
                continue
            
            # Standalone items
            fixed_lines.append(line)
            i += 1
        
        return '\n'.join(fixed_lines)
    
    def fix_role_file_structure(self, content):
        """Fix role file structures (tasks, vars, defaults, etc.)"""
        lines = content.split('\n')
        fixed_lines = []
        
        for line in lines:
            stripped = line.strip()
            
            if not stripped or stripped.startswith('#'):
                fixed_lines.append(line)
                continue
                
            if stripped == '---':
                fixed_lines.append('---')
                continue
            
            # Top-level list items (tasks, handlers)
            if stripped.startswith('- name:'):
                fixed_lines.append(stripped)
                continue
            elif stripped.startswith('-') and ':' in stripped:
                # Other list items
                fixed_lines.append(stripped)
                continue
            elif ':' in stripped and not line.startswith(' '):
                # Top-level key-value pairs
                fixed_lines.append(stripped)
                continue
            elif ':' in stripped and line.startswith(' '):
                # Indented key-value pairs - normalize to 2 spaces
                key_value = stripped
                if line.startswith('    '):
                    # 4+ spaces, keep as sub-item (4 spaces)
                    fixed_lines.append(f'    {key_value}')
                elif line.startswith('  '):
                    # 2 spaces, normal item
                    fixed_lines.append(f'  {key_value}')
                else:
                    # Odd spacing, normalize to 2 spaces
                    fixed_lines.append(f'  {key_value}')
                continue
            
            # Default: preserve line
            fixed_lines.append(line)
        
        return '\n'.join(fixed_lines)
    
    def clean_empty_lines(self, content):
        """Remove excessive empty lines"""
        lines = content.split('\n')
        cleaned_lines = []
        prev_empty = False
        
        for line in lines:
            if not line.strip():
                if not prev_empty:
                    cleaned_lines.append('')
                    prev_empty = True
            else:
                cleaned_lines.append(line)
                prev_empty = False
        
        return '\n'.join(cleaned_lines)
    
    def process_file(self, file_path):
        """Process a single YAML file"""
        try:
            print(f"Processing: {file_path}")
            
            with open(file_path, 'r', encoding='utf-8') as f:
                original_content = f.read()
            
            if not original_content.strip():
                print("  ✓ Empty file, skipping")
                self.processed_files += 1
                return
            
            # Apply appropriate formatting based on file type
            if self.is_ansible_playbook(original_content):
                formatted_content = self.fix_playbook_structure(original_content)
            else:
                # Role files, configs, etc.
                formatted_content = self.fix_role_file_structure(original_content)
            
            # Clean up empty lines
            formatted_content = self.clean_empty_lines(formatted_content)
            
            # Ensure file ends with newline
            if formatted_content and not formatted_content.endswith('\n'):
                formatted_content += '\n'
            
            # Only write if content changed
            if formatted_content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(formatted_content)
                self.fixed_files += 1
                print("  ✓ Fixed and formatted")
            else:
                print("  ✓ Already properly formatted")
            
            self.processed_files += 1
            
        except Exception as e:
            print(f"  ✗ Error processing {file_path}: {e}")
            self.failed_files.append((str(file_path), str(e)))
    
    def run(self):
        """Run the formatter on all YAML files"""
        print("Updates and Patching YAML Formatter - Starting...")
        
        yaml_files = self.find_yaml_files()
        total_files = len(yaml_files)
        
        print(f"Found {total_files} YAML files to process")
        
        # Sort files for consistent processing
        yaml_files.sort()
        
        for file_path in yaml_files:
            self.process_file(file_path)
        
        print("\n" + "="*60)
        print("Updates and Patching YAML Formatting Complete!")
        print(f"Total files found: {total_files}")
        print(f"Files processed: {self.processed_files}")
        print(f"Files fixed: {self.fixed_files}")
        print(f"Files failed: {len(self.failed_files)}")
        
        if self.failed_files:
            print("\nFailed files:")
            for file_path, error in self.failed_files:
                print(f"  - {file_path}: {error}")

if __name__ == "__main__":
    formatter = UpdatesPatchingYAMLFormatter("/home/sgallego/Downloads/GIT/updates-and-patching")
    formatter.run()
