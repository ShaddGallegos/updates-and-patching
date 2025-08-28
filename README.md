# Enterprise Updates and Patching Automation

A comprehensive automation suite for enterprise-grade system updates, patching, and Red Hat Satellite management using Ansible Automation Platform 2.5.

## Overview

This repository provides professional automation for:
* **RHEL System Updates**: RHEL 7, 8, and 9 comprehensive update management
* **Windows Updates**: Enterprise Windows patching and configuration
* **Red Hat Satellite 6.17**: Complete lifecycle management automation
* **Security Updates**: Vulnerability assessment and remediation
* **Performance Management**: System monitoring and optimization
* **Enterprise Reporting**: Multi-format professional reports

## Quick Start - Demo Environment

### Demo Credentials
For demonstration and testing purposes, use these default credentials:
- **Username**: `admin`
- **Password**: `NTY4NjIw`
- **Organization**: `Default Organization`

**⚠️ WARNING**: These are DEMO credentials only. Never use in production!

### Demo Commands
```bash
# Quick demo setup and credential verification
ansible-playbook -i inventory_demo satellite_quick_demo.yml

# Complete Satellite 6.17 management demo  
ansible-playbook -i inventory_demo satellite_complete_demo.yml

# Use demo variables file
ansible-playbook -i inventory_demo -e @group_vars/satellite_demo.yml satellite_complete_demo.yml
```

## Core Playbooks

### System Updates
- `simple_patching.yml` - Survey-driven comprehensive patching
- `security_update.yml` - Enterprise security update management  
- `update_systems.yml` - Multi-platform system updates
- `update_rhel.yml` - RHEL-specific updates with Insights integration
- `check_rhel_updates_with_report.yml` - Update assessment with reporting

### Red Hat Satellite Management
- `satellite_complete_demo.yml` - Complete Satellite 6.17 lifecycle demo
- `satellite_quick_demo.yml` - Quick setup and credential verification
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
