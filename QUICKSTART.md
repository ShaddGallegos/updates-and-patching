# Quick Start Guide

This guide will help you get started with the Updates and Patching automation framework.

## Prerequisites

### Software Requirements
- Ansible 2.12 or newer
- Python 3.6 or newer
- SSH access to target systems
- Sudo/privilege escalation on targets

### Install Ansible
```bash
# RHEL/CentOS
sudo dnf install ansible

# Ubuntu/Debian
sudo apt install ansible

# From pip
pip3 install ansible ansible-core
```

### Install Collections
```bash
# Install required collections
ansible-galaxy collection install -r requirements.yml

# Or install individually
ansible-galaxy collection install servicenow.itsm
ansible-galaxy collection install awx.awx
ansible-galaxy collection install ansible.controller
ansible-galaxy collection install nutanix.ncp
ansible-galaxy collection install community.general
ansible-galaxy collection install ansible.posix
```

## Initial Setup

### 1. Clone the Repository
```bash
git clone https://github.com/ShaddGallegos/updates-and-patching.git
cd updates-and-patching
```

### 2. Set Up Configuration
```bash
# Create ansible.cfg (if not exists)
make setup

# Or manually
cp env.yml.example env.yml
vi env.yml
```

### 3. Configure Inventory
```bash
# Create your inventory from example
cp inventory/example.ini inventory/production

# Edit with your servers
vi inventory/production
```

### 4. Set Up Vault for Secrets
```bash
# Create vault password file
echo "your-vault-password" > ~/.vault_pass.txt
chmod 600 ~/.vault_pass.txt

# Create vault.yml for secrets
ansible-vault create vault.yml --vault-password-file ~/.vault_pass.txt
```

Add to `vault.yml`:
```yaml
---
vault_servicenow_password: "your-servicenow-password"
vault_aap_password: "your-aap-password"
vault_nutanix_password: "your-nutanix-password"
vault_pagerduty_key: "your-pagerduty-key"
```

### 5. Test Connectivity
```bash
# Test SSH connectivity
ansible all -i inventory/production -m ping

# Test privilege escalation
ansible all -i inventory/production -m shell -a "whoami" --become
```

## Basic Usage

### Patching Operations

#### Security Updates Only
```bash
# RHEL systems
ansible-playbook playbooks/patching/rhel_patch_manager.yml \
  -i inventory/production \
  -e "security_only=true"

# All Linux distributions
ansible-playbook playbooks/patching/linux_universal_patcher.yml \
  -i inventory/production \
  -e "security_only=true"
```

#### Full System Update
```bash
# With dry-run (preview changes)
ansible-playbook playbooks/patching/rhel_patch_manager.yml \
  -i inventory/production \
  -e "dry_run=true"

# Apply updates
ansible-playbook playbooks/patching/rhel_patch_manager.yml \
  -i inventory/production \
  -e "allow_reboot=true"
```

#### Target Specific Hosts
```bash
# Target single host
ansible-playbook playbooks/patching/rhel_patch_manager.yml \
  -i inventory/production \
  -l rhel9-web01.example.com

# Target group
ansible-playbook playbooks/patching/rhel_patch_manager.yml \
  -i inventory/production \
  -l webservers
```

### Security Scanning

#### Vulnerability Scan
```bash
# Scan only
ansible-playbook playbooks/security/vulnerability_scanner.yml \
  -i inventory/production

# Scan and remediate
ansible-playbook playbooks/security/vulnerability_scanner.yml \
  -i inventory/production \
  -e "auto_remediate=true"
```

### System Reporting

#### Generate System Reports
```bash
# All formats (HTML, JSON, YAML, text)
ansible-playbook playbooks/reporting/system_reporter.yml \
  -i inventory/production \
  -e "report_format=all"

# HTML only with performance metrics
ansible-playbook playbooks/reporting/system_reporter.yml \
  -i inventory/production \
  -e "report_format=html collect_performance=true collect_security=true"
```

#### Package Audit
```bash
ansible-playbook playbooks/reporting/package_auditor.yml \
  -i inventory/production \
  -e "audit_type=full"
```

### Orchestrated Workflows

#### Standard Workflow
```bash
ansible-playbook playbooks/orchestration/automation_wrapper.yml \
  -i inventory/production \
  -e "workflow=standard"
```

#### Comprehensive Analysis
```bash
ansible-playbook playbooks/orchestration/automation_wrapper.yml \
  -i inventory/production \
  -e "workflow=comprehensive email_report=true email_address=admin@example.com"
```

#### Using Makefile Shortcuts
```bash
# Patching
make patch-rhel
make patch-universal

# Scanning
make scan-vulns

# Reporting
make report-system
make audit-packages

# Orchestration
make orchestrate
make orchestrate-comprehensive
```

## Event-Driven Ansible (EDA)

### Prerequisites
```bash
# Install ansible-rulebook
pip3 install ansible-rulebook

# Install EDA collections
ansible-galaxy collection install splunk.eda
```

### Configure Environment
```bash
# Set Splunk credentials
export SPLUNK_HEC_URL="https://splunk.example.com:8088"
export SPLUNK_HEC_TOKEN="your-token-here"

# Configure in env.yml or vault.yml
servicenow_instance: company.service-now.com
aap_host: https://aap.example.com
```

### Run Disk Monitoring Rulebook
```bash
ansible-rulebook \
  --rulebook playbooks/eda-support/rulebook_disk_monitoring.yml \
  --inventory inventory/production \
  --verbose
```

This will:
- Monitor Splunk for disk space alerts
- Automatically extend LVM volumes when usage > 90%
- Create ServiceNow change requests
- Send multi-tier alerts
- Escalate failures to on-call engineers

## Common Patterns

### Dry Run First
Always test with dry-run before applying changes:
```bash
ansible-playbook <playbook> -i inventory -e "dry_run=true"
```

### Check Mode
Preview changes without applying:
```bash
ansible-playbook <playbook> -i inventory --check
```

### See What Will Change
```bash
ansible-playbook <playbook> -i inventory --check --diff
```

### Verbose Output for Troubleshooting
```bash
ansible-playbook <playbook> -i inventory -vvv
```

### Limit to Test Hosts First
```bash
ansible-playbook <playbook> -i inventory -l development
```

## Maintenance Windows

### Scheduled Patching
```bash
# Tag servers for maintenance
ansible-playbook playbooks/patching/rhel_patch_manager.yml \
  -i inventory/production \
  -l production \
  -e "security_only=true allow_reboot=true" \
  --tags maintenance
```

### Emergency Patching
For critical CVEs:
```bash
ansible-playbook playbooks/patching/rhel_patch_manager.yml \
  -i inventory/production \
  -e "security_only=true force_mode=true"
```

## Troubleshooting

### Connection Issues
```bash
# Test connectivity
ansible all -i inventory -m ping -vvv

# Check SSH configuration
ssh -vvv ansible_user@target-host
```

### Permission Issues
```bash
# Test sudo
ansible all -i inventory -m shell -a "whoami" --become -vvv

# Check sudoers configuration on target
sudo visudo
```

### View Logs
```bash
# Ansible logs (if configured)
tail -f /var/log/ansible.log

# Playbook execution logs
tail -f /tmp/patch_reports/patch-*.log
```

### Debug Mode
```bash
# Run with maximum verbosity
ANSIBLE_DEBUG=1 ansible-playbook <playbook> -i inventory -vvvv
```

## Best Practices

1. **Always use dry-run first** - Preview changes before applying
2. **Test in development** - Test on dev hosts before production
3. **Use tags** - Tag critical systems appropriately
4. **Schedule appropriately** - Run during maintenance windows
5. **Monitor reports** - Review generated reports after execution
6. **Use vault for secrets** - Never commit passwords to git
7. **Backup before patching** - Ensure backups are current
8. **Check dependencies** - Verify application dependencies before updates
9. **Communicate changes** - Notify teams about scheduled patching
10. **Have rollback plan** - Know how to rollback if needed

## Next Steps

1. Review `playbooks/README.md` for detailed playbook documentation
2. Customize variables in `inventory/production`
3. Set up vault credentials in `vault.yml`
4. Test connectivity and permissions
5. Run dry-run on development hosts
6. Schedule maintenance window
7. Execute patching playbooks
8. Review reports and logs
9. Set up EDA for automated responses

## Support

- Documentation: `playbooks/README.md`
- Examples: `inventory/example.ini`
- Issues: GitHub Issues
- Questions: Open a discussion

## Additional Resources

- [Ansible Documentation](https://docs.ansible.com/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Event-Driven Ansible](https://www.ansible.com/products/event-driven-ansible)
- [ServiceNow ITSM Collection](https://galaxy.ansible.com/servicenow/itsm)
