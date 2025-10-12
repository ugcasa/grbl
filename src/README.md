# grbl iron core


Tarkoituksena on kirjoittaa coren toiminnasuus c- kielellä. common.sh yleiskäyttöfunktiot 
sisällytetään 

Selvitetään 

- dokumentoidaan core.sh
    - [ ] mitä ympäristömuuttujia tarvitaan 
- mitä toiminteita nyksyssä core.sh varsin käytetään. 



Valitaan seuraavat periaatteet ([x] valittu)

core joka
- [ ] tunnistaa käskystä varatut verbit, lista on coren globaali muuttuja
- [ ] käsitelee lyhyet optiot (-dcfq) ja muuttujalliset (-vuh)
- [ ] välittää käskyt vaaditussa järjesteyksessä modulille, 
- [ ] välitetään pitkät optiot arvoineen modulille lyhyinä (--n > -n)
- [ ] modulit ei ole itsenäisiä, 
- [ ] jos rc-tiedosto puuttuu lähtee moduli etsimään ensin käyttäjän ja sitten default cfg 
- [ ] jos minkään tasoista cfg ei löydy ulos errorilla 

Bash modulit
- [ ] Luodaan elinympäristö sh moduleille?
  - [ ] source moduli.sh, suorittaa konfiguroinnin ja muodostaa .rc tiedoston /tmp/ 
  - [ ] source .rc tietostosta populoi modulin ympäristömuuttujat 
  - [ ] modulin funktiot on käytettävissä `moduli.main()` kautta tai suoraan `moduli.funktio()`
- [ ] Suoritetaan /bin/bash sh moduli ja odotellaan paluukoodia?

c- ympäristö 
- [ ] makefile? 
- [ ] cmake?
- [ ] gcc?
  
Binaarit
- [ ] kannetaan käännetyt modulit mukana gitissä 
- [x] käännetään asennuksen yhteydessä. install.sh pitää huolen kääntötyökalujen asennuksesta. 
- [ ] jos asennus on olemssa käännetään vain muuttuneet

Aliakset
- [ ] muutama esimerkiksi?
- [ ] käyttäjä määrittelee kaikki?
- [ ] runsaasti oikoteitä?

Asennus
- [x] asentuu > ~/bin, jotta ei tarvi sudo asennuksessa
- [x] symlik ~/bin > asenuskansioon = fast upgrade and branch testing
  - [ ] media kulkee paremmin mukana
  - [ ] default config < cfg/ << ~/config/grbl/$USER/
  - [ ] ei tarvi asentaa muutoksia testauttaessa
- [ ] ~~kopioida asenuskansioon > ~/bin = nykyinen, raskaampi~~

