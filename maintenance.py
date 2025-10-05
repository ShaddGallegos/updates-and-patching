#!/usr/bin/env python3
"""
LVM Auto-Extension Maintenance Tool
Project maintenance and setup utility for Add_LVM_to_System_nutanix
"""

import os
import sys
import shutil
import subprocess
from pathlib import Path
from datetime import datetime

class C:
    """Color codes for terminal output"""
    R = '\033[0;31m'  # Red
    G = '\033[0;32m'  # Green
    Y = '\033[0;33m'  # Yellow
    B = '\033[0;34m'  # Blue
    M = '\033[0;35m'  # Magenta
    C = '\033[0;36m'  # Cyan
    N = '\033[0m'     # Reset

class ProjectMaintenance:
    """Main maintenance tool class"""
    
    # Role task templates
    ROLE_TASKS = {
        'servicenow_ticket_management': """---
- name: Manage ServiceNow tickets
  uri:
    url: "https://{{ servicenow_instance }}.service-now.com/api/now/table/incident"
    method: POST
    user: "{{ servicenow_username }}"
    password: "{{ servicenow_password }}"
    body_format: json
    body:
      short_description: "{{ ticket_description }}"
      urgency: "{{ ticket_urgency | default('3') }}"
      impact: "{{ ticket_impact | default('3') }}"
    force_basic_auth: yes
    status_code: 201
  register: servicenow_result
  when: create_ticket | default(false)

- name: Display ticket information
  debug:
    msg: "Ticket created: {{ servicenow_result.json.result.number }}"
  when: servicenow_result is defined and servicenow_result.json is defined
""",

        'lvm_smart_extend': """---
- name: Check if filesystem is LVM
  shell: "df {{ mount_point }} | tail -1 | awk '{print $1}' | xargs lvdisplay 2>/dev/null"
  register: lvm_check
  failed_when: false
  changed_when: false

- name: Extend LVM if space available
  block:
    - name: Get volume group free space
      shell: "vgdisplay {{ vg_name }} | grep 'Free' | awk '{print $7}'"
      register: vg_free_space

    - name: Extend logical volume
      lvol:
        vg: "{{ vg_name }}"
        lv: "{{ lv_name }}"
        size: "+{{ extend_size | default('10G') }}"
      when: vg_free_space.stdout | int > 0

    - name: Resize filesystem
      filesystem:
        fstype: "{{ fstype | default('xfs') }}"
        dev: "/dev/{{ vg_name }}/{{ lv_name }}"
        resizefs: yes
  when: lvm_check.rc == 0
""",

        'lvm_system_inspection': """---
- name: Gather LVM facts
  setup:
    gather_subset:
      - hardware
      - mounts

- name: Check LVM configuration
  command: pvs --noheadings -o pv_name,vg_name
  register: lvm_pvs
  changed_when: false

- name: Check logical volumes
  command: lvs --noheadings -o lv_name,vg_name,lv_size
  register: lvm_lvs
  changed_when: false

- name: Check volume groups
  command: vgs --noheadings -o vg_name,vg_size,vg_free
  register: lvm_vgs
  changed_when: false

- name: Display LVM information
  debug:
    msg:
      - "Physical Volumes: {{ lvm_pvs.stdout_lines }}"
      - "Logical Volumes: {{ lvm_lvs.stdout_lines }}"
      - "Volume Groups: {{ lvm_vgs.stdout_lines }}"
"""
    }
    
    # Role defaults templates
    ROLE_DEFAULTS = {
        'servicenow_ticket_management': """---
# ServiceNow Ticket Management Defaults
servicenow_instance: "{{ lookup('env', 'SNOW_INSTANCE') }}"
servicenow_username: "{{ lookup('env', 'SNOW_USER') }}"
servicenow_password: "{{ lookup('env', 'SNOW_PASS') }}"
ticket_urgency: 3
ticket_impact: 3
create_ticket: false
""",

        'lvm_smart_extend': """---
# LVM Smart Extend Defaults
extend_percent: 20
threshold_percent: 80
critical_threshold_percent: 90
extend_size: "10G"
fstype: "xfs"
""",

        'lvm_system_inspection': """---
# LVM System Inspection Defaults
check_interval: 300
alert_threshold: 80
"""
    }
    
    # Playbook templates
    PLAYBOOK_TEMPLATES = {
        'servicenow_create_ticket.yml': """---
- name: Create ServiceNow Ticket
  hosts: localhost
  gather_facts: no
  vars:
    ticket_description: "LVM disk space alert"
    ticket_urgency: "2"
    ticket_impact: "2"
  tasks:
    - name: Create incident ticket
      uri:
        url: "https://{{ servicenow_instance }}.service-now.com/api/now/table/incident"
        method: POST
        user: "{{ servicenow_username }}"
        password: "{{ servicenow_password }}"
        body_format: json
        body:
          short_description: "{{ ticket_description }}"
          urgency: "{{ ticket_urgency }}"
          impact: "{{ ticket_impact }}"
        force_basic_auth: yes
        status_code: 201
      register: ticket_result

    - name: Display ticket number
      debug:
        msg: "Ticket created: {{ ticket_result.json.result.number }}"
""",

        'servicenow_update_ticket.yml': """---
- name: Update ServiceNow Ticket
  hosts: localhost
  gather_facts: no
  vars:
    ticket_number: "{{ incident_number }}"
    update_message: "LVM extension completed successfully"
  tasks:
    - name: Update incident ticket
      uri:
        url: "https://{{ servicenow_instance }}.service-now.com/api/now/table/incident/{{ ticket_number }}"
        method: PATCH
        user: "{{ servicenow_username }}"
        password: "{{ servicenow_password }}"
        body_format: json
        body:
          work_notes: "{{ update_message }}"
        force_basic_auth: yes
        status_code: 200
      register: update_result

    - name: Display update confirmation
      debug:
        msg: "Ticket {{ ticket_number }} updated"
""",

        'servicenow_close_ticket.yml': """---
- name: Close ServiceNow Ticket
  hosts: localhost
  gather_facts: no
  vars:
    ticket_number: "{{ incident_number }}"
    close_notes: "Issue resolved - LVM extended successfully"
  tasks:
    - name: Close incident ticket
      uri:
        url: "https://{{ servicenow_instance }}.service-now.com/api/now/table/incident/{{ ticket_number }}"
        method: PATCH
        user: "{{ servicenow_username }}"
        password: "{{ servicenow_password }}"
        body_format: json
        body:
          state: "6"
          close_notes: "{{ close_notes }}"
        force_basic_auth: yes
        status_code: 200
      register: close_result

    - name: Display close confirmation
      debug:
        msg: "Ticket {{ ticket_number }} closed"
""",

        'servicenow_create_manual_ticket.yml': """---
- name: Create Manual ServiceNow Ticket
  hosts: localhost
  gather_facts: yes
  tasks:
    - name: Prompt for ticket details
      pause:
        prompt: "Enter ticket description"
      register: ticket_desc

    - name: Create incident
      uri:
        url: "https://{{ servicenow_instance }}.service-now.com/api/now/table/incident"
        method: POST
        user: "{{ servicenow_username }}"
        password: "{{ servicenow_password }}"
        body_format: json
        body:
          short_description: "{{ ticket_desc.user_input }}"
          urgency: "3"
          impact: "3"
        force_basic_auth: yes
        status_code: 201
      register: manual_ticket

    - name: Show ticket number
      debug:
        msg: "Manual ticket created: {{ manual_ticket.json.result.number }}"
""",

        'non_lvm_alert.yml': """---
- name: Alert for Non-LVM Filesystem
  hosts: localhost
  gather_facts: no
  vars:
    alert_message: "Non-LVM filesystem detected - cannot auto-extend"
  tasks:
    - name: Send alert
      debug:
        msg: "{{ alert_message }}"

    - name: Log to file
      lineinfile:
        path: /var/log/lvm-automation.log
        line: "{{ ansible_date_time.iso8601 }} - {{ alert_message }}"
        create: yes
""",

        'unsupported_os_alert.yml': """---
- name: Alert for Unsupported OS
  hosts: localhost
  gather_facts: yes
  tasks:
    - name: Check OS support
      debug:
        msg: "OS {{ ansible_distribution }} {{ ansible_distribution_version }} may not be fully supported"

    - name: Log warning
      lineinfile:
        path: /var/log/lvm-automation.log
        line: "{{ ansible_date_time.iso8601 }} - Unsupported OS: {{ ansible_distribution }}"
        create: yes
"""
    }
    
    # Script templates
    SCRIPT_TEMPLATES = {
        'start_eda.sh': """#!/bin/bash
# Start Event-Driven Ansible controller

set -e

echo "Starting EDA controller..."

ansible-rulebook --rulebook playbooks/rulebook.yml \\
  --inventory inventory/hosts \\
  --verbose &

echo "EDA controller started (PID: $!)"
echo "Webhook endpoint: http://localhost:5000/webhook"
""",

        'test_webhook.sh': """#!/bin/bash
# Test webhook functionality

set -e

WEBHOOK_URL="${WEBHOOK_URL:-http://localhost:5000/webhook}"
HOSTNAME="${HOSTNAME:-$(hostname)}"

echo "Testing webhook at: $WEBHOOK_URL"

# Test high disk usage alert
curl -X POST "$WEBHOOK_URL" \\
  -H 'Content-Type: application/json' \\
  -d '{
    "hostname": "'"$HOSTNAME"'",
    "disk_usage_percent": 92,
    "mount_point": "/",
    "device": "/dev/mapper/rhel-root",
    "is_lvm": true,
    "vg_name": "rhel",
    "lv_name": "root"
  }'

echo -e "\\n\\nTest completed"
""",

        'test_email_notifications.sh': """#!/bin/bash
# Test email notifications

echo "Testing email notification configuration..."

ansible localhost -m community.general.mail -a "\\
  host=${SMTP_HOST:-localhost} \\
  port=${SMTP_PORT:-25} \\
  to=${TEST_EMAIL:-admin@example.com} \\
  subject='LVM Automation Test Email' \\
  body='This is a test email from the LVM automation system.'"

echo "Test email sent"
""",

        'setup_monitoring_cron.sh': """#!/bin/bash
# Setup monitoring cron job

set -e

WEBHOOK_URL="${WEBHOOK_URL:-http://eda-controller:5000/webhook}"

echo "Setting up disk monitoring cron job..."

cat > /usr/local/bin/lvm-disk-monitor.sh << 'EOF'
#!/bin/bash
WEBHOOK_URL="$WEBHOOK_URL"
HOSTNAME="$(hostname)"

df -h | grep -E '^/dev/' | while read line; do
    USAGE=$(echo $line | awk '{print $5}' | tr -d '%')
    MOUNT=$(echo $line | awk '{print $6}')
    DEVICE=$(echo $line | awk '{print $1}')
    
    if [ $USAGE -ge 90 ]; then
        curl -X POST "$WEBHOOK_URL" \\
          -H 'Content-Type: application/json' \\
          -d "{\\"hostname\\": \\"$HOSTNAME\\", \\"disk_usage_percent\\": $USAGE, \\"mount_point\\": \\"$MOUNT\\", \\"device\\": \\"$DEVICE\\"}"
    fi
done
EOF

chmod +x /usr/local/bin/lvm-disk-monitor.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/lvm-disk-monitor.sh") | crontab -

echo "Monitoring cron job installed"
"""
    }
    
    def __init__(self):
        self.root = Path("/home/runner/work/updates-and-patching/updates-and-patching")
        os.chdir(self.root)
        self.backup = self.root / "backups"
        self.roles = ['servicenow_ticket_management', 'lvm_smart_extend', 'lvm_system_inspection', 
                     'lvm_extension_orchestrator', 'disk_usage_alerting']
        
    def cls(self): 
        os.system('clear')
        
    def pause(self): 
        input(f"\n{C.Y}Press [Enter]...{C.N}")
        
    def backup_dir(self, name): 
        d = self.backup / f"{name}_{datetime.now():%Y%m%d_%H%M%S}"
        d.mkdir(parents=True, exist_ok=True)
        return d
        
    def header(self, title):
        self.cls()
        print(f"{C.C}╔═════════════════════════════════════════╗{C.N}")
        print(f"{C.C}║  {title:^39}║{C.N}")
        print(f"{C.C}╚═════════════════════════════════════════╝{C.N}\n")
        
    def create_role(self, name):
        """Create role structure"""
        rp = self.root / "roles" / name
        for d in ['tasks', 'defaults', 'vars', 'handlers', 'meta', 'templates', 'files']:
            (rp / d).mkdir(parents=True, exist_ok=True)
            
        (rp / "tasks/main.yml").write_text(self.ROLE_TASKS.get(name, 
            f"---\n- debug: {{msg: 'Role {name} needs implementation'}}\n"))
        (rp / "defaults/main.yml").write_text(self.ROLE_DEFAULTS.get(name, 
            f"---\n# {name.replace('_',' ').title()} Defaults\n"))
        (rp / "meta/main.yml").write_text(f"""---
galaxy_info:
  author: System Administrator
  description: {name.replace('_',' ').title()}
  license: MIT
  min_ansible_version: 2.9
  platforms:
    - name: EL
      versions:
        - 8
        - 9
dependencies: []
""")
        (rp / "README.md").write_text(f"""# {name.replace('_',' ').title()}

## Description
Handles {name.replace('_',' ')}.

## Requirements
- RHEL/CentOS 8+
- Ansible 2.9+

## Example
```yaml
- hosts: servers
  roles:
    - {name}
```
""")
        return rp

    def create_playbook(self, name, content):
        """Create playbook file"""
        pb_path = self.root / "playbooks" / name
        if pb_path.exists():
            print(f"  {C.Y}⚠{C.N} {name} already exists, skipping")
            return False
        pb_path.write_text(content)
        print(f"  {C.G}✓{C.N} Created {name}")
        return True

    def create_script(self, name, content):
        """Create script file"""
        script_path = self.root / name
        if script_path.exists():
            print(f"  {C.Y}⚠{C.N} {name} already exists, skipping")
            return False
        script_path.write_text(content)
        script_path.chmod(0o755)
        print(f"  {C.G}✓{C.N} Created {name} (executable)")
        return True
        
    def missing_roles(self):
        """Get missing roles"""
        missing = []
        rd = self.root / "roles"
        for r in self.roles:
            rp = rd / r
            if not rp.exists() or not all((rp/f).exists() for f in ['tasks/main.yml','defaults/main.yml','meta/main.yml']):
                missing.append(r)
        return missing
        
    def create_missing(self, roles=None):
        """Create missing roles"""
        for r in roles or self.missing_roles():
            print(f"\n{C.Y}Creating: {r}{C.N}")
            self.create_role(r)
            print(f"{C.G}✓{C.N} Created {r}")

    def create_missing_playbooks(self):
        """Create missing ServiceNow and alert playbooks"""
        self.header("Create Missing Playbooks")
        print(f"{C.Y}Creating missing playbooks...{C.N}\n")
        
        (self.root / "playbooks").mkdir(exist_ok=True)
        
        created = 0
        for name, content in self.PLAYBOOK_TEMPLATES.items():
            if self.create_playbook(name, content):
                created += 1
        
        if created > 0:
            print(f"\n{C.G}✓ Created {created} playbooks{C.N}")
        else:
            print(f"\n{C.Y}All playbooks already exist{C.N}")
        
        self.pause()

    def create_missing_scripts(self):
        """Create missing utility scripts"""
        self.header("Create Missing Scripts")
        print(f"{C.Y}Creating missing scripts...{C.N}\n")
        
        created = 0
        for name, content in self.SCRIPT_TEMPLATES.items():
            if self.create_script(name, content):
                created += 1
        
        if created > 0:
            print(f"\n{C.G}✓ Created {created} scripts{C.N}")
        else:
            print(f"\n{C.Y}All scripts already exist{C.N}")
        
        self.pause()

    def create_license(self):
        """Create LICENSE file"""
        license_path = self.root / "LICENSE"
        if license_path.exists():
            print(f"{C.Y}LICENSE already exists{C.N}")
            return
        
        license_content = f"""MIT License

Copyright (c) {datetime.now().year} LVM Automation Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""
        license_path.write_text(license_content)
        print(f"{C.G}✓{C.N} Created LICENSE")

    def create_all_missing_components(self):
        """Create all missing components at once"""
        self.header("Create All Missing Components")
        print(f"{C.Y}This will create:{C.N}")
        print(f"  • Missing roles")
        print(f"  • ServiceNow playbooks")
        print(f"  • Alert playbooks")
        print(f"  • Utility scripts")
        print(f"  • LICENSE file")
        print()
        
        if input(f"{C.Y}Continue? [Y/n]: {C.N}").strip().lower() == 'n':
            print(f"{C.Y}Cancelled{C.N}")
            self.pause()
            return
        
        print(f"\n{C.C}━━━ Creating Roles ━━━{C.N}\n")
        if m := self.missing_roles():
            self.create_missing(m)
        else:
            print(f"{C.G}All roles exist{C.N}")
        
        print(f"\n{C.C}━━━ Creating Playbooks ━━━{C.N}\n")
        (self.root / "playbooks").mkdir(exist_ok=True)
        pb_created = 0
        for name, content in self.PLAYBOOK_TEMPLATES.items():
            if self.create_playbook(name, content):
                pb_created += 1
        
        print(f"\n{C.C}━━━ Creating Scripts ━━━{C.N}\n")
        script_created = 0
        for name, content in self.SCRIPT_TEMPLATES.items():
            if self.create_script(name, content):
                script_created += 1
        
        print(f"\n{C.C}━━━ Creating LICENSE ━━━{C.N}\n")
        self.create_license()
        
        print(f"\n{C.G}╔═════════════════════════════════════════╗{C.N}")
        print(f"{C.G}║        Component Creation Complete      ║{C.N}")
        print(f"{C.G}╚═════════════════════════════════════════╝{C.N}\n")
        print(f"{C.B}Summary:{C.N}")
        print(f"  • Playbooks created: {pb_created}")
        print(f"  • Scripts created: {script_created}")
        print(f"  • Roles validated/created")
        print(f"  • LICENSE file created")
        
        self.pause()
            
    # SETUP MENU
    def menu_setup(self):
        while True:
            self.header("Setup & Initialization")
            print(f"  {C.G}1){C.N} Initial project setup")
            print(f"  {C.G}2){C.N} Check roles")
            print(f"  {C.G}3){C.N} Create missing roles")
            print(f"  {C.G}4){C.N} Recreate all roles")
            print(f"  {C.G}5){C.N} Create missing playbooks")
            print(f"  {C.G}6){C.N} Create missing scripts")
            print(f"  {C.G}7){C.N} Create all missing components")
            print(f"\n  {C.R}0){C.N} Back\n")
            choice = input("Choice [0-7]: ").strip()
            if choice == '1': 
                self.initial_setup()
            elif choice == '2': 
                self.check_roles()
            elif choice == '3': 
                self.setup_roles()
            elif choice == '4': 
                self.create_all_roles()
            elif choice == '5': 
                self.create_missing_playbooks()
            elif choice == '6': 
                self.create_missing_scripts()
            elif choice == '7': 
                self.create_all_missing_components()
            elif choice == '0': 
                break
                
    def initial_setup(self):
        self.header("Initial Setup")
        print(f"{C.Y}Creating structure...{C.N}\n")
        
        (self.root / "inventory/group_vars").mkdir(parents=True, exist_ok=True)
        (self.root / "playbooks").mkdir(parents=True, exist_ok=True)
        
        if not (hf := self.root / "inventory/hosts").exists():
            hf.write_text("# Ansible Inventory\n[nutanix_hosts]\n# server01.example.com\n\n[lvm_servers:children]\nnutanix_hosts\n\n[all:vars]\nansible_user=ansible\nansible_become=true\n")
            print(f"{C.G}✓{C.N} Created inventory/hosts")
            
        if not (av := self.root / "inventory/group_vars/all.yml").exists():
            av.write_text("---\nservicenow_instance: \"{{lookup('env','SNOW_INSTANCE')}}\"\nservicenow_username: \"{{lookup('env','SNOW_USER')}}\"\nservicenow_password: \"{{lookup('env','SNOW_PASS')}}\"\nnutanix_host: \"{{lookup('env','NUTANIX_HOST')}}\"\nnutanix_username: \"{{lookup('env','NUTANIX_USER')}}\"\nnutanix_password: \"{{lookup('env','NUTANIX_PASS')}}\"\nextend_percent: 20\nthreshold_percent: 80\ncritical_threshold_percent: 90\n")
            print(f"{C.G}✓{C.N} Created group_vars/all.yml")
            
        if not (ee := self.root / ".env.example").exists():
            ee.write_text("export SNOW_INSTANCE=dev12345\nexport SNOW_USER=admin\nexport SNOW_PASS=password\nexport NUTANIX_HOST=nutanix.example.com\nexport NUTANIX_USER=admin\nexport NUTANIX_PASS=password\n")
            print(f"{C.G}✓{C.N} Created .env.example")
            
        print(f"\n{C.Y}Checking roles...{C.N}\n")
        if m := self.missing_roles():
            print(f"{C.Y}{len(m)} missing{C.N}")
            for r in m:
                print(f"  {C.R}✗{C.N} {r}")
            if input(f"\n{C.Y}Create? [Y/n]: {C.N}").strip().lower() != 'n':
                self.create_missing(m)
        else: 
            print(f"{C.G}✓ All roles present{C.N}")
        print(f"\n{C.G}Setup complete!{C.N}")
        self.pause()
        
    def check_roles(self):
        self.header("Check Roles")
        rd = self.root / "roles"
        for r in self.roles:
            rp = rd / r
            if rp.exists():
                print(f"{C.G}✓{C.N} {r}")
                for f in ['tasks/main.yml','defaults/main.yml','meta/main.yml']:
                    exists = (rp/f).exists()
                    print(f"  {C.G if exists else C.R}{'✓' if exists else '✗'}{C.N} {f}")
            else: 
                print(f"{C.R}✗{C.N} {r} (not found)")
        if m := self.missing_roles():
            print(f"\n{C.Y}Missing: {len(m)}{C.N}")
            if input(f"{C.Y}Create? [Y/n]: {C.N}").strip().lower() != 'n':
                self.create_missing(m)
                print(f"\n{C.G}✓ Created{C.N}")
        else: 
            print(f"\n{C.G}✓ All complete{C.N}")
        self.pause()
        
    def setup_roles(self):
        self.header("Setup Missing Roles")
        if m := self.missing_roles():
            print(f"{C.Y}{len(m)} missing{C.N}\n")
            for r in m:
                print(f"  {C.R}✗{C.N} {r}")
            print()
            self.create_missing(m)
            print(f"\n{C.G}✓ All created{C.N}")
        else: 
            print(f"{C.G}✓ All complete{C.N}")
        self.pause()
        
    def create_all_roles(self):
        self.header("Recreate All Roles")
        print(f"{C.Y}This recreates all role structures{C.N}")
        if input(f"{C.R}Continue? [y/N]: {C.N}").strip().lower() == 'y':
            bd = self.backup_dir("roles_recreate")
            if (rd := self.root / "roles").exists():
                shutil.copytree(rd, bd / "roles", dirs_exist_ok=True)
                print(f"{C.G}✓{C.N} Backed up\n")
            for r in self.roles:
                print(f"{C.Y}Creating {r}...{C.N}")
                self.create_role(r)
                print(f"{C.G}✓{C.N} {r}")
            print(f"\n{C.G}Complete!{C.N}\n{C.B}Backup: {bd}{C.N}")
        else: 
            print(f"{C.Y}Cancelled{C.N}")
        self.pause()
        
    # CONSOLIDATION MENU
    def menu_consolidation(self):
        while True:
            self.header("Consolidation")
            print(f"  {C.G}1){C.N} Reorganize playbooks")
            print(f"  {C.G}2){C.N} Organize scripts")
            print(f"  {C.G}3){C.N} Organize tests")
            print(f"  {C.G}4){C.N} Full consolidation")
            print(f"\n  {C.R}0){C.N} Back\n")
            choice = input("Choice [0-4]: ").strip()
            if choice == '1': 
                self.reorg_playbooks()
            elif choice == '2': 
                self.org_scripts()
            elif choice == '3': 
                self.org_tests()
            elif choice == '4': 
                self.full_consol()
            elif choice == '0': 
                break
                
    def reorg_playbooks(self):
        self.header("Reorganize Playbooks")
        (pd := self.root / "playbooks").mkdir(exist_ok=True)
        bd = self.backup_dir("playbook_reorg")
        moved = 0
        for yf in self.root.glob("*.yml"):
            if yf.name not in ['requirements.yml','site.yml']:
                shutil.copy2(yf, bd)
                shutil.move(str(yf), str(pd / yf.name))
                print(f"{C.G}✓{C.N} {yf.name}")
                moved += 1
        print(f"\n{C.G}Moved {moved}{C.N}\n{C.B}Backup: {bd}{C.N}")
        self.pause()
        
    def org_scripts(self):
        self.header("Organize Scripts")
        (self.root / "scripts/operations").mkdir(parents=True, exist_ok=True)
        (self.root / "scripts/maintenance").mkdir(parents=True, exist_ok=True)
        print(f"{C.G}✓{C.N} Script dirs ready\n  - scripts/operations/\n  - scripts/maintenance/")
        self.pause()
        
    def org_tests(self):
        self.header("Organize Tests")
        td = self.root / "tests"
        for sd in ['unit','integration','molecule','fixtures']:
            (td / sd).mkdir(parents=True, exist_ok=True)
            print(f"{C.G}✓{C.N} tests/{sd}/")
        self.pause()
        
    def full_consol(self):
        self.header("Full Consolidation")
        print(f"{C.Y}Running all tasks...{C.N}\n")
        input(f"{C.Y}Press Enter for playbooks...{C.N}")
        self.reorg_playbooks()
        input(f"\n{C.Y}Press Enter for scripts...{C.N}")
        self.org_scripts()
        input(f"\n{C.Y}Press Enter for tests...{C.N}")
        self.org_tests()
        print(f"\n{C.G}Complete!{C.N}")
        self.pause()
        
    # ANALYSIS MENU
    def menu_analysis(self):
        while True:
            self.header("Analysis & Reporting")
            print(f"  {C.G}1){C.N} Analyze obsolete")
            print(f"  {C.G}2){C.N} Analyze YAML")
            print(f"  {C.G}3){C.N} Generate report")
            print(f"\n  {C.R}0){C.N} Back\n")
            choice = input("Choice [0-3]: ").strip()
            if choice == '1': 
                self.analyze_obsolete()
            elif choice == '2': 
                self.analyze_yaml()
            elif choice == '3': 
                self.gen_report()
            elif choice == '0': 
                break
                
    def analyze_obsolete(self):
        self.header("Analyze Obsolete")
        rf = f"obsolete_analysis_{datetime.now():%Y%m%d_%H%M%S}.txt"
        items = []
        for pat in ['*.backup','*.bak','*~','*.swp']:
            items.extend([str(f) for f in self.root.rglob(pat) if '.git' not in str(f) and 'backups' not in str(f)])
        items.extend([str(d) for d in self.root.rglob('__pycache__') if '.git' not in str(d)])
        
        with open(rf, 'w') as f:
            f.write(f"Obsolete Analysis - {datetime.now()}\n{'='*50}\n\nTotal: {len(items)}\n\n")
            for i in items:
                f.write(f"  - {i}\n")
        
        print(f"{C.Y}Found {len(items)}{C.N}")
        if items:
            print(f"\n{C.B}Items:{C.N}")
            for i in items[:10]:
                print(f"  - {Path(i).name}")
            if len(items) > 10: 
                print(f"  ... +{len(items)-10} more")
        print(f"\n{C.B}Report: {rf}{C.N}")
        self.pause()
        
    def analyze_yaml(self):
        self.header("Analyze YAML")
        ess = ['extend_lvm.yml','disk_usage_monitor.yml','rulebook.yml','respond_to_disk_alert.yml']
        print(f"{C.C}━━━ Essential Playbooks ━━━{C.N}\n")
        for y in ess:
            pb = self.root / "playbooks" / y
            rpb = self.root / y
            exists = pb.exists() or rpb.exists()
            loc = "playbooks/" if pb.exists() else "root" if rpb.exists() else "missing"
            print(f"  {C.G if exists else C.R}{'✓' if exists else '✗'}{C.N} {y} ({loc})")
        
        print(f"\n{C.C}━━━ ServiceNow Playbooks ━━━{C.N}\n")
        snow_pbs = ['servicenow_create_ticket.yml', 'servicenow_update_ticket.yml', 
                   'servicenow_close_ticket.yml', 'servicenow_create_manual_ticket.yml']
        for y in snow_pbs:
            pb = self.root / "playbooks" / y
            exists = pb.exists()
            print(f"  {C.G if exists else C.R}{'✓' if exists else '✗'}{C.N} {y} ({'playbooks/' if exists else 'missing'})")
        
        print(f"\n{C.C}━━━ Roles ━━━{C.N}\n")
        if (rd := self.root / "roles").exists():
            for r in sorted(rd.iterdir()):
                if r.is_dir():
                    comp = all((r/f).exists() for f in ['tasks/main.yml','defaults/main.yml','meta/main.yml'])
                    print(f"  {C.G if comp else C.Y}{'✓' if comp else '⚠'}{C.N} {r.name}")
        else: 
            print(f"  {C.R}✗ roles/ not found{C.N}")
        self.pause()
        
    def gen_report(self):
        self.header("Generate Report")
        rf = f"project_analysis_{datetime.now():%Y%m%d_%H%M%S}.txt"
        with open(rf, 'w') as f:
            f.write(f"{'='*60}\nPROJECT ANALYSIS\n{'='*60}\n\nGenerated: {datetime.now()}\nProject: {self.root}\n\n")
            f.write(f"FILE COUNTS\n{'-'*60}\nYAML: {len(list(self.root.rglob('*.yml')))}\nShell: {len(list(self.root.rglob('*.sh')))}\nPython: {len(list(self.root.rglob('*.py')))}\n\n")
            f.write(f"ROLES\n{'-'*60}\n")
            if (rd := self.root / "roles").exists():
                for r in sorted(rd.iterdir()):
                    if r.is_dir():
                        f.write(f"  - {r.name}\n")
            else: 
                f.write("  None\n")
            f.write(f"\nPLAYBOOKS\n{'-'*60}\n")
            if (pd := self.root / "playbooks").exists():
                for p in sorted(pd.glob("*.yml")):
                    f.write(f"  - {p.name}\n")
            else: 
                f.write("  None\n")
        print(f"{C.G}✓{C.N} Generated: {C.B}{rf}{C.N}")
        self.pause()
        
    # CLEANUP MENU
    def menu_cleanup(self):
        while True:
            self.header("Cleanup & Maintenance")
            print(f"  {C.G}1){C.N} Clean obsolete")
            print(f"  {C.G}2){C.N} Clean reports")
            print(f"  {C.G}3){C.N} View structure")
            print(f"  {C.G}4){C.N} View backups")
            print(f"\n  {C.R}0){C.N} Back\n")
            choice = input("Choice [0-4]: ").strip()
            if choice == '1': 
                self.clean_obsolete()
            elif choice == '2': 
                self.clean_reports()
            elif choice == '3': 
                self.view_structure()
            elif choice == '4': 
                self.view_backups()
            elif choice == '0': 
                break
                
    def clean_obsolete(self):
        self.header("Clean Obsolete")
        bd = self.backup_dir("cleanup")
        removed = 0
        for pat in ['*.backup','*.bak','*~','*.pyc','*.swp']:
            for f in self.root.rglob(pat):
                if '.git' not in str(f) and 'backups' not in str(f):
                    rel = f.relative_to(self.root)
                    bf = bd / rel
                    bf.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(f, bf)
                    f.unlink()
                    removed += 1
                    print(f"{C.G}✓{C.N} {f.name}")
        for cd in self.root.rglob('__pycache__'):
            if '.git' not in str(cd) and cd.exists():
                shutil.rmtree(cd)
                removed += 1
                print(f"{C.G}✓{C.N} {cd.relative_to(self.root)}")
        print(f"\n{C.G}Removed {removed}{C.N}\n{C.B}Backup: {bd}{C.N}")
        self.pause()
        
    def clean_reports(self):
        self.header("Clean Reports")
        if reps := list(self.root.glob("*_analysis_*.txt")):
            print(f"{C.Y}Found {len(reps)}{C.N}\n")
            for r in reps:
                print(f"  - {r.name}")
            if input(f"\n{C.R}Delete? [y/N]: {C.N}").strip().lower() == 'y':
                for r in reps:
                    r.unlink()
                for r in reps:
                    print(f"{C.G}✓{C.N} {r.name}")
                print(f"\n{C.G}Deleted {len(reps)}{C.N}")
            else: 
                print(f"{C.Y}Cancelled{C.N}")
        else: 
            print(f"{C.G}Nothing to clean{C.N}")
        self.pause()
        
    def view_structure(self):
        self.header("Project Structure")
        try: 
            subprocess.run(['tree','-L','3','-I','.git|__pycache__|backups','--dirsfirst'])
        except FileNotFoundError:
            print(f"{C.B}Structure:{C.N}\n")
            self._tree(self.root, 3)
        self.pause()
        
    def _tree(self, d, depth, prefix="", cur=0):
        if cur >= depth: 
            return
        try:
            items = sorted(d.iterdir(), key=lambda x: (not x.is_dir(), x.name))
            for i, item in enumerate(items):
                if item.name.startswith('.') or item.name in ['__pycache__','backups']: 
                    continue
                is_last = i == len(items) - 1
                print(f"{prefix}{'└── ' if is_last else '├── '}{item.name}")
                if item.is_dir():
                    self._tree(item, depth, prefix + ("    " if is_last else "│   "), cur + 1)
        except: 
            pass
        
    def view_backups(self):
        self.header("Recent Backups")
        if self.backup.exists():
            if bks := sorted(self.backup.iterdir(), key=lambda x: x.stat().st_mtime, reverse=True)[:10]:
                print(f"{C.B}Last 10:{C.N}\n")
                for b in bks:
                    sz = sum(f.stat().st_size for f in b.rglob('*') if f.is_file()) / (1024*1024)
                    mt = datetime.fromtimestamp(b.stat().st_mtime).strftime("%Y-%m-%d %H:%M")
                    print(f"  {C.G}•{C.N} {b.name}\n    {sz:.2f}MB | {mt}")
            else: 
                print(f"{C.G}None found{C.N}")
        else: 
            print(f"{C.G}No backup dir{C.N}")
        self.pause()
        
    def clean_base_scripts(self):
        self.header("Cleanup Scripts")
        print(f"{C.Y}Removing .sh from base...{C.N}\n")
        bd = self.backup_dir("script_cleanup")
        removed = 0
        for sh in self.root.glob("*.sh"):
            shutil.copy2(sh, bd)
            sh.unlink()
            print(f"{C.G}✓{C.N} {sh.name}")
            removed += 1
        print(f"\n{C.G}Removed {removed}{C.N}\n{C.B}Backup: {bd}{C.N}")
        self.pause()
        
    # MAIN
    def main(self):
        while True:
            self.cls()
            print(f"{C.C}╔═════════════════════════════════════════╗{C.N}")
            print(f"{C.C}║  LVM Auto-Extension Maintenance Tool    ║{C.N}")
            print(f"{C.C}╚═════════════════════════════════════════╝{C.N}\n")
            print(f"{C.B}Project:{C.N} updates-and-patching\n{C.B}Location:{C.N} {self.root}\n")
            print(f"{C.M}  1) Setup & Initialization{C.N}")
            print(f"{C.M}  2) Consolidation{C.N}")
            print(f"{C.M}  3) Analysis & Reporting{C.N}")
            print(f"{C.M}  4) Cleanup & Maintenance{C.N}")
            print(f"\n{C.Y}  8) Cleanup base scripts{C.N}")
            print(f"{C.Y}  9) Quick start{C.N}")
            print(f"\n{C.R}  0) Exit{C.N}\n")
            
            choice = input("Choice [0-9]: ").strip()
            if choice == '1': 
                self.menu_setup()
            elif choice == '2': 
                self.menu_consolidation()
            elif choice == '3': 
                self.menu_analysis()
            elif choice == '4': 
                self.menu_cleanup()
            elif choice == '8': 
                self.clean_base_scripts()
            elif choice == '9': 
                self.quick_start()
            elif choice == '0':
                self.cls()
                print(f"\n{C.G}╔═════════════════════════════════════════╗{C.N}")
                print(f"{C.G}║     Thank you! Goodbye!                 ║{C.N}")
                print(f"{C.G}╚═════════════════════════════════════════╝{C.N}\n")
                sys.exit(0)
            else:
                print(f"\n{C.R}Invalid{C.N}")
                self.pause()
                
    def quick_start(self):
        self.header("Quick Start")
        print(f"{C.M}━━━ Setup ━━━{C.N}\n")
        print("1. $ cp .env.example .env && vi .env")
        print("2. $ vi inventory/hosts")
        print("3. $ ./maintenance.py  # 1->7 (Create all missing)")
        print("4. $ ansible -i inventory/hosts all -m ping\n")
        print(f"{C.M}━━━ Running ━━━{C.N}\n")
        print("$ ansible-playbook playbooks/disk_usage_monitor.yml -i inventory/hosts")
        print("$ ansible-playbook playbooks/extend_lvm.yml -i inventory/hosts")
        print("$ ansible-rulebook --rulebook playbooks/rulebook.yml -i inventory/hosts\n")
        print(f"{C.M}━━━ Testing ━━━{C.N}\n")
        print("$ ./start_eda.sh  # Start EDA in background")
        print("$ ./test_webhook.sh  # Test webhook")
        print("$ ./test_email_notifications.sh  # Test emails")
        self.pause()
        
    def run(self):
        try: 
            self.main()
        except KeyboardInterrupt: 
            print(f"\n\n{C.Y}Interrupted{C.N}\n")
            sys.exit(0)
        except Exception as e: 
            print(f"\n{C.R}Error: {e}{C.N}\n")
            import traceback
            traceback.print_exc()
            sys.exit(1)

if __name__ == "__main__":
    ProjectMaintenance().run()
