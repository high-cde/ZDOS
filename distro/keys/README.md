# Chiavi di release

La chiave privata di firma **non deve mai essere committata**. Per abilitare il canale `production`:

1. generare una coppia Ed25519 in un key manager approvato;
2. pubblicare soltanto la chiave pubblica nel repository o nel registro di release approvato;
3. salvare la chiave privata nel secret/environment `ZDOS_RELEASE_SIGNING_KEY`;
4. salvare la chiave pubblica nel secret/environment `ZDOS_RELEASE_SIGNING_PUBLIC_KEY`;
5. verificare che il workflow confronti fingerprint, manifest e firma prima della pubblicazione.

Il canale `preview` può verificare gli hash SHA-256, ma non deve essere promosso a produzione finché la coppia di chiavi e il verificatore di firma non sono configurati.
