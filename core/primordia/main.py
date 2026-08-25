from .primordia_core import PrimordiaCore

def start_primordia():
    """
    Funzione per avviare l'organismo ZDOS // PRIMORDIA.
    """
    print("Avvio dell'organismo ZDOS // PRIMORDIA...")
    primordia = PrimordiaCore()
    primordia.run()
    print("Organismo ZDOS // PRIMORDIA avviato e in esecuzione.")

if __name__ == "__main__":
    start_primordia()
