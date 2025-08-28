# register_rhel

An Ansible role to register RHEL systems with Red Hat CDN or Red Hat Satellite with comprehensive repository configuration.

## Description

This role provides a unified interface for registering RHEL systems with either the Red Hat Customer Portal (CDN) or Red Hat Satellite. It handles certificate installation, subscription attachment, and repository configuration automatically.

## Features

- **Dual Registration Support**: CDN or Satellite registration
- **Smart Detection**: Checks existing registration status
- **Flexible Authentication**: Username/password or activation keys for Satellite
- **Repository Management**: Automatic repository configuration per RHEL version
- **Validation**: Comprehensive parameter validation
- **Safe Operation**: Prevents duplicate registrations unless forced
- **Comprehensive Logging**: Detailed output for troubleshooting

## Requirements

- RHEL 7, 8, or 9
- Ansible 2.9+
- Root/sudo access on target systems
- Valid Red Hat subscription credentials or Satellite access

## Role Variables

### Common Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `register_rhel_type` | `cdn` | Registration type: 'cdn' or 'satellite' |
| `register_rhel_verbose` | `true` | Display verbose output |
| `register_rhel_force` | `false` | Force re-registration if already registered |

### CDN Registration Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `register_rhel_username` | Yes | Red Hat Customer Portal username |
| `register_rhel_password` | Yes | Red Hat Customer Portal password |
| `register_rhel_auto_attach` | No (true) | Automatically attach available subscriptions |
| `register_rhel_pool_ids` | No | Specific pool IDs to attach |
| `register_rhel_consumer_type` | No | Consumer type for registration |
| `register_rhel_consumer_name` | No | Custom consumer name |

### Satellite Registration Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `register_rhel_satellite_url` | Yes | Satellite server URL |
| `register_rhel_org_id` | Yes | Organization ID in Satellite |
| `register_rhel_activation_key` | Yes* | Activation key for registration |
| `register_rhel_satellite_username` | Yes* | Satellite username (if not using activation key) |
| `register_rhel_satellite_password` | Yes* | Satellite password (if not using activation key) |
| `register_rhel_install_satellite_ca` | No (true) | Install Satellite CA certificate |
| `register_rhel_install_satellite_tools` | No (false) | Install Satellite client tools |
| `register_rhel_validate_certs` | No (true) | Validate SSL certificates |

*Either activation key OR username/password required

### Repository Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `register_rhel_configure_repos` | `true` | Configure repositories after registration |
| `register_rhel_use_default_repos` | `true` | Enable default repos for RHEL version |
| `register_rhel_additional_repos` | `[]` | Additional repositories to enable |
| `register_rhel_disable_repos` | `[]` | Repositories to disable |
| `register_rhel_update_cache` | `true` | Update package cache after registration |

## Dependencies

None.

## Example Playbooks

### CDN Registration

```yaml
---
- hosts: rhel_servers
  become: true
  roles:
    - role: register_rhel
      vars:
        register_rhel_type: cdn
        register_rhel_username: "{{ vault_rhn_username }}"
        register_rhel_password: "{{ vault_rhn_password }}"
```

### Satellite Registration with Activation Key

```yaml
---
- hosts: rhel_servers
  become: true
  roles:
    - role: register_rhel
      vars:
        register_rhel_type: satellite
        register_rhel_satellite_url: "https://satellite.example.com"
        register_rhel_org_id: "Example_Org"
        register_rhel_activation_key: "rhel-servers-key"
        register_rhel_install_satellite_tools: true
```

### Satellite Registration with Username/Password

```yaml
---
- hosts: rhel_servers
  become: true
  roles:
    - role: register_rhel
      vars:
        register_rhel_type: satellite
        register_rhel_satellite_url: "https://satellite.example.com"
        register_rhel_org_id: "Example_Org"
        register_rhel_satellite_username: "{{ vault_satellite_username }}"
        register_rhel_satellite_password: "{{ vault_satellite_password }}"
```

### Custom Repository Configuration

```yaml
---
- hosts: rhel_servers
  become: true
  roles:
    - role: register_rhel
      vars:
        register_rhel_type: cdn
        register_rhel_username: "{{ vault_rhn_username }}"
        register_rhel_password: "{{ vault_rhn_password }}"
        register_rhel_additional_repos:
          - ansible-automation-platform-2.4-for-rhel-9-x86_64-rpms
          - codeready-builder-for-rhel-9-x86_64-rpms
        register_rhel_disable_repos:
          - rhel-9-for-x86_64-supplementary-rpms
```

## Default Repositories by RHEL Version

### RHEL 7
- rhel-7-server-rpms
- rhel-7-server-rh-common-rpms
- rhel-7-server-extras-rpms
- rhel-7-server-optional-rpms
- rhel-7-server-supplementary-rpms

### RHEL 8
- rhel-8-for-x86_64-baseos-rpms
- rhel-8-for-x86_64-appstream-rpms
- rhel-8-for-x86_64-supplementary-rpms
- rhel-8-for-x86_64-highavailability-rpms

### RHEL 9
- rhel-9-for-x86_64-baseos-rpms
- rhel-9-for-x86_64-appstream-rpms
- rhel-9-for-x86_64-supplementary-rpms
- rhel-9-for-x86_64-highavailability-rpms

## Security Considerations

- Store sensitive variables (passwords, usernames) in Ansible Vault
- Use activation keys instead of username/password for Satellite when possible
- Validate SSL certificates in production environments
- Limit access to playbooks containing registration credentials

## Troubleshooting

- Set `register_rhel_verbose: true` for detailed output
- Use `register_rhel_force: true` to re-register existing systems
- Check subscription-manager logs: `/var/log/rhsm/rhsm.log`
- Verify network connectivity to Red Hat CDN or Satellite server

## License

Apache-2.0

## Author Information

Created by ShaddGallegos for Red Hat system administration.
