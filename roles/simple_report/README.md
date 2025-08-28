# simple_report

A modern, professional system reporting role for RHEL 7, 8, 9, and 10 that generates comprehensive HTML, PDF, CSV, and JSON reports with executive summaries and web-based dashboards.

## Description

This role provides enterprise-grade system reporting for Red Hat Enterprise Linux infrastructure. It collects comprehensive system information, analyzes security posture, tracks update compliance, and generates professional reports suitable for technical teams and management stakeholders.

## Features

### 🎯 **Multi-Format Reporting**
- **Professional HTML Reports**: Interactive, responsive web reports with charts and dashboards
- **Executive Summaries**: High-level overviews for management stakeholders
- **CSV Data Export**: Raw data for business intelligence and spreadsheet analysis
- **JSON Data Export**: Machine-readable format for integration with monitoring tools
- **PDF Generation**: Print-ready reports using wkhtmltopdf (when available)

### 🔍 **Comprehensive System Analysis**
- **System Information**: Hardware, OS version, virtualization, uptime
- **Security Assessment**: Available security updates, patch compliance status
- **Update Analysis**: Comprehensive package update tracking (security, bugfix, enhancement)
- **Resource Monitoring**: Memory usage, CPU load, disk utilization
- **Service Status**: Critical system service health checks
- **Subscription Status**: Red Hat subscription and entitlement verification

### 🎨 **Professional Presentation**
- **Modern UI Design**: Responsive, mobile-friendly interface
- **Interactive Charts**: Visual representation of system metrics
- **Status Indicators**: Color-coded health and security status
- **Executive Dashboard**: High-level KPIs and recommendations
- **Web Server Integration**: Built-in HTTP server for report viewing

### 🔧 **Advanced Configuration**
- **Flexible Output**: Customizable report formats and locations
- **Timestamped Reports**: Automatic report organization with timestamps
- **Cleanup Management**: Automatic cleanup of old reports
- **Performance Monitoring**: Configurable thresholds for warnings

## Requirements

- RHEL 7, 8, 9, or 10
- Ansible 2.9+
- Python 3 (for web server functionality)
- wkhtmltopdf (optional, for PDF generation)
- Active Red Hat subscription (for subscription status reporting)

## Role Variables

### Core Report Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `report_title` | `"RHEL System Status Report"` | Main report title |
| `report_company` | `"Red Hat Enterprise Linux Infrastructure"` | Company/organization name |
| `report_output_dir` | `"/tmp/reports_{{ ansible_date_time.epoch }}"` | Output directory path |
| `report_filename_prefix` | `"rhel_system_report"` | Filename prefix for generated reports |

### Output Format Control

| Variable | Default | Description |
|----------|---------|-------------|
| `report_output_formats` | `["html", "csv", "json"]` | List of formats to generate |
| `report_include_pdf` | `true` | Generate PDF version (requires wkhtmltopdf) |
| `report_html_theme` | `"professional"` | HTML report styling theme |
| `report_html_responsive` | `true` | Enable responsive design |

### Content Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `report_include_system_info` | `true` | Include basic system information |
| `report_include_updates` | `true` | Include update analysis |
| `report_include_security` | `true` | Include security assessment |
| `report_include_packages` | `true` | Include package information |
| `report_include_services` | `true` | Include service status |
| `report_include_storage` | `true` | Include storage information |
| `report_include_network` | `true` | Include network configuration |

### Analysis Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `report_analyze_security_updates` | `true` | Analyze security updates |
| `report_analyze_bugfix_updates` | `true` | Analyze bugfix updates |
| `report_analyze_enhancement_updates` | `true` | Analyze enhancement updates |
| `report_show_update_details` | `true` | Show detailed update information |

### Warning Thresholds

| Variable | Default | Description |
|----------|---------|-------------|
| `disk_usage_warning_threshold` | `85` | Disk usage warning threshold (%) |
| `memory_usage_warning_threshold` | `90` | Memory usage warning threshold (%) |
| `cpu_load_warning_threshold` | `80` | CPU load warning threshold (%) |

### Web Server Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `report_enable_web_server` | `false` | Start built-in web server |
| `report_web_server_port` | `8080` | Web server port |
| `report_web_server_host` | `"0.0.0.0"` | Web server bind address |

### Maintenance Settings

| Variable | Default | Description |
|----------|---------|-------------|
| `report_cleanup_old_reports` | `true` | Clean up old report directories |
| `report_keep_reports_days` | `30` | Days to keep old reports |

## Dependencies

None.

## Example Playbooks

### Basic System Report

```yaml
---
- hosts: rhel_servers
  become: true
  roles:
    - simple_report
```

### Comprehensive Report with Web Server

```yaml
---
- hosts: rhel_servers
  become: true
  roles:
    - role: simple_report
      vars:
        report_title: "Production RHEL Infrastructure Report"
        report_company: "ACME Corporation"
        report_enable_web_server: true
        report_web_server_port: 8080
        report_output_formats:
          - html
          - pdf
          - csv
          - json
```

### Executive Summary Focus

```yaml
---
- hosts: rhel_servers
  become: true
  roles:
    - role: simple_report
      vars:
        report_title: "Monthly Security Assessment"
        report_analyze_security_updates: true
        report_show_update_details: true
        report_include_pdf: true
        disk_usage_warning_threshold: 80
        memory_usage_warning_threshold: 85
```

### Minimal Report for Automation

```yaml
---
- hosts: rhel_servers
  become: true
  roles:
    - role: simple_report
      vars:
        report_output_formats:
          - json
          - csv
        report_include_pdf: false
        report_enable_web_server: false
        report_cleanup_old_reports: true
        report_keep_reports_days: 7
```

## Generated Reports

The role generates several types of reports:

### 1. **Main Index (index.html)**
- Navigation hub for all reports
- Quick statistics overview
- Links to detailed reports

### 2. **Executive Summary (executive_summary_YYYY-MM-DD.html)**
- High-level infrastructure overview
- Key performance indicators (KPIs)
- Risk assessment and recommendations
- Management-focused content

### 3. **Detailed System Report (rhel_system_report_YYYY-MM-DD.html)**
- Comprehensive system analysis
- Individual host details
- Interactive charts and graphs
- Technical details for system administrators

### 4. **Data Exports**
- **CSV**: Raw data for spreadsheet analysis
- **JSON**: Machine-readable format for integration
- **PDF**: Print-ready professional report

### 5. **Report Manifest (REPORT_MANIFEST.txt)**
- Complete inventory of generated files
- Report metadata and statistics
- Generation timestamps

## Report Structure

```
/tmp/reports_<timestamp>/
├── index.html                           # Main navigation
├── executive_summary_YYYY-MM-DD.html    # Executive overview
├── rhel_system_report_YYYY-MM-DD.html   # Detailed report
├── rhel_system_report_YYYY-MM-DD.csv    # Data export
├── rhel_system_report_YYYY-MM-DD.json   # Machine data
├── rhel_system_report_YYYY-MM-DD.pdf    # PDF report
├── REPORT_MANIFEST.txt                  # File inventory
└── .report_metadata.json                # Integration metadata
```

## Web Server Access

When `report_enable_web_server` is enabled, you can access reports at:

```
http://<ansible_controller_ip>:8080/
```

The web server serves the report directory and provides immediate access to all generated reports.

## Integration

### Business Intelligence Tools

The JSON and CSV exports are designed for integration with:
- Grafana dashboards
- Splunk/ELK stack
- Business intelligence platforms
- Custom monitoring solutions

### Automation Workflows

The role creates `.report_metadata.json` with structured information for:
- CI/CD pipeline integration
- Automated alerting based on thresholds
- Report archival automation
- Follow-up remediation workflows

## Version-Specific Behavior

### RHEL 7
- Uses `yum` for package analysis
- Compatible with older Python versions
- Graceful degradation for missing features

### RHEL 8+
- Uses `dnf` for enhanced package analysis
- Better update categorization
- Enhanced service status reporting
- Improved subscription management information

## Performance Considerations

- Report generation typically takes 30-60 seconds per host
- Memory usage scales with number of hosts (approximately 50MB per 100 hosts)
- PDF generation adds 10-15 seconds per report
- Web server uses minimal resources (single-threaded Python HTTP server)

## Troubleshooting

### PDF Generation Issues
```bash
# Install wkhtmltopdf on RHEL 8+
sudo dnf install wkhtmltopdf

# For RHEL 7
sudo yum install wkhtmltopdf
```

### Web Server Port Conflicts
```yaml
# Change web server port
report_web_server_port: 9080
```

### Permission Issues
```bash
# Ensure output directory is writable
chmod 755 /tmp/reports_*
```

## License

Apache-2.0

## Author Information

Created by Santiago Gallego  
Enhanced for RHEL 7-10 support with modern reporting capabilities

## Contributing

This role is part of a comprehensive RHEL management suite. For issues, feature requests, or contributions, please follow the project's contribution guidelines.
