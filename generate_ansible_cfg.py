#!/usr/bin/env python3
"""
Ansible Configuration Generator
This script generates ansible.cfg files from templates, using credentials from env.yml
"""

import os
import sys
import yaml
import argparse
import re
from pathlib import Path
from jinja2 import Template, Environment, FileSystemLoader

# Default locations
HOME = os.path.expanduser("~")
ENV_FILE = os.path.join(HOME, ".ansible", "conf", "env.yml")
DEFAULT_PROJECT_ROOT = os.getcwd()

def parse_args():
    parser = argparse.ArgumentParser(description="Generate ansible.cfg from template and environment variables")
    parser.add_argument("--env-file", default=ENV_FILE, help="Path to environment YAML file")
    parser.add_argument("--project-root", default=DEFAULT_PROJECT_ROOT, help="Project root directory")
    parser.add_argument("--template", default="templates/ansible.cfg.j2", help="Path to ansible.cfg.j2 template file")
    parser.add_argument("--output", default="ansible.cfg", help="Output file path")
    return parser.parse_args()

def ensure_env_file(env_file_path):
    """Ensure the env file exists, create if it doesn't"""
    env_dir = os.path.dirname(env_file_path)
    
    if not os.path.exists(env_dir):
        os.makedirs(env_dir, mode=0o700)
    
    if not os.path.exists(env_file_path):
        # Create a default env.yml with placeholders
        default_content = {
            "RH_CREDENTIALS_TOKEN": "",
            "REDHAT_CDN_USERNAME": "",
            "REDHAT_CDN_PASSWORD": "",
            "AUTOMATION_HUB_URL": "https://console.redhat.com/api/automation-hub/",
            "GALAXY_SERVER_URL": "https://galaxy.ansible.com/"
        }
        
        with open(env_file_path, 'w') as f:
            yaml.dump(default_content, f, default_flow_style=False)
        
        os.chmod(env_file_path, 0o600)
        print(f"Created default environment file at {env_file_path}")
        print("Please update it with your credentials")
        return default_content
    
    return load_env_file(env_file_path)

def load_env_file(env_file_path):
    """Load the environment variables from YAML file"""
    try:
        with open(env_file_path, 'r') as f:
            env_vars = yaml.safe_load(f) or {}
        return env_vars
    except Exception as e:
        print(f"Error loading environment file: {e}")
        return {}

def prompt_for_missing_credentials(env_vars):
    """Prompt for any missing credentials"""
    updated = False
    
    # Check for Red Hat Credentials Token
    if not env_vars.get('RH_CREDENTIALS_TOKEN'):
        print("\nRed Hat Automation Hub token not found.")
        token = input("Enter your Red Hat Credentials Token (or press Enter to skip): ").strip()
        if token:
            env_vars['RH_CREDENTIALS_TOKEN'] = token
            updated = True
    
    # Check for Red Hat CDN Username
    if not env_vars.get('REDHAT_CDN_USERNAME'):
        print("\nRed Hat CDN username not found.")
        username = input("Enter your Red Hat CDN username (or press Enter to skip): ").strip()
        if username:
            env_vars['REDHAT_CDN_USERNAME'] = username
            updated = True
    
    # Check for Red Hat CDN Password if username is provided
    if env_vars.get('REDHAT_CDN_USERNAME') and not env_vars.get('REDHAT_CDN_PASSWORD'):
        import getpass
        print("\nRed Hat CDN password not found.")
        password = getpass.getpass("Enter your Red Hat CDN password: ").strip()
        if password:
            env_vars['REDHAT_CDN_PASSWORD'] = password
            updated = True
    
    return env_vars, updated

def save_env_file(env_file_path, env_vars):
    """Save updated environment variables to YAML file"""
    try:
        with open(env_file_path, 'w') as f:
            yaml.dump(env_vars, f, default_flow_style=False)
        os.chmod(env_file_path, 0o600)
        print(f"Updated environment file at {env_file_path}")
    except Exception as e:
        print(f"Error saving environment file: {e}")

def generate_ansible_cfg(template_path, output_path, env_vars):
    """Generate ansible.cfg from template using environment variables"""
    try:
        template_dir = os.path.dirname(template_path)
        template_file = os.path.basename(template_path)
        
        env = Environment(loader=FileSystemLoader(template_dir))
        template = env.get_template(template_file)
        
        # Create a variables dictionary for Jinja2
        context = env_vars.copy()
        
        # Add additional variables used in the template
        context.update({
            'project_dir': os.path.dirname(output_path),
            'inventory_path': './inventory',
            'timestamp': '{{ "%Y-%m-%d %H:%M:%S" | strftime }}',
        })
        
        # Render the template
        output = template.render(**context)
        
        # Create output directory if it doesn't exist
        output_dir = os.path.dirname(output_path)
        if output_dir and not os.path.exists(output_dir):
            os.makedirs(output_dir)
        
        # Write the rendered output to the file
        with open(output_path, 'w') as f:
            f.write(output)
        
        print(f"Generated ansible.cfg at {output_path}")
        return True
    except Exception as e:
        print(f"Error generating ansible.cfg: {e}")
        return False

def update_gitignore(project_root):
    """Update .gitignore to exclude sensitive files"""
    gitignore_path = os.path.join(project_root, '.gitignore')
    ignore_entries = [
        "# Ansible generated files",
        "ansible.cfg",
        "*.retry",
        "",
        "# Credentials and secrets",
        "env.yml",
        "*.vault",
        "vault.yml",
        "vault.yaml",
        "",
        "# Backup files",
        "*backup*/",
        "*backup*",
        "*BACKUP*/",
        "*BACKUP*",
        "*Backup*/",
        "*Backup*",
        "*bak*/",
        "*bak",
        "*.bak",
        "*.BAK",
        "*~",
        "*.old",
        "*.orig",
        "*.swp",
        "*.swo",
        "",
        "# Python bytecode",
        "__pycache__/",
        "*.py[cod]",
        "*$py.class",
        "*.so",
        ".Python",
        "env/",
        "venv/",
        "ENV/",
        ".venv/",
        ""
    ]
    
    existing_entries = set()
    if os.path.exists(gitignore_path):
        with open(gitignore_path, 'r') as f:
            existing_entries = set(line.strip() for line in f.readlines())
    
    # Add missing entries
    with open(gitignore_path, 'a+') as f:
        f.seek(0)
        content = f.read()
        
        # If file is not empty and doesn't end with newline, add one
        if content and not content.endswith('\n'):
            f.write('\n')
        
        for entry in ignore_entries:
            if entry not in existing_entries:
                f.write(f"{entry}\n")
    
    print(f"Updated .gitignore at {gitignore_path}")

def main():
    args = parse_args()
    
    # Calculate paths
    project_root = os.path.abspath(args.project_root)
    env_file_path = os.path.abspath(args.env_file)
    template_path = os.path.join(project_root, args.template)
    output_path = os.path.join(project_root, args.output)
    
    print(f"Project root: {project_root}")
    print(f"Environment file: {env_file_path}")
    print(f"Template path: {template_path}")
    print(f"Output path: {output_path}")
    
    # Ensure template file exists
    if not os.path.exists(template_path):
        print(f"Error: Template file not found at {template_path}")
        return 1
    
    # Load/create environment file
    env_vars = ensure_env_file(env_file_path)
    
    # Prompt for missing credentials
    env_vars, updated = prompt_for_missing_credentials(env_vars)
    
    # Save updated env file if changes were made
    if updated:
        save_env_file(env_file_path, env_vars)
    
    # Generate ansible.cfg
    if not generate_ansible_cfg(template_path, output_path, env_vars):
        return 1
    
    # Update .gitignore
    update_gitignore(project_root)
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
