#!/bin/bash
# automation-wrapper.sh
# Comprehensive automation wrapper for all patching and reporting tools
# Master script to orchestrate enterprise-grade system management
# Author: {{ ansible_user }}
# Version: 2.0.0
# Date: 2024-08-27

set -euo pipefail

# Script configuration
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="automation-wrapper"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  REPORT_DIR="/tmp/automation_reports_${TIMESTAMP}"
  WORKFLOW="standard" # standard, security, performance, comprehensive
  DRY_RUN=false
  VERBOSE=false

# Color codes
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  PURPLE='\033[0;35m'
  CYAN='\033[0;36m'
  NC='\033[0m'
  BOLD='\033[1m'

# Tool paths (relative to script directory)
  SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
    RHEL_PATCHER="${SCRIPT_DIR}/rhel-patch-manager.sh"
    UNIVERSAL_PATCHER="${SCRIPT_DIR}/linux-universal-patcher.sh"
    VULNERABILITY_SCANNER="${SCRIPT_DIR}/vulnerability-scanner.sh"
    KPATCH_MANAGER="${SCRIPT_DIR}/kpatch-manager.sh"
    SYSTEM_REPORTER="${SCRIPT_DIR}/system-reporter.sh"
    PACKAGE_AUDITOR="${SCRIPT_DIR}/package-auditor.sh"

# Logging
    log() {
      local level=$1
      shift
      mkdir -p "$REPORT_DIR"
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" | tee -a "${REPORT_DIR}/automation-wrapper-${TIMESTAMP}.log"
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

    log_workflow() {
      log "WORKFLOW" "$*"
      echo -e "${PURPLE}[WORKFLOW]${NC} $*"
    }

# Help function
    show_help() {
      cat << EOF
      ${BOLD}Enterprise Automation Wrapper v${SCRIPT_VERSION}${NC}
      Master orchestration script for system management automation

        ${BOLD}USAGE:${NC}
        $0 [WORKFLOW] [OPTIONS]

        ${BOLD}WORKFLOWS:${NC}
        standard Basic patching and reporting (default)
          security Security-focused audit and patching
          performance Performance analysis and optimization
          comprehensive Complete system analysis and management

          ${BOLD}OPTIONS:${NC}
          -h, --help Show this help
          -o, --output DIR Custom report directory
          -d, --dry-run Simulate operations without making changes
          -v, --verbose Verbose output
          -e, --email EMAIL Email consolidated report
          --sendgrid-key KEY SendGrid API key for email
            --force Force operations that normally require confirmation

            ${BOLD}WORKFLOW DESCRIPTIONS:${NC}

            ${BOLD}standard${NC}
            - System information report
            - Package audit (installed packages)
              - Basic security updates check
              - Consolidated reporting

              ${BOLD}security${NC}
              - Vulnerability scanning (current CVEs)
                - Security updates detection and installation
                - Live kernel patching (RHEL systems)
                  - Security-focused system audit
                  - Compliance reporting

                  ${BOLD}performance${NC}
                  - Performance metrics collection
                  - Resource utilization analysis
                  - Process monitoring
                  - Performance optimization recommendations

                  ${BOLD}comprehensive${NC}
                  - All standard workflow components
                  - Complete security analysis
                  - Performance monitoring
                  - Package management audit
                  - Live kernel patching
                  - Multi-format reporting
                  - Professional documentation

                  ${BOLD}EXAMPLES:${NC}
# Standard workflow
                  $0 standard --email admin@company.com

# Security-focused automation
                  $0 security --verbose --output /opt/security-reports

# Comprehensive analysis (dry run)
                  $0 comprehensive --dry-run --verbose

# Performance analysis
                  $0 performance --email devops@company.com

                  EOF
                }

# Validate environment and tools
                validate_environment() {
                  log_info "Validating automation environment..."

# Check if running as root (required for most operations)
                  if [[ $EUID -ne 0 && $DRY_RUN == false ]]; then
                    log_warn "Not running as root - some operations may fail"
                  fi

# Validate required tools exist
                  local missing_tools=()

                    for tool in "$RHEL_PATCHER" "$UNIVERSAL_PATCHER" "$VULNERABILITY_SCANNER" "$KPATCH_MANAGER" "$SYSTEM_REPORTER" "$PACKAGE_AUDITOR"; do
                      if [[ ! -f "$tool" ]]; then
                        missing_tools+=("$(basename "$tool")")
                        fi
                      done

                      if [[ ${#missing_tools[@]} -gt 0 ]]; then
                        log_error "Missing required tools: ${missing_tools[*]}"
                        log_error "Ensure all scripts are in the same directory: $SCRIPT_DIR"
                        exit 1
                      fi

# Make tools executable
                      chmod +x "$RHEL_PATCHER" "$UNIVERSAL_PATCHER" "$VULNERABILITY_SCANNER"
                      chmod +x "$KPATCH_MANAGER" "$SYSTEM_REPORTER" "$PACKAGE_AUDITOR"

# Detect distribution for workflow planning
                      if [[ -f /etc/redhat-release ]]; then
                        DISTRO_FAMILY="RedHat"
                        PRIMARY_PATCHER="$RHEL_PATCHER"
                      else
                        DISTRO_FAMILY="Other"
                        PRIMARY_PATCHER="$UNIVERSAL_PATCHER"
                      fi

                      log_success "Environment validation completed"
                      export DISTRO_FAMILY PRIMARY_PATCHER
                    }

# Execute standard workflow
                    run_standard_workflow() {
                      log_workflow "Executing Standard Workflow"

# 1. System reporting
                      log_info "Step 1: System information collection"
                      if [[ $DRY_RUN == false ]]; then
                        "$SYSTEM_REPORTER" --output "$REPORT_DIR" --format json
                      else
                        log_info "[DRY RUN] Would run system reporter"
                      fi

# 2. Package audit
                      log_info "Step 2: Package audit"
                      if [[ $DRY_RUN == false ]]; then
                        "$PACKAGE_AUDITOR" --type installed --output "$REPORT_DIR"
                      else
                        log_info "[DRY RUN] Would run package auditor"
                      fi

# 3. Basic security check
                      log_info "Step 3: Security updates check"
                      if [[ $DRY_RUN == false ]]; then
                        "$PRIMARY_PATCHER" --check-only --output "$REPORT_DIR" --format json
                      else
                        log_info "[DRY RUN] Would check for security updates"
                        fi

                        log_success "Standard workflow completed"
                      }

# Execute security workflow
                      run_security_workflow() {
                        log_workflow "Executing Security Workflow"

# 1. Vulnerability scanning
                        log_info "Step 1: Vulnerability scanning"
                        if [[ $DRY_RUN == false ]]; then
                          "$VULNERABILITY_SCANNER" --scan --fix --output "$REPORT_DIR" --format json
                        else
                          log_info "[DRY RUN] Would run vulnerability scanner"
                        fi

# 2. Security updates
                        log_info "Step 2: Security patching"
                        if [[ $DRY_RUN == false ]]; then
                          "$PRIMARY_PATCHER" --security-only --output "$REPORT_DIR" --format json
                        else
                          log_info "[DRY RUN] Would apply security patches"
                        fi

# 3. Live kernel patching (RHEL only)
                        if [[ $DISTRO_FAMILY == "RedHat" ]]; then
                          log_info "Step 3: Live kernel patching"
                          if [[ $DRY_RUN == false ]]; then
                            "$KPATCH_MANAGER" auto --output "$REPORT_DIR"
                          else
                            log_info "[DRY RUN] Would manage kpatches"
                          fi
                        fi

# 4. Security audit
                        log_info "Step 4: Security package audit"
                        if [[ $DRY_RUN == false ]]; then
                          "$PACKAGE_AUDITOR" --type security --vulnerabilities --output "$REPORT_DIR"
                        else
                          log_info "[DRY RUN] Would run security audit"
                        fi

                        log_success "Security workflow completed"
                      }

# Execute performance workflow
                      run_performance_workflow() {
                        log_workflow "Executing Performance Workflow"

# 1. System performance reporting
                        log_info "Step 1: Performance metrics collection"
                        if [[ $DRY_RUN == false ]]; then
                          "$SYSTEM_REPORTER" --performance --output "$REPORT_DIR" --format all
                        else
                          log_info "[DRY RUN] Would collect performance metrics"
                        fi

# 2. Package performance analysis
                        log_info "Step 2: Package performance audit"
                        if [[ $DRY_RUN == false ]]; then
                          "$PACKAGE_AUDITOR" --type all --output "$REPORT_DIR"
                        else
                          log_info "[DRY RUN] Would analyze package performance"
                        fi

                        log_success "Performance workflow completed"
                      }

# Execute comprehensive workflow
                      run_comprehensive_workflow() {
                        log_workflow "Executing Comprehensive Workflow"

# Run all workflows
                        run_security_workflow
                        run_performance_workflow

# Additional comprehensive reporting
                        log_info "Generating comprehensive system analysis"
                        if [[ $DRY_RUN == false ]]; then
                          "$SYSTEM_REPORTER" --performance --security --output "$REPORT_DIR" --format all
                        else
                          log_info "[DRY RUN] Would generate comprehensive report"
                        fi

                        log_success "Comprehensive workflow completed"
                      }

# Generate consolidated report
                      generate_consolidated_report() {
                        log_info "Generating consolidated automation report..."

                        local hostname=$(hostname -f)
                          local consolidated_file="${REPORT_DIR}/consolidated-automation-report-${hostname}-${TIMESTAMP}.json"

                          cat > "$consolidated_file" << EOF
                          {
                            "metadata": {
                              "script_name": "${SCRIPT_NAME}",
                              "version": "${SCRIPT_VERSION}",
                              "hostname": "${hostname}",
                              "timestamp": "$(date -Iseconds)",
                              "report_id": "${hostname}-${TIMESTAMP}",
                              "workflow_executed": "${WORKFLOW}",
                              "dry_run": ${DRY_RUN}
                            },
                            "system_summary": {
                              "distribution_family": "${DISTRO_FAMILY}",
                              "primary_patcher": "$(basename "$PRIMARY_PATCHER")",
                              "tools_executed": [
                              $(find "$REPORT_DIR" -name "*.json" -type f | wc -l) "tools generated reports"
                              ]
                            },
                            "workflow_results": {
                              "standard_executed": $([ "$WORKFLOW" == "standard" ] || [ "$WORKFLOW" == "comprehensive" ] && echo "true" || echo "false"),
                              "security_executed": $([ "$WORKFLOW" == "security" ] || [ "$WORKFLOW" == "comprehensive" ] && echo "true" || echo "false"),
                              "performance_executed": $([ "$WORKFLOW" == "performance" ] || [ "$WORKFLOW" == "comprehensive" ] && echo "true" || echo "false")
                              },
                              "report_location": "${REPORT_DIR}",
                              "recommendations": [
                              "Review individual tool reports for detailed analysis",
                                "Schedule regular automation runs for proactive maintenance",
                                  "Monitor security updates and apply promptly"
                                  ]
                                }
                                EOF

                                log_success "Consolidated report generated: $consolidated_file"
                                export CONSOLIDATED_REPORT="$consolidated_file"
                              }

# Main execution
                              main() {
# Parse arguments
                                if [[ $# -gt 0 && ! $1 =~ ^- ]]; then
                                  WORKFLOW="$1"
                                  shift
                                fi

                                while [[ $# -gt 0 ]]; do
                                  case $1 in
                                  -h|--help) show_help; exit 0 ;;
                                  -o|--output) REPORT_DIR="$2"; shift 2 ;;
                                  -d|--dry-run) DRY_RUN=true; shift ;;
                                  -v|--verbose) VERBOSE=true; shift ;;
                                  -e|--email) EMAIL_ADDRESS="$2"; EMAIL_REPORT=true; shift 2 ;;
                                  --sendgrid-key) SENDGRID_API_KEY="$2"; shift 2 ;;
                                  --force) FORCE=true; shift ;;
                                  *) log_error "Unknown option: $1"; exit 1 ;;
                                esac
                              done

# Validate workflow
                              if [[ ! $WORKFLOW =~ ^(standard|security|performance|comprehensive)$ ]]; then
                                log_error "Invalid workflow: $WORKFLOW"
                                show_help
                                exit 1
                              fi

                              log_info "Starting Enterprise Automation Wrapper v${SCRIPT_VERSION}"
                              log_info "Workflow: ${WORKFLOW} | Dry Run: ${DRY_RUN}"

# Create report directory
                              mkdir -p "$REPORT_DIR"

# Validate environment
                              validate_environment

# Execute workflow
                              case $WORKFLOW in
                              standard)
                                run_standard_workflow
                                ;;
                                security)
                                  run_security_workflow
                                  ;;
                                  performance)
                                    run_performance_workflow
                                    ;;
                                    comprehensive)
                                      run_comprehensive_workflow
                                      ;;
                                    esac

# Generate consolidated report
                                    generate_consolidated_report

# Display summary
                                    echo -e "\n${GREEN}${BOLD} Automation Summary${NC}"
                                    echo -e "Workflow: ${WORKFLOW}"
                                    echo -e "Mode: $([ $DRY_RUN == true ] && echo "Dry Run" || echo "Live Execution")"
                                    echo -e "Distribution: ${DISTRO_FAMILY}"
                                    echo -e "Tools Available: $(ls -1 "$SCRIPT_DIR"/*.sh | wc -l)"
                                    echo -e "Report Directory: ${REPORT_DIR}"

# List generated reports
                                    local report_count=$(find "$REPORT_DIR" -name "*.json" -o -name "*.html" -o -name "*.txt" | wc -l)
                                      echo -e "Reports Generated: ${report_count}"

# Email consolidated report if requested
                                      if [[ ${EMAIL_REPORT:-false} == true && -n ${EMAIL_ADDRESS:-} ]]; then
                                        echo "Enterprise automation report attached" | mail -s "[Automation] ${WORKFLOW} Workflow - $(hostname)" "$EMAIL_ADDRESS"
                                        log_success "Consolidated report emailed to: $EMAIL_ADDRESS"
                                      fi

# Final recommendations
                                      echo -e "\n${CYAN}${BOLD} Recommendations${NC}"
                                      case $WORKFLOW in
                                      standard)
                                        echo -e "• Review system report for resource utilization"
                                          echo -e "• Schedule regular security workflows"
                                          ;;
                                          security)
                                            echo -e "• Monitor vulnerability scan results regularly"
                                            echo -e "• Keep security patches up to date"
                                            ;;
                                            performance)
                                              echo -e "• Review performance metrics for optimization opportunities"
                                                echo -e "• Monitor resource trends over time"
                                                ;;
                                                comprehensive)
                                                  echo -e "• Review all generated reports for complete system health"
                                                    echo -e "• Implement monitoring based on findings"
                                                    echo -e "• Schedule regular comprehensive audits"
                                                    ;;
                                                  esac

                                                  log_success "Enterprise automation wrapper completed successfully"

# Exit with appropriate code
                                                  if [[ -f "${REPORT_DIR}/automation-wrapper-${TIMESTAMP}.log" ]]; then
                                                    local error_count=$(grep -c "ERROR" "${REPORT_DIR}/automation-wrapper-${TIMESTAMP}.log" || echo "0")
                                                      if [[ $error_count -gt 0 ]]; then
                                                        log_warn "Completed with $error_count errors - check logs"
                                                        exit 1
                                                      fi
                                                    fi

                                                    exit 0
                                                  }

# Trap signals for clean exit
                                                  trap 'log_error "Script interrupted"; exit 130' INT TERM

                                                  main "$@"
