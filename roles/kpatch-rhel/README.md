# kpatch-rhel

A modern, comprehensive Ansible role for managing Red Hat kpatch live kernel patching across RHEL 7, 8, 9, and 10 systems. This role provides enterprise-grade live patching capabilities with advanced verification, monitoring, and management features.

## Description

This role automates the complete lifecycle of kpatch live kernel patching on Red Hat Enterprise Linux systems. It provides intelligent patch management, comprehensive system validation, advanced verification capabilities, and automated cleanup functionality while ensuring system stability and security.

## Features

### **Comprehensive Patch Management**
- **Multi-Action Support**: Install, enable, disable, list, remove, and info operations
- **Automatic Patch Discovery**: Auto-detection of available patches for current kernel
- **Selective Patching**: Support for specific patch lists or automatic installation
- **Emergency Controls**: Emergency disable functionality for critical situations
- **Backup Management**: Automatic kernel module backups before patching

### **Advanced System Validation**
- **RHEL Version Compatibility**: Full support for RHEL 7, 8, 9, and 10
- **Architecture Validation**: x86_64 architecture verification
- **Subscription Verification**: Red Hat subscription status validation
- **Kernel Compatibility**: Kernel development package availability checks
- **Live Patching Support**: System capability assessment

### **Comprehensive Verification**
- **Multi-Level Testing**: Command functionality, patch loading, kernel symbols
- **Conflict Detection**: Automatic detection of patch conflicts and errors
- **System Stability Checks**: Load average, memory usage, and error monitoring
- **Functional Testing**: Network, filesystem, and process management validation
- **Health Monitoring**: Real-time system health assessment

### **Enterprise Monitoring & Reporting**
- **Detailed Status Reports**: Comprehensive patch status and system health
- **Performance Metrics**: System load, memory usage, and stability indicators
- **Verification Results**: Pass/fail status for all validation tests
- **Operation Logging**: Complete audit trail of all patch operations
- **Facts Integration**: Ansible facts for automation and monitoring integration

### **Intelligent Cleanup Management**
- **Automatic Cleanup**: Removal of old patches and temporary files
- **Retention Policies**: Configurable patch retention based on count or age
- **Backup Cleanup**: Automatic cleanup of old kernel module backups
- **Package Cache Management**: Automatic package manager cache cleanup
- **Activity Logging**: Complete cleanup activity logging

## Requirements

- RHEL 7, 8, 9, or 10 (x86_64 architecture)
- Ansible 2.9+
- Active Red Hat subscription
- Root/sudo access on target systems
- Internet connectivity for package downloads (or local repository access)

## Role Variables

### Core Operation Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `kpatch_action` | `"install"` | Operation to perform: install, enable, disable, list, remove, info |
| `kpatch_specific_kernel` | `{{ ansible_facts['kernel'] }}` | Target kernel version for patches |
| `kpatch_auto_install_patches` | `true` | Automatically install available patches |
| `kpatch_patch_list` | `[]` | Specific patches to install (empty means all available) |

### Package Management

| Variable | Default | Description |
|----------|---------|-------------|
| `kpatch_package_manager` | `"auto"` | Package manager to use (auto, yum, dnf) |
| `kpatch_enable_repos` | `[]` | Additional repositories to enable |
| `kpatch_install_from_repos` | `true` | Install packages from repositories |
| `kpatch_force_install` | `false` | Force installation even if already present |

### Service Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `kpatch_service_enabled` | `true` | Enable kpatch service on boot |
| `kpatch_service_state` | `"started"` | Service state (started, stopped) |

### Validation Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `kpatch_validate_kernel` | `true` | Validate kernel compatibility |
| `kpatch_validate_architecture` | `true` | Validate system architecture |
| `kpatch_validate_subscription` | `true` | Validate Red Hat subscription |
| `kpatch_skip_validation` | `false` | Skip all validations (dangerous) |

### Verification & Monitoring

| Variable | Default | Description |
|----------|---------|-------------|
| `kpatch_verify_patches` | `true` | Perform comprehensive patch verification |
| `kpatch_verification_timeout` | `60` | Verification timeout (seconds) |
| `kpatch_verification_retries` | `12` | Number of verification attempts |
| `kpatch_verification_delay` | `5` | Delay between verification attempts |

### Timeout & Retry Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `kpatch_install_timeout` | `300` | Installation timeout (seconds) |
| `kpatch_install_retries` | `3` | Number of installation retries |
| `kpatch_install_delay` | `5` | Delay between retries |

### Cleanup Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `kpatch_cleanup_old_patches` | `false` | Remove old/unused patches |
| `kpatch_keep_patches_count` | `3` | Number of patch versions to retain |

### Security & Safety

| Variable | Default | Description |
|----------|---------|-------------|
| `kpatch_require_signature` | `true` | Require signed patches (RHEL 8+) |
| `kpatch_check_certificates` | `true` | Verify patch certificates |
| `kpatch_emergency_disable` | `false` | Emergency disable all patches |
| `kpatch_backup_before_install` | `true` | Backup modules before patching |

### Logging & Reporting

| Variable | Default | Description |
|----------|---------|-------------|
| `kpatch_verbose_output` | `true` | Show detailed output |
| `kpatch_log_patches` | `true` | Log patch operations |
| `kpatch_report_status` | `true` | Report final status |
| `kpatch_set_facts` | `true` | Set Ansible facts with patch info |
| `kpatch_notify_handlers` | `true` | Notify handlers on changes |

## Dependencies

None.

## Example Playbooks

### Basic Patch Installation

```yaml
---
- hosts: rhel_servers
 become: true
 roles:
 - kpatch-rhel
```

### Install Specific Patches with Verification

```yaml
---
- hosts: production_servers
 become: true
 roles:
 - role: kpatch-rhel
 vars:
 kpatch_action: install
 kpatch_patch_list:
 - "kpatch-patch-4.18.0-372.9.1.el8_6"
 kpatch_verify_patches: true
 kpatch_backup_before_install: true
 kpatch_verbose_output: true
```

### Emergency Patch Disable

```yaml
---
- hosts: problematic_servers
 become: true
 roles:
 - role: kpatch-rhel
 vars:
 kpatch_action: disable
 kpatch_emergency_disable: true
 kpatch_verify_patches: true
```

### List All Patches with Detailed Status

```yaml
---
- hosts: all_servers
 become: true
 roles:
 - role: kpatch-rhel
 vars:
 kpatch_action: list
 kpatch_verbose_output: true
 kpatch_skip_validation: true
```

### Production Environment with Full Monitoring

```yaml
---
- hosts: production
 become: true
 serial: 1 # One server at a time in production
 roles:
 - role: kpatch-rhel
 vars:
 kpatch_action: install
 kpatch_verify_patches: true
 kpatch_backup_before_install: true
 kpatch_verification_timeout: 120
 kpatch_log_patches: true
 kpatch_cleanup_old_patches: true
 kpatch_keep_patches_count: 2
```

### Development Environment with Relaxed Validation

```yaml
---
- hosts: dev_servers
 become: true
 roles:
 - role: kpatch-rhel
 vars:
 kpatch_action: install
 kpatch_validate_subscription: false
 kpatch_backup_before_install: false
 kpatch_force_install: true
 kpatch_cleanup_old_patches: true
```

## Operation Modes

### Install Mode (`kpatch_action: install`)
- Installs kpatch packages and available patches
- Automatically detects and installs patches for current kernel
- Supports specific patch lists
- Includes comprehensive verification

### Enable Mode (`kpatch_action: enable`)
- Enables previously installed but disabled patches
- Loads patches into running kernel
- Verifies successful loading

### Disable Mode (`kpatch_action: disable`)
- Disables currently loaded patches
- Supports emergency disable for all patches
- Maintains patch availability for future use

### List Mode (`kpatch_action: list`)
- Provides detailed status of all patches
- Shows enabled, disabled, and available patches
- Includes system information and health status

### Remove Mode (`kpatch_action: remove`)
- Unloads and removes patch packages
- Supports selective or complete removal
- Includes cleanup of related files

## Verification Process

The role performs comprehensive verification including:

1. **Command Functionality**: Verifies kpatch command operation
2. **Patch Loading**: Confirms patches are properly loaded
3. **Kernel Symbols**: Validates kernel symbol integrity 
4. **Conflict Detection**: Checks for patch conflicts
5. **System Stability**: Monitors load, memory, and errors
6. **Functional Testing**: Tests network, filesystem, and processes

## Security Considerations

- **Signature Verification**: Patches are verified for authenticity (RHEL 8+)
- **Certificate Validation**: SSL certificates are verified
- **Subscription Validation**: Ensures valid Red Hat entitlements
- **Backup Creation**: Automatic backups before modifications
- **Emergency Controls**: Emergency disable capability

## Version-Specific Behavior

### RHEL 7
- Uses `yum` package manager
- Basic kpatch functionality
- Limited verification capabilities

### RHEL 8+
- Uses `dnf` package manager with kpatch-dnf plugin
- Enhanced patch signature verification
- Advanced kernel symbol validation
- Improved conflict detection

## Troubleshooting

### Common Issues

1. **Subscription Problems**
 ```yaml
 kpatch_validate_subscription: false # Bypass subscription validation
 ```

2. **Patch Installation Failures**
 ```yaml
 kpatch_force_install: true # Force installation
 kpatch_install_retries: 5 # Increase retry count
 ```

3. **Verification Failures**
 ```yaml
 kpatch_verify_patches: false # Skip verification (not recommended)
 ```

4. **Service Issues**
 ```bash
 systemctl status kpatch
 journalctl -u kpatch
 ```

### Emergency Recovery

```yaml
# Emergency disable all patches
- role: kpatch-rhel
 vars:
 kpatch_emergency_disable: true
 kpatch_skip_validation: true
```

## Performance Impact

- Minimal performance overhead during normal operation
- Brief CPU spike during patch installation/removal
- Memory usage increases by ~1-5MB per loaded patch
- No impact on system reboot time

## Best Practices

1. **Test in Development**: Always test patches in non-production first
2. **Staged Rollout**: Use `serial: 1` for production deployments
3. **Monitor Systems**: Enable comprehensive logging and monitoring
4. **Regular Cleanup**: Implement automated cleanup policies
5. **Emergency Procedures**: Have disable procedures ready

## Integration

### Monitoring Systems
```yaml
# Set facts for external monitoring
kpatch_set_facts: true
```

### CI/CD Pipelines
```yaml
# Automated patch management
kpatch_auto_install_patches: true
kpatch_cleanup_old_patches: true
```

## License

Apache-2.0

## Author Information

Created by Santiago Gallego 
Modernized kpatch management for RHEL 7-10 with enterprise features

## Contributing

This role is part of a comprehensive RHEL management suite. For issues, feature requests, or contributions, please follow the project's contribution guidelines.
