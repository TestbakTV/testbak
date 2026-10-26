# Smart-tv opruimen: reclame-apps eraf (Google TV)

Bij de video **"Ik liet AI mijn smart-tv opruimen"**.

Mijn TCL-tv met Google TV zat vol reclame en apps die ik nooit gebruik. Met ADB, de officiële onderhoudsingang van Android, haal je die apps weg. Je hebt geen root nodig, de garantie blijft intact en alles is terug te zetten.

> **Getest op:** TCL Google TV met Android 14.
> Andere merken (Philips, Sony, Hisense, Chromecast met Google TV) werken op dezelfde manier, maar de apps hebben andere namen. Gebruik dan de stappen en pas `packages.txt` aan.

---

## Wat je nodig hebt

- Een **Windows-pc** op hetzelfde netwerk als de tv
- Ongeveer **15 minuten**
- De afstandsbediening van de tv

## Stap 1: Ontwikkelaarsopties aanzetten op de tv

1. Ga naar **Instellingen → Systeem → Over → Android TV OS-build**.
2. Klik **7 keer** op **Android TV OS-build**.
   Let op: klik niet op "Versie", want dan krijg je alleen een easter egg.
3. Je ziet "Je bent nu ontwikkelaar".
4. Ga naar **Instellingen → Systeem → Ontwikkelaarsopties**.
5. Zet **USB-foutopsporing** aan. Bij sommige tv's heet het ook **Netwerkfoutopsporing** of **ADB via netwerk**.

## Stap 2: Scripts downloaden

Klik hierboven op **Code → Download ZIP** en pak de ZIP uit, bijvoorbeeld in `C:\Temp\testbak`. Open daarna de map `tv-debloat`.

## Stap 3: De tv zoeken (er wordt nog niets verwijderd)

Dubbelklik **`START-tv-scan.cmd`**. Dit script:

1. downloadt ADB van Google (de officiële *platform-tools*);
2. zoekt je tv op het netwerk;
3. maakt verbinding. **Kijk dan op de tv:** bij de melding "Foutopsporing toestaan?" vink je *Altijd toestaan* aan en kies je **OK**;
4. slaat de lijst met alle apps op in de map `tv\`.

> Windows laat misschien de melding "Windows heeft uw pc beschermd" zien. Klik dan op *Meer informatie → Toch uitvoeren*. Lees het script gerust eerst door, het is gewone tekst.

## Stap 4: Kiezen wat er weg moet

Open **`packages.txt`** in Kladblok. Daar staat per app wat hij doet.

- Wil je een app houden? Zet dan een `#` aan het begin van de regel.
- Heb je een ander merk? Kijk in `tv\packages_all.txt` welke apps er op jouw tv staan, en zet de apps die je kwijt wilt in `packages.txt`.

**Laat deze apps altijd staan:** de launcher (`com.google.android.apps.tv.launcherx`), Play Store, Play Services, de instellingen en alles met `bluetooth`, `inputmethod` of `tvsettings` in de naam. Zonder die apps werkt je tv niet goed meer.

## Stap 5: Opruimen

Dubbelklik **`START-tv-debloat.cmd`**. Het script laat eerst de lijst zien en vraagt of je zeker bent. Pas daarna verwijdert het de apps, en daarna kun je de tv laten herstarten.

## Stap 6: Deur weer dicht ⚠️

Zet op de tv **USB-foutopsporing weer UIT**, of zet de ontwikkelaarsopties helemaal uit. Zolang het aan staat, kan elk apparaat op je netwerk proberen verbinding te maken met je tv.

---

## Iets terugzetten?

- **Alles terug:** zet USB-foutopsporing tijdelijk aan en dubbelklik `START-tv-restore.cmd`.
- **Eén app terug:** open PowerShell in deze map en typ:
  ```powershell
  powershell -ExecutionPolicy Bypass -File tv-restore.ps1 com.tcl.channelplus
  ```
- **Fabrieksreset:** daarmee komen ook alle apps terug.

## Liever met de hand? (Mac / Linux)

Installeer de [Android platform-tools](https://developer.android.com/tools/releases/platform-tools) en typ:

```bash
adb connect <ip-van-je-tv>:5555
adb shell pm list packages            # alle apps bekijken
adb shell pm uninstall --user 0 com.tcl.channelplus     # een app weghalen
adb shell cmd package install-existing com.tcl.channelplus   # en weer terugzetten
```

## Hoe werkt het?

`pm uninstall --user 0` haalt een app weg **voor jouw gebruikersprofiel**. De app blijft wel in het systeem van de tv staan. Daarom:

- hoef je niet te rooten, en verandert er niets aan de systeempartitie;
- kun je een app altijd terugzetten met `install-existing`;
- kan een grote firmware-update sommige apps terugzetten. Draai het script dan gewoon nog een keer.

## Wat ik ervan merkte

- Het startscherm heeft geen TCL-reclamerij meer, en er komen geen promoberichten meer.
- De tv voelt iets vlotter, omdat er minder op de achtergrond draait.
- Netflix, YouTube en Google TV werken gewoon.

---

*Gebruik op eigen risico. Getest op mijn eigen tv, maar jouw model kan anders zijn. Vragen? Open een [issue](../../../issues).*
