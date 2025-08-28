#!/bin/bash
# kpatch-manager.sh
# Live kernel patching management script for RHEL systems
# Compatible with: RHEL 7, 8, 9, 10 with kpatch support
# Author: sgallego
# Version: 2.0.0
# Date: 2024-08-27

set -euo pipefail

# Script configuration
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="kpatch-manager"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  REPORT_DIR="/tmp/kpatch_reports_${TIMESTAMP}"
  ACTION="status" # status, install, remove, list, auto
  PATCH_ID=""
  VERBOSE=false

# Color codes
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
  BOLD='\033[1m'

# Logging
  log() {
    local level=$1
    shift
    mkdir -p "$REPORT_DIR"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "${REPORT_DIR}/kpatch-${TIMESTAMP}.log"
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
    ${BOLD}Live Kernel Patch Manager v${SCRIPT_VERSION}${NC}
    Enterprise kpatch management for RHEL 7-10 systems

      ${BOLD}USAGE:${NC}
      $0 [ACTION] [OPTIONS]

      ${BOLD}ACTIONS:${NC}
      status Show current kpatch status
      list List available patches
      install PATCH_ID Install specific patch
      remove PATCH_ID Remove specific patch
      auto Auto-install available patches
      report Generate comprehensive report

      ${BOLD}OPTIONS:${NC}
      -h, --help Show this help
      -v, --verbose Verbose output
      -o, --output DIR Custom report directory
      --email EMAIL Email report
      --force Force operation

      ${BOLD}EXAMPLES:${NC}
# Check kpatch status
      $0 status --verbose

# List available patches
      $0 list

# Auto-install available patches
      $0 auto --email admin@company.com

# Generate comprehensive report
      $0 report --output /opt/reports

      EOF
    }

# Detect RHEL environment for kpatch
    detect_kpatch_environment() {
      log_info "Detecting kpatch environment..."

# Check if RHEL family
      if [[ ! -f /etc/redhat-release ]]; then
        log_error "kpatch is only supported on RHEL family systems"
        exit 1
      fi

# Get RHEL version
      RHEL_VERSION=$(rpm -q --queryformat '%{VERSION}' redhat-release-server 2>/dev/null || \
      grep -oP '(?<=release )[0-9]+' /etc/redhat-release)
        RHEL_MAJOR=${RHEL_VERSION%%.*}

# Validate kpatch support
        case $RHEL_MAJOR in
        7|8|9|10)
          log_success "RHEL $RHEL_MAJOR detected - kpatch supported"
          ;;
          *)
            log_error "RHEL $RHEL_MAJOR - kpatch support unknown"
            exit 1
            ;;
          esac

# Check if kpatch is installed
          if ! command -v kpatch >/dev/null 2>&1; then
            log_warn "kpatch not installed - installing..."
            if command -v dnf >/dev/null 2>&1; then
              dnf install -y kpatch
            else
              yum install -y kpatch
            fi
          fi

# Check if kpatch service is running
          if ! systemctl is-active --quiet kpatch; then
            log_info "Starting kpatch service..."
            systemctl enable --now kpatch
          fi

          export RHEL_VERSION RHEL_MAJOR
        }

# Get kpatch status
        get_kpatch_status() {
          log_info "Checking kpatch status..."

# Service status
          local service_status=$(systemctl is-active kpatch 2>/dev/null || echo "inactive")
            local service_enabled=$(systemctl is-enabled kpatch 2>/dev/null || echo "disabled")

# Loaded patches
              local loaded_patches=$(kpatch list 2>/dev/null | grep -c "^" || echo "0")

# Available patches
                local available_patches
                if command -v dnf >/dev/null 2>&1; then
                  available_patches=$(dnf list available kpatch-patch-* 2>/dev/null | grep -c "^kpatch-patch" || echo "0")
                  else
                    available_patches=$(yum list available kpatch-patch-* 2>/dev/null | grep -c "^kpatch-patch" || echo "0")
                    fi

                    log_info "Service Status: $service_status"
                    log_info "Loaded Patches: $loaded_patches"
                    log_info "Available Patches: $available_patches"

                    export KPATCH_SERVICE_STATUS=$service_status
                    export KPATCH_LOADED_PATCHES=$loaded_patches
                    export KPATCH_AVAILABLE_PATCHES=$available_patches
                  }

# List available kpatches
                  list_available_patches() {
                    log_info "Listing available kpatches..."

                    local patch_list="${REPORT_DIR}/available-kpatches-${TIMESTAMP}.txt"

                    if command -v dnf >/dev/null 2>&1; then
                      dnf list available kpatch-patch-* > "$patch_list" 2>/dev/null || true
                    else
                      yum list available kpatch-patch-* > "$patch_list" 2>/dev/null || true
                    fi

                    if [[ -s $patch_list ]]; then
                      log_success "Available patches listed in: $patch_list"
                      [[ $VERBOSE == true ]] && cat "$patch_list"
                    else
                      log_info "No kpatches available for current kernel"
                      fi
                    }

# Auto-install available patches
                    auto_install_patches() {
                      log_info "Auto-installing available kpatches..."

                      local install_count=0

# Get list of available patches
                      local patch_packages
                      if command -v dnf >/dev/null 2>&1; then
                        patch_packages=$(dnf list available kpatch-patch-* 2>/dev/null | grep "^kpatch-patch" | awk '{print $1}' || true)
                        else
                          patch_packages=$(yum list available kpatch-patch-* 2>/dev/null | grep "^kpatch-patch" | awk '{print $1}' || true)
                          fi

                          if [[ -n $patch_packages ]]; then
                            for patch in $patch_packages; do
                              log_info "Installing kpatch: $patch"

                              if command -v dnf >/dev/null 2>&1; then
                                dnf install -y "$patch"
                              else
                                yum install -y "$patch"
                              fi

                              ((install_count++))
                                log_success "Installed: $patch"
                              done

# Load patches
                              systemctl restart kpatch
                              log_success "Auto-installed $install_count kpatches"
                            else
                              log_info "No kpatches available for auto-installation"
                              fi

                              export KPATCH_INSTALLED=$install_count
                            }

# Generate kpatch report
                            generate_kpatch_report() {
                              log_info "Generating kpatch report..."

                              local hostname=$(hostname -f)
                                local kernel_version=$(uname -r)

# JSON Report
                                  cat > "${REPORT_DIR}/kpatch-report-${hostname}-${TIMESTAMP}.json" << EOF
                                  {
                                    "metadata": {
                                      "script_name": "${SCRIPT_NAME}",
                                      "version": "${SCRIPT_VERSION}",
                                      "hostname": "${hostname}",
                                      "timestamp": "$(date -Iseconds)",
                                      "report_id": "${hostname}-${TIMESTAMP}"
                                    },
                                    "system_info": {
                                      "distribution": "$(cat /etc/redhat-release)",
                                      "rhel_version": "${RHEL_VERSION}",
                                      "kernel_version": "${kernel_version}",
                                      "architecture": "$(uname -m)"
                                    },
                                    "kpatch_status": {
                                      "service_status": "${KPATCH_SERVICE_STATUS}",
                                      "loaded_patches": ${KPATCH_LOADED_PATCHES},
                                      "available_patches": ${KPATCH_AVAILABLE_PATCHES},
                                      "patches_installed_this_run": ${KPATCH_INSTALLED:-0}
                                    },
                                    "loaded_patches": $(kpatch list 2>/dev/null | jq -R . | jq -s . || echo '[]'),
                                    "recommendations": "$([ ${KPATCH_AVAILABLE_PATCHES} -gt 0 ] && echo "Install available kpatches to avoid reboot" || echo "System up to date with live patches")"
                                  }
                                  EOF

                                  log_success "kpatch report generated"
                                }

# Main execution
                                main() {
# Parse arguments
                                  if [[ $# -eq 0 ]]; then
                                    ACTION="status"
                                  else
                                    ACTION="$1"
                                    shift
                                  fi

                                  while [[ $# -gt 0 ]]; do
                                    case $1 in
                                    -h|--help) show_help; exit 0 ;;
                                    -v|--verbose) VERBOSE=true; shift ;;
                                    -o|--output) REPORT_DIR="$2"; shift 2 ;;
                                    --email) EMAIL_ADDRESS="$2"; shift 2 ;;
                                    --force) FORCE=true; shift ;;
                                    *) PATCH_ID="$1"; shift ;;
                                  esac
                                done

# Validate root
                                if [[ $EUID -ne 0 ]]; then
                                  log_error "This script must be run as root"
                                  exit 1
                                fi

                                log_info "Starting kpatch manager v${SCRIPT_VERSION}"

                                detect_kpatch_environment
                                get_kpatch_status

# Execute action
                                case $ACTION in
                                status)
                                  echo -e "\n${GREEN}${BOLD} kpatch Status${NC}"
                                  echo -e "Service: ${KPATCH_SERVICE_STATUS}"
                                  echo -e "Loaded Patches: ${KPATCH_LOADED_PATCHES}"
                                  echo -e "Available Patches: ${KPATCH_AVAILABLE_PATCHES}"
                                  ;;
                                  list)
                                    list_available_patches
                                    ;;
                                    auto)
                                      auto_install_patches
                                      ;;
                                      report)
                                        generate_kpatch_report
                                        ;;
                                        *)
                                          log_error "Unknown action: $ACTION"
                                          show_help
                                          exit 1
                                          ;;
                                        esac

                                        [[ $ACTION == "report" || $ACTION == "auto" ]] && generate_kpatch_report
                                        [[ -n ${EMAIL_ADDRESS:-} ]] && echo "kpatch report attached" | mail -s "[kpatch] Live Kernel Patch Report" "$EMAIL_ADDRESS"

                                        log_success "kpatch manager completed"
                                      }

                                      main "$@"
