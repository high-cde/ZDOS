import hashlib
import numpy as np

# -------------------------
# NORMALIZZAZIONE
# -------------------------
def normalize(text: str) -> str:
    return text.strip().lower()


# -------------------------
# TOKENIZZAZIONE
# -------------------------
def tokenize(text: str):
    return text.split()


# -------------------------
# EMBEDDING SEMANTICO (fake embedding v2)
# -------------------------
def embedding(tokens):
    vectors = []
    for t in tokens:
        h = int(hashlib.sha256(t.encode()).hexdigest(), 16)
        vec = np.array([(h >> (i * 8)) & 0xFF for i in range(32)], dtype=np.float32)
        vectors.append(vec)
    if not vectors:
        return np.zeros(32, dtype=np.float32)
    return np.mean(vectors, axis=0)


# -------------------------
# RIDUZIONE DIMENSIONALE
# -------------------------
def reduce_vector(vec):
    return vec.reshape(8, 4).mean(axis=1)


# -------------------------
# ESTRAZIONE CONCETTI
# -------------------------
def concepts(tokens):
    return sorted(set(tokens))


# -------------------------
# FINGERPRINT COGNITIVO
# -------------------------
def fingerprint(vec):
    b = vec.tobytes()
    return hashlib.sha256(b).hexdigest()


# -------------------------
# PIPELINE COMPLETA
# -------------------------
def encode(text: str) -> dict:
    norm = normalize(text)
    toks = tokenize(norm)
    emb = embedding(toks)
    red = reduce_vector(emb)
    conc = concepts(toks)
    fp = fingerprint(red)

    return {
        "normalized": norm,
        "tokens": toks,
        "embedding": emb.tolist(),
        "reduced": red.tolist(),
        "concepts": conc,
        "fingerprint": fp,
        "length": len(norm)
    }


def decode(data: dict) -> str:
    return data.get("normalized", "")
