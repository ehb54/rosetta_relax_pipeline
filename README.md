# 📦 relax_pipeline

## Incremental Rosetta Relaxation of Multichain Protein Variants

This pipeline incrementally relaxes multichain protein models in which residues **87–140** of each chain are replaced. It ensures steric clashes are resolved in each chain before progressively reintroducing additional chains.

---

## 🚀 Overview

**Goal:** Generate a single, clash-free, physically plausible structure by relaxing only the modified region of each chain (residues 87–140) while keeping the rest (1–86) fixed.

**Strategy:**
1. Start with all chains (A–E), each 1–140 residues.
2. Remove residues 87–140 from chains C–E.
3. Relax variant region in chains A and B using Rosetta.
4. Check for steric clashes (`fa_rep`) after relaxation.
5. If clash-free, reintroduce the next chain’s variant region and repeat.
6. Continue until all chains are reattached and relaxed.

---

## 📁 Directory Layout

```
relax_pipeline/
├── generate_relax_xml.py        # Auto-generates RosettaScripts XML
├── prepare_phase.pl             # Cuts residues 87–140 from selected chains
├── reassemble_phase.pl          # Reattaches residues from original structure
├── check_clashes.pl             # Scores relaxed output and reports fa_rep clashes
├── relax_run.sh                 # Runs full relax + clash check with retries
├── input/                       # Full original PDB(s)
│   └── input.pdb
├── variants/                    # Working phase inputs (e.g. AB_variant.pdb)
├── output/                      # Relaxed outputs and diagnostics
└── xml/                         # Auto-generated relax XML files
```

---

## 🔧 Requirements

- [Rosetta](https://www.rosettacommons.org/) (academic license required)
- Perl, Python 3, Bash
- `score_jd2.default.linuxgccrelease` and `rosetta_scripts.default.linuxgccrelease` built and in `~/rosetta/source/bin/`

---

## 🧪 Example Workflow

### 1. Prepare first phase input (relax chains A+B)
```bash
perl prepare_phase.pl input/input.pdb variants/AB_variant.pdb "A B" "C D E" 87 140
```

### 2. Relax and check for clashes
```bash
./relax_run.sh variants/AB_variant.pdb output/AB 87 140 A B
```

- If clashes are found (`fa_rep > 10`), up to 3 relax attempts are tried.
- Reports and PyMOL selection files are saved.

### 3. Reassemble with next chain (e.g. C)
```bash
perl reassemble_phase.pl input/input.pdb output/AB/AB_variant_relaxed_try1_0001.pdb "C" 87 140 variants/ABC_variant.pdb
```

### 4. Repeat
```bash
./relax_run.sh variants/ABC_variant.pdb output/ABC 87 140 A B C
```

---

## 📊 Clash Checking & Output

- `check_clashes.pl` uses Rosetta `score_jd2` to extract per-residue `fa_rep`
- Any residue above a configurable threshold (default: 10) is flagged
- Output:
  - `residue_energies.txt` — tabular list of fa_rep outliers
  - `clash_selection.pml` — PyMOL selection script
  - Retried structures with suffixes like `_relaxed_try2_0001.pdb`

---

## 🔄 Environment Variables

You can override defaults via environment variables:

```bash
CLASH_THRESHOLD=12 MAX_RETRIES=5 ./relax_run.sh ...
```

---

## 🧠 Why Incremental Relaxation?

- Prevents structural distortion by resolving clashes chain-by-chain
- Enables selective backbone mobility in modified regions only
- Ensures clean, reproducible integration of variant segments

---

## 📬 Questions?

Feel free to open an issue or reach out for clarification on adapting the pipeline for different chain counts, residue ranges, or constraints.
