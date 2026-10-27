# Taccuino allenatore — design

Editor a blocchi ricorsivo per scrivere sessioni di allenamento nuoto con calcolo automatico dei metri (non testo libero: l'allenatore ha confermato di volere il calcolo automatico).

Decisioni UX validate con due mockup interattivi (ottobre 2026).

## Modello dati

**Un solo albero ricorsivo**, non una gerarchia fissa Sessione→Sezione→Riga. Due tipi di nodo:

**Gruppo**
- **etichetta opzionale** (es. "Riscaldamento", "Serie centrale")
- **moltiplicatore**, default 1x, oppure indefinito "Nx" (è l'atleta a scegliere quante ripetizioni fare)
- **recupero opzionale** (vedi sotto)
- **figli**: altri gruppi o righe

**Riga (foglia)**
- **ripetizioni**, default 1, oppure "Nx"
- **distanza** in metri (numero libero, non vincolato a multipli della vasca: si può scrivere 15)
- **stile** (es. stile libero, dorso) — vedi "Stile e modalità"
- **modalità opzionale** (es. gambe, braccia, pull buoy, tavoletta)
- **nota opzionale**, testo libero (es. "andata braccia, ritorno gambe", "sciolto, a scelta")
- **recupero opzionale**

"400 stile libero" equivale a "1x 400 stile libero": il moltiplicatore 1 non viene mostrato.

Le sezioni non sono obbligatorie: chi scrive tutto in fila ottiene lo stesso albero, semplicemente senza gruppi con etichetta — nessuna modalità speciale nell'editor.

**Profondità massima: 3 livelli di gruppo.** Al terzo livello il pulsante "+ gruppo" sparisce, resta solo "+ riga".

## Stile e modalità

Due campi separati, entrambi **testo libero con suggerimenti**, non menu chiusi:

- sotto il campo, i valori predefiniti e quelli già usati dall'allenatore come chip da un tocco; si può sempre scrivere un termine proprio, che da quel momento compare tra i suggerimenti
- nessuna schermata per gestire i valori: l'elenco dei suggerimenti si ricava da quelli già usati
- **i predefiniti si salvano come chiave** (`freestyle`, `backstroke`, `kick`, `pull`…) e vengono mostrati tradotti nella lingua dell'app; i valori personalizzati si salvano così come sono stati scritti. Altrimenti cambiando lingua le statistiche si spezzano in due voci ("stile libero" e "freestyle")
- i valori personalizzati si confrontano senza distinguere maiuscole/minuscole e senza spazi ai bordi ("Pull" e "pull" sono la stessa voce)

Casi combinati:
- **alternanze** (andata braccia / ritorno gambe): si scrivono con l'albero, `2x [25 stile libero · braccia, 25 stile libero · gambe]` — metri contati sia per stile sia per modalità
- **casi troppo complessi da modellare**: riga con stile e senza modalità, descrizione nella nota. Lo stile viene contato, la modalità no — scelta accettata

## Recupero

Un solo campo per nodo (gruppo o riga) con selettore **Partenza @ / Pausa**: le due cose si escludono per costruzione, non serve disabilitarne una né svuotare il valore per cambiare tipo (cambiando selettore il valore resta, cambia solo il tipo).

- **Partenza @X'** = tempo di partenza ciclico (si riparte ogni X dall'inizio della ripetizione precedente)
- **Pausa X'** = riposo fisso tra una ripetizione e l'altra

Il valore è testo (es. `1'30`), è solo metadata da mostrare: **non entra nel calcolo dei metri**. È una proprietà del nodo, non un finto figlio a distanza zero, altrimenti la somma dei figli richiede casi speciali.

## Calcolo dei metri

- Riga: `ripetizioni × distanza`
- Gruppo: `moltiplicatore × (somma dei totali dei figli)`

Verificati a mano:
- `4x [2x [2x50 gambe @1' + 2x50 braccia @1' + 2x50 completo @1'] Pausa1']` → gruppo interno 300m, ×2 = 600m, ×4 = 2400m
- `3x [3x [2x50 SL gambe @1', 2x [25 SL braccia, 25 SL gambe]] Pausa 1']` → 100 + 100 = 200m, ×3 = 600m, ×3 = 1800m

### Ripetizioni indefinite ("Nx")

Un nodo "Nx" ha totale indefinito, e l'indefinito si propaga verso l'alto (un gruppo con un figlio indefinito non ha somma definita). Il totale sessione è la **somma dei soli rami definiti**: si saltano solo i sottoalberi "Nx", quindi in `4x [Nx 50, 100]` i 400 m del 100 restano contati (stesso criterio dei metri per stile, così i riepiloghi tornano col totale). Accanto compare la didascalia "Parziale: alcune parti sono a ripetizioni libere" (testo provvisorio).

### Metri per stile e per modalità

Sotto il totale sessione, due righe di riepilogo: metri per stile e metri per modalità. Si calcolano percorrendo l'albero e moltiplicando i moltiplicatori degli antenati; i rami "Nx" sono esclusi. Una riga senza modalità conta solo nello stile.

## Editor (UI)

- **Livelli indicati dal colore, non dal rientro**: ogni livello di gruppo ha una barra laterale di colore diverso e rientra di poco, così il terzo livello resta leggibile su schermo stretto
- ogni gruppo mostra in testa moltiplicatore, etichetta, recupero e **totale metri del gruppo**, sempre visibili; i gruppi si possono comprimere
- in fondo a ogni gruppo: "+ riga" e "+ gruppo"
- **modifica in un pannello che sale dal basso** (`showModalBottomSheet`), non direttamente sulla riga. All'apertura la lista scorre in modo che la riga in modifica resti visibile appena sopra il pannello
- nel pannello: Duplica (copia il nodo con tutti i figli subito sotto l'originale), Elimina, Fatto
- **riordino trascinando** con pressione prolungata, solo dentro lo stesso gruppo. Lo spostamento tra gruppi diversi è rimandato: col trascinamento è scomodo su telefono

## Vincoli dell'app da rispettare

- **Multilingua (it/en)**: tutte le stringhe in `lib/l10n/app_*.arb`, nessun testo fisso nel codice. Numeri formattati con `intl` secondo la lingua (2.400 / 2,400). Stili e modalità predefiniti tradotti tramite chiave (vedi sopra)
- **Tema personalizzabile** (`ThemeService`: chiaro/scuro e colore): i colori delle barre di livello vanno presi da `Theme.of(context).colorScheme` (es. primary / tertiary / secondary), mai colori fissi, così funzionano con ogni tema e in modalità scura
- **Font e dimensione del testo** (`AppFont` con OpenDyslexic, `AppTextSize` fino a ×1.15 sopra la scala di sistema): le righe devono andare a capo invece di troncare, chip incluse (`Wrap`, non `Row` a larghezza fissa). Da provare con OpenDyslexic + testo grande, che è il caso più largo

## Multi-taccuino

Un allenatore può crearne più di uno (verosimilmente uno per sessione/periodo, o come template riutilizzabili — granularità non ancora specificata).

## Persistenza ed export

- **Dati locali** (Sembast), non sincronizzati col server per ora.
- **Export JSON** (formato dati, per backup/riapertura) e **PDF** (per stampa/lettura, es. a bordo vasca). Import da JSON.
- **Condivisione** (email/WhatsApp/altro): share sheet nativo del sistema (`share_plus` o equivalente) — un solo meccanismo per "invia con qualunque app", non integrare ogni app singolarmente.
- **Backup**: il taccuino entra nell'export/backup generico esistente (stesso Sembast) come default, più export singolo per condividere un taccuino alla volta — due granularità diverse, non due sistemi di backup separati.
- **`schemaVersion` nel JSON esportato fin dal primo giorno**: costa nulla, evita rotture se il modello ad albero cambia (specie se un giorno diventa sincronizzabile col server).

## Dipendenze da aggiungere (non ancora in `pubspec.yaml`)

- Un package PDF (es. `pdf` + `printing`)
- Un package per lo share sheet (es. `share_plus`)

## Ordine di implementazione proposto

1. Modello Dart + calcolo metri (totale, per stile, per modalità, Nx) con un test
2. Persistenza Sembast + elenco taccuini + editor
3. Export/import JSON e ingresso nel backup generico
4. PDF e condivisione

## Aperto

- Testo esatto della didascalia "parziale" — non bloccante.
- Elenco preciso dei predefiniti di stile e modalità (base: stile libero, dorso, rana, delfino, misti / gambe, braccia, completo, pull buoy, tavoletta).
- Spostamento di un nodo tra gruppi diversi (es. azione "Sposta in…" nel pannello) — rimandato.

## Nota architetturale (footer navigazione)

Il taccuino è uno dei tab previsti in una futura bottom navigation bar (Allenatore / Planning / Taccuino allenatore / Profilo). Oggi la navigazione parte da `WelcomeScreen` con push in stack, nessuna tab bar persistente — aggiungere il footer è un cambio di ossatura dell'app (Scaffold con le sezioni sempre visibili, stack interno a ciascuna invariato), da pianificare in una sessione dedicata, non a spizzichi tra le altre feature. Fino ad allora il taccuino si apre da un punto d'ingresso semplice nella schermata principale.
