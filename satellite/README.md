# Red Hat Satellite 6.17 Management Automation Project

## Overview

This project provides comprehensive automation for Red Hat Satellite 6.17 management using Ansible Automation Platform 2.5. The automation covers the complete lifecycle of Satellite management from repository setup through host compliance management.

## Project Structure

```
satellite/
├── README.md # This file - Project overview and usage
├── SATELLITE_README.md # Detailed technical documentation
├── CREDENTIAL_UPDATES.md # Credential change log
├── inventory_demo # Demo inventory file
├── playbooks/ # All satellite playbooks
│ ├── satellite_complete_demo.yml # Complete management demo
│ └── satellite_quick_demo.yml # Quick demo setup
├── roles/ # Satellite management roles
│ ├── satellite-repository-management/ # Repository and sync management
│ ├── satellite-content-lifecycle/ # Lifecycle and activation keys
│ └── satellite-host-management/ # Host registration and updates
└── group_vars/ # Variable configurations
 └── satellite_demo.yml # Demo environment variables
```

## Quick Start

### 1. Complete Satellite Demo
```bash
cd satellite
ansible-playbook -i inventory_demo playbooks/satellite_complete_demo.yml
```

### 2. Quick Demo Setup
```bash
cd satellite
ansible-playbook -i inventory_demo playbooks/satellite_quick_demo.yml
```

### 3. With Custom Variables
```bash
cd satellite
ansible-playbook -i inventory_demo playbooks/satellite_complete_demo.yml \
 -e satellite_server_url="https://your-satellite.com" \
 -e satellite_organization="Your Organization"
```

## Architecture

### Three-Phase Approach

1. **Repository Management** (`satellite-repository-management`)
 - Red Hat CDN repository enablement
 - RHEL 9 repository support (BaseOS, AppStream, Supplementary)
 - Satellite 6.17 repository configuration
 - Automated sync plans by product

2. **Content Lifecycle** (`satellite-content-lifecycle`)
 - Lifecycle environment creation (DEV/TEST/PROD)
 - Content views with dependency solving
 - Composite content views with auto-publish
 - Activation key generation and management

3. **Host Management** (`satellite-host-management`)
 - Single node registration with activation keys
 - Host group bulk operations
 - CVE-specific update management
 - Red Hat Insights and RHC integration

## Key Features

### Security Management
- CVE-specific patching (CVE-2024-6387, CVE-2024-1086, CVE-2023-4911)
- Security update automation
- Red Hat Insights integration
- Compliance baseline maintenance

### Automation Capabilities
- Complete repository lifecycle management
- Automated content view publishing
- Host registration and management
- Multi-format reporting (HTML/JSON)
- Professional registration scripts

### Enterprise Integration
- Red Hat Satellite 6.17 native API
- Ansible Automation Platform 2.5 compatibility
- Red Hat Connector (RHC) configuration
- Comprehensive audit trails

## Configuration

### Default Demo Credentials
- **Username**: `admin`
- **Password**: `NTY4NjIw`
- **Server**: `https://satellite.example.com`
- **Organization**: `Default Organization`

### Customization
Edit `group_vars/satellite_demo.yml` for your environment or use command-line overrides.

## Individual Role Usage

### Repository Management Only
```bash
ansible-playbook -i inventory_demo playbooks/satellite_complete_demo.yml \
 --tags repository-management
```

### Content Lifecycle Only
```bash
ansible-playbook -i inventory_demo playbooks/satellite_complete_demo.yml \
 --tags content-lifecycle
```

### Host Management Only
```bash
ansible-playbook -i inventory_demo playbooks/satellite_complete_demo.yml \
 --tags host-management
```

## Requirements

- Red Hat Satellite 6.17
- Administrative access to Satellite server
- Ansible Automation Platform 2.5+
- Network connectivity between controller and Satellite
- Valid Red Hat subscriptions and manifest

## Reporting

All operations generate comprehensive reports in:
- HTML format for executive summaries
- JSON format for programmatic processing
- Detailed operation logs with timestamps

Reports are saved in `./reports/` with timestamps for historical tracking.

## Support

For detailed technical documentation, see [SATELLITE_README.md](SATELLITE_README.md).

For credential changes and updates, see [CREDENTIAL_UPDATES.md](CREDENTIAL_UPDATES.md).

## License

This project is licensed under the MIT License.

## Red Hat Integration

Designed specifically for:
- Red Hat Satellite 6.17
- Red Hat Enterprise Linux 9
- Ansible Automation Platform 2.5
- Red Hat Insights and RHC
