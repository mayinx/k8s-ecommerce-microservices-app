# complete system discovery via shell

Linux sd-178532 6.8.12-18-pve #1 SMP PREEMPT_DYNAMIC PMX 6.8.12-18 (2025-12-15T18:07Z) x86_64

The programs included with the Debian GNU/Linux system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Debian GNU/Linux comes with ABSOLUTELY NO WARRANTY, to the extent
permitted by applicable law.
Last login: Wed Apr  1 20:44:37 CEST 2026 on pts/0
root@sd-178532:~# cat /etc/os-release && uname -a
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
NAME="Debian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
VERSION_CODENAME=bookworm
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
Linux sd-178532 6.8.12-18-pve #1 SMP PREEMPT_DYNAMIC PMX 6.8.12-18 (2025-12-15T18:07Z) x86_64 GNU/Linux

root@sd-178532:~# lscpu
Architecture:                x86_64
  CPU op-mode(s):            32-bit, 64-bit
  Address sizes:             46 bits physical, 48 bits virtual
  Byte Order:                Little Endian
CPU(s):                      8
  On-line CPU(s) list:       0-7
Vendor ID:                   GenuineIntel
  BIOS Vendor ID:            Intel
  Model name:                Intel(R) Xeon(R) CPU E5-1410 v2 @ 2.80GHz
    BIOS Model name:               Intel(R) Xeon(R) CPU E5-1410 v2 @ 2.80GHz  CPU @ 2.8GHz
    BIOS CPU family:         179
    CPU family:              6
    Model:                   62
    Thread(s) per core:      2
    Core(s) per socket:      4
    Socket(s):               1
    Stepping:                4
    CPU(s) scaling MHz:      69%
    CPU max MHz:             3200.0000
    CPU min MHz:             1200.0000
    BogoMIPS:                5599.77
    Flags:                   fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflu
                             sh dts acpi mmx fxsr sse sse2 ss ht tm pbe syscall nx pdpe1gb rdtscp lm const
                             ant_tsc arch_perfmon pebs bts rep_good nopl xtopology nonstop_tsc cpuid aperf
                             mperf pni pclmulqdq dtes64 monitor ds_cpl vmx smx est tm2 ssse3 cx16 xtpr pdc
                             m pcid dca sse4_1 sse4_2 x2apic popcnt tsc_deadline_timer aes xsave avx f16c 
                             rdrand lahf_lm cpuid_fault pti ssbd ibrs ibpb stibp tpr_shadow flexpriority e
                             pt vpid fsgsbase smep erms xsaveopt dtherm ida arat pln pts vnmi md_clear flu
                             sh_l1d ibpb_exit_to_user
Virtualization features:     
  Virtualization:            VT-x
Caches (sum of all):         
  L1d:                       128 KiB (4 instances)
  L1i:                       128 KiB (4 instances)
  L2:                        1 MiB (4 instances)
  L3:                        10 MiB (1 instance)
NUMA:                        
  NUMA node(s):              1
  NUMA node0 CPU(s):         0-7
Vulnerabilities:             
  Gather data sampling:      Not affected
  Indirect target selection: Not affected
  Itlb multihit:             KVM: Mitigation: VMX disabled
  L1tf:                      Mitigation; PTE Inversion; VMX conditional cache flushes, SMT vulnerable
  Mds:                       Mitigation; Clear CPU buffers; SMT vulnerable
  Meltdown:                  Mitigation; PTI
  Mmio stale data:           Unknown: No mitigations
  Reg file data sampling:    Not affected
  Retbleed:                  Not affected
  Spec rstack overflow:      Not affected
  Spec store bypass:         Mitigation; Speculative Store Bypass disabled via prctl
  Spectre v1:                Mitigation; usercopy/swapgs barriers and __user pointer sanitization
  Spectre v2:                Mitigation; Retpolines; IBPB conditional; IBRS_FW; STIBP conditional; RSB fil
                             ling; PBRSB-eIBRS Not affected; BHI Not affected
  Srbds:                     Not affected
  Tsa:                       Not affected
  Tsx async abort:           Not affected
  Vmscape:                   Mitigation; IBPB before exit to userspace

root@sd-178532:~# free -h
               total        used        free      shared  buff/cache   available
Mem:            94Gi       2.4Gi        90Gi        53Mi       1.8Gi        91Gi
Swap:          1.0Gi          0B       1.0Gi

root@sd-178532:~# uptime
 21:19:37 up 41 days, 12:10,  1 user,  load average: 0.09, 0.07, 0.07

root@sd-178532:~# df -ht
df: option requires an argument -- 't'
Try 'df --help' for more information.

root@sd-178532:~# df -hT
Filesystem     Type      Size  Used Avail Use% Mounted on
udev           devtmpfs   48G     0   48G   0% /dev
tmpfs          tmpfs     9.5G  1.7M  9.5G   1% /run
/dev/md1       ext4       52G  6.0G   43G  13% /
tmpfs          tmpfs      48G   49M   48G   1% /dev/shm
tmpfs          tmpfs     5.0M     0  5.0M   0% /run/lock
/dev/md0       ext4      469M  189M  251M  43% /boot
/dev/fuse      fuse      128M   16K  128M   1% /etc/pve
zpve           zfs       5.3T  128K  5.3T   1% /zpve
tmpfs          tmpfs     9.5G     0  9.5G   0% /run/user/0

root@sd-178532:~# lsblk -f
NAME    FSTYPE       FSVER LABEL           UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
sda                                                                                            
├─sda1                                                                                         
├─sda2  swap         1                     d128bdf7-67ee-4351-a8dd-6ae750949d83                [SWAP]
├─sda3  linux_raid_m 1.2   51-158-200-94:0 7e2738e5-a564-480d-c87a-a6075542a31b                
│ └─md0 ext4         1.0                   5434bca5-36ba-465a-bd2d-6765961c46bc  250.5M    40% /boot
├─sda4  linux_raid_m 1.2   51-158-200-94:1 eec55adb-7d68-04d8-6184-7a9ec3130f12                
│ └─md1 ext4         1.0                   f5221d61-5b93-4350-9c9b-88f8f82544c7   42.7G    12% /
└─sda5  zfs_member   5000  zpve            9479252990969773238                                 
sdb                                                                                            
├─sdb1                                                                                         
├─sdb2  swap         1                     90dbbc24-6ae7-48c7-a384-25aa50ce7345                [SWAP]
├─sdb3  linux_raid_m 1.2   51-158-200-94:0 7e2738e5-a564-480d-c87a-a6075542a31b                
│ └─md0 ext4         1.0                   5434bca5-36ba-465a-bd2d-6765961c46bc  250.5M    40% /boot
├─sdb4  linux_raid_m 1.2   51-158-200-94:1 eec55adb-7d68-04d8-6184-7a9ec3130f12                
│ └─md1 ext4         1.0                   f5221d61-5b93-4350-9c9b-88f8f82544c7   42.7G    12% /
└─sdb5  zfs_member   5000  zpve            9479252990969773238                    

root@sd-178532:~# pvs
root@sd-178532:~# vgs
root@sd-178532:~# lvs
root@sd-178532:~# ip -c a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host noprefixroute 
       valid_lft forever preferred_lft forever
2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq master vmbr0 state UP group default qlen 1000
    link/ether c8:1f:66:c9:b3:9f brd ff:ff:ff:ff:ff:ff
    altname enp2s0f0
3: eno2: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether c8:1f:66:c9:b3:a0 brd ff:ff:ff:ff:ff:ff
    altname enp2s0f1
4: vmbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether c8:1f:66:c9:b3:9f brd ff:ff:ff:ff:ff:ff
    inet 51.158.200.94/24 scope global vmbr0
       valid_lft forever preferred_lft forever
    inet6 fe80::ca1f:66ff:fec9:b39f/64 scope link 
       valid_lft forever preferred_lft forever

root@sd-178532:~# ip route
default via 51.158.200.1 dev vmbr0 proto kernel onlink 
51.158.200.0/24 dev vmbr0 proto kernel scope link src 51.158.200.94 

root@sd-178532:~# ss -tulpn
Netid   State     Recv-Q    Send-Q                           Local Address:Port       Peer Address:Port   Process                                                                                                   
udp     UNCONN    0         0                                    127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=79))                                                                          
udp     UNCONN    0         0                                    127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=78))                                                                          
udp     UNCONN    0         0                                    127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=77))                                                                          
udp     UNCONN    0         0                                    127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=76))                                                                          
udp     UNCONN    0         0                                    127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=75))                                                                          
udp     UNCONN    0         0                                    127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=74))                                                                          
udp     UNCONN    0         0                                    127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=73))                                                                          
udp     UNCONN    0         0                                    127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=72))                                                                          
udp     UNCONN    0         0                                      0.0.0.0:111             0.0.0.0:*       users:(("rpcbind",pid=624,fd=5),("systemd",pid=1,fd=126))                                                
udp     UNCONN    0         0                                51.158.200.94:123             0.0.0.0:*       users:(("ntpd",pid=776,fd=21))                                                                           
udp     UNCONN    0         0                                    127.0.0.1:123             0.0.0.0:*       users:(("ntpd",pid=776,fd=18))                                                                           
udp     UNCONN    0         0                                      0.0.0.0:123             0.0.0.0:*       users:(("ntpd",pid=776,fd=17))                                                                           
udp     UNCONN    0         0                                        [::1]:53                 [::]:*       users:(("named",pid=737,fd=96))                                                                          
udp     UNCONN    0         0                                        [::1]:53                 [::]:*       users:(("named",pid=737,fd=97))                                                                          
udp     UNCONN    0         0                                        [::1]:53                 [::]:*       users:(("named",pid=737,fd=98))                                                                          
udp     UNCONN    0         0                                        [::1]:53                 [::]:*       users:(("named",pid=737,fd=99))                                                                          
udp     UNCONN    0         0                                        [::1]:53                 [::]:*       users:(("named",pid=737,fd=101))                                                                         
udp     UNCONN    0         0                                        [::1]:53                 [::]:*       users:(("named",pid=737,fd=100))                                                                         
udp     UNCONN    0         0                                        [::1]:53                 [::]:*       users:(("named",pid=737,fd=103))                                                                         
udp     UNCONN    0         0                                        [::1]:53                 [::]:*       users:(("named",pid=737,fd=102))                                                                         
udp     UNCONN    0         0            [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=128))                                                                         
udp     UNCONN    0         0            [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=131))                                                                         
udp     UNCONN    0         0            [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=133))                                                                         
udp     UNCONN    0         0            [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=129))                                                                         
udp     UNCONN    0         0            [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=132))                                                                         
udp     UNCONN    0         0            [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=136))                                                                         
udp     UNCONN    0         0            [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=135))                                                                         
udp     UNCONN    0         0            [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=134))                                                                         
udp     UNCONN    0         0                                         [::]:111                [::]:*       users:(("rpcbind",pid=624,fd=7),("systemd",pid=1,fd=128))                                                
udp     UNCONN    0         0            [fe80::ca1f:66ff:fec9:b39f]%vmbr0:123                [::]:*       users:(("ntpd",pid=776,fd=22))                                                                           
udp     UNCONN    0         0                                        [::1]:123                [::]:*       users:(("ntpd",pid=776,fd=19))                                                                           
udp     UNCONN    0         0                                         [::]:123                [::]:*       users:(("ntpd",pid=776,fd=16))                                                                           
tcp     LISTEN    0         128                                    0.0.0.0:22              0.0.0.0:*       users:(("sshd",pid=763,fd=3))                                                                            
tcp     LISTEN    0         4096                                   0.0.0.0:111             0.0.0.0:*       users:(("rpcbind",pid=624,fd=4),("systemd",pid=1,fd=125))                                                
tcp     LISTEN    0         20                                   127.0.0.1:25              0.0.0.0:*       users:(("exim4",pid=1073,fd=4))                                                                          
tcp     LISTEN    0         10                                   127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=84))                                                                          
tcp     LISTEN    0         10                                   127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=91))                                                                          
tcp     LISTEN    0         10                                   127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=83))                                                                          
tcp     LISTEN    0         10                                   127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=87))                                                                          
tcp     LISTEN    0         10                                   127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=93))                                                                          
tcp     LISTEN    0         10                                   127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=89))                                                                          
tcp     LISTEN    0         10                                   127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=81))                                                                          
tcp     LISTEN    0         10                                   127.0.0.1:53              0.0.0.0:*       users:(("named",pid=737,fd=80))                                                                          
tcp     LISTEN    0         4096                                 127.0.0.1:85              0.0.0.0:*       users:(("pvedaemon worke",pid=3621453,fd=6),("pvedaemon worke",pid=3581464,fd=6),("pvedaemon worke",pid=3562995,fd=6),("pvedaemon",pid=1114,fd=6))
tcp     LISTEN    0         5                                    127.0.0.1:953             0.0.0.0:*       users:(("named",pid=737,fd=113))                                                                         
tcp     LISTEN    0         5                                    127.0.0.1:953             0.0.0.0:*       users:(("named",pid=737,fd=118))                                                                         
tcp     LISTEN    0         5                                    127.0.0.1:953             0.0.0.0:*       users:(("named",pid=737,fd=117))                                                                         
tcp     LISTEN    0         5                                    127.0.0.1:953             0.0.0.0:*       users:(("named",pid=737,fd=116))                                                                         
tcp     LISTEN    0         5                                    127.0.0.1:953             0.0.0.0:*       users:(("named",pid=737,fd=115))                                                                         
tcp     LISTEN    0         5                                    127.0.0.1:953             0.0.0.0:*       users:(("named",pid=737,fd=119))                                                                         
tcp     LISTEN    0         5                                    127.0.0.1:953             0.0.0.0:*       users:(("named",pid=737,fd=114))                                                                         
tcp     LISTEN    0         5                                    127.0.0.1:953             0.0.0.0:*       users:(("named",pid=737,fd=112))                                                                         
tcp     LISTEN    0         4096                                         *:8006                  *:*       users:(("pveproxy worker",pid=961506,fd=6),("pveproxy worker",pid=961273,fd=6),("pveproxy worker",pid=955934,fd=6),("pveproxy",pid=1123,fd=6))
tcp     LISTEN    0         128                                       [::]:22                 [::]:*       users:(("sshd",pid=763,fd=4))                                                                            
tcp     LISTEN    0         4096                                      [::]:111                [::]:*       users:(("rpcbind",pid=624,fd=6),("systemd",pid=1,fd=127))                                                
tcp     LISTEN    0         4096                                         *:3128                  *:*       users:(("spiceproxy work",pid=764908,fd=6),("spiceproxy",pid=1129,fd=6))                                 
tcp     LISTEN    0         10           [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=137))                                                                         
tcp     LISTEN    0         10           [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=138))                                                                         
tcp     LISTEN    0         10           [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=140))                                                                         
tcp     LISTEN    0         10           [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=141))                                                                         
tcp     LISTEN    0         10           [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=139))                                                                         
tcp     LISTEN    0         10           [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=142))                                                                         
tcp     LISTEN    0         10           [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=143))                                                                         
tcp     LISTEN    0         10           [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53                 [::]:*       users:(("named",pid=737,fd=144))                                                                         
tcp     LISTEN    0         5                                        [::1]:953                [::]:*       users:(("named",pid=737,fd=121))                                                                         
tcp     LISTEN    0         5                                        [::1]:953                [::]:*       users:(("named",pid=737,fd=122))                                                                         
tcp     LISTEN    0         5                                        [::1]:953                [::]:*       users:(("named",pid=737,fd=125))                                                                         
tcp     LISTEN    0         5                                        [::1]:953                [::]:*       users:(("named",pid=737,fd=126))                                                                         
tcp     LISTEN    0         5                                        [::1]:953                [::]:*       users:(("named",pid=737,fd=124))                                                                         
tcp     LISTEN    0         5                                        [::1]:953                [::]:*       users:(("named",pid=737,fd=120))                                                                         
tcp     LISTEN    0         5                                        [::1]:953                [::]:*       users:(("named",pid=737,fd=127))                                                                         
tcp     LISTEN    0         5                                        [::1]:953                [::]:*       users:(("named",pid=737,fd=123))                                                                         
tcp     LISTEN    0         20                                       [::1]:25                 [::]:*       users:(("exim4",pid=1073,fd=5))                                                                          
tcp     LISTEN    0         10                                       [::1]:53                 [::]:*       users:(("named",pid=737,fd=104))                                                                         
tcp     LISTEN    0         10                                       [::1]:53                 [::]:*       users:(("named",pid=737,fd=105))                                                                         
tcp     LISTEN    0         10                                       [::1]:53                 [::]:*       users:(("named",pid=737,fd=108))                                                                         
tcp     LISTEN    0         10                                       [::1]:53                 [::]:*       users:(("named",pid=737,fd=109))                                                                         
tcp     LISTEN    0         10                                       [::1]:53                 [::]:*       users:(("named",pid=737,fd=110))                                                                         
tcp     LISTEN    0         10                                       [::1]:53                 [::]:*       users:(("named",pid=737,fd=107))                                                                         
tcp     LISTEN    0         10                                       [::1]:53                 [::]:*       users:(("named",pid=737,fd=111))                                                                         
tcp     LISTEN    0         10                                       [::1]:53                 [::]:*       users:(("named",pid=737,fd=106))               

root@sd-178532:~# ss -tulpn | grep 80
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=128))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=131))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=133))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=129))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=132))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=136))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=135))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=134))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:123          [::]:*    users:(("ntpd",pid=776,fd=22))                                                                                                                    
tcp   LISTEN 0      10                             127.0.0.1:53        0.0.0.0:*    users:(("named",pid=737,fd=80))                                                                                                                   
tcp   LISTEN 0      4096                                   *:8006            *:*    users:(("pveproxy worker",pid=961506,fd=6),("pveproxy worker",pid=961273,fd=6),("pveproxy worker",pid=955934,fd=6),("pveproxy",pid=1123,fd=6))    
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=137))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=138))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=140))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=141))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=139))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=142))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=143))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=144))                                                                                                                  

root@sd-178532:~# ss -tulpn | grep "80"
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=128))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=131))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=133))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=129))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=132))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=136))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=135))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=134))                                                                                                                  
udp   UNCONN 0      0      [fe80::ca1f:66ff:fec9:b39f]%vmbr0:123          [::]:*    users:(("ntpd",pid=776,fd=22))                                                                                                                    
tcp   LISTEN 0      10                             127.0.0.1:53        0.0.0.0:*    users:(("named",pid=737,fd=80))                                                                                                                   
tcp   LISTEN 0      4096                                   *:8006            *:*    users:(("pveproxy worker",pid=961506,fd=6),("pveproxy worker",pid=961273,fd=6),("pveproxy worker",pid=955934,fd=6),("pveproxy",pid=1123,fd=6))    
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=137))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=138))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=140))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=141))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=139))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=142))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=143))                                                                                                                  
tcp   LISTEN 0      10     [fe80::ca1f:66ff:fec9:b39f]%vmbr0:53           [::]:*    users:(("named",pid=737,fd=144))                                                                                                                  

root@sd-178532:~# ss -tulpn | grep ":80"
tcp   LISTEN 0      4096                                   *:8006            *:*    users:(("pveproxy worker",pid=961506,fd=6),("pveproxy worker",pid=961273,fd=6),("pveproxy worker",pid=955934,fd=6),("pveproxy",pid=1123,fd=6))    

root@sd-178532:~# ss -tulpn | grep ":443"

root@sd-178532:~# ss -tulpn | grep "443"

root@sd-178532:~# cat /etc/resolv.conf
nameserver 127.0.0.1
nameserver 62.210.16.6
nameserver 62.210.16.7

root@sd-178532:~# sudo ufw status
-bash: sudo: command not found

root@sd-178532:~# ufw status
-bash: ufw: command not found

root@sd-178532:~# cat /etc/apt/sources.list
deb http://mirrors.online.net/debian bookworm main contrib non-free non-free-firmware

deb-src http://mirrors.online.net/debian bookworm main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
root@sd-178532:~# cat /etc/apt/sources.list /etc/apt/sources.list.d/*.list
deb http://mirrors.online.net/debian bookworm main contrib non-free non-free-firmware

deb-src http://mirrors.online.net/debian bookworm main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
root@sd-178532:~# apt list --upgradable
Listing... Done
bind9-dnsutils/oldstable-security 1:9.18.47-1~deb12u1 amd64 [upgradable from: 1:9.18.44-1~deb12u1]
bind9-host/oldstable-security 1:9.18.47-1~deb12u1 amd64 [upgradable from: 1:9.18.44-1~deb12u1]
bind9-libs/oldstable-security 1:9.18.47-1~deb12u1 amd64 [upgradable from: 1:9.18.44-1~deb12u1]
bind9-utils/oldstable-security 1:9.18.47-1~deb12u1 amd64 [upgradable from: 1:9.18.44-1~deb12u1]
bind9/oldstable-security 1:9.18.47-1~deb12u1 amd64 [upgradable from: 1:9.18.44-1~deb12u1]
gstreamer1.0-plugins-base/oldstable-security 1.22.0-3+deb12u6 amd64 [upgradable from: 1.22.0-3+deb12u5]
gstreamer1.0-x/oldstable-security 1.22.0-3+deb12u6 amd64 [upgradable from: 1.22.0-3+deb12u5]
libgstreamer-plugins-base1.0-0/oldstable-security 1.22.0-3+deb12u6 amd64 [upgradable from: 1.22.0-3+deb12u5]
libnss3/oldstable-security 2:3.87.1-1+deb12u2 amd64 [upgradable from: 2:3.87.1-1+deb12u1]
libpng16-16/oldstable-security 1.6.39-2+deb12u4 amd64 [upgradable from: 1.6.39-2+deb12u3]
libpve-cluster-api-perl/stable 8.1.3 all [upgradable from: 8.1.2]
libpve-cluster-perl/stable 8.1.3 all [upgradable from: 8.1.2]
libpve-notify-perl/stable 8.1.3 all [upgradable from: 8.1.2]
libvpx7/oldstable-security 1.12.0-1+deb12u5 amd64 [upgradable from: 1.12.0-1+deb12u4]
libxml-parser-perl/oldstable-security 2.46-4+deb12u1 amd64 [upgradable from: 2.46-4]
linux-image-amd64/oldstable-security 6.1.164-1 amd64 [upgradable from: 6.1.162-1]
linux-libc-dev/oldstable-security 6.1.164-1 amd64 [upgradable from: 6.1.162-1]
proxmox-kernel-6.8/stable 6.8.12-20 all [upgradable from: 6.8.12-18]
proxmox-widget-toolkit/stable 4.3.16 all [upgradable from: 4.3.13]
pve-cluster/stable 8.1.3 amd64 [upgradable from: 8.1.2]
pve-manager/stable 8.4.17 all [upgradable from: 8.4.16]
root@sd-178532:~# dnf check-update
-bash: dnf: command not found
root@sd-178532:~# python3 --version, node -v, java -version.
unknown option --version,
usage: python3 [option] ... [-c cmd | -m mod | file | -] [arg] ...
Try `python -h' for more information.
root@sd-178532:~# python3 --version
Python 3.11.2
root@sd-178532:~# node -v
-bash: node: command not found
root@sd-178532:~# java -version.
-bash: java: command not found
root@sd-178532:~# sudo -l
-bash: sudo: command not found
root@sd-178532:~# sestatus
-bash: sestatus: command not found
root@sd-178532:~# aa-status
apparmor module is loaded.
20 profiles are loaded.
20 profiles are in enforce mode.
   /usr/bin/lxc-copy
   /usr/bin/lxc-start
   /usr/bin/man
   /usr/lib/NetworkManager/nm-dhcp-client.action
   /usr/lib/NetworkManager/nm-dhcp-helper
   /usr/lib/connman/scripts/dhclient-script
   /usr/sbin/ntpd
   /{,usr/}sbin/dhclient
   lsb_release
   lxc-container-default
   lxc-container-default-cgns
   lxc-container-default-with-mounting
   lxc-container-default-with-nesting
   man_filter
   man_groff
   named
   nvidia_modprobe
   nvidia_modprobe//kmod
   pve-container-mounthotplug
   swtpm
0 profiles are in complain mode.
0 profiles are in kill mode.
0 profiles are in unconfined mode.
2 processes have profiles defined.
2 processes are in enforce mode.
   /usr/sbin/ntpd (776) 
   /usr/sbin/named (737) named
0 processes are in complain mode.
0 processes are unconfined but have a profile defined.
0 processes are in mixed mode.
0 processes are in kill mode.
root@sd-178532:~# cat /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin
_apt:x:42:65534::/nonexistent:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-network:x:998:998:systemd Network Management:/:/usr/sbin/nologin
systemd-timesync:x:997:997:systemd Time Synchronization:/:/usr/sbin/nologin
messagebus:x:100:107::/nonexistent:/usr/sbin/nologin
sshd:x:101:65534::/run/sshd:/usr/sbin/nologin
bind:x:102:109::/var/cache/bind:/usr/sbin/nologin
ntpd:x:103:110::/var/run/openntpd:/usr/sbin/nologin
ntpsec:x:104:111::/nonexistent:/usr/sbin/nologin
_rpc:x:105:65534::/run/rpcbind:/usr/sbin/nologin
Debian-exim:x:106:112::/var/spool/exim4:/usr/sbin/nologin
statd:x:107:65534::/var/lib/nfs:/usr/sbin/nologin
gluster:x:108:114::/var/lib/glusterd:/usr/sbin/nologin
tss:x:109:115:TPM software stack,,,:/var/lib/tpm:/bin/false
ceph:x:64045:64045:Ceph storage service:/var/lib/ceph:/usr/sbin/nologin
root@sd-178532:~# systemctl list-units --type=service --state=running
  UNIT                     LOAD   ACTIVE SUB     DESCRIPTION                                            
  cron.service             loaded active running Regular background program processing daemon
  dbus.service             loaded active running D-Bus System Message Bus
  exim4.service            loaded active running LSB: exim Mail Transport Agent
  getty@tty1.service       loaded active running Getty on tty1
  lxc-monitord.service     loaded active running LXC Container Monitoring Daemon
  lxcfs.service            loaded active running FUSE filesystem for LXC
  mdmonitor.service        loaded active running MD array monitor
  named.service            loaded active running BIND Domain Name Server
  ntpsec.service           loaded active running Network Time Service
  proxmox-firewall.service loaded active running Proxmox nftables firewall
  pve-cluster.service      loaded active running The Proxmox VE cluster filesystem
  pve-firewall.service     loaded active running Proxmox VE firewall
  pve-ha-crm.service       loaded active running PVE Cluster HA Resource Manager Daemon
  pve-ha-lrm.service       loaded active running PVE Local HA Resource Manager Daemon
  pve-lxc-syscalld.service loaded active running Proxmox VE LXC Syscall Daemon
  pvedaemon.service        loaded active running PVE API Daemon
  pvefw-logger.service     loaded active running Proxmox VE firewall logger
  pveproxy.service         loaded active running PVE API Proxy Server
  pvescheduler.service     loaded active running Proxmox VE scheduler
  pvestatd.service         loaded active running PVE Status Daemon
  qmeventd.service         loaded active running PVE Qemu Event Daemon
  rpcbind.service          loaded active running RPC bind portmap service
  rrdcached.service        loaded active running LSB: start or stop rrdcached
  smartmontools.service    loaded active running Self Monitoring and Reporting Technology (SMART) Daemon
  spiceproxy.service       loaded active running PVE SPICE Proxy Server
  ssh.service              loaded active running OpenBSD Secure Shell server
  systemd-journald.service loaded active running Journal Service
  systemd-logind.service   loaded active running User Login Management
  systemd-udevd.service    loaded active running Rule-based Manager for Device Events and Files
  user@0.service           loaded active running User Manager for UID 0
  watchdog-mux.service     loaded active running Proxmox VE watchdog multiplexer
  zfs-zed.service          loaded active running ZFS Event Daemon (zed)

LOAD   = Reflects whether the unit definition was properly loaded.
ACTIVE = The high-level unit activation state, i.e. generalization of SUB.
SUB    = The low-level unit activation state, values depend on unit type.
32 loaded units listed.
root@sd-178532:~# systemctl --failed
  UNIT LOAD ACTIVE SUB DESCRIPTION
0 loaded units listed.
root@sd-178532:~# ls -la /etc/cron.*
/etc/cron.d:
total 28
drwxr-xr-x   2 root root 4096 Feb 19 08:03 .
drwxr-xr-x 101 root root 4096 Feb 19 08:10 ..
-rw-r--r--   1 root root  201 Jun  6  2025 e2scrub_all
-rw-r--r--   1 root root  589 Feb 24  2023 mdadm
-rw-r--r--   1 root root  140 Jan 17  2023 ntpsec
-rw-r--r--   1 root root  102 Mar  2  2023 .placeholder
lrwxrwxrwx   1 root root   20 Feb 19 08:03 vzdump -> /etc/pve/vzdump.cron
-rw-r--r--   1 root root  377 May 20  2023 zfsutils-linux

/etc/cron.daily:
total 40
drwxr-xr-x   2 root root 4096 Feb 19 08:01 .
drwxr-xr-x 101 root root 4096 Feb 19 08:10 ..
-rwxr-xr-x   1 root root 1478 May 25  2023 apt-compat
-rwxr-xr-x   1 root root  123 Mar 27  2023 dpkg
-rwxr-xr-x   1 root root 4722 Jun 17  2024 exim4-base
-rwxr-xr-x   1 root root  377 Dec 14  2022 logrotate
-rwxr-xr-x   1 root root 1395 Mar 12  2023 man-db
-rwxr-xr-x   1 root root  622 Feb 24  2023 mdadm
-rw-r--r--   1 root root  102 Mar  2  2023 .placeholder

/etc/cron.hourly:
total 12
drwxr-xr-x   2 root root 4096 Feb 19 07:35 .
drwxr-xr-x 101 root root 4096 Feb 19 08:10 ..
-rw-r--r--   1 root root  102 Mar  2  2023 .placeholder

/etc/cron.monthly:
total 12
drwxr-xr-x   2 root root 4096 Feb 19 07:35 .
drwxr-xr-x 101 root root 4096 Feb 19 08:10 ..
-rw-r--r--   1 root root  102 Mar  2  2023 .placeholder

/etc/cron.weekly:
total 16
drwxr-xr-x   2 root root 4096 Feb 19 07:41 .
drwxr-xr-x 101 root root 4096 Feb 19 08:10 ..
-rwxr-xr-x   1 root root 1055 Mar 12  2023 man-db
-rw-r--r--   1 root root  102 Mar  2  2023 .placeholder

/etc/cron.yearly:
total 12
drwxr-xr-x   2 root root 4096 Feb 19 07:35 .
drwxr-xr-x 101 root root 4096 Feb 19 08:10 ..
-rw-r--r--   1 root root  102 Mar  2  2023 .placeholder
root@sd-178532:~# crontab -l
no crontab for root
root@sd-178532:~# alias audit='history | grep -E "install|config|systemctl"'
root@sd-178532:~# alias audit='history'
root@sd-178532:~# 