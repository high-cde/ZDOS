# ZDOS Anonymous Overlay

## Stato del documento

**Versione:** 0.1  
**Stato:** laboratorio e validazione  
**Profilo ZLang:** `zdos.anonymous-overlay.v0.1`  
**Compatibilità Tor:** non dichiarata  
**Traffico pubblico:** disabilitato

## Decisione progettuale

ZDOS Anonymous Overlay è un progetto di rete a circuiti ispirato a principi di minimizzazione della conoscenza dei relay. Non è Tor, non dichiara compatibilità con Tor e non promette anonimato assoluto. La prima versione è una policy ZLang verificabile. Non è ancora un trasporto anonimo operativo.

ZLang descrive ruoli, capacità, transizioni, limiti e rifiuti. Un sottosistema esterno implementerà in seguito il trasporto usando primitive crittografiche mature e librerie sottoposte a revisione. La policy non può aprire socket, leggere chiavi, modificare il filesystem o avviare processi.

> **Regola di sicurezza:** nessuna capacità di rete viene concessa implicitamente. Ogni azione deve essere presente nella policy e verificata dal runtime.

## Scopo della versione 0.1

La versione 0.1 definisce un client di laboratorio con circuito minimo di tre ruoli: guard, middle ed exit. Il circuito è valido solo quando il consenso firmato è recente, i link sono autenticati e i relay non condividono lo stesso operatore o la stessa famiglia amministrativa quando tale informazione è disponibile.

Il profilo consente solo flussi TCP verso le porte 80 e 443. Il DNS diretto viene rifiutato. UDP, TUN, servizi onion, pubblicazione e listener pubblico sono disabilitati. Questa restrizione evita di trasformare una policy di laboratorio in un proxy generale non controllato.

| Area | Decisione v0.1 |
|---|---|
| Ruolo | client |
| Circuito minimo | guard → middle → exit |
| Trasporto applicativo | TCP mediato |
| Porte di uscita | 80 e 443 |
| DNS | solo attraverso circuito |
| UDP | rifiutato |
| TUN | disabilitato |
| Onion services | disabilitati |
| Listener pubblico | disabilitato |
| Pubblicazione directory | disabilitata |
| Modalità | validate-only / laboratorio |

## Strati del sistema

| Strato | Responsabilità | Non deve fare |
|---|---|---|
| ZLang policy layer | Ruoli, capacità, limiti, stati e rifiuti | Implementare crittografia o socket |
| Node runtime | Identità del nodo, consenso e macchine a stati | Ignorare una policy valida o inventare transizioni |
| Link protocol | Collegamento autenticato tra due relay | Riutilizzare chiavi tra hop |
| Circuit protocol | Creazione, estensione e chiusura del circuito | Esporre l’indirizzo del client a ogni relay |
| Application gateway | Proxy TCP limitato e osservabile | Consentire DNS diretto, UDP o porte non autorizzate |

## Stato e transizioni

Il profilo definisce una macchina a stati deterministica:

```text
startup
  → directory-verified
  → link-authenticated
  → circuit-ready
  → stream-open
  → closing
  → halted
```

Il runtime deve rifiutare consenso obsoleto, firme invalide, versioni sconosciute, campi duplicati, frame non canonici, handshake scaduti e transizioni non dichiarate. Un errore irreversibile deve chiudere esplicitamente lo stream e il circuito interessato.

## Crittografia e segreti

La policy non introduce primitive crittografiche. Il trasporto dovrà usare librerie mature con parametri fissati, gestione esplicita delle versioni e API strette. Le chiavi private dovranno essere generate dal CSPRNG del sistema operativo. Non dovranno essere presenti nel sorgente ZLang, nei log, nei manifest pubblici o nei file di configurazione ordinari.

Le chiavi di identità del relay, le chiavi di sessione del link, le chiavi del circuito e le chiavi derivate dello stream devono avere scopi distinti. Una chiave non deve essere riutilizzata tra hop o tra circuiti. La rotazione e la revoca devono essere rappresentate nel consenso firmato prima di qualsiasi uso dei metadati.

## Formato minimo dei messaggi

Il formato binario futuro dovrà essere versionato e canonico. Ogni frame dovrà contenere almeno versione, tipo, identificatore del circuito, identificatore dello stream, lunghezza dichiarata, contatore anti-replay, payload autenticato e tag di autenticazione.

Il parser deve avere limiti rigidi di lunghezza e memoria. Deve rifiutare campi duplicati, versioni sconosciute, lunghezze incoerenti e rappresentazioni non canoniche. Il parser non deve usare ricorsione non necessaria. Il fuzzing e il property-based testing devono essere prerequisiti prima di collegare il trasporto a Internet.

## Minacce e contromisure

| Minaccia | Contromisura prevista |
|---|---|
| Relay malevolo | Handshake autenticato, identità verificata e consenso firmato |
| Directory manipolata | Firme multiple, verifica temporale e rifiuto di documenti incoerenti |
| Replay | Nonce, contatori monotoni e finestre temporali |
| Parser exploit | Parser piccolo, limiti rigidi, fuzzing e assenza di ricorsione inutile |
| Correlazione globale | Padding e multiplexing solo dopo specifica; nessuna promessa assoluta |
| DNS leak | Risoluzione attraverso circuito o rifiuto della modalità |
| Bypass overlay | Policy per applicazione e TUN disabilitato nella v0.1 |
| Flooding | Quote, backpressure, limite circuiti e rate limit |
| Nodo compromesso | Privilegi ridotti, segreti minimizzati e aggiornamenti firmati |
| Errori applicativi | Isolamento del client, contenuti attivi esclusi e limiti documentati |

La selezione dei relay deve ridurre, quando i dati sono disponibili, la probabilità di scegliere nodi sotto lo stesso operatore o nella stessa famiglia amministrativa. La diversità geografica non è una prova di indipendenza.

## Capacità ZLang

Il file [`network/zlang/zdos-anonymous-overlay-policy.zlang`](../network/zlang/zdos-anonymous-overlay-policy.zlang) è il profilo dichiarativo di riferimento. Le capacità iniziali sono `directory.read`, `circuit.create`, `circuit.extend`, `stream.open` e `stream.close`.

Il profilo non concede `socket.open`, `key.read`, `key.export`, `filesystem.write`, `process.exec`, `policy.publish`, `service.onion` o `tun.enable`. Queste capacità sono fuori dal perimetro della versione 0.1.

Il runtime deve produrre eventi osservabili per policy accettata, directory verificata, circuito creato, circuito esteso, stream aperto, stream chiuso, policy rifiutata e violazione di sicurezza. Gli eventi non devono contenere segreti, payload applicativi o credenziali.

## Roadmap controllata

| Fase | Risultato | Gate |
|---|---|---|
| A | Specifica, policy e modello di minaccia | Revisione della policy e test negativi |
| B | Wrapper crittografici e parser | Fuzzing, limiti di risorsa e API review |
| C | Rete locale deterministica | Relay di laboratorio e test di creazione/estensione |
| D | Directory e consenso | Firme, scadenza, revoca e relay malevoli simulati |
| E | Proxy TCP limitato | Solo porte dichiarate, DNS attraverso circuito e backpressure |
| F | Revisione indipendente | Audit, test di carico e decisione esplicita sul rilascio |

Nessuna fase autorizza automaticamente la successiva. Il passaggio a una rete pubblica richiede revisione indipendente, audit crittografico, disclosure process e verifica di due implementazioni indipendenti del formato.

## Criteri di accettazione v0.1

La policy è accettata quando ogni messaggio invalido viene rifiutato senza crescita illimitata della memoria, nessuna chiave o credenziale appare nei log, un relay non presente in un consenso valido viene rifiutato, le firme e le versioni invalide vengono respinte e ogni circuito ha chiavi distinte per hop.

Devono inoltre essere verificati chiusura su timeout, errori e revoca, divieto di DNS diretto, limiti di memoria, banda, circuiti e stream, oltre a test indipendenti contro il gateway. Un audit esterno non deve lasciare vulnerabilità critiche aperte. La documentazione deve distinguere privacy del percorso, anonimato dell’utente e sicurezza dell’endpoint.

## Limiti dichiarati

Questa versione non offre anonimato assoluto. Non protegge da un osservatore globale, da endpoint compromessi, da correlazione temporale avanzata, da errori applicativi o da una rete con relay collusi in modo significativo. Non deve essere usata per traffico pubblico, elusione, abuso o attività non autorizzate.

## Riferimenti

[1]: ../network/zlang/zdos-anonymous-overlay-policy.zlang "ZDOS Anonymous Overlay Policy v0.1"

[2]: https://www.z-lang.org/ "ZLang project reference"

[3]: https://www.torproject.org/about/history/ "Tor project background and public scope"
