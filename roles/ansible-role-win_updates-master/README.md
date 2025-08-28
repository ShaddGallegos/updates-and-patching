# Ansible Role: Windows Updates Master (v2.0)

A comprehensive, modernized Ansible role for managing Windows updates across the latest Windows distributions with enhanced security, automation, and enterprise-grade features.

##  New in v2.0

- **Distribution-Specific Support**: Optimized for Windows 11, Windows Server 2022, and Windows 10 22H2
- **Enhanced Security Features**: Advanced security configurations and compliance integration
- **Professional Reporting**: Comprehensive HTML/JSON reports with executive summaries
- **Enterprise Integration**: Ready for enterprise environments with proper error handling
- **Automated Cleanup**: Intelligent post-update cleanup and optimization
- **Modern PowerShell**: Leverages latest PowerShell capabilities and Windows features

##  Supported Windows Distributions

| Distribution | Version | Build | Status |
|--------------|---------|-------|---------|
| **Windows 11** | 21H2+ | 22000+ |  Fully Supported |
| **Windows Server 2022** | All Editions | 20348+ |  Fully Supported |
| **Windows 10 22H2** | Pro/Enterprise/Education | 19041+ |  Fully Supported |
| Windows 10 (older) | < 22H2 | < 19041 |  Legacy Support |
| Windows Server 2019 | All Editions | 17763+ |  Legacy Support |

##  Quick Start

### Basic Usage

```yaml
- hosts: windows
  roles:
    - ansible-role-win_updates-master
  vars:
    win_updates_category_names:
      - SecurityUpdates
      - CriticalUpdates
      - UpdateRollups
    win_updates_generate_report: true
    win_updates_reboot: false
```

##  Role Variables

### Core Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `win_updates_category_names` | `['SecurityUpdates', 'CriticalUpdates']` | Update categories to install |
| `win_updates_state` | `installed` | State of updates (installed/searched) |
| `win_updates_reboot` | `false` | Automatically reboot if required |
| `win_updates_reboot_timeout` | `1200` | Timeout for reboot operations (seconds) |

### Distribution-Specific Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `win_updates_auto_detect_distribution` | `true` | Automatically detect Windows distribution |
| `windows_distribution` | `auto` | Override distribution detection |
| `win_updates_distribution_specific` | `true` | Enable distribution-specific features |

### Enterprise Features

| Variable | Default | Description |
|----------|---------|-------------|
| `win_updates_generate_report` | `true` | Generate comprehensive reports |
| `win_updates_cleanup_enabled` | `true` | Enable post-update cleanup |
| `win_updates_optimize_settings` | `true` | Optimize Windows Update settings |

##  Distribution-Specific Features

### Windows 11 Features
- **Smart App Control** integration
- **Enhanced Phishing Protection** updates
- **Controlled Folder Access** compatibility
- **Microsoft Store** app updates
- **Windows Security** advanced features

### Windows Server 2022 Features
- **WSUS client** optimization
- **Server Core** compatibility
- **Security baseline** enforcement
- **.NET Framework** updates
- **PowerShell** enhancement updates

### Windows 10 22H2 Features
- **Extended support** notifications
- **Upgrade eligibility** checks
- **Legacy feature** support warnings
- **Microsoft Edge** WebView2 updates

##  Usage Examples

### Basic Security Updates

```yaml
- name: Install security updates only
  include_role:
    name: ansible-role-win_updates-master
  vars:
    win_updates_category_names:
      - SecurityUpdates
    win_updates_generate_report: true
```

### Enterprise Maintenance Window

```yaml
- name: Maintenance window update session
  include_role:
    name: ansible-role-win_updates-master
  vars:
    win_updates_category_names:
      - SecurityUpdates
      - CriticalUpdates
      - UpdateRollups
      - DefinitionUpdates
    win_updates_reboot: true
    win_updates_reboot_timeout: 1800
    win_updates_generate_report: true
    win_updates_cleanup_enabled: true
```

##  Requirements

### Ansible Controller
- Ansible 2.12 or later
- `community.windows` collection 2.2.0+
- Python 3.8+ with `pywinrm`

### Target Systems
- Windows 11 (Build 22000+)
- Windows Server 2022 (Build 20348+)  
- Windows 10 22H2 (Build 19041+)
- PowerShell 5.1 or PowerShell Core 7.0+
- WinRM configured and accessible
- Administrator privileges

##  License

This role is licensed under the MIT License.

##  Author Information

This role was modernized by the Enterprise Automation Team for Windows 11, Server 2022, and Windows 10 22H2 support.

---

**ansible-role-win_updates-master v2.0** - Modern Windows Updates Management for Enterprise Environments
