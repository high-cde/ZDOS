import secrets
import hashlib
import json

def generate_takeaway_identity():
    """Genera un'identità fantasma per Z-NEXUS"""
    
    # 1. Generiamo un Alias univoco per la board (es. Z-Node-0742)
    node_id = secrets.randbelow(9999)
    alias = f"Z-Node-{node_id:04d}"

    # 2. Generiamo la Chiave Privata (TAKE-AWAY - mostrata all'utente 1 sola volta)
    private_key = secrets.token_hex(32) # 64 caratteri esadecimali

    # 3. Creiamo il 'Salt' e l'Hash che rimarranno sul Server
    salt = secrets.token_hex(16)
    server_hash = hashlib.sha256((private_key + salt).encode()).hexdigest()

    # 4. Formattiamo i dati
    return {
        "user_view": {
            "alias": alias,
            "private_key": private_key,
            "WARNING": "SALVA QUESTA CHIAVE OFFLINE. NON SARÀ MAI PIÙ MOSTRATA."
        },
        "server_view": {
            "alias": alias,
            "salt": salt,
            "hash": server_hash
        }
    }

if __name__ == "__main__":
    print("\n[!] === Z-NEXUS // GENERAZIONE IDENTITÀ FANTASMA ===")
    identity = generate_takeaway_identity()
    
    print(f"\n[+] ALIAS ASSEGNATO : {identity['user_view']['alias']}")
    print(f"[+] CHIAVE PRIVATA  : {identity['user_view']['private_key']}")
    print(f"[!] {identity['user_view']['WARNING']}")
    
    print("\n[*] Dati registrati nel Database ZDOS (Irreversibili):")
    print(json.dumps(identity['server_view'], indent=2))
    print("===================================================\n")
