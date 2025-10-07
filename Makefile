# Standard Makefile for Ansible projects

# Variables
ANSIBLE_PLAYBOOK := ansible-playbook
ANSIBLE_LINT := ansible-lint
VAULT_PASSWORD_FILE := ~/.vault_pass.txt
PROJECT_NAME := $(shell basename $(CURDIR))

# Default target
.PHONY: all
all: help

# Help target
.PHONY: help
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  setup        Setup the project environment"
	@echo "  run          Run the main playbook"
	@echo "  lint         Lint all Ansible files"
	@echo "  test         Test the playbooks (syntax check)"
	@echo "  encrypt      Encrypt vault files"
	@echo "  decrypt      Decrypt vault files"
	@echo "  clean        Clean temporary files"
	@echo ""
	@echo "Playbook Targets:"
	@echo "  patch-rhel       Run RHEL patch manager"
	@echo "  patch-universal  Run universal patcher (all distros)"
	@echo "  scan-vulns       Run vulnerability scanner"
	@echo "  report-system    Generate system reports"
	@echo "  audit-packages   Run package auditor"
	@echo "  orchestrate      Run automation wrapper"
	@echo ""
	@echo "  help             Show this help message"

# Setup project environment
.PHONY: setup
setup:
	@echo "Setting up project environment for $(PROJECT_NAME)..."
	@if [ ! -f $(VAULT_PASSWORD_FILE) ]; then \
		echo "Creating vault password file..."; \
		echo "r3dh4t7!" > $(VAULT_PASSWORD_FILE); \
		chmod 600 $(VAULT_PASSWORD_FILE); \
	fi
	@if [ -f env.yml.example ] && [ ! -f env.yml ]; then \
		echo "Creating env.yml from example..."; \
		cp env.yml.example env.yml; \
	fi
	@if [ -f vault.yml.example ] && [ ! -f vault.yml ]; then \
		echo "Creating vault.yml from example..."; \
		cp vault.yml.example vault.yml; \
		ansible-vault encrypt vault.yml --vault-password-file $(VAULT_PASSWORD_FILE); \
	fi
	@echo "Setup completed."

# Run the main playbook
.PHONY: run
run:
	@echo "Running main playbook..."
	@if [ -f site-$(PROJECT_NAME).yml ]; then \
		$(ANSIBLE_PLAYBOOK) site-$(PROJECT_NAME).yml --vault-password-file $(VAULT_PASSWORD_FILE); \
	else \
		echo "Error: site-$(PROJECT_NAME).yml not found"; \
		exit 1; \
	fi

# Lint Ansible files
.PHONY: lint
lint:
	@echo "Linting Ansible files..."
	@if command -v $(ANSIBLE_LINT) > /dev/null; then \
		find . -name "*.yml" -not -path "./roles/*" -print0 | xargs -0 -n1 $(ANSIBLE_LINT); \
	else \
		echo "ansible-lint not installed. Install with: pip install ansible-lint"; \
	fi

# Test playbooks (syntax check)
.PHONY: test
test:
	@echo "Testing playbooks..."
	@if [ -f site-$(PROJECT_NAME).yml ]; then \
		$(ANSIBLE_PLAYBOOK) site-$(PROJECT_NAME).yml --syntax-check; \
	else \
		echo "Error: site-$(PROJECT_NAME).yml not found"; \
		exit 1; \
	fi

# Encrypt vault files
.PHONY: encrypt
encrypt:
	@echo "Encrypting vault files..."
	@if [ -f vault.yml ]; then \
		ansible-vault encrypt vault.yml --vault-password-file $(VAULT_PASSWORD_FILE); \
	else \
		echo "Error: vault.yml not found"; \
		exit 1; \
	fi

# Decrypt vault files
.PHONY: decrypt
decrypt:
	@echo "Decrypting vault files..."
	@if [ -f vault.yml ]; then \
		ansible-vault decrypt vault.yml --vault-password-file $(VAULT_PASSWORD_FILE); \
	else \
		echo "Error: vault.yml not found"; \
		exit 1; \
	fi

# Clean temporary files
.PHONY: clean
clean:
	@echo "Cleaning temporary files..."
	@find . -name "*.retry" -type f -delete
	@find . -name "*.pyc" -type f -delete
	@find . -name "__pycache__" -type d -exec rm -rf {} +
	@find . -name ".pytest_cache" -type d -exec rm -rf {} +

# Playbook targets
.PHONY: patch-rhel
patch-rhel:
	@echo "Running RHEL Patch Manager..."
	$(ANSIBLE_PLAYBOOK) playbooks/patching/rhel_patch_manager.yml -i inventory

.PHONY: patch-universal
patch-universal:
	@echo "Running Universal Patcher..."
	$(ANSIBLE_PLAYBOOK) playbooks/patching/linux_universal_patcher.yml -i inventory

.PHONY: scan-vulns
scan-vulns:
	@echo "Running Vulnerability Scanner..."
	$(ANSIBLE_PLAYBOOK) playbooks/security/vulnerability_scanner.yml -i inventory

.PHONY: report-system
report-system:
	@echo "Generating System Reports..."
	$(ANSIBLE_PLAYBOOK) playbooks/reporting/system_reporter.yml -i inventory -e "report_format=all"

.PHONY: audit-packages
audit-packages:
	@echo "Running Package Auditor..."
	$(ANSIBLE_PLAYBOOK) playbooks/reporting/package_auditor.yml -i inventory

.PHONY: orchestrate
orchestrate:
	@echo "Running Automation Wrapper (standard workflow)..."
	$(ANSIBLE_PLAYBOOK) playbooks/orchestration/automation_wrapper.yml -i inventory -e "workflow=standard"

.PHONY: orchestrate-comprehensive
orchestrate-comprehensive:
	@echo "Running Automation Wrapper (comprehensive workflow)..."
	$(ANSIBLE_PLAYBOOK) playbooks/orchestration/automation_wrapper.yml -i inventory -e "workflow=comprehensive"
