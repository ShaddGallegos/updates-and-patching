# Enterprise Updates and Patching Automation

A comprehensive automation suite for enterprise-grade system updates, patching, and Red Hat Satellite management using Ansible Automation Platform 2.5.

## Overview

This repository provides professional automation for:
* **RHEL System Updates**: RHEL 7, 8, and 9 comprehensive update management
* **Windows Updates**: Enterprise Windows patching and configuration
* **Red Hat Satellite 6.17**: Complete lifecycle management automation (see [`satellite/`](satellite/) project)
* **Security Updates**: Vulnerability assessment and remediation
* **Performance Management**: System monitoring and optimization
* **Enterprise Reporting**: Multi-format professional reports

## Project Structure

```
updates-and-patching/
├── satellite/ # Red Hat Satellite 6.17 Management Project
│ ├── README.md # Satellite project overview
│ ├── playbooks/ # Satellite automation playbooks
│ ├── roles/ # Satellite management roles
│ └── group_vars/ # Satellite configuration variables
├── roles/ # Core system management roles
├── playbooks/ # System update playbooks
├── bindep.txt # System dependencies
├── requirements.txt # Python dependencies
├── execution-environment.yml # Container build configuration
└── DEPENDENCIES.md # Dependency documentation
```

## Quick Start - Demo Environment

### For Red Hat Satellite Automation
See the dedicated [Satellite Project](satellite/README.md) for complete Satellite 6.17 automation.

```bash
# Navigate to satellite project
cd satellite

# Quick demo setup and credential verification 
ansible-playbook -i inventory_demo playbooks/satellite_quick_demo.yml

# Complete Satellite 6.17 management demo
ansible-playbook -i inventory_demo playbooks/satellite_complete_demo.yml
```

### Demo Credentials (Satellite)
For Satellite demonstration and testing:
- **Username**: `admin`
- **Password**: `NTY4NjIw`
- **Organization**: `Default Organization`

**[WARNING] WARNING**: These are DEMO credentials only. Never use in production!

## Core Playbooks

### System Updates
- `simple_patching.yml` - Survey-driven comprehensive patching
- `security_update.yml` - Enterprise security update management 
- `update_systems.yml` - Multi-platform system updates
- `update_rhel.yml` - RHEL-specific updates with Insights integration
- `check_rhel_updates_with_report.yml` - Update assessment with reporting

### Red Hat Satellite Management
**Note**: Satellite automation has been moved to the [`satellite/`](satellite/) project folder.
- `rhel_register_rhn.yml` - System registration automation
- `kpatch_rhel.yml` - Kernel live patching management

### Security and Monitoring 
- `check_vulner.yml` - Comprehensive vulnerability assessment
- `windows_high_cpu_mem_reaction.yml` - Windows performance management

## Enterprise Features

### Multi-Platform Support
- **Linux**: RHEL 7/8/9, CentOS, Ubuntu, SUSE, Alpine, Arch
- **Windows**: Server 2016/2019/2022, Windows 10/11
- **Containers**: Execution Environment support

### Professional Reporting
- **HTML Dashboards**: Interactive web reports
- **JSON/YAML**: Machine-readable automation data
- **CSV**: Spreadsheet-compatible exports 
- **Executive Summaries**: Management-ready reports

### Security Integration
- **Red Hat Insights**: Automated vulnerability detection
- **CVE Management**: Targeted security update deployment
- **Compliance Reporting**: Enterprise compliance automation

## Windows Management (WinRM) 
Scripts that may need to be run on your remote Windows host(s) (please review the code to varify they are applicable to your hosts, and test before you distribute to all your hosts):

Upgrade-PowerShell.ps1 – Upgrades PowerShell and .NET Framework to a supported version (if not present)
Install-WMF3Hotfix.ps1 – Installs a Windows HotFix for a known memory leak in WinRM (if not present)
ConfigureRemotingForAnsible.ps1 – Configures WinRM remote PowerShell for Ansible
