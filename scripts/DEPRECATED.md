# Shell Scripts - DEPRECATED

⚠️ **IMPORTANT: These shell scripts are deprecated and will be removed in a future release.**

## Migration to Ansible Playbooks

All shell scripts in this directory have been converted to Ansible playbooks for better integration, maintainability, and functionality.

### Migration Guide

| Deprecated Script | New Playbook | Migration Notes |
|------------------|--------------|-----------------|
| `automation-wrapper.sh` | `playbooks/orchestration/automation_wrapper.yml` | Use `-e workflow=<type>` instead of command-line workflow argument |
| `rhel-patch-manager.sh` | `playbooks/patching/rhel_patch_manager.yml` | All options now available as Ansible variables |
| `linux-universal-patcher.sh` | `playbooks/patching/linux_universal_patcher.yml` | Cross-distribution support maintained |
| `vulnerability-scanner.sh` | `playbooks/security/vulnerability_scanner.yml` | Enhanced CVE detection and reporting |
| `system-reporter.sh` | `playbooks/reporting/system_reporter.yml` | More report formats available |
| `package-auditor.sh` | `playbooks/reporting/package_auditor.yml` | Improved package analysis |
| `kpatch-manager.sh` | `playbooks/maintenance/kpatch_manager.yml` | Better state management |
| `ansible-performance-setup.sh` | `playbooks/maintenance/ansible_performance_setup.yml` | Idempotent configuration |

### Quick Migration Examples

#### Before (Shell Script)
```bash
./scripts/rhel-patch-manager.sh --security-only --allow-reboot
```

#### After (Ansible Playbook)
```bash
ansible-playbook playbooks/patching/rhel_patch_manager.yml \
  -i inventory \
  -e "security_only=true allow_reboot=true"
```

---

#### Before (Shell Script)
```bash
./scripts/automation-wrapper.sh security --verbose
```

#### After (Ansible Playbook)
```bash
ansible-playbook playbooks/orchestration/automation_wrapper.yml \
  -i inventory \
  -e "workflow=security" \
  -v
```

---

#### Before (Shell Script)
```bash
./scripts/system-reporter.sh --format html --security
```

#### After (Ansible Playbook)
```bash
ansible-playbook playbooks/reporting/system_reporter.yml \
  -i inventory \
  -e "report_format=html collect_security=true"
```

## Why Migrate?

### Benefits of Ansible Playbooks

✅ **Native Integration** - Seamless integration with Ansible Tower/AAP  
✅ **Idempotent** - Safe to run multiple times without unintended changes  
✅ **Better Error Handling** - Built-in retry logic and error management  
✅ **Parallel Execution** - Run across multiple hosts simultaneously  
✅ **Check Mode** - Preview changes before applying (`--check`)  
✅ **Diff Mode** - See what will change (`--diff`)  
✅ **Tags** - Run specific parts of playbooks  
✅ **Event-Driven** - Integration with EDA for automated responses  
✅ **Vault Integration** - Secure credential management  
✅ **Role Composition** - Reusable with existing Ansible roles  

### Limitations of Shell Scripts

❌ Not idempotent - can cause issues if run multiple times  
❌ Limited error handling and recovery  
❌ Sequential execution only  
❌ No native integration with Ansible Tower/AAP  
❌ Harder to test and validate  
❌ Template variables ({{ ansible_user }}) not rendered  

## Timeline

- **Current** - Scripts deprecated but still functional
- **Next Release** - Scripts will show deprecation warnings
- **Future Release** - Scripts will be removed from repository

## Support

If you encounter issues during migration:

1. Review the playbook documentation: `playbooks/README.md`
2. Check variable mappings in playbook `vars:` sections
3. Test with `--check` mode first
4. Use `-vvv` for detailed debugging output

## Still Need Scripts?

If you have a specific use case that requires shell scripts, please:

1. Open an issue describing your use case
2. We'll help you migrate to the playbook-based approach
3. Or identify what functionality is missing from playbooks

The playbook-based approach is more powerful and flexible - there should be no need to continue using scripts.

---

**See:** `playbooks/README.md` for complete playbook documentation
