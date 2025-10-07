# Maintenance Tool Guide

## Overview

The `maintenance.py` script is a comprehensive maintenance tool for the LVM Auto-Extension project. It provides an interactive menu-driven interface for managing project components, roles, playbooks, and scripts.

## Prerequisites

- Python 3.6 or higher
- Linux environment (RHEL, CentOS, Ubuntu, etc.)
- Write access to the project directory

## Quick Start

```bash
# Make the script executable (if not already)
chmod +x maintenance.py

# Run the maintenance tool
./maintenance.py
```

## Main Menu Options

### 1. Setup & Initialization
Create and validate project structure, roles, and configuration files.

**Sub-options:**
- **Initial project setup** - Creates inventory, group_vars, and .env.example
- **Check roles** - Validates existing roles structure
- **Create missing roles** - Creates any missing role directories
- **Recreate all roles** - Rebuilds all role structures (with backup)
- **Create missing playbooks** - Generates ServiceNow and alert playbooks
- **Create missing scripts** - Creates utility scripts (EDA, webhook testing, etc.)
- **Create all missing components** - One-click setup of all components

### 2. Consolidation
Organize and restructure project files.

**Sub-options:**
- **Reorganize playbooks** - Moves playbooks to playbooks/ directory
- **Organize scripts** - Creates organized script directories
- **Organize tests** - Sets up test directory structure
- **Full consolidation** - Runs all consolidation tasks

### 3. Analysis & Reporting
Analyze project structure and generate reports.

**Sub-options:**
- **Analyze obsolete** - Find backup files, swap files, and cache directories
- **Analyze YAML** - Check essential playbooks and role completeness
- **Generate report** - Create comprehensive project analysis report

### 4. Cleanup & Maintenance
Clean up temporary files and view project information.

**Sub-options:**
- **Clean obsolete** - Remove backup and temporary files (with backup)
- **Clean reports** - Delete old analysis reports
- **View structure** - Display project tree structure
- **View backups** - List recent backup directories

### 8. Cleanup base scripts
Remove .sh scripts from project root (moves them to backup).

### 9. Quick start
Display quick reference guide for common tasks.

## Components Created

### Roles
The tool creates and manages these roles:
- `servicenow_ticket_management` - ServiceNow API integration
- `lvm_smart_extend` - Intelligent LVM extension
- `lvm_system_inspection` - System LVM analysis
- `lvm_extension_orchestrator` - Extension workflow coordination
- `disk_usage_alerting` - Disk usage monitoring and alerts

### Playbooks
Generates these playbooks in the `playbooks/` directory:
- `servicenow_create_ticket.yml` - Create incident tickets
- `servicenow_update_ticket.yml` - Update existing tickets
- `servicenow_close_ticket.yml` - Close resolved tickets
- `servicenow_create_manual_ticket.yml` - Interactive ticket creation
- `non_lvm_alert.yml` - Alert for non-LVM filesystems
- `unsupported_os_alert.yml` - OS compatibility warnings

### Utility Scripts
Creates these scripts in the project root:
- `start_eda.sh` - Start Event-Driven Ansible controller
- `test_webhook.sh` - Test webhook functionality
- `test_email_notifications.sh` - Test email alert system
- `setup_monitoring_cron.sh` - Install disk monitoring cron job

## Usage Examples

### First-Time Setup
```bash
./maintenance.py
# Select: 1 (Setup & Initialization)
# Select: 7 (Create all missing components)
# Follow prompts
```

### Check Project Health
```bash
./maintenance.py
# Select: 3 (Analysis & Reporting)
# Select: 2 (Analyze YAML)
```

### Clean Up Project
```bash
./maintenance.py
# Select: 4 (Cleanup & Maintenance)
# Select: 1 (Clean obsolete)
```

### Generate Project Report
```bash
./maintenance.py
# Select: 3 (Analysis & Reporting)
# Select: 3 (Generate report)
```

## Backup System

All destructive operations create timestamped backups in the `backups/` directory:
- Format: `backups/{operation_name}_{YYYYMMDD_HHMMSS}/`
- Can be reviewed using option 4.4 (View backups)
- Backups are never automatically deleted

## Configuration Files Created

### .env.example
Template for environment variables:
```bash
export SNOW_INSTANCE=dev12345
export SNOW_USER=admin
export SNOW_PASS=password
export NUTANIX_HOST=nutanix.example.com
export NUTANIX_USER=admin
export NUTANIX_PASS=password
```

### inventory/hosts
Ansible inventory template with nutanix_hosts group.

### inventory/group_vars/all.yml
Global variables for ServiceNow and Nutanix integration.

## Color Coding

The script uses color-coded output for better readability:
- 🔴 **Red** - Errors, missing items, destructive operations
- 🟢 **Green** - Success, completed items, safe operations
- 🟡 **Yellow** - Warnings, pending items, requires attention
- 🔵 **Blue** - Information, file paths, references
- 🟣 **Magenta** - Menu options, headers
- 🔷 **Cyan** - Sub-headers, section dividers

## Safety Features

1. **Confirmation prompts** - Destructive operations require confirmation
2. **Automatic backups** - All changes create timestamped backups
3. **Non-destructive defaults** - Won't overwrite existing files
4. **Dry-run support** - Preview changes before applying
5. **Detailed logging** - All operations are logged with timestamps

## Troubleshooting

### Script won't run
```bash
# Ensure Python 3 is available
python3 --version

# Make executable
chmod +x maintenance.py

# Run with python3 explicitly
python3 maintenance.py
```

### Permission denied
```bash
# Some operations require elevated privileges
sudo ./maintenance.py
```

### Missing modules
```bash
# The script uses only Python standard library
# No additional packages required
```

## Advanced Usage

### Direct Script Execution
The script can be run non-interactively by piping choices:
```bash
# Example: Run option 9 (Quick start) then exit
echo -e "9\n0" | ./maintenance.py
```

### Backup Recovery
To restore from a backup:
```bash
# List backups
ls -lh backups/

# Restore from backup
cp -r backups/backup_name_TIMESTAMP/* ./
```

## Best Practices

1. **Run initial setup first** - Option 1.1 before other operations
2. **Check roles regularly** - Option 1.2 to validate structure
3. **Generate reports** - Document project state before major changes
4. **Review backups** - Check backup sizes and locations periodically
5. **Clean obsolete files** - Remove temporary files after validating changes

## Support

For issues or questions:
1. Check the Quick Start guide (Option 9)
2. Review generated reports for project analysis
3. Consult backup directories for recovery options
4. Refer to project documentation in README.md

## Version

Current version: 1.0.0
Compatible with: LVM Auto-Extension project
