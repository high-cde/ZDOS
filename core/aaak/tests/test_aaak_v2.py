import aaak
import numpy as np

def test_encode_structure():
    out = aaak.encode("Hello world")
    assert "embedding" in out
    assert "reduced" in out
    assert "concepts" in out
    assert "fingerprint" in out

def test_embedding_shape():
    out = aaak.encode("Hello world")
    assert len(out["embedding"]) == 32

def test_reduced_shape():
    out = aaak.encode("Hello world")
    assert len(out["reduced"]) == 8

def test_concepts():
    out = aaak.encode("Hello hello world")
    assert out["concepts"] == ["hello", "world"]

def test_fingerprint_stability():
    fp1 = aaak.encode("Hello world")["fingerprint"]
    fp2 = aaak.encode("Hello world")["fingerprint"]
    assert fp1 == fp2
