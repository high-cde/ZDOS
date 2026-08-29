# ZDOS Native Command Library

La console ZDOS usa comandi brevi, adatti alla modalità testuale e all'interfaccia retro-computing. Il prompt standard è `x@zdos /`, per dare subito l'impressione di trovarsi dentro il sistema operativo e non in una shell Linux esterna. La brevità è una scorciatoia di ingresso, non una riduzione dei controlli: ogni comando passa ancora dalle policy ZDOS e dal bridge Zlang quando accede ai dati.

## Vocabolario

| Comando | Nome completo | Azione |
|---|---|---|
| `h` | `help` | Mostra il vocabolario. |
| `i` | `identity` | Verifica chiave pubblica e grant del ruolo. |
| `s` | `status` | Mostra stato ZDOS, Zlang, ruolo e namespace. |
| `z` | `zspace` | Elenca gli oggetti del namespace autorizzato. |
| `r <oggetto>` | `read <object>` | Traduce la richiesta nella capability Zlang `storage.read-v1`. |
| `q` | `quit` | Chiude la console. |

I comandi distruttivi, l'esecuzione arbitraria di shell, rete e copie o spostamenti non sono alias disponibili nella console minima. Le operazioni amministrative restano esplicite e richiedono in futuro una capability separata.

## Avvio

```sh
python3 commands/zdoscmd.py \
  --identity-dir "$HOME/.zdos/identity/alice" \
  --root "$HOME/.zdos/data"
```

Per eseguire una sola istruzione:

```sh
python3 commands/zdoscmd.py \
  --identity-dir "$HOME/.zdos/identity/alice" \
  --root "$HOME/.zdos/data" \
  --once 'r marker'
```

## Esempio

```text
ZDOS NATIVE CONSOLE | ZLANG CONNECTED | usa h per aiuto
x@zdos / s
ZDOS=READY ZLANG=CONNECTED ROLE=administrator NAMESPACE=...
x@zdos / z
OBJ  marker
x@zdos / r marker
ZDOS native data
x@zdos / q
```

Il comando `r` non legge direttamente il filesystem con privilegi generici. Crea una breve istruzione Zlang `storage.read`, la passa al bridge e lascia al bridge la verifica di identità, ruolo, firma, namespace, path relativo e quota. Il modello è quindi:

```text
alias breve → comando semantico → capability Zlang → policy ZDOS → oggetto ZSpace
```

## ZSpace e formati

Lo ZSpace è orientato a oggetti: `identity`, `programs`, `data`, `evidence` e `shared`. Un oggetto deve avere tipo, proprietario, policy e versione. TXT, JPG, HTML e archivi non sono comandi o primitive della console; se un adapter li riceve, il suo compito è convertirli in un oggetto ZDOS dichiarato, non introdurre un file manager classico.
