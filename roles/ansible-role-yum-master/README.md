yum role
=========

Role to configure the default yum repositories.

Requirements
------------

The role has to be executed with root permission, using the root user or via sudo because it will modify system parameters.

Minimum ansible version required to run this role is 2.2

This Role is compatible with RHEL and SUSE.


Role Variables
--------------



Dependencies
------------

Testing
--------
[TestInfra](https://testinfra.readthedocs.io/en/latest/) scripts will be located in the tests/ directory. They can be consumed by any testing product, but they are developed to be integrated with [molecule](http://molecule.readthedocs.io/en/latest/), using the **ansible_runner** library for testinfra, which obtains the inventory dynamically.
```
testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')
```

To integrate this role with **molecule**, checkout the last version of the [molecule project](http://rmavmgit.mrd.roche.com:7990/scm/ans/molecule.git) inside the role, in the molecule folder
```
$ ls -l molecule/
total 0
$ git submodule add http://rmavmgit.mrd.roche.com:7990/scm/ans/molecule.git
Cloning into '[...]/ansible-role-xxxx/molecule'...
remote: Counting objects: 23, done.
remote: Compressing objects: 100% (19/19), done.
remote: Total 23 (delta 5), reused 0 (delta 0)
Unpacking objects: 100% (23/23), done.
$ ls -l molecule/
total 4
drwxrwxr-x 2 user user   45 jul  2 15:22 common
lrwxrwxrwx 1 user user    6 jul  2 15:22 default -> vmware
drwxrwxr-x 2 user user   26 jul  2 15:22 kvm
-rw-rw-r-- 1 user user 2051 jul  2 15:22 README.md
drwxrwxr-x 2 user user   87 jul  2 15:22 vmware

```
Follow usage instructions from the molecule [README.md](http://rmavmgit.mrd.roche.com:7990/projects/ANS/repos/molecule/browse/README.md) file

Jenkins Integration
----------------
[Jenkins file](Jenkinsfile) is based on a library provided by [this](http://rmavmgit.mrd.roche.com:7990/projects/ANS/repos/jenkinsfile-lib/browse) git repo. It has to be available on Jenkins before executing any pipeline.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: ansible-role-yum }

License
-------

Copyright (c) 2018 F. Hoffmann-La Roche Ltd. All rights reserved.

Author Information
------------------

Developed by Markus Filip Karlsson (markus_filip.karlsson@roche.com) @ F. Hoffmann-La Roche Ltd.
