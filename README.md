Guru io connector client and user tools
---------------------------------------

![tricon.png](./icons/giocon-150px.png)

[giocon](https://bitbucket.org/account/user/ugdev/projects/GIOC) 
is terminal and menu tool kit to connect ujo.guru computers through the mobile barriers over ssh. 

Cause *giocon.client* will be used with terminal and aim is to make usage child easy, text based menu interface with command line argument control selected as user intercase. 

### Install 

Clone giocon client: `git clone https://ujoguru@bitbucket.org/ugdev/giocon.client.git`
run install.sh by typing `./install.sh`


To disable type `gio.disable` and to enable type `gio.enable` and open new terminal. 

Test by typing `play.by nyan cat`

----


## Noter, stamper, dozer -> notes

# uguru.io (ujoguru) Work Flow Tool Kit

![logo](./icons/noter-128px.png)

Lähinnä Juhan ja Marjan käyttöön muutama simppeli tekstinkäsittelyskripti. 
Nothing special. 

### Käyttö

Pikanapit siirtää sisällön leikepöydälle, pasetetaan käsin haluttuun kohtaa tekstitidostoa. 
Suurin osa toolkitistä perustuu markdown syntaksiin.
Pikanapit toimii järjestelmän laajuisesti ja kutsuttavissa myös konsolista. 
Listan käskyista saa kirjoittamalla `gio.` ja painamalla *Tab* näppäintä paristi. 
Tiedostossa 'sfg/noter.cfg' määritellään muistiinpanon lokaatio ja editori.

Ominaisuuksia mm: 

- *FUNC+n* avaa kyseisen päivän muistiinpanon
- Työajan aloitus ja lopetus neljännestunnin tarkkuudella painotetusti. Pikanapit *CTRL+F10* aloitus ja lopetus *CTRL+F12* *CTRL+F11* on puhdas keskiarvo
- erilaisia tekstileimoja *FUNC+j c, m, h* nimikirjoituksia, headereita yms.
- aikaleimata *FUNC+d, datestamp, F9 timestamp*
- Lisäksi muutama taktinen esim *F1* avaa terminaalin
- Terminaalin puolella *gio.dozer* kääntää markdown tiedoston openofficen formaattiin ujo.gurun innohomen tai dealcompin templatelle
- Myös terminaalityökalu lähinnä tiedostonimien tuottamiseen asiakayrityksille *gio.datestamp* tuottaa eri firmojen haluamia aikaleimoja jotka poikkeaa ujo.gurun leimoista (esim innolle formaatissa '1stFab2019')
- Vielä erillisenä, mutta intrgroidaan puhelimen kuvien hakutoiminto perustuen ssh/scp kun samassa lähiverkossa
- Työaikaparseri *memoparser* on omassa repossaan. Lisätään myöhemmin installeriin toiminto joka kloonaa tarvittavat osat mukaan tai integroidaan suoraan tähänn repoon (jälkimmäinen mielestäni parempi) yksinpuhelua issuetrackerissä lisää. 

----
casa (c) ujo.guru 2015 - 2019
