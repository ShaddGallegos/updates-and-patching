#!/usr/bin/env python3
"""
Nuclear YAML Fix - Completely rebuild broken YAML files
"""

import os
import re
import yaml
from pathlib import Path

def rebuild_ansible_playbook(content, filename):
    """Completely rebuild an Ansible playbook from scratch"""
    lines = [line.rstrip() for line in content.split('\n')]
    
    # Start fresh
    result = ['---']
    
    # Find plays (lines that look like play definitions)
    current_play = None
    current_task = None
    current_key = None
    in_shell = False
    shell_content = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        
        if not stripped or stripped.startswith('#'):
            i += 1
            continue
            
        # End shell block if we hit something that's clearly not shell
        if in_shell and (stripped.startswith('- name:') or 
                        stripped.endswith(':') or 
                        stripped.startswith('register:') or
                        stripped.startswith('when:') or
                        stripped.startswith('vars:')):
            if shell_content:
                result.append('    shell: |')
                for shell_line in shell_content:
                    result.append('      ' + shell_line)
                shell_content = []
            in_shell = False
        
        # Play definition
        if re.match(r'^\s*-?\s*(name|hosts):\s*', stripped):
            if not stripped.startswith('-'):
                result.append('- ' + stripped)
            else:
                result.append(stripped)
            current_play = stripped
            current_task = None
            i += 1
            continue
            
        # Task definition
        if stripped.startswith('- name:'):
            if in_shell and shell_content:
                result.append('    shell: |')
                for shell_line in shell_content:
                    result.append('      ' + shell_line)
                shell_content = []
                in_shell = False
            result.append('  ' + stripped)
            current_task = stripped
            i += 1
            continue
            
        # Task attributes
        task_attrs = ['register:', 'when:', 'become:', 'vars:', 'with_items:', 'loop:', 'notify:', 'tags:', 'ignore_errors:']
        if any(stripped.startswith(attr) for attr in task_attrs):
            if in_shell and shell_content:
                result.append('    shell: |')
                for shell_line in shell_content:
                    result.append('      ' + shell_line)
                shell_content = []
                in_shell = False
            result.append('    ' + stripped)
            i += 1
            continue
            
        # Play attributes
        play_attrs = ['gather_facts:', 'become:', 'vars:', 'tasks:', 'roles:', 'handlers:', 'pre_tasks:', 'post_tasks:']
        if any(stripped.startswith(attr) for attr in play_attrs):
            result.append('  ' + stripped)
            i += 1
            continue
            
        # Shell command detection
        shell_patterns = [
            r'^\s*dnf\s+', r'^\s*yum\s+', r'^\s*rpm\s+', r'^\s*subscription-manager\s+',
            r'^\s*kpatch\s+', r'^\s*uptime\s*$', r'^\s*echo\s+', r'^\s*cat\s+',
            r'^\s*grep\s+', r'^\s*awk\s+', r'^\s*sed\s+', r'^\s*find\s+',
            r'^\s*ls\s+', r'^\s*cp\s+', r'^\s*mv\s+', r'^\s*rm\s+',
            r'^\s*mkdir\s+', r'^\s*touch\s+', r'^\s*chmod\s+',
            r'^\s*systemctl\s+', r'^\s*service\s+', r'^\s*mount\s+',
            r'^\s*df\s+', r'^\s*free\s+', r'^\s*ps\s+', r'^\s*kill\s+',
            r'^\s*for\s+\w+\s+in\s+', r'^\s*while\s+', r'^\s*if\s+',
            r'^\s*case\s+', r'^\s*\[\[\s+', r'^\s*\$\w+\s*=',
            r'^\s*Get-\w+', r'^\s*Set-\w+', r'^\s*New-\w+',
            r'^\s*===\s+', r'^\s*\*\w+', r'^\s*current_kernels=',
            r'^\s*lsmod\s+', r'^\s*try\s*{', r'^\s*\w+\(\)'
        ]
        
        is_shell = any(re.match(pattern, stripped) for pattern in shell_patterns)
        
        if is_shell:
            if not in_shell:
                in_shell = True
                shell_content = []
            shell_content.append(stripped)
            i += 1
            continue
            
        # Ansible modules
        ansible_modules = [
            'yum:', 'dnf:', 'package:', 'service:', 'systemd:',
            'copy:', 'template:', 'file:', 'lineinfile:', 'blockinfile:',
            'command:', 'shell:', 'script:', 'raw:', 'debug:', 'set_fact:',
            'group_by:', 'add_host:', 'wait_for:', 'uri:', 'get_url:',
            'unarchive:', 'synchronize:', 'mount:', 'user:', 'group:',
            'cron:', 'at:', 'mail:', 'include_vars:', 'include_tasks:',
            'import_tasks:', 'include_role:', 'import_role:',
            'win_updates:', 'win_reboot:', 'win_service:', 'win_feature:',
            'win_package:', 'win_chocolatey:', 'win_command:', 'win_shell:',
            'redhat_subscription:', 'rhsm_repository:'
        ]
        
        if any(stripped.startswith(module) for module in ansible_modules):
            if in_shell and shell_content:
                result.append('    shell: |')
                for shell_line in shell_content:
                    result.append('      ' + shell_line)
                shell_content = []
                in_shell = False
            result.append('    ' + stripped)
            i += 1
            continue
            
        # Default: treat as continuation or attribute
        if current_task and not in_shell:
            result.append('    ' + stripped)
        elif current_play and not current_task and not in_shell:
            result.append('  ' + stripped)
        elif in_shell:
            shell_content.append(stripped)
        else:
            # Skip malformed lines
            pass
            
        i += 1
    
    # Close any open shell block
    if in_shell and shell_content:
        result.append('    shell: |')
        for shell_line in shell_content:
            result.append('      ' + shell_line)
    
    return '\n'.join(result)

def rebuild_vars_file(content):
    """Rebuild a vars file"""
    lines = [line.rstrip() for line in content.split('\n')]
    result = ['---']
    
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith('#') or stripped == '---':
            continue
            
        if ':' in stripped and not stripped.startswith('-'):
            result.append(stripped)
    
    return '\n'.join(result)

def rebuild_meta_file(content):
    """Rebuild a meta/main.yml file"""
    return '''---
galaxy_info:
  author: Unknown
  description: Ansible role
  company: ""
  license: license (MIT)
  min_ansible_version: "2.1"
  platforms:
    - name: EL
      versions:
        - "7"
        - "8"
        - "9"
  galaxy_tags: []

dependencies: []'''

def nuclear_yaml_fix(file_path):
    """Nuclear option - completely rebuild the YAML file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        filename = str(file_path)
        
        # Different strategies for different file types
        if 'meta/main.yml' in filename:
            new_content = rebuild_meta_file(content)
        elif any(keyword in filename for keyword in ['vars/', 'defaults/', 'group_vars/']):
            new_content = rebuild_vars_file(content)
        elif filename.endswith('.yml') or filename.endswith('.yaml'):
            new_content = rebuild_ansible_playbook(content, filename)
        else:
            return None, False, "Unknown file type"
        
        # Test the result
        try:
            yaml.safe_load(new_content)
            return new_content, True, "Nuclear rebuild successful"
        except yaml.YAMLError as e:
            return new_content, False, f"Rebuild failed: {str(e)[:100]}"
            
    except Exception as e:
        return None, False, f"File error: {str(e)}"

def nuclear_fix_directory(directory):
    """Apply nuclear fix to all YAML files"""
    yaml_files = []
    for ext in ['*.yml', '*.yaml']:
        yaml_files.extend(Path(directory).rglob(ext))
    
    yaml_files = [f for f in yaml_files if not f.name.endswith('.backup')]
    
    fixed = 0
    failed = 0
    
    print(f"Nuclear fixing {len(yaml_files)} YAML files...")
    
    for file_path in sorted(yaml_files):
        content, success, message = nuclear_yaml_fix(file_path)
        
        if success and content:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"☢️  {file_path}: {message}")
                fixed += 1
            except Exception as e:
                print(f"❌ {file_path}: Write error - {e}")
                failed += 1
        else:
            print(f"❌ {file_path}: {message}")
            failed += 1
    
    print(f"\n{'='*60}")
    print(f"Nuclear Fix Summary:")
    print(f"Fixed: {fixed}")
    print(f"Failed: {failed}")
    print(f"Total: {len(yaml_files)}")

if __name__ == "__main__":
    nuclear_fix_directory("/home/sgallego/Downloads/GIT/updates-and-patching")
