test20201009-1-report-guru-client-automated-tester-generator-PASSED.md

# automated test generator test #1

## pre test conditions need to set manually

      casa@electra:~/git/hub/guru-client/test$ guru corsair start
      starting kb-next-daemon..

## Generating tester

      casa@electra:~/git/hub/guru-client/test$ ./make.sh corsair -V
      module: ../core/corsair.sh
      output: test-corsair.sh
      13 functions to test
      overwrite test-corsair.sh? [y/n]: y
      corsair.main
      corsair.test_main
      corsair.help
      corsair.test_help
      corsair.check
      corsair.test_check
      corsair.status
      corsair.test_status
      corsair.start
      corsair.test_start
      corsair.init
      corsair.test_init
      corsair.raw_write
      corsair.test_raw_write
      corsair.set
      corsair.test_set
      corsair.reset
      corsair.test_reset
      corsair.end
      corsair.test_end
      corsair.kill
      corsair.test_kill
      corsair.install
      corsair.test_install
      corsair.remove
      corsair.test_remove

## Run all tests

I did not remember that corsair has non tested installer, did not remove my settings, huh

      casa@electra:~/git/hub/guru-client/test$ ./test-corsair.sh all
      testing corsair.main
      corsair: unknown command:
      corsair.main passed
      testing corsair.help
      guru-client corsair help

      usage:    guru corsair [start|init|set|reset|end|kill|status|help|install|remove] <key> <color>

      commands:
       start                       start ckb-next-daemon
       init <mode>                 init keyboard mode listed below
                                   [status|red|olive|dark] able to set keys
                                   [trippy|yes-no|rainbow] active animations
       set <key> <color>           write key color to keyboard key
       reset <key>                 reset one key or if empty, all pipes
        end                         end playing with keyboard, set to normal
       kill                        stop ckb-next-daemon
       status                      blink esc, print status and return
       install                     install requirements
       remove                      remove corsair driver
       help                        this help

      examples:
                guru corsair status -v
                guru corsair init trippy
                guru corsair end

      corsair.help passed
      testing corsair.check
      01:57:09 checking ckb-next-daemon.. OK
      corsair.check passed
      testing corsair.status
      01:57:09 checking ckb-next-daemon.. OK
      01:57:09 corsair on service
      01:57:09 set ESC color to green
      01:57:09 /tmp/ckbpipe000 <- 008000FF
      01:57:09 resetting key esc
      01:57:09 set ESC color to olive
      01:57:09 /tmp/ckbpipe000 <- 80800010
      corsair.status passed
      testing corsair.start
      already running
      corsair.start passed
      testing corsair.init
      corsair.init passed
      testing corsair.raw_write
      ../core/corsair.sh: line 202: : No such file or directory
      corsair.raw_write passed
      testing corsair.set
      01:57:10 set  color to
      no such color
      corsair.set passed
      testing corsair.reset
      01:57:10 resetting keys.............. done
      corsair.reset passed
      testing corsair.end
      corsair.end passed
      testing corsair.kill
      killing ckb-next-daemon..
      kill verified
      corsair.kill passed
      testing corsair.install
      Reading package lists... Done
      Building dependency tree
      Reading state information... Done
      libappindicator-dev is already the newest version (12.10.1+18.04.20180322.1-1mint2).
      build-essential is already the newest version (12.4ubuntu1).
      libxcb-ewmh-dev is already the newest version (0.4.1-1ubuntu1).
      zlib1g-dev is already the newest version (1:1.2.11.dfsg-0ubuntu2).
      libqt5x11extras5-dev is already the newest version (5.9.5-0ubuntu1).
      libquazip5-dev is already the newest version (0.7.3-5ubuntu1).
      pavucontrol is already the newest version (3.0-4).
      qttools5-dev is already the newest version (5.9.5-0ubuntu1).
      cmake is already the newest version (3.10.2-1ubuntu2.18.04.1).
      git is already the newest version (1:2.17.1-1ubuntu0.7).
      libpulse-dev is already the newest version (1:11.1-1ubuntu7.10).
      libudev-dev is already the newest version (237-3ubuntu10.42).
      libxcb-screensaver0-dev is already the newest version (1.13-2~ubuntu18.04).
      libxcb1-dev is already the newest version (1.13-2~ubuntu18.04).
      qt5-default is already the newest version (5.9.5+dfsg-0ubuntu2.5).
      The following packages were automatically installed and are no longer required:
        brasero-common dvd+rw-tools gthumb-data libbrasero-media3-1 libburn4 libisofs6 libjte1 libllvm9 libllvm9:i386 linux-headers-4.15.0-101 linux-headers-4.15.0-101-generic linux-headers-4.15.0-112 linux-headers-4.15.0-112-generic
        linux-image-4.15.0-101-generic linux-image-4.15.0-112-generic linux-modules-4.15.0-101-generic linux-modules-4.15.0-112-generic linux-modules-extra-4.15.0-101-generic linux-modules-extra-4.15.0-112-generic
      Use 'sudo apt autoremove' to remove them.
      0 upgraded, 0 newly installed, 0 to remove and 110 not upgraded.
      fatal: destination path 'ckb-next' already exists and is not an empty directory.
      -- The C compiler identification is GNU 7.5.0
      -- The CXX compiler identification is GNU 7.5.0
      -- Check for working C compiler: /usr/bin/cc
      -- Check for working C compiler: /usr/bin/cc -- works
      -- Detecting C compiler ABI info
      -- Detecting C compiler ABI info - done
      -- Detecting C compile features
      -- Detecting C compile features - done
      -- Check for working CXX compiler: /usr/bin/c++
      -- Check for working CXX compiler: /usr/bin/c++ -- works
      -- Detecting CXX compiler ABI info
      -- Detecting CXX compiler ABI info - done
      -- Detecting CXX compile features
      -- Detecting CXX compile features - done
      -- Found Git: /usr/bin/git (found version "2.17.1")
      -- ckb-next version: 0.4.2-108-g7abbe53 (Non-release)
      -- Looking for pthread.h
      -- Looking for pthread.h - found
      -- Looking for pthread_create
      -- Looking for pthread_create - not found
      -- Check if compiler accepts -pthread
      -- Check if compiler accepts -pthread - yes
      -- Found Threads: TRUE
      -- Performing Test ICONV_SECOND_ARGUMENT_IS_CONST
      -- Performing Test ICONV_SECOND_ARGUMENT_IS_CONST - Failed
      -- Found Iconv: /usr/lib/x86_64-linux-gnu/libc.so
      -- Checking for module 'libudev'
      --   Found libudev, version 237
      -- Found UDEV: /lib/x86_64-linux-gnu/libudev.so
      -- Searching for running ckb and/or ckb-next GUI
      -- NOTE:
          Privileged access is required for operations upon the daemon at
          configure time as it is owned by root. If this is unacceptable,
          disable SAFE_INSTALL and prepare the filesystem manually.
      -- systemd detected
      -- Generating and importing ckb-next-daemon.service (systemd)
      inactive
      Failed to get unit file state for ckb-daemon.service: No such file or directory
      inactive
      enabled
      -- Enabled ckb-next-daemon detected
      -- Found QuaZip: /usr/lib/x86_64-linux-gnu/libquazip5.so
      -- Found PulseAudioSimple: /usr/lib/x86_64-linux-gnu/libpulse-simple.so
      -- Found PulseAudio: /usr/lib/x86_64-linux-gnu/libpulse.so
      -- Found ZLIB: /usr/lib/x86_64-linux-gnu/libz.so (found version "1.2.11")
      -- Looking for XOpenDisplay in /usr/lib/x86_64-linux-gnu/libX11.so;/usr/lib/x86_64-linux-gnu/libXext.so
      -- Looking for XOpenDisplay in /usr/lib/x86_64-linux-gnu/libX11.so;/usr/lib/x86_64-linux-gnu/libXext.so - found
      -- Looking for gethostbyname
      -- Looking for gethostbyname - found
      -- Looking for connect
      -- Looking for connect - found
      -- Looking for remove
      -- Looking for remove - found
      -- Looking for shmat
      -- Looking for shmat - found
      -- Looking for IceConnectionNumber in ICE
      -- Looking for IceConnectionNumber in ICE - found
      -- Found X11: /usr/lib/x86_64-linux-gnu/libX11.so
      -- Found PkgConfig: /usr/bin/pkg-config (found version "0.29.1")
      -- Checking for module 'xcb'
      --   Found xcb, version 1.13
      -- Checking for module 'xcb-ewmh'
      --   Found xcb-ewmh, version 0.4.1
      -- Checking for module 'xcb-screensaver'
      --   Found xcb-screensaver, version 1.13
      -- Could NOT find dbusmenu-qt5 (missing: dbusmenu-qt5_DIR)
      CMake Error at src/gui/CMakeLists.txt:265 (message):
        dbusmenu-qt5 was not found.  Either install it or pass -DUSE_DBUS_MENU=0 to
        fall back to the default Qt tray icon.


      -- Configuring incomplete, errors occurred!
      See also "/tmp/ckb-next/build/CMakeFiles/CMakeOutput.log".
      See also "/tmp/ckb-next/build/CMakeFiles/CMakeError.log".
      An error occurred,
      press enter to exit.
      Bus 003 Device 004: ID 1b1c:1b75 Corsair
      Bus 003 Device 003: ID 1b1c:1b4f Corsair
      corsair.install passed
      testing corsair.remove
      make: *** No rule to make target 'uninstall'.  Stop.
      corsair.remove passed

Heh, it did not print errorcodes, it did passed!

Me happy, continuing to automate things

Looks more clear with colors, but better add some newlines

## run by guru-client tester

      casa@electra:~/git/hub/guru-client$ guru test corsair

      TEST 19: guru-client corsair #all - Sat Oct 10 02:09:14 EEST 2020
      /home/casa/bin/test/test-corsair.sh: line 5: ../core/corsair.sh: No such file or directory
      testing corsair.main
      corsair: unknown command:
      corsair.main passed
      testing corsair.help
      usage:    guru corsair [start|init|set|reset|end|kill|status|help|install|remove] <key> <color>
      corsair.help passed
      testing corsair.check
      corsair.check passed
      testing corsair.status
      corsair.status passed
      testing corsair.start
      corsair.start passed
      testing corsair.init
      corsair.init passed
      testing corsair.raw_write
      /home/casa/bin/corsair.sh: line 202: : No such file or directory
      corsair.raw_write passed
      testing corsair.set
      no such color
      corsair.set passed
      testing corsair.reset
      corsair.reset passed
      testing corsair.end
      corsair.end passed
      testing corsair.kill
      killing ckb-next-daemon..
      kill verified
      corsair.kill passed
      testing corsair.install
      Reading package lists... Done
      Building dependency tree
      Reading state information... Done
      libappindicator-dev is already the newest version (12.10.1+18.04.20180322.1-1mint2).
      build-essential is already the newest version (12.4ubuntu1).
      libxcb-ewmh-dev is already the newest version (0.4.1-1ubuntu1).
      zlib1g-dev is already the newest version (1:1.2.11.dfsg-0ubuntu2).
      libqt5x11extras5-dev is already the newest version (5.9.5-0ubuntu1).
      libquazip5-dev is already the newest version (0.7.3-5ubuntu1).
      pavucontrol is already the newest version (3.0-4).
      qttools5-dev is already the newest version (5.9.5-0ubuntu1).
      cmake is already the newest version (3.10.2-1ubuntu2.18.04.1).
      git is already the newest version (1:2.17.1-1ubuntu0.7).
      libpulse-dev is already the newest version (1:11.1-1ubuntu7.10).
      libudev-dev is already the newest version (237-3ubuntu10.42).
      libxcb-screensaver0-dev is already the newest version (1.13-2~ubuntu18.04).
      libxcb1-dev is already the newest version (1.13-2~ubuntu18.04).
      qt5-default is already the newest version (5.9.5+dfsg-0ubuntu2.5).
      The following packages were automatically installed and are no longer required:
        brasero-common dvd+rw-tools gthumb-data libbrasero-media3-1 libburn4 libisofs6 libjte1 libllvm9 libllvm9:i386 linux-headers-4.15.0-101 linux-headers-4.15.0-101-generic linux-headers-4.15.0-112 linux-headers-4.15.0-112-generic
        linux-image-4.15.0-101-generic linux-image-4.15.0-112-generic linux-modules-4.15.0-101-generic linux-modules-4.15.0-112-generic linux-modules-extra-4.15.0-101-generic linux-modules-extra-4.15.0-112-generic
      Use 'sudo apt autoremove' to remove them.
      0 upgraded, 0 newly installed, 0 to remove and 110 not upgraded.
      fatal: destination path 'ckb-next' already exists and is not an empty directory.
      -- The C compiler identification is GNU 7.5.0
      -- The CXX compiler identification is GNU 7.5.0
      -- Check for working C compiler: /usr/bin/cc
      -- Check for working C compiler: /usr/bin/cc -- works
      -- Detecting C compiler ABI info
      -- Detecting C compiler ABI info - done
      -- Detecting C compile features
      -- Detecting C compile features - done
      -- Check for working CXX compiler: /usr/bin/c++
      -- Check for working CXX compiler: /usr/bin/c++ -- works
      -- Detecting CXX compiler ABI info
      -- Detecting CXX compiler ABI info - done
      -- Detecting CXX compile features
      -- Detecting CXX compile features - done
      -- Found Git: /usr/bin/git (found version "2.17.1")
      -- ckb-next version: 0.4.2-108-g7abbe53 (Non-release)
      -- Looking for pthread.h
      -- Looking for pthread.h - found
      -- Looking for pthread_create
      -- Looking for pthread_create - not found
      -- Check if compiler accepts -pthread
      -- Check if compiler accepts -pthread - yes
      -- Found Threads: TRUE
      -- Performing Test ICONV_SECOND_ARGUMENT_IS_CONST
      -- Performing Test ICONV_SECOND_ARGUMENT_IS_CONST - Failed
      -- Found Iconv: /usr/lib/x86_64-linux-gnu/libc.so
      -- Checking for module 'libudev'
      --   Found libudev, version 237
      -- Found UDEV: /lib/x86_64-linux-gnu/libudev.so
      -- Searching for running ckb and/or ckb-next GUI
      -- Running ckb-next GUI detected
      -- NOTE:
          Privileged access is required for operations upon the daemon at
          configure time as it is owned by root. If this is unacceptable,
          disable SAFE_INSTALL and prepare the filesystem manually.
      -- systemd detected
      -- Generating and importing ckb-next-daemon.service (systemd)
      inactive
      Failed to get unit file state for ckb-daemon.service: No such file or directory
      inactive
      enabled
      -- Enabled ckb-next-daemon detected
      -- Found QuaZip: /usr/lib/x86_64-linux-gnu/libquazip5.so
      -- Found PulseAudioSimple: /usr/lib/x86_64-linux-gnu/libpulse-simple.so
      -- Found PulseAudio: /usr/lib/x86_64-linux-gnu/libpulse.so
      -- Found ZLIB: /usr/lib/x86_64-linux-gnu/libz.so (found version "1.2.11")
      -- Looking for XOpenDisplay in /usr/lib/x86_64-linux-gnu/libX11.so;/usr/lib/x86_64-linux-gnu/libXext.so
      -- Looking for XOpenDisplay in /usr/lib/x86_64-linux-gnu/libX11.so;/usr/lib/x86_64-linux-gnu/libXext.so - found
      -- Looking for gethostbyname
      -- Looking for gethostbyname - found
      -- Looking for connect
      -- Looking for connect - found
      -- Looking for remove
      -- Looking for remove - found
      -- Looking for shmat
      -- Looking for shmat - found
      -- Looking for IceConnectionNumber in ICE
      -- Looking for IceConnectionNumber in ICE - found
      -- Found X11: /usr/lib/x86_64-linux-gnu/libX11.so
      -- Found PkgConfig: /usr/bin/pkg-config (found version "0.29.1")
      -- Checking for module 'xcb'
      --   Found xcb, version 1.13
      -- Checking for module 'xcb-ewmh'
      --   Found xcb-ewmh, version 0.4.1
      -- Checking for module 'xcb-screensaver'
      --   Found xcb-screensaver, version 1.13
      -- Could NOT find dbusmenu-qt5 (missing: dbusmenu-qt5_DIR)
      CMake Error at src/gui/CMakeLists.txt:265 (message):
        dbusmenu-qt5 was not found.  Either install it or pass -DUSE_DBUS_MENU=0 to
        fall back to the default Qt tray icon.


      -- Configuring incomplete, errors occurred!
      See also "/tmp/ckb-next/build/CMakeFiles/CMakeOutput.log".
      See also "/tmp/ckb-next/build/CMakeFiles/CMakeError.log".
      An error occurred,
      press enter to exit.
      Bus 003 Device 004: ID 1b1c:1b75 Corsair
      Bus 003 Device 003: ID 1b1c:1b4f Corsair
      corsair.install passed
      testing corsair.remove
      make: *** No rule to make target 'uninstall'.  Stop.
      corsair.remove passed
      TEST 19 corsair.sh test result is: PASSED


Noise!

