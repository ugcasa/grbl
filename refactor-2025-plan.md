# Suunnitelma `grbl 0.7.5` final ja nimenvaihto `grbl` "gerbil" 

- `feature/modulin_nimi` Pyritään pitämään eteneminen selkeänä, moduli kerrallaan 

- `bugfix/issue`  bugfixit alkaa myös devistä ja jos;
  - on pienitöinen ja voidaan siten puskea masteriin ennen ominaisuutta
    - tällöin koitetaan korjata siten ettei kollisio julkaisun mergessä
    - pusketaan deviin ja sieltä masteriin
  - jos on samaisessa modulissa joka työnalla ominaisuutena
    - aikataulutetaan julkaisuun
    - jos on pakko tehdä niin tehdään varovaisesti ja cherrypikataan featureen 



## 2. `gpbl` muutetaan remotessa projektin nimi 

- [x] muutetaan remotessa projektin nimi `gpbl`
- [x] cloonastaan uuteen hakemistoon `code` 
  - tällä pitäisi välttyä origin nimen säätelystä lokalina
  - jos kuitenkin tulee konffailla, sitten konffaillaan
- [x] testataan että konfigit toimii

```sh
cd code
git pull https://github.com/ugcasa/grbl.git
git remote set-url origin git@github.com:ugcasa/grbl.git
```
## 1. Luodaan nykyisestä uusi haara `release/0.7.5`

- [x] tehdään `release/0.7.5` haara 
- [x] ja pusketaan remoteen 
- tämä hakemisto saa jäädä paikalliseksi arkistoksi ja josta voidaan intalloida toimiva 
- ei tehdä pull reguestia, koskaan

```sh
git checkout master
git checkout -b release/0.7.5
git push origin release/0.7.5
git tag 0.7.5
```

## 3. Tehdään `dev` haara

- Otetaan masterista uusi haara nimeltä 'dev' josta haaroitellaan featuret ja bugfixit
- Uudet ominaisuudet alkaa aina devistä
- ei tehdä pull reguestia, vielä

```sh
git checkout master
git checkout -b dev
git push origin dev
```
- Nyt on dev branch olemassa lokaalina ja remotessa


## 4. Dellitään toimimattomat

- [ ] tehdään lista mitkä on välttämättömiä
- [ ] dellitään huuhaamodulit pois
- [ ] ei tärkeät modulit pois
- [ ] testataan käsin että toimii
  - testaamista helpottaa että jäljellä on vain todella toiminan kannalta välttämättömät osat
- [ ] testataan vielä kerran kielon päälle, tässä saa mennä aikaa

```sh
git branch --show-current
git rm -r broken_modules
git commit -m "Poistettiin toimimattomat moduulit"
git push origin dev
```

## 5. Aletaan muuttaa pritouttien ja muuttujien nimiä

- [ ] tehdään `name-change` haara
- [ ] muutetaan muuttujien nimet
- [ ] muutetaan viestejä 
  - [ ] help funktiot
- [ ] muutetaan konffitiedostot   
  - testataan jatkuvasti että toimii
  - samalla voi kirjoittaa testikeissejä
- [ ] tehdään laajempi testi jossa käydään tarpeellimen määrä asioita läpi
- [ ] mergetään feature/name-change deviin

```sh
git checkout -b feature/name-change
git commit -m "GRBL_ -> GRBL_ "
git commit -m "koodissa grbl nimi grbl:si"
git commit -m "config tiedostoissa grbl nimi grbl:si"
git push origin feature/name-change
git checkout dev
git merge feature/name-change
git push origin dev
git push -d feature/name-change # dellii remoten
git branch -d feature/name-change # dellii remoten
```

## 6. Varmistetaan että serverin päässä ei tule esteitä nimenmuutoksesta

- [ ] käydään rankenne läpi jos muutettavaa
  - [ ] tehdään symlinkit, mutta ei kosketa originaaleihin
  - kaiken pitäisi toimia, grbl nimi siellä täällä, mutta user konfiguraatiot pysyy kuitenkin samoina
  - muutetaan myöhemmin mikäli tarpeelliseksi nähdään

```sh
ssh roima
```

## 7. Alustetaan seuraavaa vaihetta ja tehdään massanimenmootukset vanhalle koodille

- [ ] koppastaan koko paska arkistoidusta toiseen hakemistoon
- [ ] vaihdetaan `release/0.7.5` haaraan
- [ ] tehdään sublimellä massamuutokset vastaamaan deviin tehtyjä muutosia
  - [ ] muutetaan muuttujien nimet
  - [ ] muutetaan viestit 
  - [ ] muutetaan konffitiedostot
- [ ] tätä ei tarvitse testata, massamuutokset riitää

```sh
cp grbl gr-0.7.5
git checkout release/0.7.5
```
- Kun tämä vaihe valmis voidaan aloitaa vanhojen modulien tuonti uudelle puolelle

## 8. Aletaan tuomaan moduleita vanhasta koodista

- [ ] Luodaan `feature/module_name`
- [ ] muokataan muuttujanimet
  - testataan jatkuvasti että toimii (unit test)
  - samalla voi kirjoittaa testikeissejä
- Integraatiotestataan aluksi käsin (ja myöhemmin automaatiolla) feature haaroisa  
- [ ] mergetään feature/name-change deviin

```sh
git checkout -b feature/module_name
git commit -m "moduli x toimii"
git push origin feature/module_name # luodaan myös remoteen uusi branci
git checkout dev
git merge feature/name-change
git push origin dev
```

## 9. Copy pasteillaan kantajulkaisusta 0.7.5 modulin raato kerrallaan 

- korjaillaan
- yksikkötestaillaan testimodulilla ja käsin 
- Testausta jatketaan käsin (ja myöhemmin automaatiolla) dev haarassa
- Kun testit alka mennä läpi mergetään deviin ja voidaan ottaa seuraava bugi/ominaisuus työnalle

```sh
git checkout -b feature/module_name2
git commit -m "moduli x toimii"
git push origin feature/module_name2 # luodaan myös remoteen uusi branci
git checkout dev
git merge feature/module_name2
git push -d feature/module_name2 # dellii remoten
git branch -d feature/module_name2 # dellii remoten
```

## 10. Kokeillaan piruuttaa korjata joku bugi matkalla jotta nähdään toimiiko

```sh
git branch --show-current
git checkout -b bugfix/issue
git commit -m "bugi korjastu"
git checkout dev
git merge bugfix/issue
git push -d bugfix/issue # dellii remoten
git branch -d bugfix/issue # dellii remoten
```

## 11. Kun alkaa olemaan julkaisumieliala tehdään vielä prelease/versionumero  

- testataan
- mergetään deviin 
- jätetään release/versio haisemaan, ei dellitä jotta testejä pääsee ajamaan uudestaan
- ja sieltä masteriin. 

```sh
git checkout -b release/0.7.6
git commit -m "julkaisuvalmis"
git checkout dev
git merge release/0.7.6
git checkout master
git merge release
git tag v0.7.6
```
- Ja sykli alkaa alusta. 

Aikas härdelli on, mutta toivottavasti tuo selkeyttä, vai käykö päinvastoin?
