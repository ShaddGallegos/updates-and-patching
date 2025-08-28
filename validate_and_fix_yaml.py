#!/usr/bin/env python3
"""
Complete YAML Validation and Fix
Tests each YAML file individually and fixes common issues
"""

import os
import yaml
import re
from pathlib import Path

def test_and_fix_yaml_file(file_path):
    """Test and fix a single YAML file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Try to parse the YAML
        try:
            yaml.safe_load(content)
            return True, "YAML is valid"
        except yaml.YAMLError as e:
            # Try to fix common issues
            fixed_content = fix_common_yaml_issues(content)
            
            # Test the fixed content
            try:
                yaml.safe_load(fixed_content)
                # Write the fixed content back
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(fixed_content)
                return True, f"Fixed YAML issues: {str(e)[:100]}"
            except yaml.YAMLError as e2:
                return False, f"Cannot fix YAML: {str(e2)[:100]}"
                
    except Exception as e:
        return False, f"File error: {str(e)}"

def fix_common_yaml_issues(content):
    """Fix common YAML formatting issues"""
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
        
        # Fix play definitions
        if re.match(r'^-?\s*(name|hosts):\s*(.+)', stripped):
            match = re.match(r'^-?\s*(name|hosts):\s*(.+)', stripped)
            if match:
                key, value = match.groups()
                fixed_lines.append(f'- {key}: {value}')
            else:
                fixed_lines.append(f'- {stripped}')
            i += 1
            continue
        
        # Fix task definitions
        if stripped.startswith('- name:'):
            # Check if this is properly indented for a task list
            if not line.startswith('  ') and i > 0:
                # This should be indented as a task
                fixed_lines.append('    ' + stripped)
            else:
                fixed_lines.append(line)
            i += 1
            continue
        
        # Fix key-value pairs with proper indentation
        if ':' in stripped and not stripped.startswith('-'):
            # Determine proper indentation level
            if not line.startswith(' '):
                # Top-level key
                fixed_lines.append(f'  {stripped}')
            elif line.startswith('  ') and not line.startswith('    '):
                # Play-level attribute
                fixed_lines.append(line)
            elif line.startswith('    '):
                # Task-level attribute
                fixed_lines.append(line)
            else:
                # Normalize to 2-space indentation
                fixed_lines.append(f'  {stripped}')
            i += 1
            continue
        
        # Default: keep the line as-is
        fixed_lines.append(line)
        i += 1
    
    return '\n'.join(fixed_lines)

def run_validation_on_directory(directory):
    """Run validation on all YAML files in directory"""
    yaml_files = []
    for ext in ['*.yml', '*.yaml']:
        yaml_files.extend(Path(directory).rglob(ext))
    
    yaml_files = [f for f in yaml_files if not f.name.endswith('.backup')]
    
    passed = 0
    failed = 0
    fixed = 0
    
    print(f"Validating {len(yaml_files)} YAML files...")
    
    failed_files = []
    
    for file_path in sorted(yaml_files):
        success, message = test_and_fix_yaml_file(file_path)
        
        if success:
            if "Fixed" in message:
                print(f"🔧 {file_path}: {message}")
                fixed += 1
            else:
                print(f"✅ {file_path}: Valid")
            passed += 1
        else:
            print(f"❌ {file_path}: {message}")
            failed += 1
            failed_files.append((str(file_path), message))
    
    print(f"\n{'='*60}")
    print(f"YAML Validation Summary:")
    print(f"Total files: {len(yaml_files)}")
    print(f"Passed: {passed}")
    print(f"Fixed: {fixed}")
    print(f"Failed: {failed}")
    
    if failed_files:
        print(f"\nFailed files:")
        for file_path, error in failed_files[:10]:  # Show first 10 failures
            print(f"  {file_path}: {error}")

if __name__ == "__main__":
    run_validation_on_directory("/home/sgallego/Downloads/GIT/updates-and-patching")
