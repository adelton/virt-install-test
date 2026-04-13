
# Create virtual machine using virt-install

While it is easy to get environments of different operating systems
than the GitHub Actions runners with `podman` or `docker`, sometimes
containers are not enough and a true virtual machine (VM) is needed.

This action fetches a VM image from a URL provided as input, then creates
and runs a virtual machine using
[virt-install](https://github.com/virt-manager/virt-manager/blob/main/man/virt-install.rst).

Examples of getting AlmaLinux 10 virtual machines:
```
jobs:
  virt-install-almalinux-x86_64:
    runs-on: ubuntu-latest
    steps:
      - uses: adelton/virt-install@master
        with:
          disk-url: https://repo.almalinux.org/almalinux/10.1/cloud/x86_64/images/AlmaLinux-10-GenericCloud-10.1-20251125.0.x86_64.qcow2
      - run: ssh root@vm1.example.com cat /proc/cmdline
  virt-install-almalinux-aarch64:
    runs-on: ubuntu-24.04-arm
    steps:
      - uses: adelton/virt-install@master
        with:
          disk-url: https://repo.almalinux.org/almalinux/10.1/cloud/aarch64/images/AlmaLinux-10-GenericCloud-10.1-20251125.0.aarch64.qcow2
      - run: ssh root@vm1.example.com cat /etc/os-release
```

This action has been tested on GitHub hosted runners
`ubuntu-24.04` (`ubuntu-latest`) and `ubuntu-24.04-arm`.
Note that the `ubuntu-24.04-arm` hosted runners do not enable
nested virtualization so the virtual machines will run
emulated and thus slower than the x86_64/amd64 VMs
on the `ubuntu-24.04` runners.

Before running `virt-install`, this action
- installs the needed packages;
- fetches the image from the provided URL (input `disk-url`);
- generates an SSH key;
- optionally runs a `virt-customize` command;
- creates a cloud-init config on a
  [CD-ROM filesystem](https://docs.cloud-init.io/en/latest/reference/datasources/nocloud.html#source-2-drive-with-labeled-filesystem)
  to set up [SSH authorized_keys and enable SSH access to
  root](https://cloudinit.readthedocs.io/en/latest/reference/modules.html#ssh);
- enables access to the `virbr0` bridge to use system libvirtd's
  networking and DHCP.

Then `virt-install` is run, creating the VM in `qemu:///session`.
Name of the VM can be controlled by the `vm-name` input.

After creating the virtual machine, the action will

- wait for the `login:` prompt on the VM console;
- determine the IP address that the VM got from DHCP;
- add an entry to `/etc/hosts` for the VM name provided (input `vm-name`);
- SSH to the VM as root to test the setup;
- set the `ip-address` output.

## Inputs

### disk-url

The URL of a QCOW2 image to fetch and use for the virtual machine.

Required; no default.

Example:
```
      - uses: adelton/virt-install@master
        with:
          disk-url: https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img
```

### vm-name

Name of the virtual machine (libvirt domain) to use. It will be also
used to set up hostname resolution to the VM IP address in `/etc/hosts`,
so after
```
      - uses: adelton/virt-install@master
        with:
          disk-url: https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img
          vm-name: ubuntu.example.test
```
steps like
```
      - run: ssh root@ubuntu.example.test cat /etc/os-release
```
or
```
      - run: virsh dumpxml ubuntu.example.test
```
can be used.

Default: `vm1.example.com`.

Allowed characters: lowercase alphanumeric, dot, dash, and underscore only.

### osinfo

Since `virt-install` requires the `--osinfo` option, this allows it to
be explicitly specified.

Example:
```
      - uses: adelton/virt-install@master
        with:
          disk-url: https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/x86_64/images/Fedora-Cloud-Base-Generic-43-1.6.x86_64.qcow2
          osinfo: fedora41
```

Default: `generic`.

Possible values depend on the version of the `osinfo-db` package on the host,
see [the list of `osinfo` values on Ubuntu 24.04 runners](docs/osinfo-ubuntu-24.04.md).

### boot

The value of `virt-install` `--boot` argument.

Example:
```
      - uses: adelton/virt-install@master
        with:
          disk-url: https://fastly.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-cloudimg.qcow2
          osinfo: archlinux
          boot: uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=no
```

Default: `uefi`.

The [man virt-install(1) page](https://github.com/virt-manager/virt-manager/blob/main/man/virt-install.rst#--boot)
lists supported values. The noteworthy ones are

* `hd` to boot from BIOS;
* `uefi,firmware.feature0.name=secure-boot,firmware.feature0.enabled=no` to disable Secure Boot.

### virt-customize

Command-line argument to `virt-customize` to be run on the image
before `virt-install`. It can be used for example with images that do
not include cloud-init, to configure the SSH keys; or to make other
minor customizations to the image before running the virtual machine.

Example:

```
      - uses: adelton/virt-install@master
        with:
          disk-url: https://download.fedoraproject.org/pub/fedora/linux/releases/43/Server/x86_64/images/Fedora-Server-Guest-Generic-43-1.6.x86_64.qcow2
          osinfo: fedora42
          virt-customize: >
            --ssh-inject root:file:/home/runner/.ssh/id_rsa.pub
            --firstboot-command 'restorecon -rvv /root/.ssh'
            --link /dev/null:/etc/systemd/system/initial-setup.service
            --no-selinux-relabel
```

The `virt-customize` runs a temporary virtual machine to edit the image.
It uses host's kernel which in case of GitHub Actions' hosted Ubuntu
runners will not run with SELinux enabled. If the operating system in
the virtual machine runs with SELinux enabled, relabel of added files
might be needed, either using `--selinux-relabel`, or a firstboot command
as shown in the example above.

Default: unset, meaning `virt-customize` will not be run.

## Outputs

### ip-address

While the action sets resolution of the input `vm-name` to the VM IP
address in `/etc/hosts`, sometimes having the actual IP address is more
practical, for example to set up communications among multiple VMs.

The output `ip-address` provides that IP address, if the action was
able to retrieve it from the DHCP.

Example:
```
      - uses: adelton/virt-install@master
        with:
          disk-url: https://cloud-images.ubuntu.com/releases/noble/release/ubuntu-24.04-server-cloudimg-amd64.img
          osinfo: ubuntu24.04
        id: run-server
      - run: echo 'We will set our client VMs to talk to ${{ steps.run-server.outputs.ip-address }}'
```

## License

The code and documentation in this project are released
under the [BSD Zero Clause License](LICENSE).

