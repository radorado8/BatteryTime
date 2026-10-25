# BatteryTime

Natívna macOS aplikácia v hornom paneli, napísaná v Swifte bez externých závislostí. macOS 13 alebo novší.

`▣ 3h 24m · ⚡ 5h 10m`

- **▣**: čas zapnutej obrazovky od posledného odpojenia nabíjačky, rovnaký výpočet ako pôvodný `battery_time.sh`.
- **⚡**: zostávajúca výdrž podľa macOS. `AC` znamená napájanie zo siete, `…` nedostupný alebo práve počítaný odhad.
- Kliknutie otvorí podrobnosti, manuálne obnovenie a **Nastavenia…** s intervalom 1–120 celých minút (predvolene 1 minúta).
- Aplikácia nemá okno v Docku. Ukončuje sa cez menu v hornom paneli.

## Inštalácia na iný MacBook

1. Otvor [najnovší release](https://github.com/radorado8/BatteryTime/releases/latest) a stiahni súbor `BatteryTime-v0.5.4-universal.zip` v sekcii Assets.
2. Rozbaľ ZIP a presuň `BatteryTime.app` do priečinka **Applications / Aplikácie**.
3. Spusti aplikáciu. Údaje sa zobrazia v hornom paneli; aplikácia nemá ikonu v Docku.
4. V Nastavenia… môžeš zapnúť automatické spúšťanie po prihlásení.

Balík podporuje **Apple Silicon aj Intel**, macOS 13 a novší. Na druhom Macu netreba Xcode ani Python. Nastavenia a história sa čítajú lokálne na danom Macu.

Aplikácia má ad-hoc podpis a **nie je notarizovaná spoločnosťou Apple**. Ak macOS pri prvom spustení zablokuje neovereného vývojára, po pokuse o spustenie otvor **Systémové nastavenia → Súkromie a bezpečnosť → Otvoriť aj tak**. Podrobnosti: [návod Apple](https://support.apple.com/102445). Globálne bezpečnostné nastavenia netreba vypínať.

## Spustenie zo zdrojov

Hotová aplikácia je v `build/BatteryTime.app`. Dvojklikom ju spusti alebo použi:

```sh
open build/BatteryTime.app
```

Môžeš ju presunúť do Applications. Automatický štart zapneš alebo vypneš priamo v menu aplikácie → Nastavenia… → **Spustiť po prihlásení do macOS** → Uložiť. Prepínač číta skutočný stav zo systému cez SMAppService. Ak macOS vyžaduje schválenie, aplikácia ponúkne otvorenie Prihlasovacích položiek.

## Zostavenie a kontrola

Vyžaduje Xcode alebo Command Line Tools so Swiftom:

```sh
./build.sh
./test.sh
build/BatteryTime.app/Contents/MacOS/BatteryTime --diagnose
```

`./build.sh` vytvorí aplikáciu pre aktuálny Mac. `./build.sh --universal` vytvorí spoločný balík pre Apple Silicon a Intel. Aplikácia sa podpisuje lokálnym ad-hoc podpisom; na distribúciu bez upozornenia Gatekeepera je potrebný Developer ID podpis a notarizácia.

`./release.sh` spustí testy, vytvorí univerzálnu aplikáciu, ZIP a SHA-256 kontrolný súčet v `build/release/`.

## Význam a limity merania

Zdrojom sú časové udalosti `pmset -g log`. Meranie zahŕňa všetok čas zapnutej obrazovky, aj zamknutú obrazovku; nejde o systémový Screen Time ani súčet používania aplikácií. Rovnako ako pôvodný skript pokračuje aj po pripojení nabíjačky a vynuluje sa pri ďalšom prechode na batériu. Odhad vychádza len z dostupnej systémovej histórie; pri chýbajúcom odpojení sa zobrazí pomlčka. Neúplná história môže spôsobiť neúplný výsledok.

Údaje sa obnovujú na pozadí vo zvolenom intervale a po prebudení Macu. Aplikácia nespúšťa pôvodný skript a nepotrebuje Python, prístupnosť ani nahrávanie obrazovky. Nastavenie sa ukladá v UserDefaults pod `local.BatteryTime`. Žiadna sieťová komunikácia.

Odhad výdrže používa [Apple IOPSGetTimeRemainingEstimate](https://developer.apple.com/documentation/iokit/1523835-iopsgettimeremainingestimate) a prípadne `kIOPSTimeToEmptyKey`; mení sa podľa záťaže.

## Projekt a Git

`Sources/` obsahuje aplikáciu a parser histórie, `Tests/` kontroluje výpočet. `build/` je ignorovaný cez `.gitignore`. Verejný repozitár: [radorado8/BatteryTime](https://github.com/radorado8/BatteryTime). Hotové aplikácie sú publikované cez GitHub Releases.

## Ikona

Vlastná ikona batérie s hodinami je v `Assets/AppIcon.png`. Jej upraviteľný generátor je `Tools/make-icon.swift` (AppKit). `Assets/AppIcon.icns` obsahuje všetky veľkosti pre macOS a pri zostavení sa pridá do aplikácie.

## Režimy horného panela

V Nastavenia… → Zobrazenie v hornom paneli vyber:

- Iba zostávajúci čas.
- Iba čas zapnutej obrazovky.
- Čas obrazovky aj zostávajúci čas (predvolený režim).
- Súčet časov s farebnou čiarou pod časom: červená časť predstavuje čas obrazovky, zelená zostávajúcu výdrž. Dĺžky sú úmerné časom, nie percentu nabitia batérie.

- Celkový a zostávajúci čas.
- Celkový čas a čas obrazovky.
- Všetky tri časy: celkový, obrazovka, zostávajúci.

Vo všetkých režimoch s celkovým časom je pod ním farebná čiara. `Σ` označuje celkový čas, `▣` čas obrazovky a `⚡` zostávajúci čas.

Súčet je čas obrazovky od posledného odpojenia + aktuálny odhad zostávajúcej výdrže, nie garantovaná celková výdrž. Pri chýbajúcom údaji alebo napájaní zo siete sa zobrazí `Σ —` a sivá čiara. Voľba režimu sa ukladá a prejaví sa hneď po Uložiť. Podrobnosti oboch časov sú stále dostupné v menu a pri podržaní kurzora nad položkou panela.

Menu po kliknutí vždy zobrazuje celkový čas, čas obrazovky a zostávajúci čas, bez percent batérie, dátumu odpojenia alebo času posledného obnovenia.
