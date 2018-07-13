## cfg ja seuranta skriptien lisääminen asentajan PC:lle

1. Kopioi emailin liitteet muistitikulle ja kytke tikku asennus PC:lle (käynnissä).

2. Kun USB tikku avautuu, tuplaklikkaa cfg.zip tiedostoa. Paketissa pitäisi näkyä `aqc-kohteen_nimi.cfg` 
3. Paina *Extract* nappia 
4. Navigoi hakemistoon `/home/iisy-aj/tools/cfg` ja paina *Extract* nappia. 
5. Ohjelma kysyy salasanan, syötä ja paina *OK*. (Juha toimittaa SMS viestinä)

6. Siirrä email liitteenä olevat skriptit `syk-oulu` ja `tikankoski-vantaa` hakemistoon `/home/iisy-aj/tools` (Drag and drop)
7. Käynnistä skripti klikkaamalla tiedostoa kohdehakemistossa. Valitse *Run in terminal*


**Vikatilanne 1**

Mikäli skripti aukeaa tekstieditorissa tulee tehdä seuraava muutos ko. tiedostolle. 

1. Klikkaa hiiren kakkosnapilla tiedoston päältä. Aukeaa valikko josta valitaan *Properties*. 
2. Valitse *Permissions* sivulehti ja tee valinta kohtaan *Execute: [] Allow executing file as program*
3. Kokeile uudestaan edellisen ohjeen kohtaa 7. 


**Vikatilanne 2.**

Mikäli kohdat 5 - 9 ei syystä tai toisesta toimi voi seurantasriptin käynnistää myös käsin: 

 `test` (tai `test.sh`) käyttämisen. Jos halutaan pikanappi jonka voi käynnistää klikkaamalla, jatketaan asennusta. 


Avaa terminaali klikkaamalla *Menu* nappia ja kirjoittamalla `terminal` ja enter. Aja seuraavat käskyt

    cd tools
    ./test tikankoski-vantaa

tai 

    ./test syk-oulu
