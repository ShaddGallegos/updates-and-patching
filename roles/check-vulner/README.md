# check-vulner

A comprehensive enterprise-grade Ansible role for vulnerability scanning, analysis, and automated remediation on RHEL-based systems. This role has been completely modernized from its original single-CVE checker to a full vulnerability management solution.

## Features

- **Current Vulnerability Scanning**: Checks for 10+ current priority CVEs and security issues
- **Automated Remediation**: Automatically applies security updates and configuration fixes  
- **Professional Reporting**: Generates HTML, CSV, JSON, and executive summary reports
- **Multi-Format Output**: Email notifications, syslog integration, compliance reporting
- **RHEL 7-10 Compatibility**: Full support for all current RHEL versions
- **Enterprise Integration**: API integration for central vulnerability tracking
- **Comprehensive Coverage**: CVE scanning, package vulnerabilities, configuration issues
- **Backup & Recovery**: Automatic backups before remediation actions
- **Risk Assessment**: Categorizes vulnerabilities by severity with business impact analysis

## Requirements

- **Operating System**: RHEL 7, 8, 9, or 10 (derivatives supported)
- **Ansible**: 2.9+ (recommended: 4.0+)
- **Python**: 3.6+ on target systems
- **Privileges**: sudo/root access required for remediation
- **Network**: Internet access for vulnerability database updates (optional)
- **Dependencies**: `community.general` collection for advanced features

## Priority Vulnerabilities Checked

The role scans for these current high-priority security issues:

1. **CVE-2024-6387** - OpenSSH regreSSHion vulnerability
2. **CVE-2024-3094** - XZ Utils backdoor
3. **CVE-2023-4911** - glibc buffer overflow  
4. **CVE-2023-2650** - OpenSSL certificate validation bypass
5. **CVE-2023-32681** - Python requests session fixation
6. **CVE-2022-40674** - expat XML parser vulnerability
7. **CVE-2022-3715** - bash command substitution vulnerability
8. **CVE-2022-2625** - PostgreSQL extension script privilege escalation
9. **CVE-2022-1271** - gzip arbitrary file write vulnerability
10. **CVE-2021-44228** - Log4j remote code execution

Plus system configuration vulnerabilities and package-specific security issues.

## Role Variables

### Core Configuration

```yaml
# Vulnerability scanning settings
vulner_auto_remediate: true              # Enable automatic vulnerability fixes
vulner_create_backups: true              # Create system backups before changes
vulner_scan_frequency_days: 7            # Recommended scan frequency
vulner_max_vulnerabilities: 50           # Maximum vulnerabilities to scan

# Package management
vulner_package_manager: auto             # auto|yum|dnf - Package manager detection
vulner_update_timeout: 1800              # Package update timeout (seconds)

# Critical packages to monitor
vulner_critical_packages:
  - kernel
  - glibc
  - openssl
  - openssh
  - sudo
  - bash
  - systemd
  - curl
  - wget
  - python3
```

### Reporting Configuration

```yaml
# Report generation
vulner_generate_reports: true
vulner_report_formats:
  - json
  - html  
  - csv
vulner_report_directory: /var/log/vulnerability-reports
vulner_report_owner: root
vulner_report_group: root

# Email notifications
vulner_send_email_notifications: false
vulner_notification_email: security@company.com
vulner_smtp_server: localhost
vulner_smtp_port: 587

# Logging and monitoring
vulner_log_to_syslog: true
vulner_central_reporting: false
vulner_central_api_endpoint: ""
vulner_api_token: ""
```

### Remediation Options

```yaml
# Remediation behavior
vulner_auto_reboot: false                # Auto-reboot for kernel updates
vulner_disable_password_auth: false      # Disable SSH password auth  
vulner_fix_sudo_config: true             # Fix dangerous sudo configurations
vulner_backup_directory: /var/backups/vulnerability-remediation

# Compliance and security
vulner_compliance_framework: "NIST"      # Compliance framework for reporting
vulner_compliance_reporting: true        # Generate compliance reports
vulner_role_version: "2.0.0"            # Role version for tracking
```

## Example Playbooks

### Basic Vulnerability Scan

```yaml
---
- name: Basic vulnerability scanning
  hosts: all
  become: true
  roles:
    - role: check-vulner
      vars:
        vulner_auto_remediate: false
        vulner_generate_reports: true
        vulner_report_formats: [html, json]
```

### Full Remediation with Notifications

```yaml
---
- name: Complete vulnerability management
  hosts: production_servers
  become: true
  roles:
    - role: check-vulner
      vars:
        vulner_auto_remediate: true
        vulner_create_backups: true
        vulner_auto_reboot: false
        vulner_send_email_notifications: true
        vulner_notification_email: "security-alerts@company.com"
        vulner_report_formats: [html, csv, json]
        vulner_compliance_reporting: true
```

### Enterprise Integration

```yaml
---
- name: Enterprise vulnerability management
  hosts: all
  become: true
  roles:
    - role: check-vulner
      vars:
        vulner_auto_remediate: true
        vulner_central_reporting: true
        vulner_central_api_endpoint: "https://vuln-dashboard.company.com"
        vulner_api_token: "{{ vault_vuln_api_token }}"
        vulner_compliance_framework: "SOC2"
        vulner_log_to_syslog: true
```

## Output and Reports

### Report Types Generated

1. **HTML Report**: Professional web-based report with charts and risk assessment
2. **Executive Summary**: Business-focused text summary for management
3. **CSV Report**: Structured data for spreadsheet analysis
4. **JSON Report**: Machine-readable format for automation
5. **Compliance Report**: Framework-specific compliance status

### Key Metrics Tracked

- Total vulnerabilities by severity (Critical/High/Medium/Low)
- Risk assessment and business impact
- Remediation status and backup information
- System information and scan metadata
- Compliance status against security frameworks

## Advanced Features

### Automated Remediation

The role can automatically:
- Apply security patches for known CVEs
- Update vulnerable packages to patched versions
- Fix insecure SSH configurations
- Correct dangerous sudo configurations  
- Fix world-writable file permissions
- Schedule system reboots for kernel updates

### Integration Capabilities

- **SIEM Integration**: Structured syslog output
- **Email Alerts**: Critical vulnerability notifications
- **API Integration**: Central vulnerability database updates
- **Compliance Reporting**: Multiple framework support
- **Backup Management**: Automatic configuration backups

## Dependencies

```yaml
# Required collections
collections:
  - community.general   # For mail and advanced modules
  - ansible.posix      # For syslog and system operations
```

## Tags

Use these tags for selective execution:

```bash
# Scan only (no remediation)
ansible-playbook -t scan playbook.yml

# Remediation only  
ansible-playbook -t remediate playbook.yml

# Reports only
ansible-playbook -t report playbook.yml

# Critical vulnerabilities only
ansible-playbook -t critical playbook.yml
```

## Return Values

The role sets these facts for subsequent tasks:

```yaml
vulner_found_vulnerabilities: []      # List of all vulnerabilities found
vulner_critical_count: 0              # Number of critical issues
vulner_total_count: 0                 # Total vulnerability count
vulner_scan_completed: true           # Scan completion status
vulner_remediation_completed: false   # Remediation status
security_system_vulnerable: false     # Legacy compatibility fact
```

## Security Considerations

- **Privilege Requirements**: Role requires sudo/root for system modifications
- **Network Access**: Internet connectivity needed for vulnerability database updates
- **Backup Strategy**: Always creates backups before making system changes
- **Testing**: Test in non-production environment before production deployment
- **Change Management**: Review all planned changes before enabling auto-remediation

## Troubleshooting

### Common Issues

1. **Package Manager Detection**: Ensure yum/dnf is available and functional
2. **Network Connectivity**: Verify access to package repositories
3. **Permissions**: Confirm ansible user has appropriate sudo privileges
4. **Disk Space**: Ensure adequate space for backups and reports

### Debug Mode

Enable detailed logging:

```yaml
vulner_debug_mode: true
vulner_log_level: debug
```

## Migration from v1.x

This role has been completely rewritten. Key changes:

- **Breaking Change**: No longer checks only CVE-2019-11135
- **New Features**: 10+ current CVEs, automated remediation, professional reporting
- **Compatibility**: `security_system_vulnerable` fact maintained for backward compatibility
- **Configuration**: Many new variables available for customization

## Version History

- **v2.0.0**: Complete rewrite with modern vulnerability management
- **v1.0.0**: Original single CVE checker (deprecated)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality  
4. Submit a pull request with detailed description

## License

MIT License - See LICENSE file for details

## Author Information

**Original Role**: Basic CVE-2019-11135 checker  
**Modernized**: Enterprise vulnerability management solution  
**Maintained**: IT Security Team

For support or questions: security-team@company.com

---

** Important**: This role can make significant system changes. Always test in a development environment and review all configuration options before deploying to production systems.
