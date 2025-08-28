# update-rhel

A modern Ansible role for comprehensive RHEL system updates with intelligent package management, enhanced error handling, and sophisticated reboot management across RHEL 7, 8, 9, and 10.

## Description

This role provides intelligent, modular package updates for Red Hat Enterprise Linux systems across all major versions (7, 8, 9, 10). It features a modern task-based architecture with separate modules for pre-update preparation, package updates, post-update analysis, and comprehensive reboot handling.

## Features

- **Modern Modular Architecture**: Separate task files for different update phases
- **Multi-Version Support**: RHEL 7, 8, 9, and 10 with version-specific optimizations
- **Intelligent Package Manager Detection**: Automatic yum/dnf selection based on RHEL version
- **Enhanced Delta RPM Support**: Automatic installation of appropriate delta RPM packages
- **Comprehensive Reboot Management**: Smart kernel update detection and reboot handling
- **Advanced Error Handling**: Detailed error recovery and reporting mechanisms 
- **Post-Update Validation**: System health checks and custom command execution
- **Extensive Debugging**: Detailed logging and status reporting throughout the process
- **Flexible Update Options**: Security-only, bugfix, selective package updates
- **Performance Optimizations**: Cache management and update efficiency features

## Requirements

- RHEL 7, 8, 9, or 10
- Ansible 2.9+
- Root/sudo access on target systems
- Active Red Hat subscription or repository access

## Role Variables

### Core Update Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `update_distro_packages` | `"*"` | Packages to update (use "*" for all) |
| `update_distro_packages_excludes` | `[]` | List of packages to exclude from updates |
| `update_reboot_kernel` | `false` | Whether to reboot after kernel updates |
| `reboot_timeout` | `600` | Timeout in seconds for reboot completion |

### Update Behavior Controls

| Variable | Default | Description |
|----------|---------|-------------|
| `update_rhel_security_only` | `false` | Install security updates only |
| `update_rhel_bugfix` | `false` | Install bugfix updates |
| `update_rhel_skip_broken` | `true` | Skip packages with broken dependencies |
| `update_rhel_ignore_errors` | `false` | Continue on update errors |
| `update_rhel_clean_cache` | `true` | Clean package manager cache before updates |
| `update_rhel_force_run` | `false` | Force updates even if no updates are available |

### RHEL 8+ DNF-Specific Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `update_rhel_nobest` | `false` | Allow installation of non-best candidate packages |
| `update_rhel_allow_erasing` | `false` | Allow package removal to resolve conflicts |

### Reboot Management

| Variable | Default | Description |
|----------|---------|-------------|
| `update_rhel_force_reboot` | `false` | Force reboot regardless of kernel updates |
| `update_rhel_pre_reboot_delay` | `10` | Seconds to wait before rebooting |
| `update_rhel_post_reboot_delay` | `30` | Seconds to wait after reboot before continuing |
| `update_rhel_connect_timeout` | `10` | Connection timeout for post-reboot validation |
| `update_rhel_test_command` | `"whoami"` | Command to test system responsiveness after reboot |

### Display and Logging

| Variable | Default | Description |
|----------|---------|-------------|
| `update_rhel_verbose` | `true` | Display detailed update information |
| `update_rhel_show_updates` | `false` | Show list of available updates before installing |

### Post-Reboot Validation (Optional)

| Variable | Default | Description |
|----------|---------|-------------|
| `update_rhel_post_reboot_commands` | `undefined` | List of commands to run after successful reboot |

## Dependencies

None.

## Example Playbooks

### Basic System Update

```yaml
---
- hosts: rhel_servers
 become: true
 roles:
 - update-rhel
```

### Security Updates Only with Reboot

```yaml
---
- hosts: rhel_servers
 become: true
 roles:
 - role: update-rhel
 vars:
 update_rhel_security_only: true
 update_reboot_kernel: true
 update_rhel_verbose: true
```

### Comprehensive Update with Custom Validation

```yaml
---
- hosts: rhel_servers
 become: true
 roles:
 - role: update-rhel
 vars:
 update_reboot_kernel: true
 update_rhel_force_reboot: false
 update_rhel_post_reboot_commands:
 - "systemctl status"
 - "df -h" 
 - "free -m"
 - "uptime"
 reboot_timeout: 900
```

### Selective Package Updates with Error Handling

```yaml
---
- hosts: rhel_servers
 become: true
 roles:
 - role: update-rhel
 vars:
 update_distro_packages: "security"
 update_distro_packages_excludes:
 - kernel*
 - docker*
 update_rhel_skip_broken: true
 update_rhel_ignore_errors: false
 update_rhel_clean_cache: true
```

### High-Performance Update Configuration

```yaml
---
- hosts: rhel_servers
 become: true
 serial: 5
 roles:
 - role: update-rhel
 vars:
 update_rhel_nobest: false
 update_rhel_allow_erasing: true
 update_rhel_clean_cache: true
 update_rhel_pre_reboot_delay: 5
 update_rhel_post_reboot_delay: 15
```

## Architecture

The role uses a modular task-based architecture:

- **`main.yml`**: Orchestrates the update process using include_tasks
- **`pre_update.yml`**: Pre-update preparation, fact gathering, and delta RPM setup 
- **`package_updates.yml`**: Version-specific package updates with yum/dnf logic
- **`post_update.yml`**: Post-update analysis and reboot requirement detection
- **`reboot_handling.yml`**: Comprehensive reboot management and validation

## Version-Specific Behavior

### RHEL 7
- Uses `yum` package manager with optimized settings
- Installs `deltarpm` for delta RPM support
- Enhanced error handling for older package management
- Custom reboot detection for kernel updates

### RHEL 8+
- Uses `dnf` package manager with advanced options
- Installs `drpm` for delta RPM support 
- Enhanced DNF-specific options (nobest, allow_erasing)
- Improved reboot detection using dnf needs-restarting
- Better dependency resolution and conflict handling

## Task Flow

1. **Pre-Update Phase**: System preparation and fact gathering
2. **Package Update Phase**: Version-appropriate package manager execution
3. **Post-Update Phase**: Update analysis and reboot requirement detection 
4. **Reboot Phase**: Intelligent reboot handling with validation (if needed)

## License

Apache-2.0

## Author Information

Originally created by Orcun Atakan (oatakan@redhat.com)
Enhanced for RHEL 7-10 support by ShaddGallegos
