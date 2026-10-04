# ZDOS Web3 Observation Plane

Il sistema operativo ZDOS ora include un piano di osservazione Web3 per leggere stato di rete, blocchi e saldi di indirizzi EVM senza custodire fondi o autorizzare transazioni.

## Connettori disponibili

| Rete | Identificatore | Operazioni |
|---|---|---|
| Ethereum Mainnet | `ethereum` | chain ID, block number, balance |
| Polygon PoS | `polygon` | chain ID, block number, balance |
| Base | `base` | chain ID, block number, balance |
| Arbitrum One | `arbitrum` | chain ID, block number, balance |
| Ethereum Sepolia | `sepolia` | chain ID, block number, balance |

Gli endpoint RPC sono HTTPS allowlistati e possono essere sostituiti dall'amministratore con variabili `ZDOS_WEB3_*_RPC`. Non vengono accettati URL RPC arbitrari dalla UI.

## API locali

```text
GET /api/web3/networks
GET /api/web3/status?network=ethereum,polygon
GET /api/web3/address?network=ethereum&address=0x...
GET /api/web3/validate
```

Tutte le API sono read-only e applicano timeout di sette secondi. Gli indirizzi devono avere il formato EVM `0x` seguito da 40 caratteri esadecimali.

## Contratto Zlang

Il profilo è in [`web3/zdos_web3_observe.zlang`](../web3/zdos_web3_observe.zlang) e accetta solo capability dichiarate per osservazione:

```text
web3.networks
web3.chain.status
web3.block.read
web3.balance.read
web3.address.validate
web3.evidence.candidate
halt
```

Sono sempre negate:

```text
wallet.sign
wallet.transfer
contract.write
private-key.read
eth_sendRawTransaction
```

## Cosa non fa

- non legge seed phrase o chiavi private;
- non collega wallet browser;
- non firma messaggi o transazioni;
- non invia transazioni;
- non approva smart contract;
- non fa trading o automazione DeFi;
- non presenta dati RPC come prova di proprietà dell'indirizzo.

Il Workbench si trova nella console desktop in `#web3-workbench` e si chiama **Chain Observatory**.
