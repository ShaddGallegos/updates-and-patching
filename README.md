# Updates and Patching Automation

This repository contains Ansible roles and playbooks for automating system updates, security patching, and maintenance across your infrastructure.

## Overview

The Updates and Patching framework provides a standardized, automated approach to system maintenance with:

- Consistent patching procedures across environments
- Pre and post-update validation
- Scheduled or on-demand execution options
- Detailed reporting and logging
- Support for different operating systems
- Event-Driven Ansible (EDA) integration for automated responses
- ServiceNow integration for ITSM workflows
- Enterprise-grade orchestration capabilities

## Project Structure

```
├── playbooks/           # Organized Ansible playbooks (NEW!)
│   ├── eda-support/    # Event-Driven Ansible support playbooks
│   ├── maintenance/    # System maintenance playbooks
│   ├── orchestration/  # Workflow orchestration
│   ├── patching/       # Patching and updates
│   ├── reporting/      # System reporting
│   └── security/       # Security scanning
├── roles/              # Ansible roles
├── scripts/            # Shell scripts (DEPRECATED - use playbooks/)
├── inventory/          # Inventory files
└── templates/          # Jinja2 templates
```

**⚠️ Important:** Shell scripts in `scripts/` are deprecated. Use playbooks from `playbooks/` directory instead. See `scripts/DEPRECATED.md` for migration guide.

## Quick Start

### Using Playbooks (Recommended)

```bash
# 1. Clone repository
git clone https://github.com/ShaddGallegos/updates-and-patching.git
cd updates-and-patching

# 2. Configure inventory
vi inventory/hosts

# 3. Run a playbook
ansible-playbook playbooks/patching/rhel_patch_manager.yml -i inventory

# 4. For orchestrated workflows
ansible-playbook playbooks/orchestration/automation_wrapper.yml \
  -i inventory \
  -e "workflow=comprehensive"
```

See `playbooks/README.md` for comprehensive playbook documentation.

## Roles

### system_assessment

Evaluates systems before patching to determine update requirements and potential risks.

**Key tasks:**

- Package update availability check
- Disk space verification
- Service dependency mapping
- Security vulnerability scanning

### update_packages

Handles the core package update process across different operating systems.

**Key tasks:**

- Repository refresh
- Package updates (security or all)
- Package cleanup
- Update logging

### reboot_management

Controls system restart procedures with proper notifications and verification.

**Key tasks:**

- Pre-reboot notifications
- Coordinated reboot sequencing
- Post-reboot availability monitoring
- Service recovery automation

### verification

Validates system health and functionality after updates.

**Key tasks:**

- Service status verification
- Application health checks
- Performance baseline comparison
- Monitoring system reintegration

### reporting

Generates comprehensive reports on patching activities.

**Key tasks:**

- Update summary creation
- Failed update identification
- Compliance status reporting
- Report distribution

## Playbooks

The framework now includes organized playbooks in the `playbooks/` directory:

### Patching Playbooks

**`playbooks/patching/rhel_patch_manager.yml`** - Enterprise RHEL 7-10 patching
```bash
ansible-playbook playbooks/patching/rhel_patch_manager.yml -i inventory \
  -e "security_only=true allow_reboot=true"
```

**`playbooks/patching/linux_universal_patcher.yml`** - Cross-distribution patching
```bash
ansible-playbook playbooks/patching/linux_universal_patcher.yml -i inventory
```

### Security Playbooks

**`playbooks/security/vulnerability_scanner.yml`** - CVE scanning and remediation
```bash
ansible-playbook playbooks/security/vulnerability_scanner.yml -i inventory \
  -e "auto_remediate=true"
```

### Reporting Playbooks

**`playbooks/reporting/system_reporter.yml`** - Comprehensive system reports
```bash
ansible-playbook playbooks/reporting/system_reporter.yml -i inventory \
  -e "report_format=all"
```

**`playbooks/reporting/package_auditor.yml`** - Package management auditing
```bash
ansible-playbook playbooks/reporting/package_auditor.yml -i inventory
```

### Orchestration Playbooks

**`playbooks/orchestration/automation_wrapper.yml`** - Master orchestration with workflows
```bash
# Standard workflow
ansible-playbook playbooks/orchestration/automation_wrapper.yml \
  -i inventory -e "workflow=standard"

# Comprehensive analysis
ansible-playbook playbooks/orchestration/automation_wrapper.yml \
  -i inventory -e "workflow=comprehensive"
```

Available workflows: `standard`, `security`, `performance`, `comprehensive`

### Event-Driven Ansible (EDA)

**`playbooks/eda-support/rulebook_disk_monitoring.yml`** - Automated disk space management
```bash
# Set environment variables
export SPLUNK_HEC_URL="https://splunk.example.com:8088"
export SPLUNK_HEC_TOKEN="your-token-here"

# Run rulebook
ansible-rulebook \
  --rulebook playbooks/eda-support/rulebook_disk_monitoring.yml \
  --inventory inventory/ \
  --verbose
```

**Features:**
- Automated LVM extension at 90%+ disk usage
- ServiceNow integration for change management
- Multi-tier alerting (80%, 85%, 90%, 95%)
- Nutanix storage capacity checks
- On-call escalation for failures

See `playbooks/README.md` for complete documentation.

### Legacy Playbooks (Root Level)

**security_patching.yml** - Applies security updates only, minimizing service disruption.

**Usage:** `ansible-playbook security_patching.yml -i inventory`

**full_system_update.yml** - Comprehensive system update including all available package updates.

**Usage:** `ansible-playbook full_system_update.yml -i inventory`

**emergency_patch.yml** - Targeted patching for specific CVEs or vulnerabilities with minimal delay.

**Usage:** `ansible-playbook emergency_patch.yml -i inventory -e "cve=CVE-2023-12345"`

**maintenance_window.yml** - Orchestrates complete maintenance activities including updates, reboots, and verification within defined maintenance windows.

**Usage:** `ansible-playbook maintenance_window.yml -i inventory -e "maintenance_window=true"`

## Configuration

The framework can be configured through variables in:

- `group_vars/all.yml` - Global default settings
- `group_vars/<group>.yml` - Environment-specific configurations
- `host_vars/<hostname>.yml` - Host-specific overrides

### Key Variables

```yaml
# Update scope
security_only: true                # Only apply security updates
update_kernel: true                # Include kernel updates

# Reboot behavior
reboot_if_needed: true             # Automatically reboot when required
reboot_timeout: 1800               # Max time to wait for reboot completion

# Notifications
notify_start: true                 # Send notification before starting
notification_email: "ops@example.com"

# Prerequisites
- Ansible 2.12 or newer
- SSH access to target systems
- Appropriate sudo/privilege escalation
- Package manager access on targets
- Getting Started
- Clone this repository
- Configure your inventory
- Review and modify default variables
- Run the desired playbook

## Example:
# Test connectivity
ansible -i inventory all -m ping

# Run security patching with custom notification
"ansible-playbook -i inventory security_patching.yml -e "notification_email=admin@example.com""

Contributing
Contributions welcome! Please submit pull requests with:

Clear descriptions of changes
Test results from staging environments
Updates to documentation as needed EOF
Test results from staging environments
Updates to documentation as needed EOF


````
