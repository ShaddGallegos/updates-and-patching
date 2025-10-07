# Ansible Playbooks Directory

This directory contains all Ansible playbooks for the Updates and Patching automation framework, organized by function.

## Directory Structure

```
playbooks/
├── eda-support/          # Event-Driven Ansible support playbooks
├── maintenance/          # System maintenance playbooks
├── orchestration/        # Workflow orchestration playbooks
├── patching/            # Patching and update playbooks
├── reporting/           # System reporting playbooks
└── security/            # Security scanning and hardening playbooks
```

## Playbook Categories

### EDA Support Playbooks (`eda-support/`)

These playbooks support Event-Driven Ansible (EDA) automation and integrate with external systems:

- **`send_emergency_notification.yml`** - Sends critical alerts through multiple channels
- **`create_servicenow_incident.yml`** - Creates incidents in ServiceNow for critical issues
- **`create_servicenow_change.yml`** - Creates change requests for planned maintenance
- **`send_disk_alert.yml`** - Sends disk space alerts with different severity levels
- **`schedule_maintenance.yml`** - Schedules maintenance tasks in AAP/AWX
- **`update_servicenow_ticket.yml`** - Updates existing ServiceNow tickets
- **`page_oncall.yml`** - Pages on-call engineers via PagerDuty/Opsgenie
- **`check_nutanix_capacity.yml`** - Checks Nutanix storage capacity
- **`add_nutanix_disk.yml`** - Adds disks to VMs in Nutanix
- **`rulebook_disk_monitoring.yml`** - EDA rulebook for automated disk space management

### Patching Playbooks (`patching/`)

Enterprise-grade patching automation for Linux systems:

- **`rhel_patch_manager.yml`** - RHEL 7-10 patching with comprehensive reporting
- **`linux_universal_patcher.yml`** - Cross-distribution patching for RHEL, Debian, SUSE

**Features:**
- Security-only or full updates
- Dry-run mode
- Automatic reboot handling
- Comprehensive reporting

### Security Playbooks (`security/`)

Vulnerability scanning and security automation:

- **`vulnerability_scanner.yml`** - Scans for CVEs and security vulnerabilities
- Automated remediation capabilities
- Integration with security update repositories

### Reporting Playbooks (`reporting/`)

System reporting and auditing:

- **`system_reporter.yml`** - Comprehensive system reporting (HTML, JSON, YAML, text)
- **`package_auditor.yml`** - Package management auditing and analysis

### Maintenance Playbooks (`maintenance/`)

System maintenance and optimization:

- **`kpatch_manager.yml`** - Live kernel patching for RHEL systems
- **`ansible_performance_setup.yml`** - Configures Ansible for high performance

### Orchestration Playbooks (`orchestration/`)

Workflow orchestration and automation:

- **`automation_wrapper.yml`** - Master orchestration playbook with multiple workflows:
  - **standard** - Basic patching and reporting
  - **security** - Security-focused audit and patching
  - **performance** - Performance analysis and optimization
  - **comprehensive** - Complete system analysis and management

## Usage Examples

### Basic Patching

```bash
# RHEL security updates only
ansible-playbook playbooks/patching/rhel_patch_manager.yml \
  -i inventory \
  -e "security_only=true"

# Universal patching across all Linux distributions
ansible-playbook playbooks/patching/linux_universal_patcher.yml \
  -i inventory \
  -e "allow_reboot=true"
```

### Security Scanning

```bash
# Vulnerability scan with auto-remediation
ansible-playbook playbooks/security/vulnerability_scanner.yml \
  -i inventory \
  -e "auto_remediate=true"
```

### System Reporting

```bash
# Generate comprehensive system reports
ansible-playbook playbooks/reporting/system_reporter.yml \
  -i inventory \
  -e "report_format=all collect_performance=true"

# Package audit
ansible-playbook playbooks/reporting/package_auditor.yml \
  -i inventory \
  -e "audit_type=full"
```

### Orchestrated Workflows

```bash
# Standard workflow
ansible-playbook playbooks/orchestration/automation_wrapper.yml \
  -i inventory \
  -e "workflow=standard"

# Comprehensive analysis
ansible-playbook playbooks/orchestration/automation_wrapper.yml \
  -i inventory \
  -e "workflow=comprehensive email_report=true email_address=admin@example.com"
```

### Event-Driven Ansible

```bash
# Run disk monitoring rulebook
ansible-rulebook \
  --rulebook playbooks/eda-support/rulebook_disk_monitoring.yml \
  --inventory inventory/ \
  --verbose

# Set required environment variables
export SPLUNK_HEC_URL="https://splunk.example.com:8088"
export SPLUNK_HEC_TOKEN="your-token-here"
```

## Common Variables

### Patching Variables

```yaml
target_hosts: "all"              # Target host group
security_only: false             # Apply only security updates
allow_reboot: false              # Allow automatic reboots
dry_run: false                   # Preview changes without applying
report_dir: "/tmp/reports"       # Report output directory
```

### ServiceNow Integration

```yaml
servicenow_instance: "company.service-now.com"
servicenow_username: "automation_user"
servicenow_password: "{{ vault_servicenow_password }}"
```

### Email Notifications

```yaml
smtp_server: "smtp.example.com"
smtp_port: 25
alert_email: "ops@example.com"
emergency_email: "oncall@example.com"
```

### AAP/AWX Integration

```yaml
aap_host: "https://aap.example.com"
aap_username: "admin"
aap_password: "{{ vault_aap_password }}"
```

## Integration with Roles

Many playbooks can integrate with existing roles when available:

- `disk_usage_alerting` - For disk space alerts
- `servicenow_ticket_management` - For ServiceNow integration
- Roles from `roles/` directory in the project

## Migration from Shell Scripts

The playbooks in this directory replace the following shell scripts:

| Shell Script | Playbook Replacement |
|-------------|---------------------|
| `scripts/automation-wrapper.sh` | `orchestration/automation_wrapper.yml` |
| `scripts/rhel-patch-manager.sh` | `patching/rhel_patch_manager.yml` |
| `scripts/linux-universal-patcher.sh` | `patching/linux_universal_patcher.yml` |
| `scripts/vulnerability-scanner.sh` | `security/vulnerability_scanner.yml` |
| `scripts/system-reporter.sh` | `reporting/system_reporter.yml` |
| `scripts/package-auditor.sh` | `reporting/package_auditor.yml` |
| `scripts/kpatch-manager.sh` | `maintenance/kpatch_manager.yml` |
| `scripts/ansible-performance-setup.sh` | `maintenance/ansible_performance_setup.yml` |

## Benefits of Playbook-Based Approach

✅ **Native Ansible Integration** - Better integration with Ansible Tower/AAP  
✅ **Reusable and Modular** - Playbooks can be included and composed  
✅ **Idempotent** - Safe to run multiple times  
✅ **Better Error Handling** - Built-in Ansible error handling and retries  
✅ **Comprehensive Logging** - Detailed execution logs  
✅ **Testing Support** - Can use ansible-playbook --check and --diff  
✅ **Version Control** - Better suited for Git workflows  
✅ **Documentation** - Self-documenting with task names  

## Requirements

### Collections

```yaml
collections:
  - servicenow.itsm
  - awx.awx
  - ansible.controller
  - nutanix.ncp
  - splunk.eda
  - community.general
  - ansible.posix
```

### Python Packages

```bash
pip install ansible
pip install ansible-rulebook  # For EDA
pip install servicenow-api
```

## Support

For issues or questions:
1. Check playbook documentation (task names and comments)
2. Review variable definitions in playbook vars section
3. Run with `-vvv` for verbose debugging
4. Check reports in configured report_dir

## Contributing

When adding new playbooks:
1. Place in appropriate category directory
2. Follow existing naming conventions
3. Include comprehensive documentation in task names
4. Add example usage to this README
5. Test with `--check` mode first
