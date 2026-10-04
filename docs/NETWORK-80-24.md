# ZDOS Public Network 80.24

## Stato

Il profilo `80.24.0.0/16` è stato registrato come **rete pubblica assegnata dichiarata dall'utente**, ma resta in modalità:

```text
DESIGN_ONLY · DEFAULT_DENY · nessuna modifica al PC
```

Un `/16` contiene 65.536 indirizzi totali e 65.534 host teorici. Questo non significa che ogni indirizzo sia utilizzabile: gateway, routing, DNS, reverse DNS, ACL del provider, anti-spoofing e delega effettiva devono essere confermati dall'assegnatario/provider.

## Profilo ZDOS

Il file [`network/subnet-8024.json`](../network/subnet-8024.json) dichiara:

- CIDR `80.24.0.0/16`;
- gateway e interfaccia ancora non valorizzati;
- DHCP e NAT disabilitati;
- firewall e DNS non configurati;
- capability di sola lettura e pianificazione;
- route, firewall, apertura porte e scan esplicitamente negati.

Il programma [`network/subnet_8024_policy.zlang`](../network/subnet_8024_policy.zlang) esprime la stessa policy nel profilo ZLB2 bounded. Non esegue route, non assegna IP e non apre porte.

## Layout logico suggerito

| Zona | Scopo | Stato |
|---|---|---|
| `80.24.0.0` | network address | riservato |
| `80.24.255.255` | broadcast IPv4 | riservato |
| control plane | ZDOS/Microcosm | da assegnare dopo gateway e ACL |
| services | Glass Engine, ZComm, DNS | da assegnare con firewall |
| clients | PC e device autorizzati | da assegnare con inventory |

Non vengono inseriti IP concreti nei manifest finché non sono disponibili interfaccia, gateway e piano del provider.

## Gate obbligatori prima dell'attivazione

1. confermare delega scritta del blocco e responsabilità di routing;
2. indicare gateway, netmask/prefix, DNS e interfaccia fisica o VLAN;
3. definire firewall default-deny e ingressi necessari;
4. definire reverse DNS e certificati TLS;
5. assegnare IP solo a host inventariati;
6. verificare anti-spoofing e route senza applicarla in prima battuta;
7. fare test in namespace/network lab;
8. applicare una singola modifica reversibile con rollback documentato;
9. verificare che Glass Engine resti locale o protetto da autenticazione;
10. non eseguire port scan del blocco pubblico.

## Verifica non distruttiva

```bash
python3 tools/validate-subnet-8024.py
```

Output atteso:

```text
PASS schema
PASS cidr
PASS design_only
PASS default_deny
PASS no_gateway
PASS no_interface
PASS dhcp_disabled
PASS nat_disabled
PASS route_apply_denied
PASS firewall_apply_denied
ZDOS_SUBNET_PROFILE_VALIDATED cidr=80.24.0.0/16 hosts=65534 activation=DESIGN_ONLY
```

Per compilare il programma Zlang serve il clone canonico Zlang:

```bash
python3 ../Zlang/tools/zlangc.py \
  network/subnet_8024_policy.zlang \
  --header /tmp/subnet_8024_policy.h
```

La compilazione del programma dimostra solo la correttezza del bytecode. L'attivazione della rete è una fase separata e richiede i gate sopra.
