# Identità ZDOS per Android e futuri utenti

## Regola principale

`192.168.1.232` è un indirizzo di rete locale, non un'identità.

- cambia quando il router assegna un nuovo DHCP;
- può essere condiviso o riutilizzato;
- non è portabile fuori dalla Wi-Fi;
- non dimostra chi possiede il dispositivo.

L'IP serve solo a raggiungere il Glass Engine durante il pairing LAN:

```text
http://IP_DEL_PC:8080
```

Il telefono inserisce l'IP del PC, non il proprio IP.

## Identità proposta

Ogni installazione Microcosm riceve una coppia Ed25519 generata sul dispositivo:

```text
private key  → resta in Android Keystore / SecureStore
public key   → registrata nel profilo ZDOS
DID          → did:zdos:<fingerprint-pubkey>
```

Il DID è stabile anche se cambiano Wi-Fi, IP, SIM o porta. Il server conserva solo:

- DID;
- chiave pubblica;
- nome visualizzato scelto dall'utente;
- stato di revoca;
- timestamp di ultimo pairing;
- capability esplicite.

La chiave privata non viene mai inviata al PC o a `app.x-zdos.it`.

## Flusso futuro di onboarding

1. Il PC genera un pairing code monouso con scadenza breve.
2. L'utente scansiona un QR mostrato da Glass Engine.
3. Android genera la chiave Ed25519 localmente.
4. Android firma una richiesta di enrollment con la chiave privata.
5. Il PC associa il DID alla sessione LAN e mostra il nome/device.
6. Il server rilascia una credenziale verificabile limitata, per esempio:

   ```text
   zcomm.message.queue
   zcomm.sync.push
   zcomm.sync.pull
   ```

7. Il token LAN viene revocato dopo il bootstrap o resta solo come session token breve.

## Firma dei messaggi

Ogni messaggio ZComm dovrebbe contenere:

```json
{
  "messageId": "uuid",
  "senderDid": "did:zdos:...",
  "roomId": "piazza",
  "body": "testo",
  "createdAt": "2026-10-02T18:00:00Z",
  "nonce": "...",
  "signature": "ed25519:..."
}
```

Il bridge verifica:

- firma;
- DID registrato;
- nonce non riutilizzato;
- finestra temporale;
- capability `zcomm.message.queue`.

Un IP diverso non invalida il DID; una firma non valida invalida il messaggio anche se arriva dalla Wi-Fi corretta.

## Stato attuale del progetto

Il bridge appena aggiunto è la **fase 1**:

- token locale casuale;
- pairing manuale endpoint + token;
- coda persistente;
- nessuna shell o mutazione remota.

La **fase 2** è l'enrollment Ed25519/DID e la firma dei messaggi. Non va simulata con IP, nickname o UUID non firmati.
