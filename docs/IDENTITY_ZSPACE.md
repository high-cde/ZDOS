# ZDOS Identity e ZSpace

## Obiettivo

ZDOS usa un'identità locale indipendente dalla rete. Il **nick** è un nome leggibile; l'identità reale è il fingerprint della chiave pubblica Ed25519. L'indirizzo IP non partecipa alla generazione, al riconoscimento o alla validazione dell'utente.

Il bootstrap crea una coppia di chiavi, un grant di ruolo firmato e un codice di recovery alfanumerico di 36 caratteri. Il codice viene mostrato una sola volta e nel profilo viene conservato soltanto il digest PBKDF2-HMAC-SHA256. La chiave privata viene cifrata a riposo.

## Bootstrap

```sh
export ZDOS_IDENTITY_PASSPHRASE='scegliere-una-passphrase-locale'
python3 identity/zdos_identity.py init \
  --nick alice \
  --role administrator \
  --state-dir /var/lib/zdos/identity/alice
```

L'output contiene l'identificatore `did:zdos:<sha256-public-key>` e il recovery code. Il recovery code non deve essere salvato in shell history, commit, log o Evidence Chain.

```sh
python3 identity/zdos_identity.py verify \
  --state-dir /var/lib/zdos/identity/alice

ZDOS_RECOVERY_CODE='...' \
python3 identity/zdos_identity.py verify-recovery \
  --state-dir /var/lib/zdos/identity/alice
```

## Ruoli

| Ruolo | Capability |
|---|---|
| `standard` | `storage.read-v1` |
| `operator` | `storage.read-v1`, `evidence.append-v1` |
| `administrator` | Le capability precedenti più `identity.manage-v1` e `policy.manage-v1` |

Il nick non concede privilegi. Il privilegio viene dalla capability ammessa dal ruolo e dal grant firmato associato alla chiave pubblica. In una fase successiva il bootstrap administrator potrà delegare, revocare o richiedere una seconda chiave per operazioni critiche.

## Connessione ZDOS–Zlang

Il contratto condiviso è [`identity/contract.json`](../identity/contract.json). La capability iniziale è `storage.read-v1`, già coerente con il bridge read-only presente nel repository Zlang.

```sh
python3 identity/zdos_zlang_bridge.py program.zlang \
  --identity-dir /var/lib/zdos/identity/alice \
  --root /mnt/data \
  --max-bytes 4096
```

Il bridge verifica schema dell'identità, ruolo, corrispondenza del subject e capability. Poi delega a `Zlang/tools/zlang_storage_read.py`, che consente soltanto path relativi dentro il namespace esplicito, senza scrittura e con quota di lettura.

Un programma minimo è:

```zlang
storage.read ".zdos-persistence-marker"
```

La connessione è quindi: **chiave ZDOS → grant di ruolo → capability `storage.read-v1` → bridge → istruzione Zlang → namespace persistente ZDOS**. Nessun IP è presente nel contratto o nel profilo identità.

## ZSpace

Il file manager tradizionale non è una primitiva di ZDOS. La superficie prevista è uno **ZSpace** orientato a oggetti nativi:

```text
identity/  system/  programs/  data/  evidence/  shared/
```

Gli oggetti avranno un tipo ZDOS/Zlang, un owner, una policy, una versione e capability esplicite. I formati esterni possono essere trattati solo da adapter di importazione temporanei; non diventano il modello interno del sistema.

## Limiti dichiarati

Questa implementazione realizza il **contratto e il bridge locale**. Non dichiara ancora un keystore TPM, un registro globale di identità, una revoca distribuita o un filesystem nativo bare-metal. Il codice recovery è un segreto di recupero; non sostituisce la chiave privata e non deve essere usato come identità pubblica.
