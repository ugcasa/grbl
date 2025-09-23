todo.md

TBD tests for update version 0.4.4 to v0.5.0 (2022-05-27)

Full Changelog
Support for new devices:
    K95 Platinum XT
    Katar Pro
    Katar Pro XT
    Glaive Pro
    M55
    K60 Pro RGB
    K60 Pro RGB Low Profile
    K60 Pro RGB SE
K68 patch still needed? TBD
Important bugfixes:
    Scroll wheels are now treated as axes (Responsiveness should be improved for specific mice)
    The lights on the K95 RGB Platinum top bar are now updated correctly
  ! An infinite loop is prevented if certain USB information can not be read
 !! GUI no longer crashes on exit under certain conditions
    Mouse scrolling works again when combined with specific libinput versions
 !! The daemon no longer hangs when quitting due to LED keyboard indicators
    The lighting programming key can now be rebound on K95 Legacy
  ! Animations won't break due to daylight savings / system time changes
 !! GUI doesn't crash when switching to a hardware mode on a fresh installation
!!! Daemon no longer causes a kernel Oops on resume under certain conditions (Devices now resume correctly from sleep)
    Window detection is more reliable and works correctly on system boot
    Settings tab now stretches correctly
    Profile switch button can now be bound correctly on mice
    ISO Enter key is now aligned correctly
    Bindings are now consistent between demo and new modes
    Firmware update dialog is no longer cut off and can be resized
    RGB data won't be sent to the daemon when brightness is set to 0%
New features:
    German translation
    66 service (not installed automatically)
    Device previews are now resizable
first installation on 24.04
PPA method worked fine
config: /home/casa/.config/ckb-next/ckb-next.conf

