# ZDOS Evidence Wallet

## Che cos'è

Evidence Wallet è il pannello umano per la **ZDOS Evidence Chain**. Mostra identità, capability, head hash, eventi e verifica del ledger. Il ledger attuale è una catena append-only di eventi non monetari con hash SHA-256 concatenati.

Non è ancora una blockchain pubblica con consenso distribuito, token, saldo o smart contract. La UI non deve chiamarlo wallet monetario e non deve imitare una falsa disponibilità di fondi.

## Confronto con MetaMask

| Concetto | MetaMask | Evidence Wallet ZDOS |
|---|---|---|
| Account | account blockchain | identità locale `did:zdos:*` |
| Network | RPC chain | profilo ZDOS / ledger locale |
| Asset | token e NFT | nessun asset monetario |
| Activity | transazioni | attestazioni e receipt |
| Security | seed/key vault | identità Ed25519 cifrata, mai letta dalla UI |
| Signing | transazioni | non disponibile nella prima release |
| Transfer | disponibile | esplicitamente negato |
| Verify | RPC/contract | hash chain + schema + sequence |

## Route

```text
GET /api/local/evidence/wallet
```

La route non legge chiavi private. Restituisce solo:

- DID pubblico e nickname se l'identità è presente;
- ruolo e capability non segrete;
- numero eventi e head hash;
- verifica locale della catena;
- capability negate (`wallet.transfer-v1`, `wallet.sign-transaction-v1`, `contract.approve-v1`).

## Installazione sul PC

Il servizio resta su `127.0.0.1:8080` per proteggere identità e stato. Per non digitare l'URL a mano:

```bash
bash scripts/install-glass-engine-desktop.sh
```

Viene creato un launcher nel menu applicazioni: **ZDOS Glass Engine**.

Per rendere il servizio raggiungibile da altri dispositivi non basta cambiare `127.0.0.1` in `0.0.0.0`: servono TLS, autenticazione, firewall, origin policy, sessioni revocabili e un reverse proxy. Questa è una fase separata e non viene attivata automaticamente.

## Evoluzione futura

1. `evidence.verify-v1` — già esposto;
2. identità locale Ed25519 e attestazioni — già disponibili nel perimetro ZDOS;
3. consenso multi-nodo e replica — da progettare;
4. timestamping/anchors esterni — da progettare;
5. smart contract Zlang con sandbox — futura milestone;
6. eventuali asset monetari — progetto separato, audit indipendente e mai implicito nel ledger Evidence.
