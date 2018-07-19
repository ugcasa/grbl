# Asentajan tietokoneen työkalut 

* [Asentajan ohjeet](https://bitbucket.org/freesi/laptop-tools/wiki/Home) (wiki is in Finnish)
* [Vika ja parannusolmoitukset ](https://bitbucket.org/freesi/laptop-tools/issues?status=new&status=open) 

| Käsky | tekninen kuvaus | Kuvaus | Tilanne
| ---------- | -------------- | ------------------------------------------------------------------ | ---
| `test` | mqtt sub + cfg | Asentaja voi seurata mitä asennettavassa verkossa tapahtuu | Käytössä |
| `commander` | mqtt pub + cfg | Kontrollerille voidaan antaa käskyjä | Käytossä |
| `remote` | cfg + rewerse ssh > ujo.guru:2018 | Avaa huoltoterminaalin | Ei tuotannossa |
| `injector` | cfg + rewerse scp | Voidaan vaihtaa yksittäisen asetuksen sisältöä | TODO |
| `update` | clone + rm .git | Asentaja voi päivittää kontrollerin softan | TODO | 

 



### Vaatimukset

* Linux käyttöjärjestelmä (debian)
* nettiyhteys
* git asennettuna
* tarvittavat ohjelmointi- ja asetuslaitteet (määritellään myöhemmin)


