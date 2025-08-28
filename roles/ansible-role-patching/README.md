# Ansible Role: Comprehensive Linux OS Patching

[![Ansible Galaxy](https://img.shields.io/badge/ansible--galaxy-patching-blue.svg)](https://galaxy.ansible.com/sgallego/patching)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An enterprise-grade Ansible role for comprehensive Linux operating system patching and upgrade management across all major Linux distributions. This role provides automated security updates, system maintenance, validation, and professional reporting with minimal downtime and maximum reliability.

## Features

### Multi-Distribution Support
- **RedHat Family**: RHEL 7-10, CentOS, Fedora, Rocky Linux, AlmaLinux
- **Debian Family**: Debian 11-12, Ubuntu 18.04-24.04, Linux Mint, Kali Linux
- **SUSE Family**: openSUSE Leap 15.4+, SLES 15+
- **Arch Linux**: Rolling release support with AUR helper integration
- **Alpine Linux**: Container-optimized patching with OpenRC support
- **Gentoo Linux**: Source-based updates with emerge integration

### Package Manager Intelligence
- **YUM/DNF**: Advanced RHEL family management with version detection
- **APT**: Debian family with unattended-upgrades integration
- **Zypper**: SUSE family with security patch categories
- **Pacman**: Arch Linux with AUR helper support
- **APK**: Alpine Linux optimized for containers
- **Portage**: Gentoo source-based compilation management

### Enterprise Features
- **Security-First Approach**: Prioritizes security updates across all platforms
- **Minimal Downtime**: Smart reboot management and service restart optimization
- **Professional Reporting**: Multi-format reports (JSON, YAML, HTML, text)
- **Comprehensive Validation**: Pre/post-patch system integrity checks
- **Selective Patching**: Package inclusion/exclusion with granular control
- **Audit Trail**: Complete logging and change tracking
- **Service Management**: Intelligent service restart coordination
- **Integration Ready**: Ansible Tower/AWX and enterprise tooling support

## Requirements

### Ansible Version
- **Minimum**: Ansible 2.12+
- **Recommended**: Ansible Core 2.14+

### Supported Platforms
```yaml
# Complete platform matrix
RedHat Family:
 - RHEL 7, 8, 9, 10
 - CentOS 7, 8, 9
 - Fedora 37-40
 - Rocky Linux 8, 9
 - AlmaLinux 8, 9

Debian Family:
 - Debian 11 (bullseye), 12 (bookworm)
 - Ubuntu 18.04, 20.04, 22.04, 24.04
 - Linux Mint 20, 21
 - Kali Linux (rolling)

SUSE Family:
 - openSUSE Leap 15.4, 15.5, 15.6
 - SLES 15 SP3, SP4, SP5

Others:
 - Arch Linux (rolling)
 - Alpine Linux 3.16+
 - Gentoo Linux (rolling)
```

### Dependencies
```yaml
# Galaxy Collections (automatically installed)
collections:
 - ansible.posix
 - community.general

# Optional Galaxy Roles
dependencies:
 - role: oatakan.rhn
 when: patch_rhn_registration | default(false)
```

## Installation Installation

### Via Ansible Galaxy
```bash
ansible-galaxy install sgallego.patching
```

### Via Requirements File
```yaml
# requirements.yml
roles:
 - name: sgallego.patching
 version: ">=2.0.0"

collections:
 - ansible.posix
 - community.general
```

```bash
ansible-galaxy install -r requirements.yml
```

## Usage

### Basic Usage
```yaml
- hosts: all
 become: true
 roles:
 - sgallego.patching
```

### Advanced Configuration
```yaml
- hosts: production_servers
 become: true
 vars:
 # Security-focused patching
 patch_type: security
 patch_allow_reboot: true
 patch_reboot_timeout: 900
 
 # Comprehensive validation
 patch_pre_validation_enabled: true
 patch_post_validation_enabled: true
 patch_disk_space_threshold: 85
 
 # Professional reporting
 patch_generate_reports: true
 patch_report_formats:
 - json
 - yaml 
 - text
 patch_report_path: /var/log/ansible/patching
 
 # Service management
 patch_restart_services: true
 patch_critical_services:
 - sshd
 - httpd
 - postgresql
 
 # Package exclusions
 patch_exclude_packages:
 - kernel*
 - docker*
 
 roles:
 - sgallego.patching
```

## Installation Role Variables

### Core Configuration
```yaml
# Patching behavior
patch_type: full # full, security, minimal
patch_allow_reboot: false # Allow automatic reboots
patch_reboot_timeout: 600 # Reboot timeout in seconds
patch_dry_run: false # Preview changes without applying

# Package management
patch_update_cache: true # Update package cache before patching
patch_exclude_packages: [] # Packages to exclude from updates
patch_include_packages: [] # Specific packages to update
patch_security_only: false # Apply only security updates
```

See `defaults/main.yml` for complete variable documentation with 50+ configuration options.

## Professional Reporting Professional Reporting

The role generates comprehensive reports in multiple formats:

### JSON Report Structure
```json
{
 "metadata": {
 "hostname": "server01.example.com",
 "timestamp": "2024-01-15T10:30:45Z",
 "duration_seconds": 245
 },
 "system_info": {
 "os_family": "RedHat",
 "distribution": "Red Hat Enterprise Linux",
 "version": "9.3",
 "package_manager": "dnf"
 },
 "patch_summary": {
 "patches_applied": 23,
 "security_patches": 8,
 "reboot_required": true,
 "total_size_mb": 156.7
 }
}
```

## Quick Start Example Playbooks

### Production Server Patching
```yaml
---
- name: Enterprise Production Server Patching
 hosts: production
 become: true
 serial: 1 # Patch servers one at a time
 
 vars:
 patch_type: security
 patch_allow_reboot: true
 patch_generate_reports: true
 patch_critical_services:
 - httpd
 - postgresql
 
 roles:
 - sgallego.patching
```

## Security Considerations

- **Signature Verification**: All packages verified before installation
- **Repository Security**: Only trusted repositories enabled by default
- **Configuration Backup**: Critical files backed up before changes
- **Audit Logging**: Complete operation logging for compliance

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) for details.

## License License

MIT

## Related Roles Related Roles

- [sgallego.simple_report](https://galaxy.ansible.com/sgallego/simple_report) - Professional system reporting
- [sgallego.kpatch_rhel](https://galaxy.ansible.com/sgallego/kpatch_rhel) - Live kernel patching 
- [sgallego.check_vulner](https://galaxy.ansible.com/sgallego/check_vulner) - Vulnerability scanning

---

**Enterprise-Grade Linux Patching** | **Zero-Downtime Updates** | **Professional Reporting**
