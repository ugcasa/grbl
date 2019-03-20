Guru io connector client 
-------------------------

Aim is to connect ujo.guru computers through the mobile barriers.

Cause *giocon.client* will be used with terminal and aim is to make usage child easy, text based menu interface with command line argument control selected as user intercase. 

Based on [Freesi diagnostics](https://bitbucket.org/freesi/diagnostics)



Plan - Suunnitelma (in finnish)
-------------------------------

Kun esteban haluaa että esteban ottaa yhteyden kommonikoidaan seuraavasti

- http://lassila.ujo.guru:XX webuserveri saa parametrin `?ssh=esteban` (php/java style)
- MQTT topic `lassila/estella/ssh-reverse` julkaistaan arvo `esteban`  (metodi löytyy "diagnostic" projektista)
- toimiston puhelinumeroon tulee tekstiviesti "ssh esteban"


## Nimi
 - control jotn. - nyt vasta yhteyksien luontiin
 - access, accesser - paska kirjoittaa
 - tunnel, tunneler - ei ihan osu
 - connec, connecter, ugconnector, gio.connector, connector, pinemmille giot.controller, **giocon ja giotcon**
- asiakaspäään apin nimi on **giocon.client**


## [Forkataan diagnostic](https://ujoguru@bitbucket.org/ugdev/giocon.client.git)

 - `git clone https://ujoguru@bitbucket.org/ugdev/giocon.client.git`


## Logo 

![tricon.png](./icons/tricon.png)

Valitettavast kuvat huonosti skaalatti, eli ei ollenkaan. Mikä olisi mieleisin?

## Wiki 

Kirjoitetaan Freesi ulos, lyhennetaan ja jaetaan uudestaan (kun sen aika)