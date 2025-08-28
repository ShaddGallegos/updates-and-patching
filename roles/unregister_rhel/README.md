# unregister_rhel

An Ansible role to unregister RHEL systems from Red Hat Subscription Manager or Red Hat Satellite with comprehensive cleanup.

## Description

This role automatically detects whether a RHEL system is registered to Red Hat Subscription Manager (direct) or Red Hat Satellite, then performs appropriate unregistration and cleanup tasks.

## Features

- **Smart Detection**: Automatically determines registration type (Satellite vs direct RHN)
- **Comprehensive Cleanup**: Removes all subscription data, certificates, and configurations
- **Satellite-Specific Cleanup**: Additional cleanup for Satellite-managed systems including:
  - Katello agent packages and services
  - Puppet configurations and data
  - Foreman configurations
  - Satellite cron jobs and logs
- **Safe Operation**: All tasks use `ignore_errors: true` to prevent failures on missing items
- **Configurable**: Multiple variables to control behavior

## Requirements

- RHEL 7, 8, or 9
- Ansible 2.9+
- Root/sudo access on target systems

## Role Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `unregister_rhel_verbose` | `true` | Display verbose output during unregistration |
| `unregister_rhel_clean_satellite` | `true` | Perform Satellite-specific cleanup when detected |
| `unregister_rhel_clean_logs` | `false` | Clean up log directories (disabled by default due to size) |
| `unregister_rhel_force` | `false` | Force unregistration even if system appears unregistered |

## Dependencies

None.

## Example Playbook

### Basic Usage

```yaml
---
- hosts: rhel_servers
  become: true
  roles:
    - unregister_rhel
```

### Custom Configuration

```yaml
---
- hosts: rhel_servers
  become: true
  roles:
    - role: unregister_rhel
      vars:
        unregister_rhel_verbose: false
        unregister_rhel_clean_logs: true
```

## What Gets Cleaned Up

### Universal Cleanup (All Systems)
- Unregistration from subscription service
- Subscription manager data and cache
- Yum/DNF cache and metadata
- Red Hat repository files
- Consumer certificates and entitlements
- Katello CA consumer packages

### Satellite-Specific Cleanup (When Detected)
- Katello agent, Puppet agent, and related packages
- Foreman and Puppet configuration directories
- Satellite service files and cron jobs
- Satellite certificates and CA trust
- Configuration backups
- Log directories (optional)

## License

Apache-2.0

## Author Information

Created by ShaddGallegos for Red Hat system administration.
