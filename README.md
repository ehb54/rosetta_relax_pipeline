# 📦 relax_pipeline

## Incremental Rosetta Relaxation of Multichain Protein Variants

This pipeline incrementally relaxes multichain protein models in which residues **87–140** of each chain are replaced. It ensures steric clashes are resolved one chain at a time, preserving structure integrity.

---

## 🚀 Overview

**Goal:** Generate a single, clash-free, physically plausible structure by relaxing only the modified region of each chain (residues 87–140), one chain at a time.

**Strategy:**
1. Start with all chains (A–E), each 1–140 residues.
2. Assume chain **A** is always fixed and correct.
3. Add one chain at a time (B → E), and relax only residues 87–140 of the newly added chain.
4. Check for steric clashes (`fa_rep`) after each relaxation step.
5. If clash-free, reintroduce the next chain and repeat.

---

## 📁 Directory Layout

```
relax_pipeline/
├── generate_relax_xml.py        # Auto-generates RosettaScripts XML
├── prepare_phase.pl             # Cuts residues 87–140 from selected chains
├── reassemble_phase.pl          # Reattaches residues from original structure
├── check_clashes.pl             # Scores relaxed output and reports fa_rep clashes
├── relax_run.sh                 # Runs relax + clash check with retries & logging
├── run_all_phases.sh            # NEW: Wrapper for all relaxation phases
├── input/                       # Full original PDB(s)
│   └── input.pdb
├── variants/                    # Intermediate variant PDBs (AB, ABC, etc.)
├── output/                      # Relaxed outputs and logs per phase
└── xml/                         # Auto-generated relax XML files
```

---

## 🔧 Requirements

- [Rosetta](https://www.rosettacommons.org/) (academic license required)
- Perl, Python 3, Bash
- `score_jd2.default.linuxgccrelease` and `rosetta_scripts.default.linuxgccrelease` built and in your path

---

## 🧪 Example Workflow (Manual)

### 1. Prepare the first phase input (chains A+B)
```bash
perl prepare_phase.pl input/input.pdb variants/AB_variant.pdb "A B" "C D E" 87 140
```

### 2. Relax chain B only
```bash
./relax_run.sh variants/AB_variant.pdb output/AB 87 140 A B
```

### 3. Reassemble with chain C and relax C only
```bash
perl reassemble_phase.pl input/input.pdb output/AB/AB_variant_chainB_relaxed_try1_0001.pdb "C" 87 140 variants/ABC_variant.pdb
./relax_run.sh variants/ABC_variant.pdb output/ABC 87 140 A B C
```

### 4. Repeat for D, then E...

---

## 🤖 Automated Workflow

Run all phases in sequence (assumes input.pdb has chains A–E):
```bash
./run_all_phases.sh
```

This automates:
- Variant construction
- Relaxation with retries
- Clash detection
- Reassembly

---

## 📊 Clash Checking & Logging

Each relaxation run:
- Scores output with Rosetta
- Flags residues with `fa_rep > 10`
- Logs attempt status and relaxed structure to `relax_summary.log`

Example log:
```
[2025-06-27 15:01:42] input=ABC_variant.pdb  output=ABC_variant_chainC_relaxed_try1_0001.pdb  relaxed_chain=C  res=87-140  attempts=1  status=OK
```

---

## 🧠 Why Incremental?

- Prevents propagating distortion
- Minimizes unnecessary flexibility
- Pinpoints structural issues chain-by-chain
- Makes debugging and validation easy

---

## 📬 Questions?

Open an issue or contact the authors for help adapting the pipeline to other multimeric systems, alternate residue ranges, or constraints.

