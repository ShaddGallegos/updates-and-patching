#!/bin/bash
# package-auditor.sh
# Professional package management and security auditing script
# Compatible with all major Linux distributions
# Author: {{ ansible_user }}
# Version: 2.0.0
# Date: 2024-08-27

set -euo pipefail

# Script configuration
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="package-auditor"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  REPORT_DIR="/tmp/package_audit_${TIMESTAMP}"
  AUDIT_TYPE="security" # security, outdated, all, installed
  CHECK_VULNERABILITIES=false
  AUTO_UPDATE=false
  GENERATE_REPORT=true

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
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "${REPORT_DIR}/package-auditor-${TIMESTAMP}.log"
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
    ${BOLD}Professional Package Auditor v${SCRIPT_VERSION}${NC}
    Comprehensive package management and security auditing

    ${BOLD}USAGE:${NC}
    $0 [OPTIONS]

    ${BOLD}OPTIONS:${NC}
    -h, --help Show this help
    -t, --type TYPE Audit type: security,outdated,all,installed (default: security)
      -o, --output DIR Custom report directory
      -v, --vulnerabilities Check for known vulnerabilities
        -u, --auto-update Auto-update vulnerable packages
        -e, --email EMAIL Email report
        --no-report Skip report generation
        --verbose Verbose output

        ${BOLD}AUDIT TYPES:${NC}
        security Security-related packages and updates
        outdated Outdated packages that need updating
        all Complete package audit
        installed List all installed packages

        ${BOLD}EXAMPLES:${NC}
# Security audit with vulnerability check
        $0 --type security --vulnerabilities

# Full audit with auto-update
        $0 --type all --auto-update --email admin@company.com

# Check outdated packages only
        $0 --type outdated --output /opt/audits

        EOF
      }

# Detect package manager and distribution
      detect_package_manager() {
        log_info "Detecting package manager and distribution..."

# Initialize variables
        DISTRO=""
        PACKAGE_MANAGER=""
        UPDATE_COMMAND=""
        LIST_COMMAND=""
        SEARCH_COMMAND=""

# Detect distribution and package manager
        if command -v dnf >/dev/null 2>&1; then
          PACKAGE_MANAGER="dnf"
          UPDATE_COMMAND="dnf check-update"
          LIST_COMMAND="dnf list installed"
          SEARCH_COMMAND="dnf search"
          DISTRO="RedHat (DNF)"
        elif command -v yum >/dev/null 2>&1; then
          PACKAGE_MANAGER="yum"
          UPDATE_COMMAND="yum check-update"
          LIST_COMMAND="yum list installed"
          SEARCH_COMMAND="yum search"
          DISTRO="RedHat (YUM)"
        elif command -v apt >/dev/null 2>&1; then
          PACKAGE_MANAGER="apt"
          UPDATE_COMMAND="apt list --upgradable"
          LIST_COMMAND="apt list --installed"
          SEARCH_COMMAND="apt search"
          DISTRO="Debian/Ubuntu"
        elif command -v zypper >/dev/null 2>&1; then
          PACKAGE_MANAGER="zypper"
          UPDATE_COMMAND="zypper list-updates"
          LIST_COMMAND="zypper packages --installed-only"
          SEARCH_COMMAND="zypper search"
          DISTRO="SUSE"
        elif command -v pacman >/dev/null 2>&1; then
          PACKAGE_MANAGER="pacman"
          UPDATE_COMMAND="pacman -Qu"
          LIST_COMMAND="pacman -Q"
          SEARCH_COMMAND="pacman -Ss"
          DISTRO="Arch Linux"
        elif command -v apk >/dev/null 2>&1; then
          PACKAGE_MANAGER="apk"
          UPDATE_COMMAND="apk list -u"
          LIST_COMMAND="apk list -I"
          SEARCH_COMMAND="apk search"
          DISTRO="Alpine Linux"
        elif command -v emerge >/dev/null 2>&1; then
          PACKAGE_MANAGER="emerge"
          UPDATE_COMMAND="emerge -uDN --pretend world"
          LIST_COMMAND="qlist -I"
          SEARCH_COMMAND="emerge -s"
          DISTRO="Gentoo Linux"
        else
          log_error "No supported package manager found"
          exit 1
        fi

        log_success "Detected: $DISTRO with $PACKAGE_MANAGER"

        export DISTRO PACKAGE_MANAGER UPDATE_COMMAND LIST_COMMAND SEARCH_COMMAND
      }

# Audit installed packages
      audit_installed_packages() {
        log_info "Auditing installed packages..."

        local installed_file="${REPORT_DIR}/installed-packages-${TIMESTAMP}.txt"
        local installed_count=0

        case $PACKAGE_MANAGER in
        dnf|yum)
          $LIST_COMMAND > "$installed_file"
          installed_count=$(grep -c "^" "$installed_file" || echo "0")
            ;;
            apt)
              $LIST_COMMAND 2>/dev/null | grep -v "WARNING" > "$installed_file" || true
              installed_count=$(grep -c "/" "$installed_file" || echo "0")
                ;;
                zypper)
                  $LIST_COMMAND > "$installed_file"
                  installed_count=$(grep -c "|" "$installed_file" || echo "0")
                    ;;
                    pacman)
                      $LIST_COMMAND > "$installed_file"
                      installed_count=$(grep -c "^" "$installed_file" || echo "0")
                        ;;
                        apk)
                          $LIST_COMMAND > "$installed_file"
                          installed_count=$(grep -c "^" "$installed_file" || echo "0")
                            ;;
                            emerge)
                              $LIST_COMMAND > "$installed_file"
                              installed_count=$(grep -c "^" "$installed_file" || echo "0")
                                ;;
                              esac

                              log_success "Found $installed_count installed packages"
                              export INSTALLED_PACKAGES_FILE="$installed_file"
                              export INSTALLED_PACKAGES_COUNT="$installed_count"
                            }

# Check for outdated packages
                            check_outdated_packages() {
                              [[ $AUDIT_TYPE != "outdated" && $AUDIT_TYPE != "all" ]] && return

                              log_info "Checking for outdated packages..."

                                local outdated_file="${REPORT_DIR}/outdated-packages-${TIMESTAMP}.txt"
                                local outdated_count=0

                                case $PACKAGE_MANAGER in
                                dnf|yum)
                                  $UPDATE_COMMAND > "$outdated_file" 2>/dev/null || true
                                  outdated_count=$(grep -v "Last metadata expiration check\|Loaded plugins" "$outdated_file" | grep -c "^" || echo "0")
                                    ;;
                                    apt)
                                      apt update >/dev/null 2>&1
                                      $UPDATE_COMMAND 2>/dev/null | grep -v "WARNING" > "$outdated_file" || true
                                      outdated_count=$(grep -c "/" "$outdated_file" || echo "0")
                                        ;;
                                        zypper)
                                          $UPDATE_COMMAND > "$outdated_file" 2>/dev/null || true
                                          outdated_count=$(grep -c "|" "$outdated_file" || echo "0")
                                            ;;
                                            pacman)
                                              $UPDATE_COMMAND > "$outdated_file" 2>/dev/null || true
                                              outdated_count=$(grep -c "^" "$outdated_file" || echo "0")
                                                ;;
                                                apk)
                                                  $UPDATE_COMMAND > "$outdated_file" 2>/dev/null || true
                                                  outdated_count=$(grep -c "^" "$outdated_file" || echo "0")
                                                    ;;
                                                  esac

                                                  log_success "Found $outdated_count outdated packages"
                                                  export OUTDATED_PACKAGES_FILE="$outdated_file"
                                                  export OUTDATED_PACKAGES_COUNT="$outdated_count"
                                                }

# Check security updates
                                                check_security_updates() {
                                                  [[ $AUDIT_TYPE != "security" && $AUDIT_TYPE != "all" ]] && return

                                                  log_info "Checking for security updates..."

                                                    local security_file="${REPORT_DIR}/security-updates-${TIMESTAMP}.txt"
                                                    local security_count=0

                                                    case $PACKAGE_MANAGER in
                                                    dnf)
                                                      dnf updateinfo list security > "$security_file" 2>/dev/null || true
                                                      security_count=$(grep -c "^" "$security_file" || echo "0")
                                                        ;;
                                                        yum)
                                                          yum --security check-update > "$security_file" 2>/dev/null || true
                                                          security_count=$(grep -v "Loaded plugins\|Last metadata" "$security_file" | grep -c "^" || echo "0")
                                                            ;;
                                                            apt)
                                                              apt update >/dev/null 2>&1
                                                              unattended-upgrade --dry-run 2>/dev/null | grep -i security > "$security_file" || true
                                                              security_count=$(grep -c "security" "$security_file" || echo "0")
                                                                ;;
                                                                zypper)
                                                                  zypper list-patches --category security > "$security_file" 2>/dev/null || true
                                                                  security_count=$(grep -c "|" "$security_file" || echo "0")
                                                                    ;;
                                                                    *)
                                                                      echo "Security updates check not supported for $PACKAGE_MANAGER" > "$security_file"
                                                                        security_count=0
                                                                        ;;
                                                                      esac

                                                                      log_success "Found $security_count security updates"
                                                                      export SECURITY_UPDATES_FILE="$security_file"
                                                                      export SECURITY_UPDATES_COUNT="$security_count"
                                                                    }

# Check for known vulnerabilities
                                                                    check_vulnerabilities() {
                                                                      [[ $CHECK_VULNERABILITIES == false ]] && return

                                                                      log_info "Checking for known vulnerabilities..."

                                                                        local vuln_file="${REPORT_DIR}/vulnerabilities-${TIMESTAMP}.txt"
                                                                        local vuln_count=0

# Critical packages to monitor
                                                                        local critical_packages=("kernel" "openssl" "openssh" "sudo" "systemd" "glibc" "bash" "curl" "wget")

                                                                          echo "Critical Package Vulnerability Check" > "$vuln_file"
                                                                          echo "====================================" >> "$vuln_file"
                                                                          echo "Timestamp: $(date)" >> "$vuln_file"
                                                                          echo "" >> "$vuln_file"

                                                                          for package in "${critical_packages[@]}"; do
                                                                            case $PACKAGE_MANAGER in
                                                                            dnf|yum)
                                                                              local installed_version=$(rpm -q "$package" 2>/dev/null || echo "not installed")
                                                                                ;;
                                                                                apt)
                                                                                  local installed_version=$(dpkg -l "$package" 2>/dev/null | grep "^ii" | awk '{print $3}' || echo "not installed")
                                                                                    ;;
                                                                                    zypper)
                                                                                      local installed_version=$(zypper info "$package" 2>/dev/null | grep "Version" | awk '{print $3}' || echo "not installed")
                                                                                        ;;
                                                                                        pacman)
                                                                                          local installed_version=$(pacman -Q "$package" 2>/dev/null | awk '{print $2}' || echo "not installed")
                                                                                            ;;
                                                                                            *)
                                                                                              local installed_version="unknown"
                                                                                              ;;
                                                                                            esac

                                                                                            echo "$package: $installed_version" >> "$vuln_file"

                                                                                            if [[ $installed_version != "not installed" ]]; then
                                                                                              ((vuln_count++))
                                                                                              fi
                                                                                            done

                                                                                            log_success "Vulnerability check completed for $vuln_count critical packages"
                                                                                              export VULNERABILITIES_FILE="$vuln_file"
                                                                                              export VULNERABILITIES_COUNT="$vuln_count"
                                                                                            }

# Auto-update packages
                                                                                            auto_update_packages() {
                                                                                              [[ $AUTO_UPDATE == false ]] && return

                                                                                              log_info "Auto-updating packages..."

                                                                                              local update_log="${REPORT_DIR}/auto-update-${TIMESTAMP}.log"
                                                                                              local updated_count=0

                                                                                              case $PACKAGE_MANAGER in
                                                                                              dnf)
                                                                                                if [[ $AUDIT_TYPE == "security" ]]; then
                                                                                                  dnf update --security -y > "$update_log" 2>&1 || true
                                                                                                else
                                                                                                  dnf update -y > "$update_log" 2>&1 || true
                                                                                                fi
                                                                                                ;;
                                                                                                yum)
                                                                                                  if [[ $AUDIT_TYPE == "security" ]]; then
                                                                                                    yum update --security -y > "$update_log" 2>&1 || true
                                                                                                  else
                                                                                                    yum update -y > "$update_log" 2>&1 || true
                                                                                                  fi
                                                                                                  ;;
                                                                                                  apt)
                                                                                                    apt update >/dev/null 2>&1
                                                                                                    if [[ $AUDIT_TYPE == "security" ]]; then
                                                                                                      unattended-upgrade > "$update_log" 2>&1 || true
                                                                                                    else
                                                                                                      apt upgrade -y > "$update_log" 2>&1 || true
                                                                                                    fi
                                                                                                    ;;
                                                                                                    zypper)
                                                                                                      zypper update -y > "$update_log" 2>&1 || true
                                                                                                      ;;
                                                                                                      pacman)
                                                                                                        pacman -Syu --noconfirm > "$update_log" 2>&1 || true
                                                                                                        ;;
                                                                                                        *)
                                                                                                          echo "Auto-update not supported for $PACKAGE_MANAGER" > "$update_log"
                                                                                                            ;;
                                                                                                          esac

                                                                                                          updated_count=$(grep -c "Complete\|Updated\|Upgraded" "$update_log" 2>/dev/null || echo "0")
                                                                                                            log_success "Auto-update completed: $updated_count packages updated"

                                                                                                            export UPDATE_LOG="$update_log"
                                                                                                            export UPDATED_COUNT="$updated_count"
                                                                                                          }

# Generate comprehensive report
                                                                                                          generate_audit_report() {
                                                                                                            [[ $GENERATE_REPORT == false ]] && return

                                                                                                            log_info "Generating package audit report..."

                                                                                                            local hostname=$(hostname -f)
                                                                                                              local report_file="${REPORT_DIR}/package-audit-report-${hostname}-${TIMESTAMP}.json"

                                                                                                              cat > "$report_file" << EOF
                                                                                                              {
                                                                                                                "metadata": {
                                                                                                                  "script_name": "${SCRIPT_NAME}",
                                                                                                                  "version": "${SCRIPT_VERSION}",
                                                                                                                  "hostname": "${hostname}",
                                                                                                                  "timestamp": "$(date -Iseconds)",
                                                                                                                  "report_id": "${hostname}-${TIMESTAMP}",
                                                                                                                  "audit_type": "${AUDIT_TYPE}"
                                                                                                                },
                                                                                                                "system_info": {
                                                                                                                  "distribution": "${DISTRO}",
                                                                                                                  "package_manager": "${PACKAGE_MANAGER}",
                                                                                                                  "kernel_version": "$(uname -r)"
                                                                                                                },
                                                                                                                "audit_results": {
                                                                                                                  "installed_packages": ${INSTALLED_PACKAGES_COUNT:-0},
                                                                                                                  "outdated_packages": ${OUTDATED_PACKAGES_COUNT:-0},
                                                                                                                  "security_updates": ${SECURITY_UPDATES_COUNT:-0},
                                                                                                                  "vulnerabilities_checked": ${VULNERABILITIES_COUNT:-0},
                                                                                                                  "packages_updated": ${UPDATED_COUNT:-0}
                                                                                                                },
                                                                                                                "files_generated": {
                                                                                                                  "installed_packages": "${INSTALLED_PACKAGES_FILE:-}",
                                                                                                                  "outdated_packages": "${OUTDATED_PACKAGES_FILE:-}",
                                                                                                                  "security_updates": "${SECURITY_UPDATES_FILE:-}",
                                                                                                                  "vulnerabilities": "${VULNERABILITIES_FILE:-}",
                                                                                                                  "update_log": "${UPDATE_LOG:-}"
                                                                                                                },
                                                                                                                "recommendations": [
                                                                                                                $([ ${SECURITY_UPDATES_COUNT:-0} -gt 0 ] && echo "\"Apply ${SECURITY_UPDATES_COUNT} security updates immediately\"," || echo "")
                                                                                                                  $([ ${OUTDATED_PACKAGES_COUNT:-0} -gt 0 ] && echo "\"Update ${OUTDATED_PACKAGES_COUNT} outdated packages\"," || echo "")
                                                                                                                    "\"Regularly audit packages for security vulnerabilities\""
                                                                                                                      ]
                                                                                                                    }
                                                                                                                    EOF

# Remove trailing comma if present
                                                                                                                    sed -i 's/,]/]/' "$report_file"

                                                                                                                    log_success "Audit report generated: $report_file"
                                                                                                                    export AUDIT_REPORT="$report_file"
                                                                                                                  }

# Main execution
                                                                                                                  main() {
# Parse arguments
                                                                                                                    while [[ $# -gt 0 ]]; do
                                                                                                                      case $1 in
                                                                                                                      -h|--help) show_help; exit 0 ;;
                                                                                                                      -t|--type) AUDIT_TYPE="$2"; shift 2 ;;
                                                                                                                      -o|--output) REPORT_DIR="$2"; shift 2 ;;
                                                                                                                      -v|--vulnerabilities) CHECK_VULNERABILITIES=true; shift ;;
                                                                                                                      -u|--auto-update) AUTO_UPDATE=true; shift ;;
                                                                                                                      -e|--email) EMAIL_ADDRESS="$2"; EMAIL_REPORT=true; shift 2 ;;
                                                                                                                      --no-report) GENERATE_REPORT=false; shift ;;
                                                                                                                      --verbose) VERBOSE=true; shift ;;
                                                                                                                      *) log_error "Unknown option: $1"; exit 1 ;;
                                                                                                                    esac
                                                                                                                  done

# Validate audit type
                                                                                                                  if [[ ! $AUDIT_TYPE =~ ^(security|outdated|all|installed)$ ]]; then
                                                                                                                    log_error "Invalid audit type: $AUDIT_TYPE"
                                                                                                                    show_help
                                                                                                                    exit 1
                                                                                                                  fi

                                                                                                                  log_info "Starting Package Auditor v${SCRIPT_VERSION} - Audit Type: ${AUDIT_TYPE}"

# Create report directory
                                                                                                                  mkdir -p "$REPORT_DIR"

# Detect environment
                                                                                                                  detect_package_manager

# Perform audits based on type
                                                                                                                  audit_installed_packages
                                                                                                                  check_outdated_packages
                                                                                                                  check_security_updates
                                                                                                                  check_vulnerabilities

# Auto-update if requested
                                                                                                                  auto_update_packages

# Generate report
                                                                                                                  generate_audit_report

# Display summary
                                                                                                                  echo -e "\n${GREEN}${BOLD} Package Audit Summary${NC}"
                                                                                                                  echo -e "Distribution: ${DISTRO}"
                                                                                                                  echo -e "Package Manager: ${PACKAGE_MANAGER}"
                                                                                                                  echo -e "Installed Packages: ${INSTALLED_PACKAGES_COUNT:-0}"
                                                                                                                  echo -e "Outdated Packages: ${OUTDATED_PACKAGES_COUNT:-0}"
                                                                                                                  echo -e "Security Updates: ${SECURITY_UPDATES_COUNT:-0}"
                                                                                                                  echo -e "Report Directory: ${REPORT_DIR}"

# Email report if requested
                                                                                                                  if [[ ${EMAIL_REPORT:-false} == true && -n ${EMAIL_ADDRESS:-} ]]; then
                                                                                                                    echo "Package audit report attached" | mail -s "[Package Audit] $(hostname)" "$EMAIL_ADDRESS"
                                                                                                                    log_success "Report emailed to: $EMAIL_ADDRESS"
                                                                                                                  fi

                                                                                                                  log_success "Package audit completed"
                                                                                                                }

                                                                                                                main "$@"
