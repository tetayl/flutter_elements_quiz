# Flutter web - alkuaineharjoitukset

Yksinkertainen Flutter web -sovellus kahdella harjoituksella
- Näytetään lyhenne - valitse oikea nimi
- Näytetään nimi - valitse oikea lyhenne

Kumpikin käyttää samaa JSON-dataa `assets/elements.json`. Oletuksena mukana kaikki alkuaineet.

## Kehitys

- Asenna Flutter SDK
- Aja komennot:

```bash
flutter pub get
flutter run -d chrome
```

## Build web

```bash
flutter build web
```

Buildin jälkeen hakemistossa `build/web` on staattiset tiedostot.

## Julkaisu GitHub Pagesiin

Tämä projekti toimii GitHub Pagesissa. Tarvitset vain `build/web` -kansion sisällön. 
