#!/bin/bash
# rhel-patch-manager.sh
# Enterprise-grade RHEL 7-10 patching script with comprehensive reporting
# Compatible with: RHEL 7, 8, 9, 10, CentOS, Rocky Linux, AlmaLinux
# Author: sgallego
# Version: 2.0.0
# Date: 2024-08-27

set -euo pipefail

# Script configuration
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="rhel-patch-manager"
LOG_LEVEL="INFO"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  REPORT_DIR="/tmp/reports_${TIMESTAMP}"
  DRY_RUN=false
  SECURITY_ONLY=false
  ALLOW_REBOOT=false
  FORCE_MODE=false

# Color codes for output
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
  BOLD='\033[1m'

# Logging functions
  log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
      echo -e "[${timestamp}] [${level}] ${message}" | tee -a "${REPORT_DIR}/patch-${TIMESTAMP}.log"
    }

    log_info() {
      log "INFO" "$*"
      echo -e "${BLUE}[INFO]${NC} $*"
    }

    log_warn() {
      log "WARN" "$*"
      echo -e "${YELLOW}[WARN]${NC} $*"
    }

    log_error() {
      log "ERROR" "$*"
      echo -e "${RED}[ERROR]${NC} $*"
    }

    log_success() {
      log "SUCCESS" "$*"
      echo -e "${GREEN}[SUCCESS]${NC} $*"
    }

# Help function
    show_help() {
      cat << EOF
      ${BOLD}RHEL Patch Manager v${SCRIPT_VERSION}${NC}
      Enterprise-grade RHEL 7-10 patching with comprehensive reporting

      ${BOLD}USAGE:${NC}
      $0 [OPTIONS]

      ${BOLD}OPTIONS:${NC}
      -h, --help Show this help message
      -d, --dry-run Preview updates without applying
      -s, --security-only Apply only security updates
      -r, --allow-reboot Allow automatic reboot if required
        -f, --force Force patching (skip validation)
          -v, --verbose Enable verbose output
          -o, --output DIR Custom report directory
          --email EMAIL Email report to specified address
          --sendgrid-key KEY SendGrid API key for email delivery
            --slack-webhook URL Slack webhook for notifications

              ${BOLD}EXAMPLES:${NC}
# Security-only updates with dry run
              $0 --security-only --dry-run

# Full update with reboot and email report
              $0 --allow-reboot --email admin@company.com

# Production patching with SendGrid notification
              $0 --security-only --sendgrid-key SG.xxx --slack-webhook https://hooks.slack.com/...

              ${BOLD}REPORT LOCATIONS:${NC}
              Default: /tmp/reports_YYYYMMDD_HHMMSS/
              Logs: patch-YYYYMMDD_HHMMSS.log
              Reports: rhel-patch-report-YYYYMMDD_HHMMSS.[html|json|yaml]

              EOF
            }

# Detect RHEL version and package manager
            detect_rhel_environment() {
              log_info "Detecting RHEL environment..."

              if [[ ! -f /etc/redhat-release ]]; then
                log_error "This script requires a RHEL-compatible system"
                exit 1
              fi

# Extract version information
              RHEL_VERSION=$(rpm -q --queryformat '%{VERSION}' centos-release 2>/dev/null || \
              rpm -q --queryformat '%{VERSION}' rocky-release 2>/dev/null || \
              rpm -q --queryformat '%{VERSION}' almalinux-release 2>/dev/null || \
              rpm -q --queryformat '%{VERSION}' redhat-release-server 2>/dev/null || \
              grep -oP '(?<=release )[0-9]+' /etc/redhat-release)

                RHEL_MAJOR_VERSION=${RHEL_VERSION%%.*}
                DISTRIBUTION=$(cat /etc/redhat-release | awk '{print $1}')

# Determine package manager
                  if [[ $RHEL_MAJOR_VERSION -ge 8 ]]; then
                    PKG_MANAGER="dnf"
                  else
                    PKG_MANAGER="yum"
                  fi

# Validate supported versions
                  case $RHEL_MAJOR_VERSION in
                  7|8|9|10)
                    log_success "Detected: $DISTRIBUTION $RHEL_VERSION (Package Manager: $PKG_MANAGER)"
                    ;;
                    *)
                      log_error "Unsupported RHEL version: $RHEL_MAJOR_VERSION"
                      exit 1
                      ;;
                    esac

# Export environment variables
                    export RHEL_VERSION RHEL_MAJOR_VERSION DISTRIBUTION PKG_MANAGER
                  }

# System validation
                  validate_system() {
                    log_info "Performing system validation..."

# Check if running as root
                    if [[ $EUID -ne 0 ]]; then
                      log_error "This script must be run as root"
                      exit 1
                    fi

# Check disk space
                    local disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
                      if [[ $disk_usage -gt 85 ]]; then
                        log_warn "Disk usage is ${disk_usage}% - consider cleaning up before patching"
                        if [[ $FORCE_MODE == false ]]; then
                          log_error "Disk space validation failed. Use --force to override"
                          exit 1
                        fi
                      fi

# Check package manager lock
                      if [[ $PKG_MANAGER == "yum" || $PKG_MANAGER == "dnf" ]]; then
                        if pgrep -f "$PKG_MANAGER" > /dev/null; then
                          log_error "Package manager ($PKG_MANAGER) is currently running"
                          exit 1
                        fi
                      fi

# Check subscription status (RHEL only)
                      if [[ $DISTRIBUTION == "Red" ]]; then
                        if ! subscription-manager status &>/dev/null; then
                          log_warn "Subscription manager not properly configured"
                        fi
                      fi

                      log_success "System validation completed"
                    }

# Check available updates
                    check_updates() {
                      log_info "Checking for available updates..."

                        mkdir -p "$REPORT_DIR"

# Update package cache
                        log_info "Updating package cache..."
                        case $PKG_MANAGER in
                        yum)
                          yum clean all &>/dev/null
                          yum makecache &>/dev/null
                          ;;
                          dnf)
                            dnf clean all &>/dev/null
                            dnf makecache &>/dev/null
                            ;;
                          esac

# Check for updates
                          local update_check_file="${REPORT_DIR}/available_updates.txt"

                          if [[ $SECURITY_ONLY == true ]]; then
                            log_info "Checking for security updates only..."
                              case $PKG_MANAGER in
                              yum)
                                yum --security check-update > "$update_check_file" 2>/dev/null || true
                                ;;
                                dnf)
                                  dnf updateinfo list sec > "$update_check_file" 2>/dev/null || true
                                  ;;
                                esac
                              else
                                log_info "Checking for all available updates..."
                                  $PKG_MANAGER check-update > "$update_check_file" 2>/dev/null || true
                                fi

# Count updates
                                UPDATE_COUNT=$(grep -c "^[[:alpha:]]" "$update_check_file" 2>/dev/null || echo "0")
                                  SECURITY_COUNT=0

                                  if [[ $PKG_MANAGER == "dnf" ]]; then
                                    SECURITY_COUNT=$(dnf updateinfo list sec 2>/dev/null | grep -c "^" || echo "0")
                                    elif [[ $PKG_MANAGER == "yum" ]]; then
                                      SECURITY_COUNT=$(yum --security check-update 2>/dev/null | grep -c "^[[:alpha:]]" || echo "0")
                                      fi

                                      log_info "Found $UPDATE_COUNT total updates, $SECURITY_COUNT security updates"

                                      export UPDATE_COUNT SECURITY_COUNT
                                    }

# Apply updates
                                    apply_updates() {
                                      if [[ $UPDATE_COUNT -eq 0 ]]; then
                                        log_success "System is up to date - no updates required"
                                        return 0
                                      fi

                                      log_info "Applying updates..."

                                      if [[ $DRY_RUN == true ]]; then
                                        log_info "DRY RUN: Would apply $UPDATE_COUNT updates"
                                        return 0
                                      fi

# Backup critical configuration files
                                      backup_configs

# Apply updates based on type
                                      local update_cmd=""
                                      if [[ $SECURITY_ONLY == true ]]; then
                                        case $PKG_MANAGER in
                                        yum)
                                          update_cmd="yum update -y --security"
                                          ;;
                                          dnf)
                                            update_cmd="dnf update -y --security"
                                            ;;
                                          esac
                                          log_info "Applying security updates only..."
                                        else
                                          update_cmd="$PKG_MANAGER update -y"
                                          log_info "Applying all available updates..."
                                        fi

# Execute update command
                                        local start_time=$(date +%s)
                                          if $update_cmd 2>&1 | tee -a "${REPORT_DIR}/patch-output-${TIMESTAMP}.log"; then
                                            local end_time=$(date +%s)
                                              local duration=$((end_time - start_time))
                                                log_success "Updates completed successfully in ${duration} seconds"

# Check if reboot is required
                                                check_reboot_required
                                              else
                                                log_error "Update process failed - check logs for details"
                                                  exit 1
                                                fi
                                              }

# Check if reboot is required
                                              check_reboot_required() {
                                                log_info "Checking if reboot is required..."

                                                  REBOOT_REQUIRED=false

# Check for kernel updates
                                                  case $PKG_MANAGER in
                                                  yum)
                                                    if yum history list 2>/dev/null | grep -q "kernel"; then
                                                      REBOOT_REQUIRED=true
                                                    fi
                                                    ;;
                                                    dnf)
                                                      if dnf history list 2>/dev/null | grep -q "kernel"; then
                                                        REBOOT_REQUIRED=true
                                                      fi
                                                      ;;
                                                    esac

# Check for systemd updates
                                                    if [[ $PKG_MANAGER == "dnf" ]] && dnf history list 2>/dev/null | grep -q "systemd"; then
                                                      REBOOT_REQUIRED=true
                                                    fi

                                                    if [[ $REBOOT_REQUIRED == true ]]; then
                                                      log_warn "System reboot is required"

                                                      if [[ $ALLOW_REBOOT == true ]]; then
                                                        log_info "Scheduling reboot in 60 seconds..."
                                                        shutdown -r +1 "System reboot required after patching - initiated by $SCRIPT_NAME"
                                                      else
                                                        log_warn "Reboot required but not allowed by configuration"
                                                      fi
                                                    else
                                                      log_success "No reboot required"
                                                    fi

                                                    export REBOOT_REQUIRED
                                                  }

# Backup critical configuration files
                                                  backup_configs() {
                                                    log_info "Backing up critical configuration files..."

                                                    local backup_dir="${REPORT_DIR}/config_backup_${TIMESTAMP}"
                                                    mkdir -p "$backup_dir"

# List of critical files to backup
                                                    local critical_files=(
                                                    "/etc/fstab"
                                                    "/etc/hosts"
                                                    "/etc/resolv.conf"
                                                    "/etc/ssh/sshd_config"
                                                    "/etc/yum.conf"
                                                    "/etc/dnf/dnf.conf"
                                                    )

                                                      for file in "${critical_files[@]}"; do
                                                        if [[ -f $file ]]; then
                                                          cp "$file" "$backup_dir/" 2>/dev/null || true
                                                          log_info "Backed up: $file"
                                                        fi
                                                      done

                                                      log_success "Configuration backup completed"
                                                    }

# Generate comprehensive reports
                                                    generate_reports() {
                                                      log_info "Generating comprehensive reports..."

                                                      local hostname=$(hostname -f)
                                                        local ip_address=$(hostname -I | awk '{print $1}')
                                                          local kernel_version=$(uname -r)
                                                            local uptime=$(uptime -p)
                                                              local report_time=$(date -Iseconds)

# Generate JSON report
                                                                cat > "${REPORT_DIR}/rhel-patch-report-${hostname}-${TIMESTAMP}.json" << EOF
                                                                {
                                                                  "metadata": {
                                                                    "script_name": "${SCRIPT_NAME}",
                                                                    "version": "${SCRIPT_VERSION}",
                                                                    "hostname": "${hostname}",
                                                                    "ip_address": "${ip_address}",
                                                                    "timestamp": "${report_time}",
                                                                    "report_id": "${hostname}-${TIMESTAMP}"
                                                                  },
                                                                  "system_info": {
                                                                    "distribution": "${DISTRIBUTION}",
                                                                    "rhel_version": "${RHEL_VERSION}",
                                                                    "rhel_major_version": "${RHEL_MAJOR_VERSION}",
                                                                    "kernel_version": "${kernel_version}",
                                                                    "package_manager": "${PKG_MANAGER}",
                                                                    "uptime": "${uptime}",
                                                                    "architecture": "$(uname -m)"
                                                                  },
                                                                  "patch_summary": {
                                                                    "total_updates_available": ${UPDATE_COUNT},
                                                                    "security_updates_count": ${SECURITY_COUNT},
                                                                    "patch_type": "$([ $SECURITY_ONLY == true ] && echo "security" || echo "full")",
                                                                    "dry_run": ${DRY_RUN},
                                                                    "reboot_required": ${REBOOT_REQUIRED},
                                                                    "reboot_allowed": ${ALLOW_REBOOT},
                                                                    "compliance_status": "$([ $UPDATE_COUNT -eq 0 ] && echo "compliant" || echo "updates_available")"
                                                                  },
                                                                  "execution_info": {
                                                                    "start_time": "$(cat ${REPORT_DIR}/start_time.tmp 2>/dev/null || echo $report_time)",
                                                                    "end_time": "${report_time}",
                                                                    "duration_seconds": $(( $(date +%s) - $(cat ${REPORT_DIR}/start_timestamp.tmp 2>/dev/null || echo $(date +%s)) )),
                                                                    "user": "${SUDO_USER:-$(whoami)}",
                                                                    "script_path": "$0"
                                                                  }
                                                                }
                                                                EOF

# Generate YAML report
                                                                cat > "${REPORT_DIR}/rhel-patch-report-${hostname}-${TIMESTAMP}.yaml" << EOF
                                                                ---
                                                                metadata:
                                                                script_name: "${SCRIPT_NAME}"
                                                                version: "${SCRIPT_VERSION}"
                                                                hostname: "${hostname}"
                                                                ip_address: "${ip_address}"
                                                                timestamp: "${report_time}"
                                                                report_id: "${hostname}-${TIMESTAMP}"

                                                                system_info:
                                                                distribution: "${DISTRIBUTION}"
                                                                rhel_version: "${RHEL_VERSION}"
                                                                rhel_major_version: "${RHEL_MAJOR_VERSION}"
                                                                kernel_version: "${kernel_version}"
                                                                package_manager: "${PKG_MANAGER}"
                                                                uptime: "${uptime}"
                                                                architecture: "$(uname -m)"

                                                                patch_summary:
                                                                total_updates_available: ${UPDATE_COUNT}
                                                                security_updates_count: ${SECURITY_COUNT}
                                                                patch_type: "$([ $SECURITY_ONLY == true ] && echo "security" || echo "full")"
                                                                dry_run: ${DRY_RUN}
                                                                reboot_required: ${REBOOT_REQUIRED}
                                                                reboot_allowed: ${ALLOW_REBOOT}
                                                                compliance_status: "$([ $UPDATE_COUNT -eq 0 ] && echo "compliant" || echo "updates_available")"

                                                                execution_info:
                                                                start_time: "$(cat ${REPORT_DIR}/start_time.tmp 2>/dev/null || echo $report_time)"
                                                                end_time: "${report_time}"
                                                                duration_seconds: $(( $(date +%s) - $(cat ${REPORT_DIR}/start_timestamp.tmp 2>/dev/null || echo $(date +%s)) ))
                                                                  user: "${SUDO_USER:-$(whoami)}"
                                                                  script_path: "$0"
                                                                  EOF

# Generate HTML report
                                                                  generate_html_report

                                                                  log_success "Reports generated in: ${REPORT_DIR}"
                                                                }

# Generate HTML report
                                                                generate_html_report() {
                                                                  local hostname=$(hostname -f)
                                                                    local report_file="${REPORT_DIR}/rhel-patch-report-${hostname}-${TIMESTAMP}.html"

                                                                    cat > "$report_file" << EOF
                                                                    <!DOCTYPE html>
                                                                    <html lang="en">
                                                                    <head>
                                                                    <meta charset="UTF-8">
                                                                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                                                                    <title>RHEL Patch Report - ${hostname}</title>
                                                                    <style>
                                                                    body { font-family: 'Segoe UI', sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
                                                                      .container { max-width: 1000px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                                                                        .header { background: linear-gradient(135deg, #1e3a8a, #3b82f6); color: white; padding: 30px; text-align: center; }
                                                                          .header h1 { margin: 0; font-size: 2.5rem; }
                                                                            .summary { display: flex; padding: 30px; gap: 20px; background: #f8fafc; }
                                                                              .card { flex: 1; background: white; border-radius: 8px; padding: 20px; text-align: center; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
                                                                                .card-value { font-size: 2rem; font-weight: bold; margin-bottom: 5px; }
                                                                                  .compliant { color: #059669; }
                                                                                    .updates { color: #dc2626; }
                                                                                      .security { color: #ea580c; }
                                                                                        .content { padding: 30px; }
                                                                                          .status-badge { padding: 4px 12px; border-radius: 20px; font-size: 0.8rem; font-weight: 600; }
                                                                                            .status-compliant { background: #dcfce7; color: #166534; }
                                                                                              .status-updates { background: #fee2e2; color: #991b1b; }
                                                                                                </style>
                                                                                                </head>
                                                                                                <body>
                                                                                                <div class="container">
                                                                                                <div class="header">
                                                                                                <h1>RHEL Patch Report</h1>
                                                                                                <p>${hostname} - $(date)</p>
                                                                                                </div>
                                                                                                <div class="summary">
                                                                                                <div class="card">
                                                                                                <div class="card-value $([ $UPDATE_COUNT -eq 0 ] && echo "compliant" || echo "updates")">${UPDATE_COUNT}</div>
                                                                                                <div>Total Updates</div>
                                                                                                </div>
                                                                                                <div class="card">
                                                                                                <div class="card-value security">${SECURITY_COUNT}</div>
                                                                                                <div>Security Updates</div>
                                                                                                </div>
                                                                                                <div class="card">
                                                                                                <div class="card-value">$([ $REBOOT_REQUIRED == true ] && echo "YES" || echo "NO")</div>
                                                                                                <div>Reboot Required</div>
                                                                                                </div>
                                                                                                </div>
                                                                                                <div class="content">
                                                                                                <h2>System Information</h2>
                                                                                                <table>
                                                                                                <tr><td><strong>Distribution:</strong></td><td>${DISTRIBUTION} ${RHEL_VERSION}</td></tr>
                                                                                                <tr><td><strong>Kernel:</strong></td><td>$(uname -r)</td></tr>
                                                                                                <tr><td><strong>Package Manager:</strong></td><td>${PKG_MANAGER}</td></tr>
                                                                                                <tr><td><strong>Status:</strong></td><td>$([ $UPDATE_COUNT -eq 0 ] && echo '<span class="status-badge status-compliant"> Compliant</span>' || echo '<span class="status-badge status-updates"> Updates Available</span>')</td></tr>
                                                                                                </table>

                                                                                                <h2>Available Updates</h2>
                                                                                                $([ $UPDATE_COUNT -eq 0 ] && echo "<p>No updates available - system is compliant</p>" || echo "<pre>$(cat ${REPORT_DIR}/available_updates.txt)</pre>")
                                                                                                  </div>
                                                                                                  </div>
                                                                                                  </body>
                                                                                                  </html>
                                                                                                  EOF
                                                                                                }

# Send email report
                                                                                                send_email_report() {
                                                                                                  local email_address=$1
                                                                                                  local hostname=$(hostname -f)

                                                                                                    if command -v mail >/dev/null 2>&1; then
                                                                                                      log_info "Sending report via email to: $email_address"

                                                                                                      local subject="[RHEL Patch Report] ${hostname} - $(date +%Y-%m-%d)"
                                                                                                      local body="RHEL patch report attached for ${hostname}. See attached files for details."

                                                                                                        echo "$body" | mail -s "$subject" -A "${REPORT_DIR}/rhel-patch-report-${hostname}-${TIMESTAMP}.json" "$email_address"

                                                                                                        log_success "Email report sent to: $email_address"
                                                                                                      else
                                                                                                        log_warn "Mail command not available - install mailx package for email functionality"
                                                                                                        fi
                                                                                                      }

# Send SendGrid report
                                                                                                      send_sendgrid_report() {
                                                                                                        local api_key=$1
                                                                                                        local hostname=$(hostname -f)
                                                                                                          local report_content=$(cat "${REPORT_DIR}/rhel-patch-report-${hostname}-${TIMESTAMP}.json")

                                                                                                            log_info "Sending report via SendGrid..."

                                                                                                            local subject="[RHEL Patch Report] ${hostname} - $(date +%Y-%m-%d)"
                                                                                                            local html_body=$(cat "${REPORT_DIR}/rhel-patch-report-${hostname}-${TIMESTAMP}.html")

# SendGrid API call
                                                                                                              curl -X POST https://api.sendgrid.com/v3/mail/send \
                                                                                                              -H "Authorization: Bearer $api_key" \
                                                                                                              -H "Content-Type: application/json" \
                                                                                                              -d "{
                                                                                                                \"personalizations\": [{
                                                                                                                  \"to\": [{\"email\": \"admin@company.com\"}],
                                                                                                                  \"subject\": \"$subject\"
                                                                                                                }],
                                                                                                                \"from\": {\"email\": \"noreply@company.com\", \"name\": \"RHEL Patch Manager\"},
                                                                                                                  \"content\": [{
                                                                                                                    \"type\": \"text/html\",
                                                                                                                    \"value\": \"$html_body\"
                                                                                                                  }],
                                                                                                                  \"categories\": [\"ansible\", \"rhel-updates\", \"automation\"]
                                                                                                                }" &>/dev/null

                                                                                                                if [[ $? -eq 0 ]]; then
                                                                                                                  log_success "SendGrid report sent successfully"
                                                                                                                else
                                                                                                                  log_error "Failed to send SendGrid report"
                                                                                                                fi
                                                                                                              }

# Send Slack notification
                                                                                                              send_slack_notification() {
                                                                                                                local webhook_url=$1
                                                                                                                local hostname=$(hostname -f)

                                                                                                                  log_info "Sending Slack notification..."

                                                                                                                  local payload="{
                                                                                                                    \"channel\": \"#infrastructure\",
                                                                                                                    \"username\": \"RHEL Patch Manager\",
                                                                                                                    \"icon_emoji\": \": computer:\",
                                                                                                                    \"text\": \" *RHEL Patch Report*\\n*Host:* ${hostname}\\n*Status:* $([ $UPDATE_COUNT -eq 0 ] && echo " Compliant" || echo " $UPDATE_COUNT updates available")\\n*Security Updates:* ${SECURITY_COUNT}\\n*Reboot Required:* $([ $REBOOT_REQUIRED == true ] && echo "Yes" || echo "No")\\n*Generated:* $(date)\"
                                                                                                                  }"

                                                                                                                  curl -X POST -H 'Content-type: application/json' \
                                                                                                                  --data "$payload" \
                                                                                                                  "$webhook_url" &>/dev/null

                                                                                                                  if [[ $? -eq 0 ]]; then
                                                                                                                    log_success "Slack notification sent"
                                                                                                                  else
                                                                                                                    log_error "Failed to send Slack notification"
                                                                                                                  fi
                                                                                                                }

# Main execution function
                                                                                                                main() {
# Parse command line arguments
                                                                                                                  while [[ $# -gt 0 ]]; do
                                                                                                                    case $1 in
                                                                                                                    -h|--help)
                                                                                                                      show_help
                                                                                                                      exit 0
                                                                                                                      ;;
                                                                                                                      -d|--dry-run)
                                                                                                                        DRY_RUN=true
                                                                                                                        shift
                                                                                                                        ;;
                                                                                                                        -s|--security-only)
                                                                                                                          SECURITY_ONLY=true
                                                                                                                          shift
                                                                                                                          ;;
                                                                                                                          -r|--allow-reboot)
                                                                                                                            ALLOW_REBOOT=true
                                                                                                                            shift
                                                                                                                            ;;
                                                                                                                            -f|--force)
                                                                                                                              FORCE_MODE=true
                                                                                                                              shift
                                                                                                                              ;;
                                                                                                                              -v|--verbose)
                                                                                                                                LOG_LEVEL="DEBUG"
                                                                                                                                set -x
                                                                                                                                shift
                                                                                                                                ;;
                                                                                                                                -o|--output)
                                                                                                                                  REPORT_DIR="$2"
                                                                                                                                  shift 2
                                                                                                                                  ;;
                                                                                                                                  --email)
                                                                                                                                    EMAIL_ADDRESS="$2"
                                                                                                                                    shift 2
                                                                                                                                    ;;
                                                                                                                                    --sendgrid-key)
                                                                                                                                      SENDGRID_API_KEY="$2"
                                                                                                                                      shift 2
                                                                                                                                      ;;
                                                                                                                                      --slack-webhook)
                                                                                                                                        SLACK_WEBHOOK="$2"
                                                                                                                                        shift 2
                                                                                                                                        ;;
                                                                                                                                        *)
                                                                                                                                          log_error "Unknown option: $1"
                                                                                                                                          show_help
                                                                                                                                          exit 1
                                                                                                                                          ;;
                                                                                                                                        esac
                                                                                                                                      done

# Initialize
                                                                                                                                      echo "$(date +%s)" > "${REPORT_DIR}/start_timestamp.tmp"
                                                                                                                                      echo "$(date -Iseconds)" > "${REPORT_DIR}/start_time.tmp"

                                                                                                                                      log_info "Starting RHEL Patch Manager v${SCRIPT_VERSION}"
                                                                                                                                      log_info "Report directory: ${REPORT_DIR}"

# Execute patching workflow
                                                                                                                                      detect_rhel_environment
                                                                                                                                      validate_system
                                                                                                                                      check_updates

                                                                                                                                      if [[ $DRY_RUN == false ]]; then
                                                                                                                                        apply_updates
                                                                                                                                      fi

                                                                                                                                      generate_reports

# Send reports if configured
                                                                                                                                      [[ -n ${EMAIL_ADDRESS:-} ]] && send_email_report "$EMAIL_ADDRESS"
                                                                                                                                      [[ -n ${SENDGRID_API_KEY:-} ]] && send_sendgrid_report "$SENDGRID_API_KEY"
                                                                                                                                      [[ -n ${SLACK_WEBHOOK:-} ]] && send_slack_notification "$SLACK_WEBHOOK"

# Cleanup temporary files
                                                                                                                                      rm -f "${REPORT_DIR}"/start_*.tmp

                                                                                                                                      log_success "RHEL patching completed successfully"
                                                                                                                                      echo -e "\n${GREEN}${BOLD} Patching completed!${NC}"
                                                                                                                                      echo -e " Reports: ${BLUE}${REPORT_DIR}${NC}"
                                                                                                                                      echo -e " Updates Applied: ${GREEN}${UPDATE_COUNT}${NC}"
                                                                                                                                      echo -e " Security Updates: ${YELLOW}${SECURITY_COUNT}${NC}"
                                                                                                                                      echo -e " Reboot Required: $([ $REBOOT_REQUIRED == true ] && echo -e "${RED}Yes${NC}" || echo -e "${GREEN}No${NC}")"
                                                                                                                                    }

# Trap for cleanup on exit
                                                                                                                                    cleanup() {
                                                                                                                                      log_info "Cleaning up temporary files..."
                                                                                                                                      rm -f "${REPORT_DIR}"/start_*.tmp 2>/dev/null || true
                                                                                                                                    }
                                                                                                                                    trap cleanup EXIT

# Execute main function
                                                                                                                                    main "$@"
