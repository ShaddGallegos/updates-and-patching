# Updates and Patching Dependencies

This document explains the dependency files for the updates-and-patching project.

## Files Overview

### bindep.txt
System packages required for building execution environments and running Ansible collections:

- **Kerberos libraries**: Required for Windows domain authentication
- **SSL/TLS libraries**: Essential for secure communications with Red Hat Satellite
- **Development headers**: Needed for compiling Python packages
- **Core utilities**: Standard tools for system operations

### requirements.txt
Python packages required for full functionality:

- **Windows Management**: pywinrm, requests-kerberos for Windows host operations
- **Red Hat Satellite**: requests, urllib3 for API communications
- **Report Generation**: Jinja2, lxml for HTML/XML report creation
- **Security**: cryptography, paramiko for secure operations
- **Notifications**: sendgrid for email delivery

### execution-environment.yml
Example configuration showing how to use these dependencies in an Execution Environment build.

## Usage

### For Execution Environment Builds
```bash
ansible-builder build --container-runtime podman \
  --file execution-environment.yml \
  --tag updates-patching-ee:latest
```

### For Direct Installation
```bash
# Install system dependencies (RHEL/CentOS)
sudo dnf install $(grep -v '^#' bindep.txt | grep platform:rpm | awk '{print $1}')

# Install Python packages
pip install -r requirements.txt
```

## Notes

- All dependencies are pinned to minimum versions for stability
- System packages are specified per platform (RPM/DEB) 
- Python packages include security and enterprise features
- Dependencies support both Linux and Windows target hosts

## Enterprise Features Supported

- Red Hat Satellite 6.17 API integration
- Windows Server 2022 / Windows 11 management
- Professional HTML reporting
- Email notifications and alerting
- Security-first vulnerability management
- CVE-specific update targeting
