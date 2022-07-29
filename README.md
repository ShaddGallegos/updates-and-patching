# ansible-rhel-update-example
This repo has some sample playbooks for:
  * Updating RHEL 7 
  * Updating RHEL 7 and generating a report

WinRM 
Scripts that may need to be run on your remote Windows host(s) (please review the code to varify they are applicable to your hosts, and test before you distribute to all your hosts):

Upgrade-PowerShell.ps1 – Upgrades PowerShell and .NET Framework to a supported version (if not present)
Install-WMF3Hotfix.ps1 – Installs a Windows HotFix for a known memory leak in WinRM (if not present)
ConfigureRemotingForAnsible.ps1 – Configures WinRM remote PowerShell for Ansible
