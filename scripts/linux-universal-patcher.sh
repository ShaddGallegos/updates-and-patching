#!/bin/bash
# linux-universal-patcher.sh
# Universal Linux patching script for all major distributions
# Compatible with: RHEL, CentOS, Ubuntu, Debian, SUSE, Arch, Alpine, Gentoo
# Author: {{ ansible_user }}
# Version: 2.0.0
# Date: 2024-08-27

set -euo pipefail

# Script configuration
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="linux-universal-patcher"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  REPORT_DIR="/tmp/reports_${TIMESTAMP}"
  DRY_RUN=false
  SECURITY_ONLY=false
  ALLOW_REBOOT=false
  VERBOSE=false

# Color codes
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
  BOLD='\033[1m'

# Distribution detection
  DISTRO=""
  OS_FAMILY=""
  PKG_MANAGER=""
  VERSION=""

# Logging functions
  log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
      mkdir -p "$REPORT_DIR"
      echo -e "[${timestamp}] [${level}] ${message}" | tee -a "${REPORT_DIR}/universal-patch-${TIMESTAMP}.log"
    }

    log_info() {
      log "INFO" "$*"
      [[ $VERBOSE == true ]] && echo -e "${BLUE}[INFO]${NC} $*"
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
      ${BOLD}Universal Linux Patcher v${SCRIPT_VERSION}${NC}
      Enterprise-grade patching for all major Linux distributions

        ${BOLD}SUPPORTED DISTRIBUTIONS:${NC}
        RedHat Family: RHEL 7-10, CentOS, Fedora, Rocky, AlmaLinux
        Debian Family: Debian 11-12, Ubuntu 18-24, Mint, Kali
        SUSE Family: openSUSE 15+, SLES 15+
        Others: Arch Linux, Alpine Linux, Gentoo

        ${BOLD}USAGE:${NC}
        $0 [OPTIONS]

        ${BOLD}OPTIONS:${NC}
        -h, --help Show this help
        -d, --dry-run Preview updates only
        -s, --security-only Security updates only
        -r, --allow-reboot Allow automatic reboot
        -v, --verbose Enable verbose output
        -o, --output DIR Custom report directory
        --email EMAIL Email report
        --slack-webhook URL Slack notification

        ${BOLD}EXAMPLES:${NC}
# Check available updates (dry run)
        $0 --dry-run --verbose

# Security updates only
        $0 --security-only

# Full update with reboot
        $0 --allow-reboot --email admin@company.com

        EOF
      }

# Detect Linux distribution and package manager
      detect_linux_environment() {
        log_info "Detecting Linux distribution and package manager..."

# Detect distribution
        if [[ -f /etc/os-release ]]; then
          source /etc/os-release
          DISTRO="$NAME"
          VERSION="$VERSION_ID"

# Determine OS family and package manager
          case "$ID" in
          rhel|centos|rocky|almalinux|fedora)
            OS_FAMILY="RedHat"
            if command -v dnf >/dev/null 2>&1; then
              PKG_MANAGER="dnf"
            else
              PKG_MANAGER="yum"
            fi
            ;;
            ubuntu|debian|linuxmint|kali)
              OS_FAMILY="Debian"
              PKG_MANAGER="apt"
              ;;
              opensuse*|sles)
                OS_FAMILY="Suse"
                PKG_MANAGER="zypper"
                ;;
                arch|manjaro)
                  OS_FAMILY="Arch"
                  PKG_MANAGER="pacman"
                  ;;
                  alpine)
                    OS_FAMILY="Alpine"
                    PKG_MANAGER="apk"
                    ;;
                    gentoo)
                      OS_FAMILY="Gentoo"
                      PKG_MANAGER="emerge"
                      ;;
                      *)
                        log_error "Unsupported distribution: $ID"
                        exit 1
                        ;;
                      esac
                    else
                      log_error "Cannot detect Linux distribution - /etc/os-release not found"
                      exit 1
                    fi

                    log_success "Detected: $DISTRO $VERSION ($OS_FAMILY family, $PKG_MANAGER package manager)"
                    export DISTRO OS_FAMILY PKG_MANAGER VERSION
                  }

# Universal package cache update
                  update_package_cache() {
                    log_info "Updating package cache for $PKG_MANAGER..."

                      case $PKG_MANAGER in
                      yum)
                        yum clean all >/dev/null 2>&1
                        yum makecache >/dev/null 2>&1
                        ;;
                        dnf)
                          dnf clean all >/dev/null 2>&1
                          dnf makecache >/dev/null 2>&1
                          ;;
                          apt)
                            apt update >/dev/null 2>&1
                            ;;
                            zypper)
                              zypper refresh >/dev/null 2>&1
                              ;;
                              pacman)
                                pacman -Sy >/dev/null 2>&1
                                ;;
                                apk)
                                  apk update >/dev/null 2>&1
                                  ;;
                                  emerge)
                                    emerge --sync >/dev/null 2>&1
                                    ;;
                                  esac

                                  log_success "Package cache updated"
                                }

# Check for available updates
                                check_universal_updates() {
                                  log_info "Checking for available updates..."

                                    local update_file="${REPORT_DIR}/available_updates.txt"
                                    UPDATE_COUNT=0
                                    SECURITY_COUNT=0

                                    case $PKG_MANAGER in
                                    yum)
                                      if [[ $SECURITY_ONLY == true ]]; then
                                        yum --security check-update > "$update_file" 2>/dev/null || true
                                      else
                                        yum check-update > "$update_file" 2>/dev/null || true
                                      fi
                                      UPDATE_COUNT=$(grep -c "^[[:alpha:]]" "$update_file" 2>/dev/null || echo "0")
                                        SECURITY_COUNT=$(yum --security check-update 2>/dev/null | grep -c "^[[:alpha:]]" || echo "0")
                                          ;;
                                          dnf)
                                            if [[ $SECURITY_ONLY == true ]]; then
                                              dnf updateinfo list sec > "$update_file" 2>/dev/null || true
                                            else
                                              dnf check-update > "$update_file" 2>/dev/null || true
                                            fi
                                            UPDATE_COUNT=$(grep -c "^[[:alpha:]]" "$update_file" 2>/dev/null || echo "0")
                                              SECURITY_COUNT=$(dnf updateinfo list sec 2>/dev/null | grep -c "^" || echo "0")
                                                ;;
                                                apt)
                                                  apt list --upgradable > "$update_file" 2>/dev/null || true
                                                  UPDATE_COUNT=$(grep -c "/" "$update_file" 2>/dev/null || echo "0")
# APT doesn't easily distinguish security updates
                                                    SECURITY_COUNT=$(apt list --upgradable 2>/dev/null | grep -c "security" || echo "0")
                                                      ;;
                                                      zypper)
                                                        if [[ $SECURITY_ONLY == true ]]; then
                                                          zypper list-patches --category security > "$update_file" 2>/dev/null || true
                                                        else
                                                          zypper list-updates > "$update_file" 2>/dev/null || true
                                                        fi
                                                        UPDATE_COUNT=$(grep -c "^v" "$update_file" 2>/dev/null || echo "0")
                                                          SECURITY_COUNT=$(zypper list-patches --category security 2>/dev/null | grep -c "^" || echo "0")
                                                            ;;
                                                            pacman)
                                                              pacman -Qu > "$update_file" 2>/dev/null || true
                                                              UPDATE_COUNT=$(wc -l < "$update_file" 2>/dev/null || echo "0")
                                                                SECURITY_COUNT=0 # Arch doesn't categorize security updates
                                                                ;;
                                                                apk)
                                                                  apk list -u > "$update_file" 2>/dev/null || true
                                                                  UPDATE_COUNT=$(grep -c "upgradable" "$update_file" 2>/dev/null || echo "0")
                                                                    SECURITY_COUNT=0 # Alpine doesn't categorize security updates
                                                                    ;;
                                                                    emerge)
                                                                      emerge -pv --update --deep @world > "$update_file" 2>/dev/null || true
                                                                      UPDATE_COUNT=$(grep -c "^\\[" "$update_file" 2>/dev/null || echo "0")
                                                                        SECURITY_COUNT=0 # Gentoo security handled via GLSA
                                                                        ;;
                                                                      esac

                                                                      log_info "Found $UPDATE_COUNT total updates, $SECURITY_COUNT security updates"
                                                                      export UPDATE_COUNT SECURITY_COUNT
                                                                    }

# Apply universal updates
                                                                    apply_universal_updates() {
                                                                      if [[ $UPDATE_COUNT -eq 0 ]]; then
                                                                        log_success "System is up to date"
                                                                        return 0
                                                                      fi

                                                                      log_info "Applying updates using $PKG_MANAGER..."

                                                                      if [[ $DRY_RUN == true ]]; then
                                                                        log_info "DRY RUN: Would apply $UPDATE_COUNT updates"
                                                                        return 0
                                                                      fi

                                                                      local start_time=$(date +%s)
                                                                        local update_cmd=""

# Build update command based on package manager
                                                                        case $PKG_MANAGER in
                                                                        yum)
                                                                          update_cmd="yum update -y"
                                                                          [[ $SECURITY_ONLY == true ]] && update_cmd="yum update -y --security"
                                                                          ;;
                                                                          dnf)
                                                                            update_cmd="dnf update -y"
                                                                            [[ $SECURITY_ONLY == true ]] && update_cmd="dnf update -y --security"
                                                                            ;;
                                                                            apt)
                                                                              update_cmd="apt upgrade -y"
                                                                              [[ $SECURITY_ONLY == true ]] && update_cmd="unattended-upgrade -v"
                                                                              ;;
                                                                              zypper)
                                                                                update_cmd="zypper update -y"
                                                                                [[ $SECURITY_ONLY == true ]] && update_cmd="zypper patch --category security -y"
                                                                                ;;
                                                                                pacman)
                                                                                  update_cmd="pacman -Syu --noconfirm"
                                                                                  ;;
                                                                                  apk)
                                                                                    update_cmd="apk upgrade"
                                                                                    ;;
                                                                                    emerge)
                                                                                      update_cmd="emerge --update --deep @world"
                                                                                      ;;
                                                                                    esac

# Execute update
                                                                                    log_info "Executing: $update_cmd"
                                                                                    if $update_cmd 2>&1 | tee -a "${REPORT_DIR}/patch-output-${TIMESTAMP}.log"; then
                                                                                      local end_time=$(date +%s)
                                                                                        local duration=$((end_time - start_time))
                                                                                          log_success "Updates completed in ${duration} seconds"

                                                                                          check_universal_reboot_required
                                                                                        else
                                                                                          log_error "Update process failed"
                                                                                          exit 1
                                                                                        fi
                                                                                      }

# Universal reboot requirement check
                                                                                      check_universal_reboot_required() {
                                                                                        log_info "Checking reboot requirements..."

                                                                                        REBOOT_REQUIRED=false

                                                                                        case $PKG_MANAGER in
                                                                                        yum|dnf)
                                                                                          if needs-restarting -r >/dev/null 2>&1; then
                                                                                            REBOOT_REQUIRED=true
                                                                                          fi
                                                                                          ;;
                                                                                          apt)
                                                                                            if [[ -f /var/run/reboot-required ]]; then
                                                                                              REBOOT_REQUIRED=true
                                                                                            fi
                                                                                            ;;
                                                                                            zypper)
                                                                                              if zypper ps -s | grep -q "reboot"; then
                                                                                                REBOOT_REQUIRED=true
                                                                                              fi
                                                                                              ;;
                                                                                              pacman)
# Check for kernel updates
                                                                                                if grep -q "linux" "${REPORT_DIR}/available_updates.txt" 2>/dev/null; then
                                                                                                  REBOOT_REQUIRED=true
                                                                                                fi
                                                                                                ;;
                                                                                                apk|emerge)
# These typically require manual reboot determination
                                                                                                  REBOOT_REQUIRED=false
                                                                                                  ;;
                                                                                                esac

                                                                                                if [[ $REBOOT_REQUIRED == true ]]; then
                                                                                                  log_warn "System reboot required"
                                                                                                  if [[ $ALLOW_REBOOT == true ]]; then
                                                                                                    log_info "Initiating reboot in 60 seconds..."
                                                                                                    shutdown -r +1 "System reboot after patching"
                                                                                                  fi
                                                                                                else
                                                                                                  log_success "No reboot required"
                                                                                                fi

                                                                                                export REBOOT_REQUIRED
                                                                                              }

# Generate universal reports
                                                                                              generate_universal_reports() {
                                                                                                log_info "Generating universal Linux patching reports..."

                                                                                                local hostname=$(hostname -f)
                                                                                                  local kernel_version=$(uname -r)
                                                                                                    local architecture=$(uname -m)
                                                                                                      local uptime=$(uptime -p 2>/dev/null || uptime)

# JSON Report
                                                                                                        cat > "${REPORT_DIR}/linux-patch-report-${hostname}-${TIMESTAMP}.json" << EOF
                                                                                                        {
                                                                                                          "metadata": {
                                                                                                            "script_name": "${SCRIPT_NAME}",
                                                                                                            "version": "${SCRIPT_VERSION}",
                                                                                                            "hostname": "${hostname}",
                                                                                                            "timestamp": "$(date -Iseconds)",
                                                                                                            "report_id": "${hostname}-${TIMESTAMP}"
                                                                                                          },
                                                                                                          "system_info": {
                                                                                                            "distribution": "${DISTRO}",
                                                                                                            "version": "${VERSION}",
                                                                                                            "os_family": "${OS_FAMILY}",
                                                                                                            "kernel_version": "${kernel_version}",
                                                                                                            "architecture": "${architecture}",
                                                                                                            "package_manager": "${PKG_MANAGER}",
                                                                                                            "uptime": "${uptime}"
                                                                                                          },
                                                                                                          "patch_summary": {
                                                                                                            "total_updates": ${UPDATE_COUNT},
                                                                                                            "security_updates": ${SECURITY_COUNT},
                                                                                                            "patch_type": "$([ $SECURITY_ONLY == true ] && echo "security" || echo "full")",
                                                                                                            "dry_run": ${DRY_RUN},
                                                                                                            "reboot_required": ${REBOOT_REQUIRED},
                                                                                                            "compliance_status": "$([ $UPDATE_COUNT -eq 0 ] && echo "compliant" || echo "updates_available")"
                                                                                                          }
                                                                                                        }
                                                                                                        EOF

# Text Summary
                                                                                                        cat > "${REPORT_DIR}/linux-patch-summary-${hostname}-${TIMESTAMP}.txt" << EOF
                                                                                                        Universal Linux Patch Report
                                                                                                        ============================
                                                                                                        Generated: $(date)
                                                                                                          Hostname: ${hostname}
                                                                                                          Distribution: ${DISTRO} ${VERSION}
                                                                                                          OS Family: ${OS_FAMILY}
                                                                                                          Package Manager: ${PKG_MANAGER}
                                                                                                          Kernel: ${kernel_version}

                                                                                                          PATCH SUMMARY
                                                                                                          =============
                                                                                                          Total Updates Available: ${UPDATE_COUNT}
                                                                                                          Security Updates: ${SECURITY_COUNT}
                                                                                                          Patch Type: $([ $SECURITY_ONLY == true ] && echo "Security Only" || echo "Full Update")
                                                                                                            Dry Run: $([ $DRY_RUN == true ] && echo "Yes" || echo "No")
                                                                                                              Reboot Required: $([ $REBOOT_REQUIRED == true ] && echo "Yes" || echo "No")
                                                                                                                Status: $([ $UPDATE_COUNT -eq 0 ] && echo " COMPLIANT" || echo " UPDATES AVAILABLE")

                                                                                                                  AVAILABLE UPDATES
                                                                                                                  =================
                                                                                                                  $(cat "${REPORT_DIR}/available_updates.txt" 2>/dev/null || echo "No updates file generated")
                                                                                                                    EOF

                                                                                                                    log_success "Universal reports generated"
                                                                                                                  }

# Send notifications
                                                                                                                  send_notifications() {
                                                                                                                    local email_address="${EMAIL_ADDRESS:-}"
                                                                                                                    local slack_webhook="${SLACK_WEBHOOK:-}"
                                                                                                                    local hostname=$(hostname -f)

# Email notification
                                                                                                                      if [[ -n $email_address ]] && command -v mail >/dev/null 2>&1; then
                                                                                                                        log_info "Sending email report to: $email_address"

                                                                                                                        local subject="[Linux Patch Report] ${hostname} - $OS_FAMILY - $(date +%Y-%m-%d)"
                                                                                                                        local body="Linux patching report for ${hostname} (${DISTRO} ${VERSION}). Status: $([ $UPDATE_COUNT -eq 0 ] && echo "Compliant" || echo "$UPDATE_COUNT updates available")"

                                                                                                                          echo "$body" | mail -s "$subject" -A "${REPORT_DIR}/linux-patch-report-${hostname}-${TIMESTAMP}.json" "$email_address"
                                                                                                                          log_success "Email sent to: $email_address"
                                                                                                                        fi

# Slack notification
                                                                                                                        if [[ -n $slack_webhook ]]; then
                                                                                                                          log_info "Sending Slack notification..."

                                                                                                                          local status_icon="$([ $UPDATE_COUNT -eq 0 ] && echo "" || echo "")"
                                                                                                                          local status_text="$([ $UPDATE_COUNT -eq 0 ] && echo "Compliant" || echo "$UPDATE_COUNT updates available")"

                                                                                                                          curl -X POST -H 'Content-type: application/json' \
                                                                                                                          --data "{
                                                                                                                            \"text\": \" *Linux Patch Report*\\n*Host:* ${hostname}\\n*Distribution:* ${DISTRO} ${VERSION}\\n*Status:* ${status_icon} ${status_text}\\n*Security Updates:* ${SECURITY_COUNT}\\n*Reboot Required:* $([ $REBOOT_REQUIRED == true ] && echo "Yes" || echo "No")\"
                                                                                                                          }" \
                                                                                                                          "$slack_webhook" >/dev/null 2>&1

                                                                                                                          log_success "Slack notification sent"
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
                                                                                                                                  -v|--verbose)
                                                                                                                                    VERBOSE=true
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

# Validate root access
                                                                                                                                        if [[ $EUID -ne 0 ]]; then
                                                                                                                                          log_error "This script must be run as root"
                                                                                                                                          exit 1
                                                                                                                                        fi

# Initialize
                                                                                                                                        mkdir -p "$REPORT_DIR"

                                                                                                                                        log_info "Starting Universal Linux Patcher v${SCRIPT_VERSION}"
                                                                                                                                        log_info "Report directory: $REPORT_DIR"

# Execute workflow
                                                                                                                                        detect_linux_environment
                                                                                                                                        update_package_cache
                                                                                                                                        check_universal_updates

                                                                                                                                        if [[ $DRY_RUN == false ]]; then
                                                                                                                                          apply_universal_updates
                                                                                                                                        fi

                                                                                                                                        generate_universal_reports
                                                                                                                                        send_notifications

# Final status
                                                                                                                                        echo -e "\n${GREEN}${BOLD} Universal Linux Patching Complete!${NC}"
                                                                                                                                        echo -e " Distribution: ${BLUE}${DISTRO} ${VERSION}${NC}"
                                                                                                                                        echo -e " Package Manager: ${BLUE}${PKG_MANAGER}${NC}"
                                                                                                                                        echo -e " Updates: ${GREEN}${UPDATE_COUNT}${NC} total, ${YELLOW}${SECURITY_COUNT}${NC} security"
                                                                                                                                        echo -e " Reboot: $([ $REBOOT_REQUIRED == true ] && echo -e "${RED}Required${NC}" || echo -e "${GREEN}Not Required${NC}")"
                                                                                                                                        echo -e " Reports: ${BLUE}${REPORT_DIR}${NC}"
                                                                                                                                      }

# Execute main function
                                                                                                                                      main "$@"
