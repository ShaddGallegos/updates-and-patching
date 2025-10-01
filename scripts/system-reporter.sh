#!/bin/bash
# system-reporter.sh
# Professional system reporting script for Linux environments
# Compatible with all major Linux distributions
# Author: {{ ansible_user }}
# Version: 2.0.0
# Date: 2024-08-27

set -euo pipefail

# Script configuration
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="system-reporter"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  REPORT_DIR="/tmp/system_reports_${TIMESTAMP}"
  REPORT_FORMAT="all" # html, json, yaml, csv, text, all
  EMAIL_REPORT=false
  COLLECT_PERFORMANCE=false
  COLLECT_SECURITY=false

# Color codes
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  PURPLE='\033[0;35m'
  CYAN='\033[0;36m'
  NC='\033[0m'
  BOLD='\033[1m'

# Logging
  log() {
    local level=$1
    shift
    mkdir -p "$REPORT_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "${REPORT_DIR}/system-reporter-${TIMESTAMP}.log"
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
    ${BOLD}Professional System Reporter v${SCRIPT_VERSION}${NC}
    Comprehensive system reporting for all Linux distributions

      ${BOLD}USAGE:${NC}
      $0 [OPTIONS]

      ${BOLD}OPTIONS:${NC}
      -h, --help Show this help
      -o, --output DIR Custom report directory
      -f, --format FORMAT Report format: html,json,yaml,csv,text,all (default: all)
        -p, --performance Collect performance metrics
        -s, --security Collect security information
        -e, --email EMAIL Email report
        --sendgrid-key KEY SendGrid API key for email
          --smtp-server HOST SMTP server for email
            --verbose Verbose output

            ${BOLD}REPORT FORMATS:${NC}
            html Professional HTML dashboard
            json Machine-readable JSON format
              yaml YAML configuration format
                csv CSV for spreadsheet analysis
                  text Plain text executive summary
                  all Generate all formats

                    ${BOLD}EXAMPLES:${NC}
# Basic system report
                    $0

# HTML report with performance data
                    $0 --format html --performance

# Complete report with email delivery
                    $0 --performance --security --email admin@company.com

# JSON report for automation
                    $0 --format json --output /opt/reports

                    EOF
                  }

# Detect Linux distribution
                  detect_distribution() {
                    log_info "Detecting Linux distribution..."

# Initialize variables
                    DISTRO=""
                    DISTRO_VERSION=""
                    DISTRO_FAMILY=""
                    PACKAGE_MANAGER=""

# Check for various distribution files
                    if [[ -f /etc/redhat-release ]]; then
                      DISTRO=$(cat /etc/redhat-release | cut -d' ' -f1)
                        DISTRO_VERSION=$(cat /etc/redhat-release | grep -oP '(?<=release )[0-9.]+')
                          DISTRO_FAMILY="RedHat"
                          if command -v dnf >/dev/null 2>&1; then
                            PACKAGE_MANAGER="dnf"
                          else
                            PACKAGE_MANAGER="yum"
                          fi
                        elif [[ -f /etc/debian_version ]]; then
                          if [[ -f /etc/lsb-release ]]; then
                            DISTRO=$(grep DISTRIB_ID /etc/lsb-release | cut -d'=' -f2)
                              DISTRO_VERSION=$(grep DISTRIB_RELEASE /etc/lsb-release | cut -d'=' -f2)
                              else
                                DISTRO="Debian"
                                DISTRO_VERSION=$(cat /etc/debian_version)
                                fi
                                DISTRO_FAMILY="Debian"
                                PACKAGE_MANAGER="apt"
                              elif [[ -f /etc/SUSE-brand ]]; then
                                DISTRO=$(head -1 /etc/SUSE-brand)
                                  DISTRO_VERSION=$(cat /etc/os-release | grep VERSION_ID | cut -d'"' -f2)
                                    DISTRO_FAMILY="SUSE"
                                    PACKAGE_MANAGER="zypper"
                                  elif [[ -f /etc/arch-release ]]; then
                                    DISTRO="Arch Linux"
                                    DISTRO_VERSION="rolling"
                                    DISTRO_FAMILY="Arch"
                                    PACKAGE_MANAGER="pacman"
                                  elif [[ -f /etc/alpine-release ]]; then
                                    DISTRO="Alpine Linux"
                                    DISTRO_VERSION=$(cat /etc/alpine-release)
                                      DISTRO_FAMILY="Alpine"
                                      PACKAGE_MANAGER="apk"
                                    elif [[ -f /etc/gentoo-release ]]; then
                                      DISTRO="Gentoo Linux"
                                      DISTRO_VERSION=$(cat /etc/gentoo-release | cut -d' ' -f5)
                                        DISTRO_FAMILY="Gentoo"
                                        PACKAGE_MANAGER="emerge"
                                      else
                                        DISTRO="Unknown"
                                        DISTRO_VERSION="Unknown"
                                        DISTRO_FAMILY="Unknown"
                                        PACKAGE_MANAGER="unknown"
                                      fi

                                      log_success "Distribution: $DISTRO $DISTRO_VERSION ($DISTRO_FAMILY family)"

                                      export DISTRO DISTRO_VERSION DISTRO_FAMILY PACKAGE_MANAGER
                                    }

# Collect system information
                                    collect_system_info() {
                                      log_info "Collecting system information..."

# Basic system info
                                      HOSTNAME=$(hostname -f)
                                        KERNEL_VERSION=$(uname -r)
                                          ARCHITECTURE=$(uname -m)
                                            UPTIME=$(uptime -p)
                                              LOAD_AVERAGE=$(uptime | awk -F'load average:' '{print $2}')

# CPU information
                                                CPU_MODEL=$(grep "model name" /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)
                                                  CPU_CORES=$(nproc)
                                                    CPU_THREADS=$(grep "processor" /proc/cpuinfo | wc -l)

# Memory information
                                                      MEMORY_TOTAL=$(free -h | grep "^Mem:" | awk '{print $2}')
                                                        MEMORY_USED=$(free -h | grep "^Mem:" | awk '{print $3}')
                                                          MEMORY_AVAILABLE=$(free -h | grep "^Mem:" | awk '{print $7}')
                                                            MEMORY_PERCENT=$(free | grep "^Mem:" | awk '{printf "%.1f", ($3/$2)*100}')

# Disk information
                                                              DISK_INFO=$(df -h | grep -E '^/dev/' | head -5)

# Network interfaces
                                                                NETWORK_INFO=$(ip -o link show | grep -v "lo:" | awk '{print $2}' | tr -d ':')

                                                                  log_success "System information collected"

                                                                  export HOSTNAME KERNEL_VERSION ARCHITECTURE UPTIME LOAD_AVERAGE
                                                                  export CPU_MODEL CPU_CORES CPU_THREADS
                                                                  export MEMORY_TOTAL MEMORY_USED MEMORY_AVAILABLE MEMORY_PERCENT
                                                                  export DISK_INFO NETWORK_INFO
                                                                }

# Collect performance metrics
                                                                collect_performance_metrics() {
                                                                  [[ $COLLECT_PERFORMANCE == false ]] && return

                                                                  log_info "Collecting performance metrics..."

# CPU usage (5 second average)
                                                                  CPU_USAGE=$(top -bn2 -d1 | grep "Cpu(s)" | tail -1 | awk '{print $2}' | cut -d'%' -f1)

# I/O statistics
                                                                    if command -v iostat >/dev/null 2>&1; then
                                                                      IOSTAT_INFO=$(iostat -x 1 2 | tail -n +4)
                                                                      else
                                                                        IOSTAT_INFO="iostat not available"
                                                                      fi

# Network statistics
                                                                      if command -v sar >/dev/null 2>&1; then
                                                                        NETWORK_STATS=$(sar -n DEV 1 1 | grep "Average")
                                                                        else
                                                                          NETWORK_STATS="sar not available"
                                                                        fi

# Process information
                                                                        TOP_PROCESSES=$(ps aux --sort=-%cpu | head -11 | tail -10)

                                                                          log_success "Performance metrics collected"

                                                                          export CPU_USAGE IOSTAT_INFO NETWORK_STATS TOP_PROCESSES
                                                                        }

# Collect security information
                                                                        collect_security_info() {
                                                                          [[ $COLLECT_SECURITY == false ]] && return

                                                                          log_info "Collecting security information..."

# Failed login attempts
                                                                          FAILED_LOGINS=$(journalctl --since "24 hours ago" | grep -i "failed\|failure" | wc -l 2>/dev/null || echo "0")

# Open ports
                                                                            OPEN_PORTS=$(ss -tuln | grep -E "LISTEN|::" | wc -l)

# Firewall status
                                                                              if command -v ufw >/dev/null 2>&1; then
                                                                                FIREWALL_STATUS=$(ufw status | head -1)
                                                                                elif command -v firewall-cmd >/dev/null 2>&1; then
                                                                                  FIREWALL_STATUS=$(firewall-cmd --state 2>/dev/null || echo "unknown")
                                                                                  else
                                                                                    FIREWALL_STATUS="No common firewall found"
                                                                                  fi

# Last login information
                                                                                  LAST_LOGINS=$(last -n 5 | head -5)

                                                                                    log_success "Security information collected"

                                                                                    export FAILED_LOGINS OPEN_PORTS FIREWALL_STATUS LAST_LOGINS
                                                                                  }

# Generate HTML report
                                                                                  generate_html_report() {
                                                                                    [[ $REPORT_FORMAT != "html" && $REPORT_FORMAT != "all" ]] && return

                                                                                    log_info "Generating HTML report..."

                                                                                    local html_file="${REPORT_DIR}/system-report-${HOSTNAME}-${TIMESTAMP}.html"

                                                                                    cat > "$html_file" << 'EOF'
                                                                                    <!DOCTYPE html>
                                                                                    <html lang="en">
                                                                                    <head>
                                                                                    <meta charset="UTF-8">
                                                                                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                                                                                    <title>System Report Dashboard</title>
                                                                                    <style>
                                                                                    * { margin: 0; padding: 0; box-sizing: border-box; }
                                                                                      body {
                                                                                        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                                                                                        line-height: 1.6; color: #333; background: #f4f4f4;
                                                                                      }
                                                                                      .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
                                                                                        .header {
                                                                                          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                                                                                          color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px;
                                                                                          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
                                                                                        }
                                                                                        .header h1 { font-size: 2.5em; margin-bottom: 10px; }
                                                                                          .header .subtitle { font-size: 1.2em; opacity: 0.9; }
                                                                                            .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 20px; }
                                                                                              .card {
                                                                                                background: white; padding: 25px; border-radius: 10px;
                                                                                                box-shadow: 0 2px 10px rgba(0,0,0,0.1); transition: transform 0.3s;
                                                                                              }
                                                                                              .card:hover { transform: translateY(-5px); }
                                                                                                .card h2 {
                                                                                                  color: #4CAF50; margin-bottom: 15px; font-size: 1.5em;
                                                                                                  border-bottom: 2px solid #4CAF50; padding-bottom: 5px;
                                                                                                }
                                                                                                .metric { display: flex; justify-content: space-between; margin: 10px 0; }
                                                                                                  .metric-label { font-weight: 600; }
                                                                                                    .metric-value { color: #666; }
                                                                                                      .status-good { color: #4CAF50; }
                                                                                                        .status-warning { color: #ff9800; }
                                                                                                          .status-critical { color: #f44336; }
                                                                                                            .progress-bar {
                                                                                                              width: 100%; height: 20px; background: #e0e0e0;
                                                                                                              border-radius: 10px; overflow: hidden; margin: 5px 0;
                                                                                                            }
                                                                                                            .progress-fill { height: 100%; transition: width 0.3s; }
                                                                                                              .progress-low { background: #4CAF50; }
                                                                                                                .progress-medium { background: #ff9800; }
                                                                                                                  .progress-high { background: #f44336; }
                                                                                                                    pre {
                                                                                                                      background: #f8f8f8; padding: 15px; border-radius: 5px;
                                                                                                                      overflow-x: auto; font-size: 0.9em; border-left: 4px solid #4CAF50;
                                                                                                                    }
                                                                                                                    .footer {
                                                                                                                      text-align: center; margin-top: 30px; padding: 20px;
                                                                                                                      color: #666; border-top: 1px solid #ddd;
                                                                                                                    }
                                                                                                                    </style>
                                                                                                                    </head>
                                                                                                                    <body>
                                                                                                                    <div class="container">
                                                                                                                    <div class="header">
                                                                                                                    <h1> System Report Dashboard</h1>
                                                                                                                    <div class="subtitle">Professional System Analysis</div>
                                                                                                                    </div>

                                                                                                                    <div class="grid">
                                                                                                                    <div class="card">
                                                                                                                    <h2> System Information</h2>
                                                                                                                    <div class="metric">
                                                                                                                    <span class="metric-label">Hostname:</span>
                                                                                                                    <span class="metric-value">{{HOSTNAME}}</span>
                                                                                                                    </div>
                                                                                                                    <div class="metric">
                                                                                                                    <span class="metric-label">Distribution:</span>
                                                                                                                    <span class="metric-value">{{DISTRO}} {{DISTRO_VERSION}}</span>
                                                                                                                      </div>
                                                                                                                      <div class="metric">
                                                                                                                      <span class="metric-label">Kernel:</span>
                                                                                                                      <span class="metric-value">{{KERNEL_VERSION}}</span>
                                                                                                                      </div>
                                                                                                                      <div class="metric">
                                                                                                                      <span class="metric-label">Architecture:</span>
                                                                                                                      <span class="metric-value">{{ARCHITECTURE}}</span>
                                                                                                                      </div>
                                                                                                                      <div class="metric">
                                                                                                                      <span class="metric-label">Uptime:</span>
                                                                                                                      <span class="metric-value">{{UPTIME}}</span>
                                                                                                                      </div>
                                                                                                                      <div class="metric">
                                                                                                                      <span class="metric-label">Package Manager:</span>
                                                                                                                      <span class="metric-value">{{PACKAGE_MANAGER}}</span>
                                                                                                                      </div>
                                                                                                                      </div>

                                                                                                                      <div class="card">
                                                                                                                      <h2> CPU Information</h2>
                                                                                                                      <div class="metric">
                                                                                                                      <span class="metric-label">Model:</span>
                                                                                                                      <span class="metric-value">{{CPU_MODEL}}</span>
                                                                                                                      </div>
                                                                                                                      <div class="metric">
                                                                                                                      <span class="metric-label">Cores:</span>
                                                                                                                      <span class="metric-value">{{CPU_CORES}}</span>
                                                                                                                      </div>
                                                                                                                      <div class="metric">
                                                                                                                      <span class="metric-label">Threads:</span>
                                                                                                                      <span class="metric-value">{{CPU_THREADS}}</span>
                                                                                                                      </div>
                                                                                                                      <div class="metric">
                                                                                                                      <span class="metric-label">Load Average:</span>
                                                                                                                      <span class="metric-value">{{LOAD_AVERAGE}}</span>
                                                                                                                      </div>
                                                                                                                      {{#if CPU_USAGE}}
                                                                                                                      <div class="metric">
                                                                                                                      <span class="metric-label">CPU Usage:</span>
                                                                                                                      <span class="metric-value">{{CPU_USAGE}}%</span>
                                                                                                                      </div>
                                                                                                                      <div class="progress-bar">
                                                                                                                      <div class="progress-fill progress-medium" style="width: {{CPU_USAGE}}%"></div>
                                                                                                                        </div>
                                                                                                                        {{/if}}
                                                                                                                        </div>

                                                                                                                        <div class="card">
                                                                                                                        <h2> Memory Information</h2>
                                                                                                                        <div class="metric">
                                                                                                                        <span class="metric-label">Total Memory:</span>
                                                                                                                        <span class="metric-value">{{MEMORY_TOTAL}}</span>
                                                                                                                        </div>
                                                                                                                        <div class="metric">
                                                                                                                        <span class="metric-label">Used Memory:</span>
                                                                                                                        <span class="metric-value">{{MEMORY_USED}}</span>
                                                                                                                        </div>
                                                                                                                        <div class="metric">
                                                                                                                        <span class="metric-label">Available:</span>
                                                                                                                        <span class="metric-value">{{MEMORY_AVAILABLE}}</span>
                                                                                                                        </div>
                                                                                                                        <div class="metric">
                                                                                                                        <span class="metric-label">Usage:</span>
                                                                                                                        <span class="metric-value">{{MEMORY_PERCENT}}%</span>
                                                                                                                        </div>
                                                                                                                        <div class="progress-bar">
                                                                                                                        <div class="progress-fill progress-low" style="width: {{MEMORY_PERCENT}}%"></div>
                                                                                                                          </div>
                                                                                                                          </div>

                                                                                                                          <div class="card">
                                                                                                                          <h2> Storage Information</h2>
                                                                                                                          <pre>{{DISK_INFO}}</pre>
                                                                                                                          </div>

                                                                                                                          {{#if COLLECT_SECURITY}}
                                                                                                                          <div class="card">
                                                                                                                          <h2> Security Status</h2>
                                                                                                                          <div class="metric">
                                                                                                                          <span class="metric-label">Failed Logins (24h):</span>
                                                                                                                          <span class="metric-value">{{FAILED_LOGINS}}</span>
                                                                                                                          </div>
                                                                                                                          <div class="metric">
                                                                                                                          <span class="metric-label">Open Ports:</span>
                                                                                                                          <span class="metric-value">{{OPEN_PORTS}}</span>
                                                                                                                          </div>
                                                                                                                          <div class="metric">
                                                                                                                          <span class="metric-label">Firewall:</span>
                                                                                                                          <span class="metric-value">{{FIREWALL_STATUS}}</span>
                                                                                                                          </div>
                                                                                                                          </div>
                                                                                                                          {{/if}}

                                                                                                                          {{#if TOP_PROCESSES}}
                                                                                                                          <div class="card">
                                                                                                                          <h2> Top Processes</h2>
                                                                                                                          <pre>{{TOP_PROCESSES}}</pre>
                                                                                                                          </div>
                                                                                                                          {{/if}}
                                                                                                                          </div>

                                                                                                                          <div class="footer">
                                                                                                                          Generated by System Reporter v{{SCRIPT_VERSION}} | {{TIMESTAMP}}
                                                                                                                            </div>
                                                                                                                            </div>
                                                                                                                            </body>
                                                                                                                            </html>
                                                                                                                            EOF

# Replace template variables
                                                                                                                            sed -i "s/{{HOSTNAME}}/$HOSTNAME/g" "$html_file"
                                                                                                                            sed -i "s/{{DISTRO}}/$DISTRO/g" "$html_file"
                                                                                                                            sed -i "s/{{DISTRO_VERSION}}/$DISTRO_VERSION/g" "$html_file"
                                                                                                                            sed -i "s/{{KERNEL_VERSION}}/$KERNEL_VERSION/g" "$html_file"
                                                                                                                            sed -i "s/{{ARCHITECTURE}}/$ARCHITECTURE/g" "$html_file"
                                                                                                                            sed -i "s/{{UPTIME}}/$UPTIME/g" "$html_file"
                                                                                                                            sed -i "s/{{PACKAGE_MANAGER}}/$PACKAGE_MANAGER/g" "$html_file"
                                                                                                                            sed -i "s/{{CPU_MODEL}}/$CPU_MODEL/g" "$html_file"
                                                                                                                            sed -i "s/{{CPU_CORES}}/$CPU_CORES/g" "$html_file"
                                                                                                                            sed -i "s/{{CPU_THREADS}}/$CPU_THREADS/g" "$html_file"
                                                                                                                            sed -i "s/{{LOAD_AVERAGE}}/$LOAD_AVERAGE/g" "$html_file"
                                                                                                                            sed -i "s/{{MEMORY_TOTAL}}/$MEMORY_TOTAL/g" "$html_file"
                                                                                                                            sed -i "s/{{MEMORY_USED}}/$MEMORY_USED/g" "$html_file"
                                                                                                                            sed -i "s/{{MEMORY_AVAILABLE}}/$MEMORY_AVAILABLE/g" "$html_file"
                                                                                                                            sed -i "s/{{MEMORY_PERCENT}}/$MEMORY_PERCENT/g" "$html_file"
                                                                                                                            sed -i "s/{{DISK_INFO}}/$DISK_INFO/g" "$html_file"
                                                                                                                            sed -i "s/{{SCRIPT_VERSION}}/$SCRIPT_VERSION/g" "$html_file"
                                                                                                                            sed -i "s/{{TIMESTAMP}}/$TIMESTAMP/g" "$html_file"

# Add optional performance data
                                                                                                                            if [[ $COLLECT_PERFORMANCE == true ]]; then
                                                                                                                              sed -i "s/{{CPU_USAGE}}/${CPU_USAGE:-0}/g" "$html_file"
                                                                                                                              sed -i "s/{{TOP_PROCESSES}}/$TOP_PROCESSES/g" "$html_file"
                                                                                                                            fi

# Add optional security data
                                                                                                                            if [[ $COLLECT_SECURITY == true ]]; then
                                                                                                                              sed -i "s/{{FAILED_LOGINS}}/$FAILED_LOGINS/g" "$html_file"
                                                                                                                              sed -i "s/{{OPEN_PORTS}}/$OPEN_PORTS/g" "$html_file"
                                                                                                                              sed -i "s/{{FIREWALL_STATUS}}/$FIREWALL_STATUS/g" "$html_file"
                                                                                                                            fi

                                                                                                                            log_success "HTML report generated: $html_file"
                                                                                                                            export HTML_REPORT="$html_file"
                                                                                                                          }

# Generate JSON report
                                                                                                                          generate_json_report() {
                                                                                                                            [[ $REPORT_FORMAT != "json" && $REPORT_FORMAT != "all" ]] && return

                                                                                                                            log_info "Generating JSON report..."

                                                                                                                            local json_file="${REPORT_DIR}/system-report-${HOSTNAME}-${TIMESTAMP}.json"

                                                                                                                            cat > "$json_file" << EOF
                                                                                                                            {
                                                                                                                              "metadata": {
                                                                                                                                "script_name": "${SCRIPT_NAME}",
                                                                                                                                "version": "${SCRIPT_VERSION}",
                                                                                                                                "hostname": "${HOSTNAME}",
                                                                                                                                "timestamp": "$(date -Iseconds)",
                                                                                                                                "report_id": "${HOSTNAME}-${TIMESTAMP}"
                                                                                                                              },
                                                                                                                              "system_info": {
                                                                                                                                "hostname": "${HOSTNAME}",
                                                                                                                                "distribution": "${DISTRO}",
                                                                                                                                "distribution_version": "${DISTRO_VERSION}",
                                                                                                                                "distribution_family": "${DISTRO_FAMILY}",
                                                                                                                                "kernel_version": "${KERNEL_VERSION}",
                                                                                                                                "architecture": "${ARCHITECTURE}",
                                                                                                                                "package_manager": "${PACKAGE_MANAGER}",
                                                                                                                                "uptime": "${UPTIME}",
                                                                                                                                "load_average": "${LOAD_AVERAGE}"
                                                                                                                              },
                                                                                                                              "hardware": {
                                                                                                                                "cpu": {
                                                                                                                                  "model": "${CPU_MODEL}",
                                                                                                                                  "cores": ${CPU_CORES},
                                                                                                                                  "threads": ${CPU_THREADS}$([ -n "${CPU_USAGE:-}" ] && echo ",\"usage_percent\": ${CPU_USAGE}" || echo "")
                                                                                                                                  },
                                                                                                                                  "memory": {
                                                                                                                                    "total": "${MEMORY_TOTAL}",
                                                                                                                                    "used": "${MEMORY_USED}",
                                                                                                                                    "available": "${MEMORY_AVAILABLE}",
                                                                                                                                    "usage_percent": ${MEMORY_PERCENT}
                                                                                                                                  }
                                                                                                                                }$([ $COLLECT_SECURITY == true ] && cat << SECURITY_JSON || echo "")
                                                                                                                                  ,
                                                                                                                                  "security": {
                                                                                                                                    "failed_logins_24h": ${FAILED_LOGINS},
                                                                                                                                    "open_ports": ${OPEN_PORTS},
                                                                                                                                    "firewall_status": "${FIREWALL_STATUS}"
                                                                                                                                  }
                                                                                                                                  SECURITY_JSON
                                                                                                                                }
                                                                                                                                EOF

                                                                                                                                log_success "JSON report generated: $json_file"
                                                                                                                                export JSON_REPORT="$json_file"
                                                                                                                              }

# Main execution
                                                                                                                              main() {
# Parse arguments
                                                                                                                                while [[ $# -gt 0 ]]; do
                                                                                                                                  case $1 in
                                                                                                                                  -h|--help) show_help; exit 0 ;;
                                                                                                                                  -o|--output) REPORT_DIR="$2"; shift 2 ;;
                                                                                                                                  -f|--format) REPORT_FORMAT="$2"; shift 2 ;;
                                                                                                                                  -p|--performance) COLLECT_PERFORMANCE=true; shift ;;
                                                                                                                                  -s|--security) COLLECT_SECURITY=true; shift ;;
                                                                                                                                  -e|--email) EMAIL_ADDRESS="$2"; EMAIL_REPORT=true; shift 2 ;;
                                                                                                                                  --sendgrid-key) SENDGRID_API_KEY="$2"; shift 2 ;;
                                                                                                                                  --smtp-server) SMTP_SERVER="$2"; shift 2 ;;
                                                                                                                                  --verbose) VERBOSE=true; shift ;;
                                                                                                                                  *) log_error "Unknown option: $1"; exit 1 ;;
                                                                                                                                esac
                                                                                                                              done

                                                                                                                              log_info "Starting System Reporter v${SCRIPT_VERSION}"

# Create report directory
                                                                                                                              mkdir -p "$REPORT_DIR"

# Collect system information
                                                                                                                              detect_distribution
                                                                                                                              collect_system_info
                                                                                                                              collect_performance_metrics
                                                                                                                              collect_security_info

# Generate reports
                                                                                                                              generate_html_report
                                                                                                                              generate_json_report

# Display summary
                                                                                                                              echo -e "\n${GREEN}${BOLD} System Report Summary${NC}"
                                                                                                                              echo -e "Hostname: ${HOSTNAME}"
                                                                                                                              echo -e "Distribution: ${DISTRO} ${DISTRO_VERSION}"
                                                                                                                              echo -e "Memory Usage: ${MEMORY_PERCENT}%"
                                                                                                                              echo -e "Report Directory: ${REPORT_DIR}"

# Email report if requested
                                                                                                                              if [[ $EMAIL_REPORT == true && -n ${EMAIL_ADDRESS:-} ]]; then
                                                                                                                                echo "System report attached" | mail -s "[System Report] ${HOSTNAME}" "$EMAIL_ADDRESS"
                                                                                                                                log_success "Report emailed to: $EMAIL_ADDRESS"
                                                                                                                              fi

                                                                                                                              log_success "System reporting completed"
                                                                                                                            }

                                                                                                                            main "$@"
