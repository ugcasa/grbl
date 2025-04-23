############################ corsair help printouts ###############################
# relies on corsair variables, source only from corsair module

corsair.help-profile () {
# inform user to set profile manually (should never need)
    gr.msg "set ckb-next profile manually" -h
    gr.msg -v1 "1) open ckb-next and click profile bar and select " -n
    gr.msg -v1 "Manage profiles " -c white
    gr.msg -v1 "2) then click " -n
    gr.msg -v1 "Import " -c white -n
    gr.msg -v1 "and navigate to " -n
    gr.msg -v1 "$GRBL_CFG " -c white -n
    gr.msg -v1 "select " -n
    gr.msg -v1 "corsair-profile.ckb " -c white
    gr.msg -v1 "3) then click " -n
    gr.msg -v1 "open " -c white -n
    gr.msg -v1 "and close ckb-next"
}

corsair.help () {
# general help
    gr.msg -v1 "grbl corsair keyboard indicator help" -h
    gr.msg -v2

    gr.msg -v0 "usage:           $GRBL_CALL corsair start|init|reset|end|status|help|set|blink <key/profile> <color>"
    gr.msg -v1 "setup:           install|compile|patch|remove"
    gr.msg -v2 "without systemd: raw start|raw status|raw stop "
    gr.msg -v2

    gr.msg -v1 "commands: " -c white
    gr.msg -v1 "  status                            printout status "
    gr.msg -v1 "  start                             start ckb-next-daemon "
    gr.msg -v1 "  stop                              stop ckb-next-daemon"
    gr.msg -v1 "  init                              initialize keyboard mode" -V2
    gr.msg -v2 "  init <mode>                       initialize keyboard mode listed below:  "
    gr.msg -v2 "                                    olive, blue, eq, trippy, rainbow"
    gr.msg -v1 "  set <key> <color>                 write key color <color> to keyboard key <key> "
    gr.msg -v1 "  reset <key>                       reset one key or if empty, all pipes "
    gr.msg -v1 "  blink set|stop|kill <key>         control blinking keys" -V2
    gr.msg -v2 "  blink set|stop|kill <key>         control blinking keys. to set key following:"
    gr.msg -v2 "    set <key color1 color2 speed delay leave_color>  "
    gr.msg -v2 "    stop <key>                      release one key from blink loop"
    gr.msg -v2 "    kill <key>                      kill all or just one key blink"
    gr.msg -v1 "  indicate <state> <key>            set varies blinks to indicate states." -V2
    gr.msg -v2 "  indicate <state> <key>            set varies blinks to indicate states. states below:"
    gr.msg -v2 "    done, active, pause, cancel, error, warning, alert, calm"
    gr.msg -v2 "    panic, passed, ok, failed, message, call, customer, hacker"
    gr.msg -v1 "  type <strig>                      blink string characters by keylights "
    gr.msg -v1 "  end                               end playing with keyboard, reset all keys "
    gr.msg -v1 "  key-id                            printout key indication codes"
    gr.msg -v1 "  keytable                          printout key table, with id's increase verbose -v2"
    gr.msg -v2

    gr.msg -v1 "installation and setup" -c white
    gr.msg -v2 "  patch <device>                    edit source devices: K68, IRONCLAW"
    gr.msg -v2 "  compile                           only compile, do not clone or patch"
    gr.msg -v1 "  install                           install requirements "
    gr.msg -v1 "  remove                            remove corsair driver "
    gr.msg -v2 "  set-suspend                       active suspend control to avoid suspend issues"
    gr.msg -v2

    gr.msg -v2 "WARNING: This module can prevent system to go suspend and stop keyboard for responding" -c white
    gr.msg -v2 "If this happens please be patient, control will be returned:"
    gr.msg -v2 "  - wait until login window reactivate, it should take less than 2 minutes "
    gr.msg -v2 "  - log back in and remove file '/lib/systemd/system-sleep/grbl-suspend.sh'"
    gr.msg -v2 "System suspending should work normally. You may try to install suspend scripts again "
    gr.msg -v2

    gr.msg -v2 "setting up daemon and suspend manually: " -c white
    gr.msg -v2 "  $GRBL_CALL corsair help profile       show how configure profile"
    gr.msg -v2 "  $GRBL_CALL corsair enable             enable corsair background service"
    gr.msg -v2 "  $GRBL_CALL system suspend install     set up grbl suspend scripts"
    gr.msg -v2

    gr.msg -v1 "examples:" -c white
    gr.msg -v1 "  $GRBL_CALL corsair help -v2            get more detailed help by adding verbosity flag"
    gr.msg -v1 "  $GRBL_CALL corsair status              printout status report "
    gr.msg -v1 "  $GRBL_CALL corsair init trippy         initialize trippy color profile"
    gr.msg -v1 "  $GRBL_CALL corsair indicate panic esc  to blink red and white"
    gr.msg -v2 "  $GRBL_CALL corsair blink set f1 red blue 1 10 green"
    gr.msg -v2 "                                   set f1 to blink red and blue second interval "
    gr.msg -v2 "                                   for 10 seconds and leave green when exit"

    gr.msg -v0 "For more detailed help, increase verbose with option" -V2
}

corsair.keytable () {
# printout key table with numbers when verbose is increased

    case $1 in number|numbers) GRBL_VERBOSE=2 ;; esac
    gr.msg -v1
    gr.msg -v1 "Indicator pipe file id's" -h
    gr.msg -v2
    gr.msg -v1 "Keyboard indicator pipe file id's" -c white
    gr.msg -v0 "                                                  brtightness  sleep" -c white
    gr.msg -v2 "                                                     109        110 " -c dark
    gr.msg -v0 "esc f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12        print  scroll  pause      stop prev play next" -c white
    gr.msg -v2 " 0   1  2  3  4  5  6  7  8  9  10  11  12         13      14      15        16   17   18   19" -c dark
    gr.msg -v3
    gr.msg -v0 "half 1 2 3 4 5 6 7 8 9 0  plus query backscape    insert  home   pageup     numlc div  mul  sub" -c white
    gr.msg -v2 " 20  1 2 3 4 5 6 7 8 9 30  31  32      33          34      35      36        37   38   39   40" -c dark
    gr.msg -v3
    gr.msg -v0 "tab q w e r t y u i o p  å tilde enter             del   end  pagedown      np7   np8  np9  add" -c white
    gr.msg -v2 " 41 2 3 4 5 6 7 8 9 50 1 2  53    54               55      56      57        58   59   60   61" -c dark
    gr.msg -v3
    gr.msg -v0 "caps a s d f g h j k  l ö ä asterix                                         np4   np5  np6" -c white
    gr.msg -v2 " 62  3 4 5 6 7 8 9 70 1 2 3    74                                            75   76   77" -c dark
    gr.msg -v3
    gr.msg -v0 "shiftl less z x  c v b n m comma perioid minus shiftr     up                np1   np2  np3 count" -c white
    gr.msg -v2 "  78    79 80 1  2 3 4 5 6   87     88     89    90       91                92    93   94   95" -c dark
    gr.msg -v3
    gr.msg -v0 "lctrl func alt space altgr fn set rctrl           left   down  right        np0   decimal " -c white
    gr.msg -v2 "  96   97   98   99  100  101 102  103            104    105    106         107     108" -c dark
    gr.msg -v1
    gr.msg -v2 "Mouse indicator pipe file id's" -c white
    gr.msg -v1
    gr.msg -v3 "thumb  wheel logo " -c white
    gr.msg -v3 " 201    202   200 " -c dark
    gr.msg -v2 "(Note: mouse indicator pipe file id's not implemented)"  # TBD
    gr.msg -v1
    gr.msg -v2 "Use thee digits to indicate id in file name example: 'F12' pipe is '/tmp/$USER/ckbpipe012'"
    gr.msg -v3
    gr.msg -v3 "Corsair_key_table list: " -c white
    gr.msg -v3 "$(corsair.key-id)}"
}
