# Red Hat Satellite 6.17 Management Automation

## Overview

This project provides comprehensive automation for Red Hat Satellite 6.17 management using Ansible Automation Platform 2.5. The automation covers the complete lifecycle of Satellite management from repository setup through host compliance management.

## Architecture

### Three-Phase Approach

1. **Repository Management** - Set up Red Hat repositories and sync plans
2. **Content Lifecycle** - Create environments, content views, and activation keys  
3. **Host Management** - Register hosts, perform updates, configure compliance

## Roles

### satellite-repository-management

Manages Red Hat repository setup and synchronization.

**Features:**
- Red Hat CDN repository enablement
- RHEL 9 repository support (BaseOS, AppStream, Supplementary)
- Satellite 6.17 repository configuration
- Automated sync plans by product
- Comprehensive validation and reporting

**Key Tasks:**
- Enable Red Hat repositories via API
- Configure sync plans (daily for RHEL, weekly for Satellite)
- Validate repository availability
- Generate detailed HTML/JSON reports

### satellite-content-lifecycle

Manages lifecycle environments, content views, and activation keys.

**Features:**
- Lifecycle environment creation (DEV/TEST/PROD)
- Content views with dependency solving
- Composite content views with auto-publish
- Activation key generation and management
- Host collection configuration
- Professional registration scripts

**Key Tasks:**
- Create RHEL_9_DEV/TEST/PROD_x86_64 environments
- Build content views with repository associations
- Generate composite content views
- Create activation keys for each environment
- Provide registration scripts for easy host onboarding

### satellite-host-management

Manages host registration, package updates, and compliance integration.

**Features:**
- Single node registration with activation keys
- Host group bulk operations
- Organization-wide management
- CVE-specific update management
- Security/bugfix update automation
- Red Hat Insights integration
- Red Hat Connector (RHC) configuration

**Key Tasks:**
- Register hosts using activation keys
- Perform targeted CVE updates
- Execute security and bugfix updates
- Configure Insights and RHC clients
- Generate comprehensive operation reports

## Usage

### Quick Start - Complete Demo

```bash
# Run complete Satellite 6.17 management demo
ansible-playbook -i inventory satellite_complete_demo.yml

# With custom variables
ansible-playbook -i inventory satellite_complete_demo.yml \
  -e satellite_server_url="https://your-satellite.com" \
  -e satellite_organization="Your Organization"
```

### Individual Role Usage

#### Repository Management Only
```bash
ansible-playbook -i inventory -e @group_vars/satellite.yml \
  --tags repository-management satellite_complete_demo.yml
```

#### Content Lifecycle Only
```bash
ansible-playbook -i inventory -e @group_vars/satellite.yml \
  --tags content-lifecycle satellite_complete_demo.yml
```

#### Host Management Only
```bash
ansible-playbook -i inventory -e @group_vars/satellite.yml \
  --tags host-management satellite_complete_demo.yml
```

### Specific Operations

#### CVE Updates Only
```bash
ansible-playbook -i inventory -e @group_vars/satellite.yml \
  --tags cve-updates satellite_complete_demo.yml
```

#### Single Node Registration
```bash
ansible-playbook -i inventory -e @group_vars/satellite.yml \
  --tags single-node satellite_complete_demo.yml
```

#### Compliance Integration
```bash
ansible-playbook -i inventory -e @group_vars/satellite.yml \
  --tags compliance-integration satellite_complete_demo.yml
```

## Configuration

### Required Variables

```yaml
# Satellite Server Configuration
satellite_server_url: "https://satellite.example.com"
satellite_username: "admin"
satellite_password: "{{ vault_satellite_password }}"
satellite_organization: "Default Organization"
satellite_location: "Default Location"

# Operation Settings
dry_run: false
debug_mode: true
```

### Target Host Configuration

```yaml
target_hosts:
  single_node:
    enabled: true
    hostname: "rhel9-server-01.example.com"
    activation_key: "RHEL_9_PROD_x86_64_Key"
    host_collection: "RHEL_9_Production_Hosts"
  
  host_groups:
    - name: "RHEL_9_Production_Servers"
      enabled: true
      activation_key: "RHEL_9_PROD_x86_64_Key"
      host_collection: "RHEL_9_Production_Hosts"
  
  all_nodes:
    enabled: false  # Organization-wide operations
```

### Package Update Configuration

```yaml
package_operations:
  cve_updates:
    enabled: true
    target_cves:
      - "CVE-2024-6387"  # OpenSSH
      - "CVE-2024-1086"  # Kernel
      - "CVE-2023-4911"  # glibc
  
  security_updates:
    enabled: true
  
  bugfix_updates:
    enabled: true
  
  all_updates:
    enabled: false
  
  reboot_if_required: true
```

### Compliance Integration

```yaml
insights_integration:
  install_client: true
  register_hosts: true
  enable_data_collection: true

rhc_integration:
  install_rhc: true
  configure_connection: true
  enable_remote_management: true
```

## Repository Structure

```
roles/
 satellite-repository-management/
    defaults/main.yml
    tasks/
       main.yml
       validation.yml
       repositories.yml
       sync_plans.yml
    templates/
        repository_report.html.j2
        repository_report.json.j2

 satellite-content-lifecycle/
    defaults/main.yml
    tasks/
       main.yml
       validation.yml
       lifecycle_environments.yml
       content_views.yml
       activation_keys.yml
       host_collections.yml
    templates/
        lifecycle_report.html.j2
        lifecycle_report.json.j2
        register_host.sh.j2

 satellite-host-management/
     defaults/main.yml
     tasks/
        main.yml
        validation.yml
        job_templates.yml
        single_node.yml
        host_groups.yml
        all_nodes.yml
        cve_updates.yml
        security_bugfix_updates.yml
        insights_rhc_integration.yml
     templates/
         host_management_report.html.j2
         host_management_report.json.j2
         update_report.html.j2
         update_report.json.j2
```

## Requirements

### Satellite Requirements
- Red Hat Satellite 6.17
- Administrative access to Satellite server
- Organization and Location configured
- Manifest imported and subscriptions available

### Ansible Requirements
- Ansible Automation Platform 2.5+
- `uri` module for REST API calls
- Access to target hosts for registration

### Network Requirements
- Connectivity from Ansible controller to Satellite server
- Connectivity from target hosts to Satellite server
- Internet access for Red Hat CDN synchronization

## Features

### Repository Management
-  Red Hat CDN repository enablement
-  RHEL 9 complete repository support
-  Satellite 6.17 repository configuration
-  Automated sync plans by product
-  Repository validation and status checking
-  Professional HTML/JSON reporting

### Content Lifecycle
-  Lifecycle environment creation (DEV/TEST/PROD)
-  Content views with dependency solving
-  Composite content views with auto-publish
-  Activation key automation
-  Host collection management
-  Professional registration script generation

### Host Management
-  Single node registration with activation keys
-  Host group bulk operations
-  Organization-wide management capabilities
-  CVE-specific update targeting
-  Security update automation
-  Bugfix update management
-  Complete system update orchestration
-  Red Hat Insights client integration
-  Red Hat Connector (RHC) configuration
-  Automated reboot management
-  Comprehensive operation reporting

## Security Considerations

### CVE Management
The automation specifically addresses critical CVEs:
- **CVE-2024-6387** - OpenSSH vulnerability
- **CVE-2024-1086** - Kernel privilege escalation  
- **CVE-2023-4911** - glibc buffer overflow
- **CVE-2023-2002** - Bluetooth vulnerability
- **CVE-2023-32629** - GStreamer vulnerability

### Compliance Features
- Red Hat Insights for proactive system health
- RHC for secure cloud connectivity
- Automated security patch deployment
- Enterprise audit trail and reporting
- Compliance baseline maintenance

## Reporting

### Generated Reports
- **Repository Management**: HTML/JSON reports with sync status
- **Content Lifecycle**: Detailed environment and activation key reports
- **Host Management**: Comprehensive operation summaries
- **Update Operations**: Detailed package update tracking
- **Complete Demo**: Executive summary with phase completion

### Report Locations
All reports are generated in the `./reports/` directory with timestamps:
- `satellite_repository_management_[timestamp].html`
- `satellite_content_lifecycle_[timestamp].html`
- `satellite_host_management_[timestamp].html`
- `satellite_complete_demo_[timestamp].html`

## Troubleshooting

### Common Issues

#### Authentication Problems
```bash
# Verify Satellite credentials
curl -u admin:password https://satellite.example.com/api/status
```

#### Repository Sync Issues
```bash
# Check repository status manually
hammer repository list --organization "Default Organization"
```

#### Host Registration Problems
```bash
# Verify activation key
hammer activation-key info --name "RHEL_9_PROD_x86_64_Key"
```

### Debug Mode
Enable detailed debugging by setting:
```yaml
debug_mode: true
```

### Dry Run Mode  
Test operations without execution:
```yaml
dry_run: true
```

## Integration Examples

### With Red Hat Insights
```yaml
insights_integration:
  install_client: true
  register_hosts: true
  enable_data_collection: true
  compliance_reporting: true
```

### With Red Hat Connector
```yaml
rhc_integration:
  install_rhc: true
  configure_connection: true
  enable_remote_management: true
  cloud_integration: true
```

### Advanced CVE Targeting
```yaml
package_operations:
  cve_updates:
    enabled: true
    target_cves:
      - "CVE-2024-6387"
      - "CVE-2024-1086" 
      - "CVE-2023-4911"
    auto_reboot_if_needed: true
```

## Support

For issues, questions, or contributions:

1. Check the generated reports in `./reports/` directory
2. Enable `debug_mode: true` for detailed logging
3. Use `dry_run: true` to test configurations
4. Review Satellite server logs for API issues
5. Consult Red Hat Satellite 6.17 documentation

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Red Hat Integration

This automation is designed specifically for:
- **Red Hat Satellite 6.17**
- **Red Hat Enterprise Linux 9**
- **Ansible Automation Platform 2.5**
- **Red Hat Insights**
- **Red Hat Connector (RHC)**

For enterprise support, contact Red Hat Support with your subscription details.
