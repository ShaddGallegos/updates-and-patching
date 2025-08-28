# Enterprise Linux System Management Scripts

This directory contains professional-grade bash scripts for comprehensive Linux system management, patching, and security operations.

## Script Overview

### Core Management Scripts
- **`rhel-patch-manager.sh`** - RHEL 7-10 specialized patching with YUM/DNF intelligence
- **`linux-universal-patcher.sh`** - Universal Linux distribution patcher (RedHat, Debian, SUSE, Arch, Alpine, Gentoo)
- **`vulnerability-scanner.sh`** - Current CVE vulnerability scanning and automated remediation
- **`kpatch-manager.sh`** - Live kernel patching management for RHEL systems
- **`system-reporter.sh`** - Professional system reporting with HTML dashboards
- **`package-auditor.sh`** - Comprehensive package management and security auditing

### Orchestration
- **`automation-wrapper.sh`** - Master orchestration script with predefined workflows

## Quick Start

### Standard System Audit
```bash
# Basic system health check
sudo ./automation-wrapper.sh standard --email admin@company.com

# Generate HTML dashboard
sudo ./system-reporter.sh --format html --performance --security
```

### Security Operations
```bash
# Comprehensive security workflow
sudo ./automation-wrapper.sh security --verbose

# Vulnerability scan with auto-fix
sudo ./vulnerability-scanner.sh --scan --fix --email security@company.com

# Live kernel patching (RHEL systems)
sudo ./kpatch-manager.sh auto --verbose
```

### Package Management
```bash
# RHEL systems - intelligent YUM/DNF management
sudo ./rhel-patch-manager.sh --update --email admin@company.com

# Any Linux distribution - universal patching
sudo ./linux-universal-patcher.sh --upgrade --format html

# Package security audit
sudo ./package-auditor.sh --type security --vulnerabilities
```

## Workflow Types

### Standard Workflow
- System information collection
- Basic package audit
- Security updates detection
- Consolidated reporting

### Security Workflow 
- Current CVE vulnerability scanning
- Security patch installation
- Live kernel patching (RHEL)
- Compliance reporting

### Performance Workflow
- Resource utilization analysis
- Performance metrics collection
- Optimization recommendations

### Comprehensive Workflow
- All workflow components combined
- Multi-format professional reporting
- Email delivery with SendGrid/SMTP support

## Individual Tool Usage

### RHEL Patch Manager
```bash
# Check updates for RHEL systems
sudo ./rhel-patch-manager.sh --check-only --format html

# Apply security updates with reporting
sudo ./rhel-patch-manager.sh --security-only --email admin@company.com

# Full system update with reboot
sudo ./rhel-patch-manager.sh --update --reboot-if-needed --verbose
```

### Universal Linux Patcher
```bash
# Check what distribution is detected
./linux-universal-patcher.sh --check-only --verbose

# Upgrade all packages (dry run)
sudo ./linux-universal-patcher.sh --upgrade --dry-run

# Security-only updates for any distribution
sudo ./linux-universal-patcher.sh --security-only --format json
```

### Vulnerability Scanner
```bash
# Scan for current top 10 CVEs
sudo ./vulnerability-scanner.sh --scan --output /opt/security

# Scan and automatically fix vulnerabilities
sudo ./vulnerability-scanner.sh --scan --fix --email security@company.com

# Custom CVE list scan
sudo ./vulnerability-scanner.sh --scan --cve-list "CVE-2024-6387,CVE-2024-1086"
```

## Reporting Features

### Multi-Format Support
- **HTML**: Professional dashboards with responsive design
- **JSON**: Machine-readable for automation and APIs
- **YAML**: Configuration-friendly format
- **CSV**: Spreadsheet analysis and data processing
- **Text**: Executive summaries and email-friendly reports

### Email Integration
- **SMTP**: Traditional email server support
- **SendGrid**: Professional email delivery service
- **Templates**: Professional email templates with executive summaries

### Report Organization
```
/tmp/reports_YYYYMMDD_HHMMSS/
 consolidated-report.html # Executive dashboard
 system-info.json # Machine-readable system data
 security-scan-results.csv # Security findings for analysis
 package-audit.yaml # Package management status
 vulnerability-report.txt # Human-readable security summary
 logs/
 automation-wrapper.log # Master execution log
 security-scanner.log # Security operation details
 patching-operations.log # Patch management activity
```

## Security Features

### Current CVE Database
Scripts include detection and remediation for:
- **CVE-2024-6387**: OpenSSH regreSSHion vulnerability
- **CVE-2024-1086**: Universal local privilege escalation
- **CVE-2023-4911**: Looney Tunables local privilege escalation
- **CVE-2023-32629**: GStreamer heap buffer overflow
- **CVE-2023-2002**: Bluetooth use-after-free vulnerability
- And 5 additional current high-priority CVEs

### Automated Remediation
- Package updates for vulnerable components
- Configuration hardening
- Service restart/reload management
- Rollback capabilities for failed operations

## Enterprise Features

### Professional Integration
- **Logging**: Comprehensive audit trails with timestamps
- **Error Handling**: Graceful failure management and recovery
- **Monitoring**: Integration with enterprise monitoring systems
- **Automation**: CI/CD pipeline friendly with JSON outputs

### Multi-Distribution Support
- **RedHat Family**: RHEL, CentOS, Rocky Linux, AlmaLinux (7-10)
- **Debian Family**: Debian, Ubuntu, Mint, Pop!_OS
- **SUSE Family**: openSUSE, SLES
- **Arch Family**: Arch Linux, Manjaro, EndeavourOS
- **Alpine**: Container-optimized distributions
- **Gentoo**: Source-based distributions

### Package Manager Intelligence
- **YUM/DNF**: RHEL ecosystem with version-specific optimizations
- **APT**: Debian ecosystem with unattended-upgrades support
- **Zypper**: SUSE ecosystem with pattern management
- **Pacman**: Arch ecosystem with AUR awareness
- **APK**: Alpine ecosystem with musl compatibility
- **Portage**: Gentoo ecosystem with USE flag optimization

## Automation Scheduling

### Cron Examples
```bash
# Daily security scans at 2 AM
0 2 * * * /opt/scripts/vulnerability-scanner.sh --scan --fix >/dev/null 2>&1

# Weekly comprehensive audit on Sundays
0 1 * * 0 /opt/scripts/automation-wrapper.sh comprehensive --email admin@company.com

# Monthly package audit with cleanup
0 3 1 * * /opt/scripts/package-auditor.sh --type all --email reports@company.com
```

### Systemd Timer Examples
```bash
# Create timer for daily security workflow
sudo systemctl enable --now security-automation.timer

# Weekly comprehensive system audit
sudo systemctl enable --now comprehensive-audit.timer
```

## Configuration Options

### Environment Variables
```bash
# Email configuration
export EMAIL_SERVER="smtp.company.com"
export EMAIL_FROM="automation@company.com"
export SENDGRID_API_KEY="your-sendgrid-key"

# Report customization
export DEFAULT_REPORT_DIR="/opt/automation-reports"
export REPORT_RETENTION_DAYS="30"

# Security settings
export AUTO_REBOOT_AFTER_KERNEL_UPDATE="false"
export SECURITY_ONLY_UPDATES="true"
```

## Troubleshooting

### Common Issues
1. **Permission Errors**: Ensure scripts run with appropriate privileges (sudo)
2. **Missing Dependencies**: Install required tools (jq, mail, curl)
3. **Network Issues**: Verify repository access and email server connectivity
4. **Distribution Detection**: Check `/etc/os-release` for proper distribution identification

### Debug Mode
```bash
# Enable verbose logging for any script
./script-name.sh --verbose

# Dry run to test without changes
./automation-wrapper.sh comprehensive --dry-run --verbose
```

## Integration Examples

### Ansible Integration
```yaml
- name: Run comprehensive security audit
 command: /opt/scripts/automation-wrapper.sh security --email {{ admin_email }}
 become: yes
 register: security_audit
```

### Docker Integration
```dockerfile
COPY scripts/ /opt/automation-scripts/
RUN chmod +x /opt/automation-scripts/*.sh
CMD ["/opt/automation-scripts/automation-wrapper.sh", "comprehensive"]
```

## Version History

### v2.0.0 (Current)
- Complete rewrite for enterprise environments
- Multi-distribution support added
- Professional reporting with HTML dashboards
- Current CVE vulnerability database integration
- Email delivery with SendGrid and SMTP support
- Comprehensive error handling and logging
- Workflow orchestration capabilities

### v1.x.x (Legacy)
- Basic PowerShell and limited Linux support
- Replaced with comprehensive enterprise solution

---

**Author**: sgallego 
**Version**: 2.0.0 
**License**: Enterprise Use 
**Support**: Professional Linux system management automation

## Legacy Windows Scripts (Archived)

The following Windows PowerShell scripts are maintained for historical compatibility:

## Upgrade-PowerShell.ps1
The `Upgrade-PowerShell.ps1` script is used to upgrade the installed version of
PowerShell on a Windows host to a newer version. Ansible requires at least
version `3.0` to be install but some modules may require a newer version.
```

When setting `username` or `password`, these values are stored in plaintext in
the registry until the script is complete. Be sure to run the script below to
clear them out.

```PowerShell
# this isn't needed but is a good security practice to complete
Set-ExecutionPolicy -ExecutionPolicy Restricted -Force

$reg_winlogon_path = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty -Path $reg_winlogon_path -Name AutoAdminLogon -Value 0
Remove-ItemProperty -Path $reg_winlogon_path -Name DefaultUserName -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $reg_winlogon_path -Name DefaultPassword -ErrorAction SilentlyContinue
```

## Install-WMF3Hotfix.ps1
When running on PowerShell v3.0, there is a bug with the WinRM service that
limits the amount of memory available to WinRM. Without this hotfix installed,
Ansible will fail to execute certain commands on the Windows host.

The script will install the WinRM hotfix [KB2842230](https://support.microsoft.com/en-us/help/2842230/-out-of-memory-error-on-a-computer-that-has-a-customized-maxmemorypers)
which fixes the memory issues that occur when running over WinRM with WMF 3.0.

The script will;
1. Detect if running on PS version 3.0 and exit if it is not
2. Check if `KB2842230` is already installed and exit if it is
3. Download the hotfix from Microsoft server's based on the OS version
4. Extract the .msu file from the downloaded hotfix
5. Install the .msu silently
6. Detect if a reboot is required and prompt whether the user wants to restart

Once the install is complete, if the install process returns an exit
code of `3010`, it will ask the user whether to restart the computer now
or whether it will be done later.

To run this script, the following commands can be run:

```PowerShell
$url = "https://raw.githubusercontent.com/jborean93/ansible-windows/master/scripts/Install-WMF3Hotfix.ps1"
$file = "$env:SystemDrive\temp\Install-WMF3Hotfix.ps1"

(New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)
powershell.exe -ExecutionPolicy ByPass -File $file -Verbose
```
## ConfigureRemotingForAnsible.ps1
 Configure a Windows host for remote management with Ansible
 -----------------------------------------------------------

 This script checks the current WinRM (PS Remoting) configuration and makes
 the necessary changes to allow Ansible to connect, authenticate and
 execute PowerShell commands.

 IMPORTANT: This script uses self-signed certificates and authentication mechanisms
 that are intended for development environments and evaluation purposes only.
 Production environments and deployments that are exposed on the network should
 use CA-signed certificates and secure authentication mechanisms such as Kerberos.

 To run this script in Powershell:

 [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
 $url = "https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1"
 $file = "$env:temp\ConfigureRemotingForAnsible.ps1"

 (New-Object -TypeName System.Net.WebClient).DownloadFile($url, $file)

 powershell.exe -ExecutionPolicy ByPass -File $file

 All events are logged to the Windows EventLog, useful for unattended runs.

 Use option -Verbose in order to see the verbose output messages.

 Use option -CertValidityDays to specify how long this certificate is valid
 starting from today. So you would specify -CertValidityDays 3650 to get
 a 10-year valid certificate.

 Use option -ForceNewSSLCert if the system has been SysPreped and a new
 SSL Certificate must be forced on the WinRM Listener when re-running this
 script. This is necessary when a new SID and CN name is created.

 Use option -EnableCredSSP to enable CredSSP as an authentication option.

 Use option -DisableBasicAuth to disable basic authentication.

 Use option -SkipNetworkProfileCheck to skip the network profile check.
 Without specifying this the script will only run if the device's interfaces
 are in DOMAIN or PRIVATE zones. Provide this switch if you want to enable
 WinRM on a device with an interface in PUBLIC zone.

 Use option -SubjectName to specify the CN name of the certificate. This
 defaults to the system's hostname and generally should not be specified.
 
 
 
