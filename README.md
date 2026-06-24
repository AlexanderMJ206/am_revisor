# AM Revisor

Et professionelt **FiveM revisor / hvidvask script** med dansk NUI, `ox_target`, candlestick-dashboard og multi-framework support.

<p align="center">
  <img src="./assets/preview.png" alt="AM Revisor Preview" width="900"/>
</p>

---

## Features

- Dansk og clean NUI
- Rødt/sort revisor terminal design
- Candlestick chart med hover-effekt
- Klient dropdown med søg
- Finder spillere tæt på revisoren
- Viser spillernavn i stedet for Steam ID
- Hvidvask af sorte penge
- Revisor kan vælge procent-cut
- Live beregning af:
  - samlet beløb
  - klientens udbetaling
  - revisorens andel
  - gebyr/procent
  - risiko
- `ox_target` interaction
- Debug mode
- `/givrevisor` command
- Discord webhook logs
- Multi-framework bridge

---

## Framework Support

Scriptet understøtter:

- ESX
- QBCore
- QBox
- vRP basic
- Standalone basic

---

## Inventory / Money Support

Scriptet understøtter blandt andet:

- ESX `black_money` account
- ESX inventory items
- ox_inventory
- QBCore/QBox item money
- qb-inventory / ps-inventory via framework functions
- vRP item support

Du kan selv vælge om sorte penge skal være account eller item i `config.lua`.

---

## Dependencies

Anbefalet:

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_target
```

Framework skal starte før scriptet:

```cfg
ensure es_extended
# eller
ensure qb-core
# eller
ensure qbx_core
# eller
ensure vrp
```

Derefter:

```cfg
ensure am_revisor
```

---

## Installation

1. Download scriptet.
2. Put mappen `am_revisor` i din `resources` mappe.
3. Tilføj dette i `server.cfg`:

```cfg
ensure oxmysql
ensure ox_lib
ensure ox_target
ensure am_revisor
```

4. Åbn `config.lua` og tilpas framework, inventory og money settings.

---

## Configuration

### Auto setup

```lua
Config.Framework = 'auto'
Config.Inventory = 'auto'
Config.BlackMoneyType = 'auto'
```

---

## ESX Example

```lua
Config.Framework = 'esx'
Config.Inventory = 'auto'

Config.BlackMoneyType = 'account'
Config.BlackMoneyAccount = 'black_money'

Config.CleanMoneyType = 'cash'
Config.CleanMoneyAccount = 'money'
```

Hvis rene penge skal gå til bank:

```lua
Config.CleanMoneyAccount = 'bank'
```

---

## QBCore / QBox Example

Hvis sorte penge er et item:

```lua
Config.Framework = 'qb' -- eller 'qbox'
Config.Inventory = 'auto'

Config.BlackMoneyType = 'item'
Config.BlackMoneyItem = 'black_money'

Config.CleanMoneyType = 'cash'
```

Hvis din server bruger `markedbills`:

```lua
Config.BlackMoneyItem = 'markedbills'
```

---

## ox_inventory Example

```lua
Config.Inventory = 'ox_inventory'

Config.BlackMoneyType = 'item'
Config.BlackMoneyItem = 'black_money'
```

---

## vRP Example

```lua
Config.Framework = 'vrp'

Config.BlackMoneyType = 'item'
Config.BlackMoneyItem = 'dirty_money'

Config.CleanMoneyType = 'cash'
```

vRP jobcheck bruger permission:

```txt
revisor.permission
```

---

## ox_target

Scriptet åbnes via `ox_target`.

```lua
Config.UseOxTarget = true
Config.TargetDistance = 2.0
Config.TargetIcon = 'fa-solid fa-computer'
Config.TargetLabel = 'Åbn revisor terminal'
```

---

## Revisor Computer Location

Standard placering:

```lua
Config.Computers = {
    {
        label = 'Revisor Computer',
        coords = vector3(-1081.55, -247.83, 37.76),
        heading = 205.0
    }
}
```

Du kan ændre `coords` til den lokation, hvor revisor-computeren skal være.

---

## Debug Mode

Debug er slået til som standard:

```lua
Config.Debug = true
```

Det betyder:

- Alle kan åbne terminalen
- Jobcheck bliver bypasset
- `/givrevisor` virker

Command:

```txt
/givrevisor
```

Når serveren skal live, bør du slå debug fra:

```lua
Config.Debug = false
```

---

## ESX Society

Hvis du bruger ESX Society:

```lua
Config.AutoRegisterSociety = true
Config.SocietyName = 'society_revisor'
Config.SocietyLabel = 'Revisor'
```

Der følger en SQL-fil med til ESX setup.

---

## SQL

Kør `am_revisor.sql`, hvis du bruger ESX og mangler job/society setup.

QB/QBox jobs skal normalt tilføjes manuelt i frameworkets job config.

---

## Discord Logs

Sæt din webhook i `config.lua`:

```lua
Config.Webhook = 'DIN_WEBHOOK_HER'
```

Logger blandt andet:

- revisor
- klient
- beløb
- procent
- revisor cut
- klient payout
- framework
- inventory

---

## Important Notes

Dette script er lavet til RP-servere og skal bruges ansvarligt.  
Hvis din server bruger et meget custom inventory, kan du ændre supporten i:

```txt
bridge/server.lua
```

---

## Preview

<p align="center">
  <img src="./assets/preview.png" alt="AM Revisor UI" width="900"/>
</p>

---

## Credits

Made for FiveM roleplay servers.

<img width="1243" height="836" alt="image" src="https://github.com/user-attachments/assets/1ebcb491-67ec-4ee6-ae3f-186ee7df1d30" />

