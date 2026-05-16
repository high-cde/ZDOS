#!/usr/bin/env python3
from pathlib import Path
import random

def generate_neurons(n=100):
    out = ["pt_root_id\tcell_type\tx\ty\tz\tneuropil"]
    for i in range(n):
        nid = 1000 + i
        ctype = random.choice(["PN", "KC", "LN", "MBON"])
        x = random.uniform(0, 200)
        y = random.uniform(0, 200)
        z = random.uniform(0, 200)
        region = random.choice(["AL", "MB", "LH", "PB"])
        out.append(f"{nid}\t{ctype}\t{x:.2f}\t{y:.2f}\t{z:.2f}\t{region}")
    return "\n".join(out)

def generate_synapses(n_neurons=100, n_syn=300):
    out = ["pre_pt_root_id\tpost_pt_root_id\tsyn_count"]
    ids = [1000 + i for i in range(n_neurons)]
    for _ in range(n_syn):
        pre = random.choice(ids)
        post = random.choice(ids)
        if pre == post:
            continue
        w = random.randint(1, 10)
        out.append(f"{pre}\t{post}\t{w}")
    return "\n".join(out)

def main():
    neurons_file = Path("flywire_neurons.tsv")
    synapses_file = Path("flywire_synapses.tsv")

    print("[GEN] Generating neurons...")
    neurons_file.write_text(generate_neurons(100))

    print("[GEN] Generating synapses...")
    synapses_file.write_text(generate_synapses(100, 300))

    print("[GEN] Done.")
    print("[GEN] Files created:")
    print(" - flywire_neurons.tsv")
    print(" - flywire_synapses.tsv")

if __name__ == "__main__":
    main()
