# README.md for generate-update-report-rhel
# Enhanced RHEL 7-10 Update Reporting

## Overview

Enterprise-grade Ansible role for generating comprehensive RHEL update reports across RHEL 7, 8, 9, and 10 infrastructure. Provides flexible report delivery options including timestamped file storage, SMTP email, and SendGrid integration with professional HTML/JSON/YAML/CSV formatting.

## Features

###  RHEL Version Support
- **RHEL 7**: YUM-based update checking with security plugin support
- **RHEL 8**: DNF-based update management with enhanced errata information
- **RHEL 9**: Modern DNF workflows with comprehensive security categorization  
- **RHEL 10**: Latest DNF features with advanced subscription management

###  Multi-Format Reporting
- **HTML**: Professional web-ready reports with responsive design
- **JSON**: Structured data for API integration and automation
- **YAML**: Human-readable format for configuration management
- **CSV**: Spreadsheet-compatible for data analysis
- **Text**: Simple format for email and notifications

###  Flexible Delivery Options
- **Timestamped Folders**: `/tmp/reports_YYYYMMDD_HHMMSS/`
- **SMTP Email**: Standard email delivery with attachments
- **SendGrid API**: Professional email service with templates
- **Webhook Notifications**: Slack, Teams, and custom integrations

## Quick Start

### Basic Usage
```yaml
- hosts: rhel_servers
  roles:
    - generate-update-report-rhel
```

### Timestamped File Reports
```yaml
- hosts: rhel_servers
  vars:
    report_storage_type: file
    report_create_timestamped_folder: true
    report_file_formats:
      - html
      - json
      - csv
  roles:
    - generate-update-report-rhel
```

### SendGrid Email Integration
```yaml
- hosts: rhel_servers
  vars:
    report_storage_type: sendgrid
    report_sendgrid_enabled: true
    sendgrid_api_key: "{{ vault_sendgrid_api_key }}"
    sendgrid_from_email_address: "reports@company.com"
    sendgrid_to_email_addresses:
      - "admin@company.com"
      - "security@company.com"
  roles:
    - generate-update-report-rhel
```

### SMTP Email Reports
```yaml
- hosts: rhel_servers
  vars:
    report_storage_type: email
    report_email_enabled: true
    send_email_with_smtp: true
    smtp_host: smtp.company.com
    smtp_port: 587
    smtp_account: "{{ vault_smtp_user }}"
    smtp_account_password: "{{ vault_smtp_password }}"
    smtp_to_email_addresses:
      - "sysadmin@company.com"
  roles:
    - generate-update-report-rhel
```

### Comprehensive Reporting (All Options)
```yaml
- hosts: rhel_servers
  vars:
    # Multi-delivery approach
    report_storage_type: all
    
    # File storage with timestamps
    report_file_enabled: true
    report_create_timestamped_folder: true
    report_file_formats:
      - html
      - json
      - yaml
      - csv
    
    # Email delivery
    report_email_enabled: true
    send_email_with_smtp: true
    smtp_host: "{{ vault_smtp_host }}"
    smtp_account: "{{ vault_smtp_user }}"
    smtp_account_password: "{{ vault_smtp_password }}"
    smtp_to_email_addresses:
      - "team@company.com"
    
    # SendGrid integration
    report_sendgrid_enabled: true
    sendgrid_api_key: "{{ vault_sendgrid_key }}"
    sendgrid_to_email_addresses:
      - "executives@company.com"
    
    # Enhanced content
    rhel_check_subscription_status: true
    rhel_include_errata_info: true
    report_include_security_updates: true
    
  roles:
    - generate-update-report-rhel
```

## Configuration Variables

### Report Storage Options
```yaml
# Storage type selection
report_storage_type: file          # file, email, sendgrid, all

# File storage
report_base_path: /tmp/reports_{{ report_timestamp }}
report_create_timestamped_folder: true
report_file_formats:
  - html
  - json
  - yaml  
  - csv

# Report retention
report_retention_days: 30
report_cleanup_old_reports: true
```

### Email Configuration
```yaml
# SMTP settings
smtp_host: smtp.gmail.com
smtp_port: 587
smtp_use_tls: true
smtp_account: 'user@company.com'
smtp_account_password: 'app_password'
smtp_to_email_addresses:
  - 'admin@company.com'

# SendGrid API settings  
sendgrid_api_key: 'SG.xxxx'
sendgrid_from_email_address: 'noreply@company.com'
sendgrid_to_email_addresses:
  - 'reports@company.com'
sendgrid_categories:
  - ansible
  - rhel-updates
  - compliance
```

### RHEL-Specific Options
```yaml
# Subscription and repository checking
rhel_check_subscription_status: true
rhel_include_satellite_info: true
rhel_include_repository_info: true
rhel_include_errata_info: true

# Security update categorization
report_include_security_updates: true
report_security_categories:
  critical: "Critical"
  important: "Important"
  moderate: "Moderate"
  low: "Low"
```

## Report Examples

### Timestamped Folder Structure
```
/tmp/reports_20240827_143022/
 rhel-update-report-server01-20240827_143022.html
 rhel-update-report-server01-20240827_143022.json
 rhel-update-report-server02-20240827_143022.html
 rhel-update-report-server02-20240827_143022.json
 rhel-update-report-fleet-summary-20240827_143022.txt
```

### JSON Report Structure
```json
{
  "metadata": {
    "hostname": "server01.example.com",
    "timestamp": "2024-08-27T14:30:22Z",
    "report_id": "server01-20240827_143022"
  },
  "system_info": {
    "distribution": "Red Hat Enterprise Linux",
    "distribution_version": "9.3",
    "package_manager": "dnf"
  },
  "update_summary": {
    "total_updates_available": 23,
    "security_updates_count": 8,
    "compliance_status": "Updates Available",
    "reboot_required": true
  }
}
```

### HTML Report Features
-  **Executive Dashboard**: Summary cards with key metrics
-  **Professional Styling**: Modern responsive design
-  **Security Highlighting**: Visual indicators for security updates
-  **Fleet Overview**: Multi-host comparison table
-  **Compliance Status**: Clear visual status indicators

## Integration Examples

### Scheduled Reporting Job
```yaml
# cron_reports.yml
---
- name: Daily RHEL Update Reports
  hosts: rhel_servers
  vars:
    report_storage_type: all
    report_company_name: "ACME Corporation"
    sendgrid_api_key: "{{ vault_sendgrid_key }}"
    
  roles:
    - generate-update-report-rhel
    
  post_tasks:
    - name: Archive reports for long-term storage
      archive:
        path: "{{ report_base_path }}/*"
        dest: "/opt/reports/archives/rhel-reports-{{ ansible_date_time.date }}.tar.gz"
      delegate_to: localhost
```

### Ansible Tower Job Template
```yaml
# job_template_vars.yml
extra_vars:
  report_storage_type: "sendgrid"
  sendgrid_api_key: "{{ sendgrid_api_vault }}"
  sendgrid_to_email_addresses:
    - "infrastructure@company.com"
    - "security@company.com"
  report_include_security_updates: true
  notification_enabled: true
  notification_slack_channel: "#infrastructure"
```

### CI/CD Pipeline Integration
```bash
# Jenkins/GitLab pipeline
ansible-playbook -i inventory reports.yml \
  --extra-vars "report_storage_type=all" \
  --extra-vars "report_file_formats=['json','html']" \
  --vault-password-file /etc/ansible/vault-pass
```

## Advanced Features

### Custom Email Templates
Create custom SendGrid templates and reference them:
```yaml
sendgrid_template_id: "d-your-custom-template-id"
sendgrid_categories:
  - "custom-category"
  - "rhel-compliance"
```

### Webhook Integration
```yaml
notification_enabled: true
notification_webhook_url: "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
notification_slack_channel: "#rhel-updates"
```

### Report Archival
```yaml
report_compress_files: true
report_archive_format: zip
report_retention_days: 90
```

## Security Considerations

- **Credentials**: Use Ansible Vault for API keys and passwords
- **Access Control**: Restrict report directory permissions
- **Data Sensitivity**: Consider report content when choosing delivery methods
- **Retention Policy**: Implement appropriate report cleanup procedures

## Troubleshooting

### Common Issues

#### SendGrid Authentication
```bash
# Test SendGrid API key
curl -X POST https://api.sendgrid.com/v3/mail/send \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json"
```

#### SMTP Connection
```bash
# Test SMTP connectivity
telnet smtp.company.com 587
```

#### Permission Issues
```bash
# Fix report directory permissions
sudo chown -R ansible:ansible /tmp/reports_*
sudo chmod -R 755 /tmp/reports_*
```

### Debug Mode
```yaml
report_debug_mode: true
ansible_verbosity: 2
```

## License

MIT

## Author

sgallego (Red Hat)
