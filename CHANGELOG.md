# Changelog

Tutte le modifiche rilevanti di SplashUp. Formato ispirato a [Keep a Changelog](https://keepachangelog.com/it/1.1.0/).

## [2.4.2] - 2026-07-18

### Corretto
- **Il click del cronometro suonava solo su "Avvia"**: in modalità bassa latenza, dopo la prima riproduzione il player di `audioplayers` resta in stato "completed" e i `play()` successivi non ripartono ("Giro" e "Ferma" restavano muti). Ora la sorgente è precaricata una sola volta con `ReleaseMode.stop` e ogni click esegue `stop()` + `resume()`, il pattern documentato per suoni brevi ripetuti.

## [2.4.1] - 2026-07-18

Fix di rifinitura dopo i test sul campo della 2.4.0.

### Corretto
- **Feedback sonoro del cronometro**: non suonava su molti dispositivi. `SystemSound.click` dipendeva dai "Suoni alla pressione" di sistema su Android (e non faceva nulla su iOS). Ora l'app usa un click in bundle (`assets/sounds/stopwatch_click.wav`, ~5 KB, generato ad hoc) riprodotto via `audioplayers` in modalità bassa latenza: funziona sempre, ovunque.
- **Tabella parziali con OpenDyslexic + testo Grande**: l'ultima cifra del tempo cumulativo veniva parzialmente coperta dalla X di azzeramento riga. Ridistribuiti i pesi delle colonne (distanza 2→1,5, cumulativo 3→3,5) e aggiunto un piccolo distacco tra campo e X.

### Modificato
- **"Precisione tempo"** ora ha la descrizione "Solo visualizzazione: il salvataggio resta al centesimo."
- **Testi sezione "Pulizia dati"** riscritti: le vecchie descrizioni suggerivano un'automazione, ma le operazioni sono (e restano) manuali. Nuove descrizioni per "Disattiva/Elimina atleti inattivi" e mini-label "Senza tempi da" / "Inattivi da" al posto di "Disattiva dopo" / "Elimina dopo".

### Tecnico
- Nuova dipendenza: `audioplayers ^6.8.1` (ultima versione).

## [2.4.0] - 2026-07-17

Release dedicata alla personalizzazione e all'accessibilità.

### Aggiunto
- **Pagina "Personalizza esperienza"** (Impostazioni → Aspetto): raccoglie tutte le opzioni di personalizzazione, con anteprima dal vivo:
  - **Tema chiaro/scuro/sistema**: spostato qui dalla vecchia voce in Impostazioni.
  - **Temi colore**: 6 palette (Blu — default storico —, Verde acqua, Verde, Corallo, Viola, Rosa) applicate a tutta l'app tramite seed color Material 3.
  - **Font OpenDyslexic**: font alternativo per utenti con dislessia (licenza SIL OFL, ~870 KB in bundle, nessun download runtime), selezionabile accanto al font standard.
  - **Dimensione testo**: Piccolo / Normale / Grande, applicata sopra la scala di sistema.
  - **Lingua in-app**: Sistema (default) / Italiano / English, prima seguiva solo la lingua del dispositivo.
- **Sezione "Cronometro" in Impostazioni**:
  - Feedback aptico su avvio, stop e giro (attivo di default).
  - Feedback sonoro (click) su avvio, stop e giro.
  - "Schermo sempre attivo" durante l'uso del cronometro (attivo di default, via `wakelock_plus`).
  - Precisione tempo visualizzato: centesimi (default) o decimi. Solo visualizzazione: i millisecondi salvati restano a precisione piena.
- **Sezione "Info" in Impostazioni**: versione app (via `package_info_plus`) e pagina licenze open source.

### Tecnico
- `ThemeService` esteso (tema colore, font, dimensione testo) e ora costruisce i `ThemeData`; nuovi `LocaleService` e `StopwatchSettingsService`, tutti persistiti in `shared_preferences`.
- Nuove dipendenze: `package_info_plus ^10.1.0`, `wakelock_plus ^1.6.1` (ultime versioni). Dipendenze esistenti già all'ultima versione.
- 32 nuove chiavi di traduzione in `app_en.arb` e `app_it.arb`.
- `StopwatchScreen` convertito in StatefulWidget per gestire il ciclo di vita del wakelock.

## [2.3.0] - 2026-07-16

Release dedicata ai dati di prova: ora multilingua, generici e sempre attuali.

### Modificato
- **Dati di prova multilingua e generici**: il generatore di dati demo non usa più nomi di persone inventati. Crea 4 squadre generiche con 10 atleti "segnaposto", interamente tradotti tramite il sistema di localizzazione dell'app:
  - Squadra A - Esordienti A / *Team A - Novice A* (2 atleti, vasca 25 m)
  - Squadra A - Master / *Team A - Masters* (2 atleti, vasca 25 m)
  - Squadra B / *Team B*, senza categoria (3 atleti, vasca 25 m)
  - Squadra C - Juniores / *Team C - Juniors* (2 atleti, vasca 50 m)
- **Età sempre coerenti**: gli anni di nascita degli atleti demo sono calcolati dinamicamente rispetto all'anno corrente (Esordienti −10/−11, Juniores −17/−18, Master −34/−38, squadra senza categoria −9/−16/−24), così i dati di prova non invecchiano mai.
- **Note e tempi demo localizzati**: i cronometraggi di esempio hanno note generiche tradotte ("Gara di esempio", "Allenamento di esempio", "Record personale!") e tempi realistici con parziali coerenti per categoria e lunghezza vasca.

### Aggiunto
- 12 nuove chiavi di traduzione (`dummy*`) in `app_en.arb` e `app_it.arb`, inclusi i suffissi di categoria adattati per lingua (ES → N per *Novice* in inglese).

### Tecnico
- `DummyDataGenerator.populateDatabase` riceve ora `AppLocalizations` per generare i dati nella lingua attiva dell'app.
- Verifica dipendenze: tutti i pacchetti già all'ultima versione; disponibili solo patch minori via `flutter pub upgrade` (intl 0.20.3, sembast 3.8.9+1, cupertino_icons 1.0.9).

## [2.2.0] - 2026-07-03

Release di consolidamento: code review completo (74 → 0 rilievi di `flutter analyze`), primi unit test (48), toolchain Android aggiornata e app pronta per la firma di release.

### Corretto — perdite di dati e crash
- **"Sposta atleti" dal flusso "Elimina squadra"**: spostando solo un atleta (o un anno), la squadra di origine veniva comunque eliminata a cascata con tutti gli atleti rimasti e i loro tempi. Ora la squadra viene eliminata solo dopo lo spostamento di *tutti* gli atleti, e nel flusso di eliminazione tipo di spostamento e squadra sorgente sono bloccati.
- **Modifica di un tempo esistente**: digitando nel campo tempo, il valore pre-compilato spariva al primo tasto (formatter fuori sincrono). Riscritto il formatter in versione stateless.
- **Grafico analisi parziali**: possibile crash con tempi senza parziali reali (intervalli griglia a zero) e snackbar residua "Charts coming soon" a ogni apertura.
- Possibili crash da `setState` dopo la chiusura della schermata di benvenuto e da anno di nascita fuori range nel dropdown di modifica atleta.

### Corretto — dati e logica
- I tempi inseriti in forma non normalizzata (es. `00:65.00` per 65 secondi) vengono ora salvati e mostrati normalizzati (`01:05.00`) ovunque, record storici inclusi.
- I tempi oltre i 60 minuti non vanno più in "wrap" (65 min mostrava `05:00.00`): ora `65:00.00`, sia nel salvataggio sia nel cronometro. I tempi oltre i 99 minuti pre-compilati restano editabili.
- Un tempo `00:00.00` non passa più la validazione (inquinava i personal best).
- I personal best sono calcolati dai millisecondi canonici (i record in formati legacy non venivano mai considerati).
- Il cronometro cattura il tempo esatto al momento dello Stop (prima poteva perdere fino a 10 ms).
- Lo stile "Misti (IM)" è ora selezionabile in creazione e non viene più perso salvando la modifica di un atleta.
- Spostamento atleta atomico: atleta e relativi tempi cambiano squadra in un'unica transazione.
- Il salvataggio di atleti e tempi avviene *prima* di chiudere la schermata: un eventuale errore viene mostrato invece di essere ignorato silenziosamente.

### Modificato — comportamento e UX
- **Cronometro**: annullando il salvataggio si torna al cronometro con tempo e vasche intatti (prima erano persi per sempre); a salvataggio riuscito il cronometro si azzera.
- "Sposta atleti" avvisa subito se manca la selezione di atleta o anno (prima: conferma senza alcun effetto).
- La lista atleti non mostra più uno spinner a ogni tasto digitato nella ricerca (stessa ottimizzazione degli stream in tutte le schermate).
- I tile delle Impostazioni ("Sposta atleti", "Elimina squadra") si abilitano/disabilitano in tempo reale col numero di squadre.
- Il warning "modifiche non salvate" appare solo quando ci sono modifiche vere (anche per genere, anno e stato attivo) e non appare più a vuoto in modifica atleta.
- Anno di nascita proposto per i nuovi atleti: anno corrente − 10 (prima: anno corrente).
- Nomi squadra di soli spazi non più accettati.
- Tutti i messaggi, gli errori e i validator sono ora localizzati (italiano/inglese): 19 nuove chiavi di traduzione.
- Nome visibile dell'app: "SplashUp" (prima "splashup").

### Aggiunto
- **Unit test** (48) su parser dei tempi, formatter di input, validazione parziali, cronometro e database (in memoria): `flutter test`.
- Accessibilità: tooltip su tutti i pulsanti icona, colori legati al tema (dark mode), contrasto corretto sui pulsanti distruttivi, slider del grafico leggibile dagli screen reader.
- Configurazione firma di release: `key.properties` + istruzioni in `SETUP_KEYSTORE.md` (fallback automatico alle chiavi di debug se non configurata).

### Tecnico / build
- **Package name definitivo**: `com.example.splashup` → `com.splashup.splashup`.
- Toolchain Android: AGP 9.0.1, Gradle 9.1.0, migrazione a Built-in Kotlin (rimosso il Kotlin Gradle Plugin), google-services disattivato insieme a Firebase.
- Supporto **16 KB page size** (requisito Play Store per Android 15+).
- Dipendenze aggiornate: fl_chart 1.2, sembast 3.8.9, flutter_svg 2.3, shared_preferences 2.5.5, path_provider 2.1.6.
- `flutter analyze` a zero: `lib/services/cloud` (Firebase, disattivato) escluso dall'analisi fino alla riattivazione.

## [2.1.0] - 2026-03-20

### Aggiunto
- **Dati di esempio al primo avvio**: se il database è vuoto, premendo "Tuffati!" un dialog di benvenuto propone di caricare dati di prova o iniziare da zero. Il nuovo generatore (`dummy_data_generator.dart`) crea 2 squadre ("Dolphins Elite Pro" vasca 50 m, "Sharks Junior" vasca 25 m) con 4 atleti e tempi realistici completi di parziali, tipo Gara/Allenamento e note.

### Tecnico
- **Firebase completamente disattivato**: `firebase_core`, `cloud_firestore`, `firebase_auth` e `google_sign_in` commentati nel `pubspec.yaml` — l'app è ora 100% offline; il backup cloud sperimentale della 2.0.0 è di fatto disabilitato. Rimossi i plugin registrant Firebase per Windows e macOS.
- Dipendenze aggiornate: sembast 3.8.6, path_provider 2.1.5, path 1.9.1, uuid 4.5.3.
- 4 nuove chiavi di traduzione per il dialog di benvenuto.

## [2.0.0] - 2026-02-24

Release major: re-architettura da app cloud-first (Firestore) ad app **local-first e offline**, con database locale.

### Modificato
- **Non serve più il login**: nuova schermata di benvenuto con slogan "Dive in. Stand out. SplashUp", sottotitolo "Il tuo compagno di nuoto — 100% Offline & Privato" e pulsante "Tuffati!" che entra direttamente nell'app.
- Tutte le schermate migrate dal `FirebaseFirestore` diretto agli stream del nuovo repository locale.
- "Elimina Account" sostituito da **"Reset Dati App"** (azzeramento locale dei dati).

### Aggiunto
- Area sperimentale "Cloud Debug" nelle impostazioni con backup manuale dei dati locali su Firebase (solo upload, senza ripristino; segnata come da nascondere in produzione).

### Tecnico
- **Pattern Repository**: interfaccia astratta `DatabaseRepository` (CRUD, stream reattivi, operazioni batch e delete a cascata) con implementazione `SembastRepository` — database NoSQL su file (`splashup.db`), ID generati con UUID v4, transazioni per le operazioni a cascata.
- Modelli `Team`, `Athlete`, `Chrono` convertiti da `fromFirestore` a `toMap`/`fromMap` (date come millisecondi).
- Codice cloud isolato in `lib/services/cloud/` con nuovo `cloud_sync_service.dart` (init Firebase lazy, solo on-demand).
- Nuove dipendenze: sembast 3.7.1, path_provider 2.1.2, path 1.9.0, uuid 4.3.3.

## [1.3.0] - 2025-12-02

### Aggiunto
- **Accesso Web**: l'app funziona da browser. SDK JavaScript di Firebase caricati e configurati in `index.html`; autenticazione resa cross-platform (`signInWithPopup` su web, google_sign_in nativo su mobile; sessione persistente al ricaricamento della pagina; logout e re-autenticazione robusti su entrambe le piattaforme).

## [1.2.2] - 2025-11-18

### Corretto
- **Selezione linee del grafico coerente con la modalità tooltip**: in modalità dettagliata la legenda usa ora una selezione singola (radio) — prima era possibile selezionare più linee o nessuna, rompendo il tooltip di segmento; in modalità compatta resta la selezione multipla (checkbox). Se la selezione si svuota viene ripristinata automaticamente la prima linea.

### Tecnico
- Primo groundwork per il web: branch `kIsWeb` nel servizio di autenticazione (completato nella 1.3.0).

## [1.2.1] - 2025-11-11

### Aggiunto
- **Due modalità di tooltip** nel grafico parziali, selezionabili con uno switch: **Compatta** (tutti i tempi alla stessa distanza) e **Dettagliata** (analisi del singolo segmento, es. "Parziale: 50-100m"), con avviso di selezionare una sola linea per i dettagli.

## [1.2.0] - 2025-10-25

### Aggiunto
- **Grafico analisi parziali**: nuova schermata con grafico a linee interattivo (distanza sull'asse X, tempo sull'asse Y) raggiungibile dal menu del dettaglio atleta:
  - filtri per distanza, stile, tipo (Gara/Allenamento) e numero di record mostrati (default: gli ultimi 5);
  - linee colorate in base alla performance, dal verde (tempo migliore) al rosso (peggiore);
  - legenda con toggle per mostrare/nascondere ogni linea e stati vuoti dedicati.

### Tecnico
- Nuova dipendenza `fl_chart` per i grafici; 10 nuove chiavi di traduzione.

## [1.1.1] - 2025-10-22

### Aggiunto
- **Formatter automatico per l'input dei tempi**: digitando solo cifre, `:` e `.` vengono inseriti automaticamente (formato MM:SS.cc) con tastiera numerica, sia sul tempo finale sia sui parziali.

### Corretto
- **Tabella parziali in dark mode**: colori fissi sostituiti con i colori del tema — testo e bordi erano poco leggibili in tema scuro.
- Errori di validazione mostrati direttamente sul singolo campo parziale (bordo rosso e messaggio); l'ultimo parziale è ora in sola lettura, allineato al tempo finale.

### Tecnico
- Aggiornamento dipendenze Firebase (core 4.2.0, firestore 6.0.3, auth 6.1.1, google_sign_in 7.2.0).

## [1.1.0] - 2025-10-21

### Aggiunto
- **Tempi parziali (splits)** nei cronometraggi:
  - editor dei parziali nella schermata tempo: template generato automaticamente da distanza e lunghezza vasca, ricalcolo automatico di segmenti e cumulativi, validazioni complete (formato, distanze multiple della vasca, ordine crescente di distanze e tempi, coerenza col tempo finale);
  - **dal cronometro ai parziali**: al salvataggio, i giri del cronometro diventano automaticamente parziali con tempi di segmento calcolati (prima venivano trascritti come note testuali);
  - visualizzazione nel dettaglio atleta: card tempo espandibile con tabella Distanza / Parziale / Cumulativo.

### Tecnico
- Modello `Chrono` esteso con `finalTimeMs` (millisecondi canonici) e lista `splits`; nuovi parser/formatter dei tempi e validazione parziali; 12+ nuove chiavi di traduzione.

## [1.0.3] - 2025-10-02

### Corretto
- **L'app è usabile anche senza connessione**: le scritture (squadre, atleti, tempi) non bloccano più la UI in attesa della rete. Ora la schermata si chiude subito e la scrittura viene accodata (persistenza offline di Firestore); prima, senza connessione, dialog e schermate restavano bloccati.

## [1.0.2] - 2025-10-01

### Corretto
- **Stabilità nelle operazioni asincrone**: eliminati potenziali crash da uso del contesto dopo `await` (controlli `mounted` sistematici, context dedicato nei dialog) nelle schermate di aggiunta/modifica atleta e tempo e nel dialog dei personal best.
- Gestione del tasto "indietro" con modifiche non salvate migrata alle API non deprecate.

## [1.0.1] - 2025-09-18

### Tecnico
- Aggiornamento maggiore delle dipendenze: firebase_core 4.1, cloud_firestore 6.0, firebase_auth 6.0 e **google_sign_in 7.1** (nuova API: init asincrona, accesso silenzioso al riavvio, re-autenticazione riscritta per l'eliminazione account).
- Messaggio "servono almeno due squadre" per lo spostamento atleti ora localizzato (prima era hardcoded in inglese).

## [1.0.0] - 2025-09-10

Prima versione dell'app (sviluppo iniziato il 2025-08-18). Backend Firebase (Firestore + Auth).

### Aggiunto
- **Squadre**: creazione con nome e lunghezza vasca predefinita, modifica, eliminazione e procedure di fine stagione.
- **Atleti**: anagrafica completa (nome, anno di nascita, sesso, stili preferiti, note, stato attivo/inattivo), card con ricerca e filtro "mostra inattivi", dettaglio con età calcolata e note in popup, eliminazione con opzione "disattiva invece".
- **Tempi**: registrazione con data, vasca, distanza, stile (inclusi i Misti), tipo Gara/Allenamento e note; filtri per distanza, stile e tipo; **personal best** automatici; protezione contro le modifiche non salvate.
- **Cronometro** con giri e salvataggio diretto come tempo.
- **Impostazioni**: tema chiaro/scuro/sistema; spostamento atleti tra squadre (singolo, per anno di nascita, tutti); eliminazione squadra con spostamento preventivo; pulizia dati (disattiva/elimina atleti inattivi da N mesi/anni); eliminazione account con cancellazione a cascata.
- **Login con Google** e localizzazione completa italiano/inglese.
