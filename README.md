# MasterProjectiOS

En iOS-app som leser helsedata via **HealthKit**, mapper dem til **FHIR R4 Observation**-ressurser og laster dem opp til en ekstern FHIR-server.
Appen sporer synkroniserte samples lokalt (for å unngå duplikater), og kjører automatisk synkronisering i bakgrunnen via **BackgroundTasks**.
UI er bygget i **SwiftUI**.

---

## Innhold

* [Skjermbilder](#skjermbilder)
* [Funksjoner](#funksjoner)
* [Arkitektur & flyt](#arkitektur--flyt)
* [Arkitektur og prinsipper (SOLID + MVVM)](#arkitektur-og-prinsipper-solid--mvvm)
* [Teknologier](#teknologier)
* [Prosjektstruktur](#prosjektstruktur)
* [Oppsett](#oppsett)
* [Bruk](#bruk)
* [Automatisk synk](#automatisk-synk)
* [Data & persistens](#data--persistens)
* [Tilganger (HealthKit)](#tilganger-healthkit)
* [Feilsøking](#feilsøking)

---

## Skjermbilder


### Hovedskjerm

![Hovedskjerm](https://github.com/587851/MasterProjectiOS/blob/main/hovedSkjermIOS.png?raw=true)

### Innstillinger

![Innstillinger](https://github.com/587851/MasterProjectiOS/blob/main/innstillingsSkjermIOS.png?raw=true)

### Historikk

![Historikk](https://github.com/587851/MasterProjectiOS/blob/main/historieSkjermIOS.png?raw=true)

### Tillatelser

![Tillatelser](https://github.com/587851/MasterProjectiOS/blob/main/tillatelseSkjermIOS.png?raw=true)

---

## Funksjoner

* **Les helsedata** fra HealthKit (f.eks. Heart Rate, Steps, Sleep, VO₂ Max, m.fl.)
* **Mapper** HealthKit-samples til FHIR `Observation`-ressurser
* **Laster opp** til ekstern FHIR-server (batch/transaksjon)
* **Duplikatkontroll**: sporer hvilke HealthKit-samples som er synket
* **Automatisk synk** via BackgroundTasks (15 min / time / dag / uke / måned)
* **Historikk**: viser når/hva som ble sendt
* **Tillatelser**: ber om og viser HealthKit-tilganger

---

## Arkitektur & flyt

```
HealthKit --> HealthDataReader --------+
                                        \
                                         --> SampleMapper --> FHIR Observations --> FHIRUploader --> FHIR Server
                                        /
SyncedSampleRepository <--- SampleSyncer +
          ^                                      |
          |                                      v
          +-------- ObservationUploader (chunking, sync tracking)

SwiftData (HistorySample, SyncedSample) <--- Historikk & duplikatkontroll

BackgroundTasks (BGAppRefresh) --> kjører lesing + opplasting periodisk

UI (SwiftUI + Charts):
- MainScreen: lese/tegne/eksportere data
- Settings: prefs, auto-sync, pasientinfo
- Permissions: status + forespørsler
- History: gruppert visning av tidligere synk
```

**DI / Composition root:** `DependencyProvider` oppretter og deler HealthKit, FHIR-klient, repositories, mapper/uploader, osv.
**App oppstart:** `StartupViewModel` rydder gamle synk-rader iht. preferanser.

---

## Arkitektur og prinsipper (SOLID + MVVM)

Prosjektet er bygget etter **MVVM-arkitektur** og følger **SOLID-prinsippene** for god struktur, testbarhet og vedlikeholdbarhet.

### MVVM (Model–View–ViewModel)

* **Model**
  Datakilder og logikk — inkluderer SwiftData-modeller (`HistorySample`, `SyncedSample`), repository-lag (`HistorySampleRepository`, `SyncedSampleRepository`), preferanser (`SyncPreferences`, `PatientPreferences`) og FHIR-integrasjonen (mapping og opplasting).

* **ViewModel**
  Forretningslogikk og dataflyt mellom Model og UI.
  Alle ViewModels eksponerer `@Published`-tilstand for SwiftUI:

  * `MainViewModel` – datahenting, sending og visningsmodus
  * `SettingsViewModel` – synk-innstillinger
  * `PermissionsViewModel` – HealthKit-status og tillatelser
  * `HistoryViewModel` – gruppering av tidligere synk
  * `PatientViewModel` – håndtering av pasientinfo
  * `StartupViewModel` – rydder gamle records ved oppstart

* **View (UI)**
  Bygget i **SwiftUI** – reaktivt, deklarativt og direkte koblet til `@Published`-felter.
  Skjermene (`MainScreen`, `SettingsScreen`, `HistoryScreen`, `PermissionsScreen`) er enkle og uten logikk — alt håndteres i ViewModel.

---

### SOLID-prinsippene i praksis

| Prinsipp                  | Hvordan det brukes                                                                                                                                                             |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **S**ingle Responsibility | Hver klasse gjør én ting: `AutoSyncManager`/`AutoSyncOperation` kun synk, `HistorySampleRepository` kun databaseoperasjoner, `FHIRPatientManager` kun håndtering av `Patient`. |
| **O**pen/Closed           | Nye datatyper og FHIR-mappinger kan legges til uten å endre eksisterende logikk — ved å utvide `ObservationType` og `SampleMapper`.                                            |
| **L**iskov Substitution   | Repositories er isolert bak egne typer; implementasjon kan byttes uten å bryte forbrukere (ny SwiftData-kontekst, test-doubles, osv.).                                         |
| **I**nterface Segregation | Små og fokuserte protokoller (Health/FHIR/Prefs/Repos) — ingen klasse tvinges til å implementere metoder den ikke trenger.                                                     |
| **D**ependency Inversion  | Høyere nivå (ViewModels/AutoSync) avhenger av **abstraksjoner**. Avhengigheter leveres via `DependencyProvider` for løs kobling og enkel utskifting i tester.                  |

---

## Teknologier

* **Swift**, **SwiftUI**, **Charts**, **Combine**
* **HealthKit** (lese helsedata)
* **SwiftData** (lokal DB) – `HistorySample`, `SyncedSample`
* **BackgroundTasks** – periodisk synk i bakgrunnen (BGAppRefresh, evt. BGProcessing)
* **FHIR R4** – egendefinert klient + modeller (`Observation`, `Patient`, Bundle-POST)
* **Swift Concurrency (async/await)**

---

## Prosjektstruktur

```
MasterProjectiOS
├── Core/
│   ├── DependencyProvider.swift
│   ├── Models/
│   │   ├── HistorySample.swift
│   │   └── SyncedSample.swift
│   ├── Enums/
│   │   ├── ObservationType.swift
│   │   └── Screen.swift
│   └── Preferences/
│       ├── PatientPreferences.swift
│       └── SyncPreferences.swift
├── Health/
│   ├── HealthDataReader.swift
│   ├── HealthDataFormatter.swift
│   ├── HealthPermissionManager.swift
│   └── HealthKitStatusService.swift
├── FHIR/
│   ├── Models/
│   │   ├── FHIRObservation.swift (+ Quantity, Coding, Period osv.)
│   │   ├── Patient.swift (+ HumanName)
│   │   └── Bundle.swift (transaction)
│   ├── FhirClientProvider.swift
│   ├── FHIRPatientManager.swift
│   ├── FHIRUploader.swift
│   └── SampleMapper.swift
├── Data/
│   ├── Repositories/
│   │   ├── HistorySampleRepository.swift
│   │   └── SyncedSampleRepository.swift
│   └── Sync/
│       ├── SampleSyncer.swift
│       ├── AutoSyncManager.swift
│       └── AutoSyncOperation.swift
├── UI/
│   ├── Screens/
│   │   ├── MainScreen.swift
│   │   ├── SettingsScreen.swift
│   │   ├── HistoryScreen.swift
│   │   └── PermissionsScreen.swift
│   └── ViewModels/
│       ├── MainViewModel.swift
│       ├── SettingsViewModel.swift
│       ├── PermissionsViewModel.swift
│       ├── PatientViewModel.swift
│       ├── HistoryViewModel.swift
│       └── StartupViewModel.swift
└── Supporting Files/
    └── Info.plist
```

---

## Oppsett

### 1) Krav

* Xcode 15+
* iOS 17+ (SwiftData krever moderne iOS; juster hvis du har tilpasset back-deployment)
* En FHIR R4 server-URL

### 2) Konfigurer FHIR server-URL

Legg base-URL i **Info.plist** som key `FHIRServerURL`:

```xml
<key>FHIRServerURL</key>
<string>https://your-fhir-server/baseR4</string>
```

`FhirClientProvider` leser denne verdien ved oppstart.

### 3) HealthKit & Privacy-tekster (Info.plist)

Legg til nødvendige HealthKit-keys, f.eks.:

```xml
<key>NSHealthShareUsageDescription</key>
<string>Appen trenger tilgang til helsedata for å lese og laste opp observasjoner.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>Appen kan oppdatere helsedata ved behov.</string>
```

Aktiver **HealthKit** i *Signing & Capabilities*.

### 4) BackgroundTasks

* Aktiver **Background Modes** → *Background fetch* (og evt. *Background processing* hvis du bytter til `BGProcessingTask`).
* Legg til BGTask-identifier i Info.plist:

```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
  <string>com.example.healthdata.autosync</string>
</array>
```

I `AutoSyncManager.registerTasks()` er ID-en `com.example.healthdata.autosync`.

---

## Bruk

1. **Start appen** – `StartupViewModel` rydder gamle `SyncedSample`-rader iht. preferanser.
2. **Gå til “Permissions”** – be om nødvendige HealthKit-tilganger.
3. **Main**:

   * Velg *Data Type* og *Time Range*
   * Trykk **Read Data** for å hente og se data (tekst / søyle / graf)
   * Trykk **Send Data to DB** for å mappe → lage FHIR `Observation` → sende
4. **History** – se historikk over hva som ble sendt (type, antall, periode, kilde).
5. **Settings** – sett auto-sync, cleanup, duplikater og pasientnavn.

---

## Automatisk synk

* **Planlegging:** `AutoSyncManager.scheduleAutoSync(interval:)` planlegger `BGAppRefreshTask` med intervaller:

  * 15 min, 1 time, 1 dag, 1 uke, 1 måned
* **Rescheduling:** Når tasken kjører ferdig/utløper, planlegges ny task automatisk.
* **Vindu:** `AutoSyncOperation` leser data for et tidsvindu basert på frekvens (for å fange opp etterslep).

---

## Data & persistens

* **SwiftData**

  * `HistorySample` – historikk over manuell/automatisk opplasting
  * `SyncedSample` – hvilke sample-IDer er allerede synket (for duplikatkontroll)
* **UserDefaults + Combine**

  * `SyncPreferences` – duplikater, cleanup, frekvens, auto-sync-typer
  * `PatientPreferences` – pasientnavn og `patientId` (fra FHIR-serveren)
* **FHIR**

  * `FHIRPatientManager` – finner/lagrer pasient-ID; oppretter `Patient` ved behov
  * `FHIRUploader` – poster `Bundle` (transaction) med `Observation`-entries i chunk
  * `ObservationUploader` – filtrerer duplikater, mapper, chunker, sender, og markerer synket

---

## Tilganger (HealthKit)

Appen bruker lese-tilganger for bl.a. Heart Rate, Steps, Sleep, O₂ Saturation, VO₂ Max, Body Temp, Body Fat m.fl.
**PermissionsScreen** viser status og lar deg be om tilganger.
**HealthPermissionManager** håndterer bulk-forespørsel og per-type sjekk..

---

## Feilsøking

* **Ingen data vises**

  * Sjekk at HealthKit er **tilgjengelig** (Permissions-skjermen viser status).
  * Sjekk at riktige **tilganger** er innvilget for valgt datatype.
  * Sjekk valgt **tidsrom** (Last 24 hours / Last week / Last month).

* **Opplasting feiler**

  * Sjekk `FHIRServerURL` i Info.plist.
  * Se konsoll for `FHIRUploader`/`ObservationUploader` logger (bundle-feil, HTTP-koder).
  * FHIR-server må støtte R4 og `Observation` POST i transaksjon.

* **Auto-sync kjører ikke**

  * Sjekk at frekvens ≠ 0 i Settings.
  * Sjekk at BackgroundTasks er konfigurert (plist-ID, capabilities).
  * Åpne appen en gang etter installasjon for å la iOS “varme opp” planleggingen.

* **Duplikater lastes opp**

  * Hvis **Allow duplicates** er slått på i Settings, tillates det.
  * Ellers sjekkes `SyncedSample` mot sample UUID før sending.
