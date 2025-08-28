#!/usr/bin/env python3
"""
Advanced YAML Recovery Tool
Handles complex broken YAML structures with comprehensive repairs
"""

import os
import re
import yaml
from pathlib import Path

def fix_shell_content_blocks(content):
    """Fix shell content that's been mangled into YAML keys"""
    lines = content.split('\n')
    fixed_lines = []
    in_shell_block = False
    
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        
        # Detect shell commands that have been mangled as YAML keys
        shell_patterns = [
            r'^\s+dnf\s+',
            r'^\s+yum\s+',
            r'^\s+rpm\s+',
            r'^\s+kpatch\s+',
            r'^\s+subscription-manager\s+',
            r'^\s+uptime\s*$',
            r'^\s+case\s+',
            r'^\s+for\s+\w+\s+in\s+',
            r'^\s+\$\w+\s*=',
            r'^\s+try\s*{',
            r'^\s+Get-\w+',
            r'^\s+\[\[\s+',
            r'^\s+echo\s+',
            r'^\s+===\s+',
            r'^\s+\*\w+',
            r'^\s+lsmod\s+',
            r'^\s+current_kernels=',
        ]
        
        is_shell = any(re.match(pattern, line) for pattern in shell_patterns)
        
        if is_shell and not in_shell_block:
            # Start a shell block
            indent = len(line) - len(line.lstrip())
            fixed_lines.append(' ' * max(0, indent - 2) + 'shell: |')
            in_shell_block = True
            shell_indent = indent
            fixed_lines.append(' ' * (shell_indent + 2) + stripped)
        elif in_shell_block and line.strip():
            # Continue shell block or end it
            current_indent = len(line) - len(line.lstrip())
            if current_indent >= shell_indent and (is_shell or not line.strip().endswith(':')):
                fixed_lines.append(' ' * (shell_indent + 2) + stripped)
            else:
                in_shell_block = False
                fixed_lines.append(line)
        else:
            if line.strip():
                in_shell_block = False
            fixed_lines.append(line)
        
        i += 1
    
    return '\n'.join(fixed_lines)

def fix_jinja_template_issues(content):
    """Fix common Jinja2 template issues in YAML"""
    # Fix template variables that got broken
    content = re.sub(r'(\s+){{\s*([^}]+)\s*}}(\s*:.*)?$', r'\1"{{ \2 }}"\3', content, flags=re.MULTILINE)
    
    # Fix broken template conditions
    content = re.sub(r'(\s+)(%\s*if\s+[^%]+\s*%)', r'\1# \2', content, flags=re.MULTILINE)
    content = re.sub(r'(\s+)(%\s*endif\s*%)', r'\1# \2', content, flags=re.MULTILINE)
    
    return content

def fix_list_structure(content):
    """Fix broken list structures"""
    lines = content.split('\n')
    fixed_lines = []
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        if not stripped or stripped.startswith('#'):
            fixed_lines.append(line)
            continue
            
        # Fix broken task lists
        if re.match(r'^\s*-\s*name:\s*(.+)', line):
            # This is a task
            indent = len(line) - len(line.lstrip())
            fixed_lines.append(line)
            continue
        
        # Fix missing dashes for list items that should be tasks
        if re.match(r'^\s+name:\s*', line) and i > 0:
            prev_line = lines[i-1].strip()
            if prev_line and not prev_line.startswith('-') and not prev_line.endswith(':'):
                # This should probably be a new list item
                indent = len(line) - len(line.lstrip())
                fixed_lines.append(' ' * max(0, indent - 2) + '- ' + stripped)
                continue
        
        fixed_lines.append(line)
    
    return '\n'.join(fixed_lines)

def fix_document_structure(content):
    """Fix document-level structure issues"""
    lines = content.split('\n')
    
    # Ensure document starts properly
    if lines and not lines[0].strip().startswith('---'):
        lines.insert(0, '---')
    
    # Fix execution-environment.yml type issues
    if 'execution-environment.yml' in content or 'version:' in content[:200]:
        # This might be an execution environment file
        new_lines = ['---']
        for line in lines[1:]:
            if line.strip() and not line.startswith(' ') and ':' in line:
                new_lines.append(line)
            elif line.strip():
                new_lines.append('  ' + line.strip())
            else:
                new_lines.append(line)
        return '\n'.join(new_lines)
    
    return '\n'.join(lines)

def fix_meta_files(content, filename):
    """Fix meta/main.yml files specifically"""
    if 'meta/main.yml' in filename:
        lines = content.split('\n')
        fixed_lines = ['---']
        
        galaxy_info_started = False
        dependencies_started = False
        
        for line in lines:
            stripped = line.strip()
            
            if not stripped or stripped.startswith('#') or stripped == '---':
                fixed_lines.append(line if line != '---' else '')
                continue
            
            # Start galaxy_info section
            if not galaxy_info_started and ('author' in stripped or 'description' in stripped or 'license' in stripped):
                fixed_lines.append('galaxy_info:')
                galaxy_info_started = True
                
            # Start dependencies section  
            if 'dependencies' in stripped and not dependencies_started:
                fixed_lines.append('dependencies: []')
                dependencies_started = True
                continue
            
            # Fix galaxy_info content
            if galaxy_info_started and not dependencies_started:
                if ':' in stripped:
                    fixed_lines.append('  ' + stripped)
                else:
                    # This might be a continuation of a previous value
                    if fixed_lines and fixed_lines[-1].strip():
                        fixed_lines[-1] += ' ' + stripped
                    else:
                        fixed_lines.append('  description: ' + stripped)
            else:
                fixed_lines.append(line)
        
        if not dependencies_started:
            fixed_lines.append('dependencies: []')
            
        return '\n'.join(fixed_lines)
    
    return content

def comprehensive_yaml_repair(file_path):
    """Apply comprehensive YAML repair"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Apply fixes in order
        content = fix_document_structure(content)
        content = fix_meta_files(content, str(file_path))
        content = fix_shell_content_blocks(content)
        content = fix_jinja_template_issues(content)
        content = fix_list_structure(content)
        
        # Test the result
        try:
            yaml.safe_load(content)
            return content, True, "Successfully repaired"
        except yaml.YAMLError as e:
            return content, False, f"Still has YAML error: {str(e)[:100]}"
            
    except Exception as e:
        return None, False, f"File error: {str(e)}"

def repair_yaml_files(directory):
    """Repair all YAML files in directory"""
    yaml_files = []
    for ext in ['*.yml', '*.yaml']:
        yaml_files.extend(Path(directory).rglob(ext))
    
    yaml_files = [f for f in yaml_files if not f.name.endswith('.backup')]
    
    repaired = 0
    failed = 0
    
    print(f"Repairing {len(yaml_files)} YAML files...")
    
    for file_path in sorted(yaml_files):
        content, success, message = comprehensive_yaml_repair(file_path)
        
        if success and content:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"🔧 {file_path}: {message}")
                repaired += 1
            except Exception as e:
                print(f"❌ {file_path}: Write error - {e}")
                failed += 1
        else:
            print(f"❌ {file_path}: {message}")
            failed += 1
    
    print(f"\n{'='*60}")
    print(f"Repair Summary:")
    print(f"Repaired: {repaired}")
    print(f"Failed: {failed}")
    print(f"Total: {len(yaml_files)}")

if __name__ == "__main__":
    repair_yaml_files("/home/sgallego/Downloads/GIT/updates-and-patching")
