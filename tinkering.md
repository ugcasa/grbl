tinkering.md

# guru-client - tinkering

Random ideas, pre-spec etc.


## guru-cli:wekan:install

### snap method

```bash
# requirements
sudo apt-get install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
# install
sudo snap install wekan
sudo snap set wekan root_url="http://localhost"
sudo snap set wekan port='3001'
sudo systemctl restart snap.wekan.mongodb
sudo systemctl restart snap.wekan.wekan
```


## guru-cli:mount issue

If not mountable, just quit with error do not ask input from user.

	casa@electra:~/guru/.data/project/summer$ ./launch.sh
	project slummer laucher
	input source folder at server: ^C
	casa@electra:~/guru/.data/project/summer$



## lokaatiotägit

**note muutos**

- otsikossa määritellään `projecti:kohde: Itse otsikko`
  - esim `## guru-cli:todo Pikaisesti korjattavaa`
  - etsitään ##, sitten : jonka vasenta blokkia verrataan:
  	- projetien nimiin
  	- varattuihin sanoihin `(private www wiki todo)`
  	- rajoittaa, esim `wiki` ei voi olla projetin nimi.
  - julkaistaan jokaisella tallennuksella

**mahdollisa kohteita**

- `projetien nimet` (suorittaa projektin julkaisumetodi) `git pull/push git.ujo.guru/project/notes + opt magic to stay bg`
- `private, priva` oma shitti (default) `git pull/push git.ujo.guru/casa/notes`
- `www` julkisin webistys > http://casa.ujo.guru/notes/20210427.html
- `wiki` aktiivisen projetin wiki, tuuttaa wikiin md -> dokuwiki käännöksen jälkeen "wiki.ujo.guru/notes/2021/4/casa-notes.20210427.txt" + tarviiko kutsua uudelleenindeksointia?
- `todo` vaikka kategorisesti ulkopuolinen, sopisi tähän jos vain listaa alla viitaten mahd?
- `secred, password` siirretään lokaalille kryptolevyulle `/modia/casa/safe/notes/casa/sec-notes-20210427.md` (mountataan ensin, salis) jos onnistui poistetaan source tiedostosta ko. kappale ja jätetään viittaus linkillä


## password: wanhan vimpelin ompelukerho

domain: wv-ompelu.fi
user: seppo
pass: kukka

poistuu ja tilalle seuraava:

---

### wanhan vimpelin ompelukerho

[encrypted login information](file:///media/casa/safe/casa/passut/login-info.md.zip)

---

## sepon puhelin tulis korjata

>kappale tallentuu vain privaattiin muistiinpanoon

pitäiskö ratoksi kirjoittaa tutkielma kojootista?


## wiki:elukat/kojootti: kojootti on hieman hämmentynyt hännällinen nisäkäs

>otsikossa oleva käsky `wiki:` ja lokaatio `elukat/kojootti:` luo tai täydentää sivun http://wiki.ujo.guru/elukat/kojootti lisäämällä kappaleen `## kojootti on hieman hämmentynyt hännällinen nisäkäs` sisällön artikkelin loppuun, mukaan lukien tämä kommentti ja kuva (jos linkki enään toimii).

![keskityypillinen Kojootti](https://respawn.fi/wp-content/uploads/2018/08/Wile-E-Coyote.jpg)


## Change lög ünd stuff

>priva ellei ###

Date              | Author     | Changes
------------------|:----------:|------------------------------
20210427-01:16:53 | casa       | created
20210427-01:16:55 | guru       | tags added: note 20210427
20210427-01:17:40 | casa       | opened

## meta blokki?

```
<meta>
<file /home/casa/guru/notes/casa/2021/04/casa_notes_20210427.md>
<www http://casa.ujo.guru/notes/20210427.html>
<wiki http://casa.ujo.guru/wiki/20210427.txt>
<project note guru-cli>
<tag text md casa note 20210427>
<ver 1.0.1>
</meta>
```

---

<meta>
<file /home/casa/guru/notes/casa/2021/04/casa_notes_20210427.md>
<www http://casa.ujo.guru/notes/20210427.html>
<wiki http://casa.ujo.guru/wiki/20210427.txt>
<project note guru-cli>
<tag text md casa note 20210427>
<ver 1.0.1>
</meta>

---


## architecture: module construction

Cause things tend to grow or/and get separated, only to bring parts back together later it is better to create folder for module and move workers and libraries in to it. <module>.sh is just an adapter for workers located in folder named by module name.

Example:

tagging is a file operation so tag.sh should be part of file module

	/modules/file.sh
	/modules/file/tag.sh
				  send.sh
				  poller.sh
				  remove.sh

with core "module" sub-foldering should not be in use.

**to solve 1.1): command flow vs. module/sub-module naming** natural command pass trough is:

	guru file send <file(s)/folder(s)><to_where>

but is more natural to say:

	guru send file (<file(s)/folder(s)>) (to) <to_where>

Solvable by logical naming and aliases or more clever core parser.

I would go with logical file naming and clever command flow, even though it can cause temporary inconsistencies.. it's more fun.

..or something else?

Does Kali bring here some solution?


## file module to contain file operations

- file module: send function to send stuff to server, phone, hostname ...
- include tag, poller,  module functionalities file folder and create hard alias for 'tag'


## config module improvements

- add 'enable' variable to user.cfg for all configurations (affects all modules that configured trough/by terminal environmental variables)
- update config module to handle all module configuration tasks
- move all user.sh functionalities to config.sh section user

- should user.cfg chapters correlate and how strongly with core module names, now quote loosely?

## ckb-next inport/export animation settings


connected device list

	kb_device_file=$(cat /dev/input/ckb0/connected |grep Keyboard|cut -f1 -d " ")
	kb_device_serial=$(cat /dev/input/ckb0/connected |grep Keyboard|cut -f2 -d " ")
	kb_device_model=$(cat /dev/input/ckb0/connected |grep Keyboard|cut -f4- -d " ")

Nope, better

	kb_device_file=$(cat /dev/input/ckb0/connected |grep Keyboard|cut -f1 -d " ")
	kb_device_model=$(cat model)


## Disable caps lock

xmodmap tesed, did not work

To turn off caps lock key, enter:

	setxkbmap -option ctrl:nocaps

To reset caps lock. enter:

	setxkbmap -option


get method, casp lock do not have rule (i think)

	gsettings get org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ next-tab '<Primary>Right'



For gnome you can use

	gsettings set org.gnome.desktop.input-sources xkb-options "['caps:ctrl_modifier']"

While the preferred way for X is now

	setxkbmap -option caps:ctrl_modifier


how to run script instead of bind to ctrl_modifier?


dconf read /org/gnome/desktop/input-sources/xkb-options

https://www.stevencombs.com/linux/2020/04/14/capslock-as-launcher.html

	setxkbmap -option caps:none
	 xmodmap -e "keycode 66 = Scroll_Lock"
	 xmodmap -e "keycode 78 = Caps_Lock"

gsettings get org.gnome.Terminal.ProfilesList default

why this guy uses albert?

hmm.. this is not os.. but not waist of time, learned thing like xev.. evx.. vex?.. ok, did not learn a thing =D


### this guy, yes.. looks good


https://michael.humanfactors.io/blog/debian-hyperkey-binding/


## gnome-terminal setting

https://ncona.com/2019/11/configuring-gnome-terminal-programmatically/

example:

```bash
GNOME_TERMINAL_PROFILE=`gsettings get org.gnome.Terminal.ProfilesList default | awk -F \' '{print $2}'`
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ font 'Monospace 10'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ use-system-font false
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ audible-bell false
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ use-theme-colors false
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ background-color '#000000'
gsettings set org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ foreground-color '#AFAFAF'

```

You can list all the properties that can be configured:

	gsettings list-keys org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/s

get value

	gsettings get org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$GNOME_TERMINAL_PROFILE/ foreground-color