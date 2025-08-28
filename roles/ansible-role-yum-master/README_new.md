# ansible-role-yum

A comprehensive Ansible role for configuring YUM/DNF package manager on Red Hat Enterprise Linux systems. This role supports RHEL versions 7, 8, 9, and 10 with intelligent detection of the appropriate package manager and version-specific optimizations.

## Features

- **Multi-Version Support**: RHEL 7, 8, 9, and 10 compatibility
- **Intelligent Package Manager Detection**: Automatically uses YUM (RHEL 7) or DNF (RHEL 8+)
- **Version-Specific Optimizations**: Tailored settings for each RHEL version
- **Enhanced Security**: GPG checking and security-focused configurations
- **Performance Tuning**: Optimized cache settings, timeouts, and download options
- **Configuration Validation**: Automatic validation of package manager configurations
- **Backup Management**: Automatic backup of original configuration files

## Requirements

- **Operating System**: Red Hat Enterprise Linux 7, 8, 9, or 10
- **Ansible**: 2.9+ (recommended: 4.0+)
- **Privileges**: sudo/root access required
- **Python**: 3.6+ on target systems

## Supported RHEL Versions

| RHEL Version | Package Manager | Key Features |
|--------------|-----------------|--------------|
| RHEL 7.x | YUM | Traditional YUM configuration, basic optimizations |
| RHEL 8.x | DNF | DNF optimizations, enhanced security, best package selection |
| RHEL 9.x | DNF | Advanced features: zchunk compression, fastest mirror, countme |
| RHEL 10.x | DNF | Latest features: module hotfixes, kernel protection, enhanced limits |

## Role Variables

### Core Configuration

```yaml
# Package manager settings
yum_keepcache: 0                    # Keep downloaded packages (0=no, 1=yes)
yum_debuglevel: 2                   # Debug logging level (0-10)
yum_gpgcheck: 1                     # Enable GPG signature checking
yum_skip_if_unavailable: 1          # Skip unavailable repositories

# Version-specific timeouts and limits
yum_timeout: 300                    # RHEL 7-8: 300s, RHEL 9+: 600s
yum_installonly_limit: 3            # RHEL 7-9: 3, RHEL 10+: 5

# Configuration management
yum_backup_original: true           # Backup original config before changes
yum_validate_config: true           # Validate configuration after changes
yum_restart_services_on_change: true # Restart services when config changes
```

### Advanced Options

```yaml
# DNF-specific settings (RHEL 8+)
yum_best: 1                         # Always install best available version
yum_clean_requirements_on_remove: 1 # Clean unused dependencies

# RHEL 9+ optimizations
yum_zchunk: 1                       # Enable zchunk compression
yum_countme: 1                      # Anonymous usage statistics
yum_fastestmirror: 1                # Use fastest available mirror

# RHEL 10+ advanced features
yum_module_hotfixes: 1              # Enable module hotfixes
yum_protect_running_kernel: 1       # Protect currently running kernel

# Enhanced security (RHEL 8+)
yum_localpkg_gpgcheck: 1            # Check local packages with GPG
yum_repo_gpgcheck: 0                # Repository GPG checking
```

## Usage Examples

### Basic Configuration

```yaml
---
- name: Configure YUM/DNF on RHEL systems
  hosts: rhel_servers
  become: true
  roles:
    - role: ansible-role-yum
```

### Advanced Configuration

```yaml
---
- name: Advanced YUM/DNF configuration
  hosts: production_servers
  become: true
  roles:
    - role: ansible-role-yum
      vars:
        yum_keepcache: 1
        yum_timeout: 900
        yum_backup_original: true
        yum_validate_config: true
```

### Version-Specific Settings

```yaml
---
- name: Configure with version-specific optimizations
  hosts: all
  become: true
  roles:
    - role: ansible-role-yum
      vars:
        # These will be automatically applied based on RHEL version
        yum_zchunk: "{{ 1 if ansible_facts['distribution_major_version']|int >= 9 else omit }}"
        yum_fastestmirror: "{{ 1 if ansible_facts['distribution_major_version']|int >= 9 else omit }}"
```

## Configuration Files

The role manages different configuration files based on RHEL version:

- **RHEL 7**: `/etc/yum.conf`
- **RHEL 8+**: `/etc/dnf/dnf.conf`

## Key Features by RHEL Version

### RHEL 7
- Traditional YUM configuration
- Basic security and performance settings
- Standard cache and timeout configurations

### RHEL 8
- DNF-based configuration
- Enhanced security with local package GPG checking
- Best package selection and dependency cleanup
- Improved performance settings

### RHEL 9
- Advanced DNF features
- Zchunk compression for faster downloads
- Fastest mirror selection
- Anonymous usage statistics (countme)
- Extended timeout for better reliability

### RHEL 10
- Latest DNF capabilities
- Module hotfix support
- Running kernel protection
- Increased installonly limits
- Enhanced security features

## Handlers

The role includes handlers for:

- **Configuration Validation**: Validates YUM/DNF configuration syntax
- **Service Management**: Restarts package manager services when needed
- **Cache Management**: Cleans and rebuilds package cache

## Tags

Use these tags for selective execution:

```bash
# Validation only
ansible-playbook -t validation playbook.yml

# Configuration only
ansible-playbook -t config playbook.yml

# Cache management only
ansible-playbook -t cache,clean playbook.yml
```

## Dependencies

No external role dependencies required.

## Testing

The role includes comprehensive testing:

- **Syntax validation** for all RHEL versions
- **Configuration validation** using native tools
- **Service functionality** testing
- **Cache operation** verification

## Troubleshooting

### Common Issues

1. **Permission Denied**: Ensure the playbook runs with `become: true`
2. **Configuration Validation Fails**: Check that all package manager tools are installed
3. **Service Restart Issues**: Verify systemd is available and functional

### Debug Mode

Enable detailed logging:

```yaml
- role: ansible-role-yum
  vars:
    yum_debuglevel: 10
```

## Version History

- **v2.0**: Complete rewrite with RHEL 7-10 support, DNF compatibility
- **v1.x**: Legacy YUM-only support (deprecated)

## License

MIT License - See LICENSE file for details

## Author Information

**Updated for Modern RHEL**: System Administration Team  
**Enterprise Infrastructure**: Multi-version RHEL support  
**Contact**: sysadmin-team@company.com

---

**⚠️ Important**: This role modifies critical package manager configuration. Always test in a development environment before deploying to production systems.
