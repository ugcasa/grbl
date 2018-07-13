Freesi-zigbee-verkon_uudelleengeneroiti


# ZigBee verkon 
uudelleengeneroiti 

## Sammuttaminen

1. Keskusyksiköt sammutetaan hallitusta käskyllä 

        ./commander <profiili> SHD

2. Irroitetaan virroista
3. Kaikki verkon osat tulee irroittaa sähköistä, mielellään heti aluksi



### Keskusyksikkö

Asetuksien palauttaminen onnistuu skriptillä (vaiheet 1-13). Tämän pitäisi riittää useimmissa tilanteissa. 

Jos kuitenkin tulee vaihtaa kohderiippuvaisia asetuksia, esimerkiksi käytössä olevaa kanavaa tulee asetukset tulee tehdä manuaalisesti XCTU ohjelmalla (vaiheet 15 ->). 

**Asetuksien saattaminen perustilaan**

1. Avaa kontrollerityksikkö pohjasta (neljä ruuvia)
2. Irroita joka modeemi jonka jälkeen xstick on helpompi irroittaa ja kytkeä
3. Irroita muut modeemin asetuslaitteet asentajan koneen USB väylästä (silloin on aina /dev/ttyUSB0)
4. Kytke modeemi asetustietokoneen USB väylään 
5. Avaa XCTU työpöydän linkistä
6. Etsi laitteita (vasen yläkulma) "add radio module". 
7. Valitse baudrate 38400
7. Valitse /dev/ttyUSB0 (tai tietämäsi muu portti mikäli kohtaa 3. ei tehty)
8. Hakee hetken asetuksia, kun valmis klikkaa vasemmasta osasta jaettua ruutua ilmestynyttä laitetta
9. Hakee hetken asetuksia, kun valmis valitse "set factory defaults" ja kirjoita modeemille painamalla "write"
10. Valitse "Profile", "Load profile". 
11. Navigoi hakemistoon './tools/ModemSettings' ja valitse "AQC-C1-test-profile_20A7.xpro" ja valitse OK
12. Paina "Write" kirjoittaaksesi asetukset modeemin muistiin. 
14. Mikäli ei tehdä enempää, sulje laite napista vasemmalla puolella jaettua ruutua ja irroita modeemi USB väylästä

**Kanava asetusten muuttaminen**

15. Käynnistä wifi kanavaskanneri läppäriltä käskyllä

        sudo iwlist wlan0 scan

16. Kierrä asennuspaikat läpi, suorita kohdan 10. käsky ja kirjaa löytyneet kanavanumerot ylös. 
17. Soita Juhalle, Laskee kanavamaskin saatujen tietojen perusteella
18. Vaihda kanava-asetukset ohjeiden mukaan 

Huomaa että skannerilla saattaa mennä minutti pari huomata olemassa olevat verkot.

### Reitittimet

#### Asentajan kaapelilla

1. Kytke usb liittimet numerojärjestyksessä
2. Kytke devauskaapeli sensorille siten että liittimessä pinnin 1. merkintä kohtaa kaapelin merkinnän kanssa
3. Avaa terminaali ja mene tools hakemistoon (ellei jo ole) käskyllä 'cd tools'
4. Suorita seuraavaat komennot

        .xbee-setup rf
        .xbee-setup r

5. Mikäli asetuksen teko meni oikein tulisi kumassakin tapauksessa tulla lista [OK] viestejä, muissa tapauksissa tarkista USB kytennät ja aja uudestaan. Reitittimissä ei modeemin reset nappia tarvitse painaa, ellei ole seonnut. 

**Kanava asetusten muuttaminen**

6. Soita Juhalle
7. Vaihda kanava-asetukset ohjeiden mukaan 


#### Devauskaapelilla

1. Aseta devauskaalin kytkimet asentoihin VCC = USB ja RESET sekä USB asentoon MODEM
2. Kytke usb liittimet numerojärjestyksessä
3. Kytke devauskaapeli sensorille siten että liittimessä olevat tarrat osoittavat paristoa kohti. (varmista että kytkimien asento on 
pysynyt)
4. Avaa terminaali ja mene tools hakemistoon (ellei jo ole) käskyllä 'cd tools'
5. Aja alla esitellyt käskyt, valitse laitteen mukaan, sensori tai reititin
6. Jos kyseessä on sensori tulee painaa nappia joka herättää modeemin
7. Suorita seuraavaat komennot

        .xbee-setup rf
        .xbee-setup r

8. Mikäli asetuksen teko meni oikein tulisi kumassakin tapauksessa tulla lista [OK] viestejä, muissa tapauksissa tarkista USB kytennät ja aja uudestaan. Reitittimissä ei modeemin reset nappia tarvitse painaa, ellei ole seonnut. 
9. Mikäli ei tehdä enempää voi seuraavan laitteen voi vaihtaa tilalle ja suorittaa eteenpäin vaiheesta 2.
       
**Kanava asetusten muuttaminen**

6. Soita Juhalle
7. Vaihda kanava-asetukset ohjeiden mukaan 


### Sensorit

#### Asentajan kaapelilla

1. Kytke usb liittimet numerojärjestyksessä
2. Kytke devauskaapeli sensorille siten että liittimessä pinnin 1. merkintä kohtaa kaapelin merkinnän kanssa
3. Avaa terminaali ja mene tools hakemistoon (ellei jo ole) käskyllä 'cd tools'
4. Suorita seuraavaat komennot. Huomaa että modeemin reset nappia tulee painaa oikealla hetkellä. 

        .xbee-setup rf
        .xbee-setup r

5. Mikäli asetuksen teko meni oikein tulisi kumassakin tapauksessa tulla lista [OK] viestejä, muissa tapauksissa tarkista USB kytennät ja aja uudestaan. Reitittimissä ei modeemin reset nappia tarvitse painaa, ellei ole seonnut. 

**Kanava asetusten muuttaminen**

6. Soita Juhalle
7. Vaihda kanava-asetukset vastaamaan kontrollerin asetuksia


#### Devauskaapelilla

1. Aseta devauskaalin kytkimet asentoihin VCC = USB ja RESET sekä USB asentoon MODEM
2. Kytke usb liittimet numerojärjestyksessä
3. Kytke devauskaapeli sensorille siten että liittimessä olevat tarrat osoittavat paristoa kohti. (varmista että kytkimien asento on 
pysynyt)
4. Avaa terminaali ja mene tools hakemistoon (ellei jo ole) käskyllä 'cd tools'
5. Aja alla esitellyt käskyt, valitse laitteen mukaan, sensori tai reititin
6. Jos kyseessä on sensori tulee painaa nappia joka herättää modeemin
7. Päivitä käytetty sensori ajamalla seuraavat käskyt terminaalissa:

Ajettaessa ensimmäinen käskyista tulee sensorin piirilevyllä olevaa nappia painaa lyhyesti kun terminaaliin ilmestyy rivi "- Discovering ..".

        .xbee-setup f
        .xbee-setup

8. Mikäli asetuksen teko meni oikein tulisi kumassakin tapauksessa tulla lista [OK] viestejä, muissa tapauksissa tarkista USB kytennät ja aja uudestaan.
9. Mikäli ei tehdä enempää voi seuraavan laitteen voi vaihtaa tilalle ja suorittaa eteenpäin vaiheesta 3.
       
**Kanava asetusten muuttaminen**

10. Soita Juhalle
11. Vaihda kanava-asetukset vastaamaan kontrollerin asetuksia



