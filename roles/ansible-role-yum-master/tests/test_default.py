import os

import testinfra.utils.ansible_runner

testinfra_hosts = testinfra.utils.ansible_runner.AnsibleRunner(
    os.environ['MOLECULE_INVENTORY_FILE']).get_hosts('all')


def test_yum_files(host):
    os_family = host.ansible("setup")["ansible_facts"]["ansible_os_family"]
    f = host.file('/etc/yum.conf')
    assert f.user == 'root'
    assert f.group == 'root'
    assert f.mode == 0644
    if os_family == 'RedHat':
        assert f.contains('cachedir=/opt/cache/yum/')
    elif os_family == 'Suse':
        assert f.contains('cachedir=/var/cache/yum/$basearch/$releasever')
