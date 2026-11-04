# A Windows 11 VM on a 7th-gen homelab box (and the driver that didn't stick)

**Angle:** Adding a Hyper-V-style Windows VM next to ~30 production containers on a 4-core i5-7500T, and the one shortcut that sent the fresh install into a boot loop.

**Story beats:**
- Feasibility check: VT-x + KVM already loaded, 31 GB RAM, but the "1 TB SSD" is really a spinning laptop HDD shared with Immich, so the VM went on the NVMe
- Made room first: `docker image prune` freed 46 GB of old image versions left by weekly updates
- Win11 refuses < 64 GB; a thin qcow2 makes "64 GB" cost what is written (~17 GB after copy)
- CPU not on Microsoft's list: one LabConfig registry key
- The trap: loading the virtio disk driver with `drvload` in the setup prompt works for the installer only; Windows installs, then loops on INACCESSIBLE_BOOT_DEVICE. Fix: `dism /add-driver` into the installed image (network driver too, so setup got internet)
- Cockpit's web console didn't pass arrow keys to the UEFI menu; driving the VM with `virsh send-key` + `virsh screenshot` from the host did
- macvtap: VM gets its own LAN IP without touching the host network (live services), at the cost of host-to-VM traffic
- Load numbers during Windows Update: 2 cores pinned, host 28% idle, 66 C, swap 2 -> 3.2 GB; 8 GB is the ceiling

**Evidence:** lemongrab log 2026-11-04 "Windows 11 VM on KVM, managed with Cockpit" and "Image updates from the weekly list"; commits 90180be, 74fc8e7, d6af05d.

**Public check:** Leave out: LAN IPs, MAC address, hostname-to-IP mapping, Cockpit URL.

**Outline:**

**Effort:**

**Priority:**

**Published:**
