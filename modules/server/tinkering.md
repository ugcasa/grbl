tinkering.md
tag: server planning

# tinkering.md

sem.3929222:subl_send-3.8:write_sem

## common /dev/shm


/dev/shm is a temporary file storage filesystem, i.e., tmpfs, that uses RAM for the backing store.  It can function as a shared memory implementation that facilitates IPC.

https://superuser.com/questions/45342/when-should-i-use-dev-shm-and-when-should-i-use-tmp

Recent 2.6 Linux kernel builds have started to offer /dev/shm as shared memory in the form of a ramdisk, more specifically as a world-writable directory that is stored in memory with a defined limit in /etc/default/tmpfs.  /dev/shm support is completely optional within the kernel config file.  It is included by default in both Fedora and Ubuntu distributions, where it is most extensively used by the Pulseaudio application.

- Siirretään gurun temppikama /tmp -> /dev/shm


## network.sh monitoring


### rkhunter

rkhunter (Rootkit Hunter) is a Unix-based tool that scans for rootkits, backdoors and possible local exploits. It does this by comparing SHA-1 hashes of important files with known good ones in online databases, searching for default directories (of rootkits), wrong permissions, hidden files, suspicious strings in kernel modules, and special tests for Linux and FreeBSD. rkhunter is notable due to its inclusion in popular operating systems (Fedora,[1] Debian,[2] etc.)

The tool has been written in Bourne shell, to allow for portability. It can run on almost all UNIX-derived systems.

It checks for:

 - SHA256 hash changes;
 - files commonly created by rootkits;
 - executables with anomalous file permissions;
 - suspicious strings in kernel modules;
 - hidden files in system directories;

```bash
sudo apt update && sudo apt install rkhunter -y

sudo rkhunter --propupd



# Invalid SCRIPTWHITELIST configuration option: Non-existent pathname: /usr/bin/egrep
# Invalid SCRIPTWHITELIST configuration option: Non-existent pathname: /usr/bin/fgrep

rk_cfg="/etc/rkhunter.conf"
    --- SCRIPTWHITELIST=/usr/bin/egrep
    --- SCRIPTWHITELIST=/usr/bin/fgrep
    +++ #SCRIPTWHITELIST=/usr/bin/egrep
    +++ #SCRIPTWHITELIST=/usr/bin/fgrep

sudo rkhunter --check

# Log found in
rk_log="/var/log/rkhunter.log"


```


## nethogs

```bash
sudo apt-get install -y nethogs

sudo nethogs

```

### tiger

The Unix security audit and intrusion detection tool

 TIGER, or the 'tiger' scripts, is a set of Bourne shell scripts, C programs and data files which are used to perform a security audit of different operating systems. The tools can be both run altogether once to generate an audit report of the system and they can also be run periodically to provide information on changes to the system's security once a security baseline has been defined. Consequently, they can be used also as a host intrusion detection mechanism.

The tools rely on specialised external security tools such as John the Ripper, Chkroot and integrity check tools (like Tripwire, Integrit or Aide) for some of the tasks. The periodic review mechanism relies on the use of the cron task scheduler and an email delivery system.

TIGER has one primary goal: report ways the system's security can be compromised.

Debian's TIGER incorporates new checks primarily oriented towards Debian distribution including: md5sums checks of installed files, location of files not belonging to packages, and analysis of local listening processes.

This package provides all the security scripts and data files.

```bash
sudo apt update && sudo apt install tiger -y
```


```bash

sudo su
tiger

```



## elena

```log

/usr/bin/lwp-request                                     [ Warning ]

```



## roima

```log

[14:06:55]   /usr/sbin/adduser                               [ OK ]
[14:06:55] Info: Found file '/usr/sbin/adduser': it is whitelisted for the 'script replacement' check.

[14:07:09]   /usr/bin/ldd                                    [ OK ]
[14:07:09] Info: Found file '/usr/bin/ldd': it is whitelisted for the 'script replacement' check.

seem fine, but not sure. should not add to white list


'[14:07:21]   /usr/bin/which                                  [ OK ]
[14:07:21] Info: Found file '/usr/bin/which': it is whitelisted for the 'script replacement' check.

[14:07:23]   /usr/bin/lwp-request                            [ Warning ]
[14:07:23] Warning: The command '/usr/bin/lwp-request' has been replaced by a script: /usr/bin/lwp-request: Perl script text executable

I did whitelist these at desktop

[14:07:35]   /bin/egrep                                      [ OK ]
[14:07:35] Info: Found file '/bin/egrep': it is whitelisted for the 'script replacement' check.
[14:07:35]   /bin/fgrep                                      [ OK ]
[14:07:35] Info: Found file '/bin/fgrep': it is whitelisted for the 'script replacement' check.

were whitelisted by default

[14:07:43]   /bin/which                                      [ Warning ]
[14:07:43] Warning: The command '/bin/which' has been replaced by a script: /bin/which: POSIX shell script, ASCII text executable

again


[14:32:48] Info: Found an SSH configuration file: /etc/ssh/sshd_config
[14:32:48] Info: Rkhunter option ALLOW_SSH_ROOT_USER set to 'no'.
[14:32:48] Info: Rkhunter option ALLOW_SSH_PROT_V1 set to '2'.
[14:32:48]   Checking if SSH root access is allowed          [ Not allowed ]
[14:32:48]   Checking if SSH protocol v1 is allowed          [ Warning ]
[14:32:48] Warning: The SSH and rkhunter configuration options should be the same:
[14:32:48]          SSH configuration option 'Protocol': 2
[14:32:48]          Rkhunter configuration option 'ALLOW_SSH_PROT_V1': 2
[14:32:48]   Checking for other suspicious configuration settings [ None found ]

hmm.. :

/etc/ssh/sshd_confi
    # Always use v2
    Protocol 2

ah juu "The SSH and rkhunter configuration options should be the same:"

 /etc/rkhunter.conf
    # The default value is '0'.
    #
    ALLOW_SSH_PROT_V1=2

# Set this option to '1' to allow the use of the SSH-1 protocol, but note
# that theoretically it is weaker, and therefore less secure, than the
# SSH-2 protocol. Do not modify this option unless you have good reasons
# to use the SSH-1 protocol (for instance for AFS token passing or Kerberos4
# authentication). If the 'Protocol' option has not been set in the SSH
# configuration file, then a value of '2' may be set here in order to
# suppress a warning message. A value of '0' indicates that the use of
# SSH-1 is not allowed.

--- ALLOW_SSH_PROT_V1=2
+++ ALLOW_SSH_PROT_V1=0


Eli toleroidaan nuo skribulla korvatut binäärit

= 2 itkua

Mut anywäy, hyvä on tulos.

Miltäköhän elenalla näyttää?

```



















## logs


#### rkhunter electra log 20210912

```log
[13:03:46] System checks summary
[13:03:46] =====================
[13:03:46]
[13:03:46] File properties checks...
[13:03:46] Files checked: 150
[13:03:46] Suspect files: 4
[13:03:46]
[13:03:46] Rootkit checks...
[13:03:46] Rootkits checked : 499
[13:03:46] Possible rootkits: 8
[13:03:46]
[13:03:46] Applications checks...
[13:03:46] All checks skipped
[13:03:46]
[13:03:46] The system checks took: 5 minutes and 13 seconds


[13:03:25]   Checking if SSH root access is allowed          [ Warning ]
[13:03:25] Warning: The SSH configuration option 'PermitRootLogin' has not been set.
           The default value may be 'yes', to allow root access.
[ FIXED ] set to 'no'


[12:58:58]   /usr/bin/lwp-request                            [ Warning ]
    [12:58:58] Warning: The command '/usr/bin/lwp-request' has been replaced by a script: /usr/bin/lwp-request: Perl script text executable
    This program can be used to send requests to WWW servers and your
    local file system. The request content for POST and PUT
    methods is read from stdin.  The content of the response is printed on
    stdout.  Error messages are printed on stderr.  The program returns a
    status value indicating the number of URLs that failed.
[ OK ] perl scripti vaikuttaa ihan legimiltä

[12:59:05]   /bin/egrep                                      [ Warning ]
    [12:59:05] Warning: The command '/bin/egrep' has been replaced by a script: /bin/egrep: POSIX shell script, ASCII text executable
    [12:59:05]   /bin/fgrep                                      [ Warning ]
    [12:59:05] Warning: The command '/bin/fgrep' has been replaced by a script: /bin/fgrep: POSIX shell script, ASCII text executable
[ OK ] pointtaa bash pätkään joka kutsuu grep vivuilla -E ja -F


[12:59:10]   /bin/which                                      [ Warning ]
    [12:59:10] Warning: The command '/bin/which' has been replaced by a script: /bin/which: POSIX shell script, ASCII text executable
[ OK ] bash scripti vaikuttaa ihan legimiltä

[13:02:28]   Checking for suspicious (large) shared memory segments [ Warning ]
    [13:02:28] Warning: The following suspicious (large) shared memory segments have been found:
    [13:02:28]          Process: /usr/lib/x86_64-linux-gnu/cinnamon-settings-daemon/csd-background    PID: 1450    Owner: casa    Size: 128MB (configured size allowed: 1,0MB)
    [13:02:28]          Process: /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1    PID: 1651    Owner: casa    Size: 4,0MB (configured size allowed: 1,0MB)
    [13:02:28]          Process: /opt/sublime_text/sublime_text    PID: 3939193    Owner: casa    Size: 64MB (configured size allowed: 1,0MB)
    [13:02:28]          Process: /usr/bin/nemo    PID: 1588217    Owner: casa    Size: 16MB (configured size allowed: 1,0MB)
    [13:02:28]          Process: /usr/bin/nemo-desktop    PID: 1649    Owner: casa    Size: 16MB (configured size allowed: 1,0MB)
    [13:02:28]          Process: /opt/sublime_text/sublime_text    PID: 292148    Owner: root    Size: 64MB (configured size allowed: 1,0MB)
    [13:02:28]          Process: /usr/bin/gimp-2.10    PID: 4009471    Owner: casa    Size: 4,0MB (configured size allowed: 1,0MB)
    [13:02:29]          Process: /usr/bin/gimp-2.10    PID: 4009471    Owner: casa    Size: 64MB (configured size allowed: 1,0MB)

    [13:03:37]   Checking for hidden files and directories       [ Warning ]
    [13:03:37] Warning: Hidden directory found: /etc/.java
[ OK ]".systemRootModFile and the other files you mentioned are part of Java system preferences and are safe. See this thread."


13:03:33]   Checking /dev for suspicious file types         [ Warning ]
    [13:03:33] Warning: Suspicious file types found in /dev:
    [13:03:33]          /dev/shm/sem.3929222:subl_arecv-3.8:write_sem: data
    [13:03:33]          /dev/shm/sem.3929222:subl_arecv-3.8:read_sem: data
    ...
    [13:03:36]          /dev/shm/3925675:subl_send-3.3: data
    [13:03:36]          /dev/input/ckb1/pollrate: ASCII text
    [13:03:36]          /dev/input/ckb1/fwversion: ASCII text
    [13:03:36]          /dev/input/ckb1/features: ASCII text
    [13:03:36]          /dev/input/ckb1/dpi: very short file (no magic)
    [13:03:36]          /dev/input/ckb1/layout: ASCII text
    [13:03:36]          /dev/input/ckb1/productid: ASCII text
    [13:03:36]          /dev/input/ckb1/serial: ASCII text
    [13:03:36]          /dev/input/ckb1/model: ASCII text
    [13:03:36]          /dev/input/ckb2/pollrate: ASCII text
    [13:03:36]          /dev/input/ckb2/fwversion: ASCII text
    [13:03:36]          /dev/input/ckb2/features: ASCII text
    [13:03:36]          /dev/input/ckb2/dpi: ASCII text
    [13:03:36]          /dev/input/ckb2/layout: very short file (no magic)
    [13:03:36]          /dev/input/ckb2/productid: ASCII text
    [13:03:36]          /dev/input/ckb2/serial: ASCII text
    [13:03:36]          /dev/input/ckb2/model: ASCII text
    [13:03:36]          /dev/input/ckb0/pid: ASCII text
    [13:03:36]          /dev/input/ckb0/version: ASCII text
    [13:03:36]          /dev/input/ckb0/connected: ASCII text
    casa@electra#:~$ cat /dev/input/ckb0/features
        cat: /dev/input/ckb0/features: No such file or directory, fine
    casa@electra#:~$ cat /dev/input/ckb1/features
        corsair k68 rgb pollrate adjrate bind notify fwversion fwupdate = corsair
    casa@electra#:~$ cat /dev/input/ckb2/features
        corsair harpoon rgb pollrate adjrate bind notify fwversion fwupdate = corsair
[ OK ], sublime temp files and keyboard input


[13:02:28] Warning: The following suspicious (large) shared memory segments have been found:
[13:02:28]          Process: /usr/lib/x86_64-linux-gnu/cinnamon-settings-daemon/csd-background    PID: 1450    Owner: casa    Size: 128MB (configured size allowed: 1,0MB)
[13:02:28]          Process: /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1    PID: 1651    Owner: casa    Size: 4,0MB (configured size allowed: 1,0MB)
[13:02:28]          Process: /opt/sublime_text/sublime_text    PID: 3939193    Owner: casa    Size: 64MB (configured size allowed: 1,0MB)
[13:02:28]          Process: /usr/bin/nemo    PID: 1588217    Owner: casa    Size: 16MB (configured size allowed: 1,0MB)
[13:02:28]          Process: /usr/bin/nemo-desktop    PID: 1649    Owner: casa    Size: 16MB (configured size allowed: 1,0MB)
[13:02:28]          Process: /opt/sublime_text/sublime_text    PID: 292148    Owner: root    Size: 64MB (configured size allowed: 1,0MB)
[13:02:28]          Process: /usr/bin/gimp-2.10    PID: 4009471    Owner: casa    Size: 4,0MB (configured size allowed: 1,0MB)
[13:02:29]          Process: /usr/bin/gimp-2.10    PID: 4009471    Owner: casa    Size: 64MB (configured size allowed: 1,0MB)

[ OK ] all programs are launched by good elfs or me

```


```log
[13:03:22] Info: Starting test name 'startup_files'
[13:03:22] Performing system boot checks
[13:03:22]   Checking for local host name                    [ Found ]


[13:03:22]
[13:03:22] Info: Starting test name 'startup_malware'
[13:03:22]   Checking for system startup files               [ Found ]


[13:03:24]
[13:03:24] Info: Starting test name 'group_accounts'
[13:03:24] Performing group and account checks
[13:03:24]   Checking for passwd file                        [ Found ]


[13:03:25] Info: Found password file: /etc/passwd
[13:03:25] Info: Found shadow file: /etc/shadow


[13:03:25]   Checking for an SSH configuration file          [ Found ]
[13:03:25] Info: Found an SSH configuration file: /etc/ssh/sshd_config
[13:03:25] Info: Rkhunter option ALLOW_SSH_ROOT_USER set to 'no'.
[13:03:25] Info: Rkhunter option ALLOW_SSH_PROT_V1 set to '2'.



[13:03:25]   Checking if SSH protocol v1 is allowed          [ Not set ]
[13:03:25]
[13:03:25] Info: Starting test name 'system_configs_syslog'
[13:03:25]   Checking for a running system logging daemon    [ Found ]
[13:03:25] Info: A running 'rsyslog' daemon has been found.
[13:03:25] Info: A running 'systemd-journald' daemon has been found.
[13:03:25] Info: Found an rsyslog configuration file: /etc/rsyslog.conf
[13:03:25] Info: Found a systemd configuration file: /etc/systemd/journald.conf
[13:03:25]   Checking for a system logging configuration file [ Found ]
[13:03:25]   Checking if syslog remote logging is allowed    [ Not allowed ]
[13:03:25]



```



### tiger install log

```
Tripwire keeps its configuration in a encrypted database that is         │
  │ generated, by default, from /etc/tripwire/twcfg.txt                      │
  │                                                                          │
  │ Any changes to /etc/tripwire/twcfg.txt, either as a result of a change   │
  │ in this package or due to administrator activity, require the            │
  │ regeneration of the encrypted database before they will take effect.     │
  │                                                                          │
  │ Selecting this action will result in your being prompted for the site    │
  │ key passphrase during the post-installation process of this package.     │
  │                                                                          │
  │ Rebuild Tripwire configuration file?



    │ Tripwire has been installed                                              │
  │                                                                          │
  │ The Tripwire binaries are located in /usr/sbin and the database is       │
  │ located in /var/lib/tripwire. It is strongly advised that these          │
  │ locations be stored on write-protected media (e.g. mounted RO floppy).   │
  │ See /usr/share/doc/tripwire/README.Debian for details.
```

```

 casa@electra#:~$  sudo apt install tiger -y

The following additional packages will be installed:
  chkrootkit john john-data tripwire
Suggested packages:
  lynis
The following NEW packages will be installed:
  chkrootkit john john-data tiger tripwire
0 upgraded, 5 newly installed, 0 to remove and 0 not upgraded.
2 not fully installed or removed.
Need to get 6 906 kB of archives.
After this operation, 24,8 MB of additional disk space will be used.
Get:1 http://mirrors.nic.funet.fi/ubuntu focal/universe amd64 tripwire amd64 2.4.3.7-1 [1 686 kB]
Get:2 http://mirrors.nic.funet.fi/ubuntu focal/universe amd64 chkrootkit amd64 0.53-1 [316 kB]
Get:3 http://mirrors.nic.funet.fi/ubuntu focal/main amd64 john-data all 1.8.0-2build1 [4 276 kB]
Get:4 http://mirrors.nic.funet.fi/ubuntu focal/main amd64 john amd64 1.8.0-2build1 [189 kB]
Get:5 http://mirrors.nic.funet.fi/ubuntu focal/universe amd64 tiger amd64 1:3.2.4~rc1-2 [438 kB]
Fetched 6 906 kB in 1s (8 031 kB/s)
Preconfiguring packages ...
Selecting previously unselected package tripwire.
(Reading database ... 540622 files and directories currently installed.)
Preparing to unpack .../tripwire_2.4.3.7-1_amd64.deb ...
Unpacking tripwire (2.4.3.7-1) ...
Selecting previously unselected package chkrootkit.
Preparing to unpack .../chkrootkit_0.53-1_amd64.deb ...
Unpacking chkrootkit (0.53-1) ...
Selecting previously unselected package john-data.
Preparing to unpack .../john-data_1.8.0-2build1_all.deb ...
Unpacking john-data (1.8.0-2build1) ...
Selecting previously unselected package john.
Preparing to unpack .../john_1.8.0-2build1_amd64.deb ...
Unpacking john (1.8.0-2build1) ...
Selecting previously unselected package tiger.
Preparing to unpack .../tiger_1%3a3.2.4~rc1-2_amd64.deb ...
Unpacking tiger (1:3.2.4~rc1-2) ...
Setting up tripwire (2.4.3.7-1) ...
Generating site key (this may take several minutes)...
Generating local key (this may take several minutes)...
Setting up initramfs-tools (0.136ubuntu6.6) ...
update-initramfs: deferring update (trigger activated)
Setting up john-data (1.8.0-2build1) ...
Setting up linux-image-5.4.0-84-generic (5.4.0-84.94) ...
Setting up chkrootkit (0.53-1) ...
Setting up tiger (1:3.2.4~rc1-2) ...

Creating config file /etc/tiger/tigerrc with new version
Setting up john (1.8.0-2build1) ...
Processing triggers for desktop-file-utils (0.24+linuxmint1) ...
Processing triggers for mime-support (3.64ubuntu1) ...
Processing triggers for gnome-menus (3.36.0-1ubuntu1) ...
Processing triggers for man-db (2.9.1-1) ...
Processing triggers for initramfs-tools (0.136ubuntu6.6) ...

```



## asennuksen aikana vastaan tulleita seikkoja

```
Miksi gennataan uutta imagea hä?

update-initramfs: Generating /boot/initrd.img-5.4.0-81-generic
I: The initramfs will attempt to resume from /dev/sda2
I: (UUID=75117c46-8d08-4c3c-8f32-9e544893d781)
I: Set the RESUME variable to override this.
Error 24 : Write error : cannot write compressed block
E: mkinitramfs failure cpio 141 lz4 -9 -l 24
update-initramfs: failed for /boot/initrd.img-5.4.0-81-generic with 1.
dpkg: error processing package initramfs-tools (--configure):
 installed initramfs-tools package post-installation script subprocess returned
error exit status 1
Processing triggers for linux-image-5.4.0-84-generic (5.4.0-84.94) ...
/etc/kernel/postinst.d/dkms:
 * dkms: running auto installation service for kernel 5.4.0-84-generic
   ...done.
/etc/kernel/postinst.d/initramfs-tools:
update-initramfs: Generating /boot/initrd.img-5.4.0-84-generic
Progress: [ 90%] [########################################################.......]
I: (UUID=75117c46-8d08-4c3c-8f32-9e544893d781)
I: Set the RESUME variable to override this.
Error 24 : Write error : cannot write compressed block #############################################..........]
E: mkinitramfs failure cpio 141 lz4 -9 -l 24
update-initramfs: failed for /boot/initrd.img-5.4.0-84-generic with 1.
run-parts: /etc/kernel/postinst.d/initramfs-tools exited with return code 1
dpkg: error processing package linux-image-5.4.0-84-generic (--configure):
 installed linux-image-5.4.0-84-generic package post-installation script subprocess returned error exit status 1
Errors were encountered while processing:
 initramfs-tools
 linux-image-5.4.0-84-generic
E: Sub-process /usr/bin/dpkg returned an error code

```

Fix

```bash
sudo apt-get auto-remove \
    && sudo apt-get clean \
    && sudo apt-get update \
    && sudo apt-get upgrade


```