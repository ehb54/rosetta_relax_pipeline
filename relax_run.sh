#!/bin/bash
set -e

# === Config ===
ROSETTA_BIN=~/rosetta/source/bin/rosetta_scripts.default.linuxgccrelease
CHECK_SCRIPT=./check_clashes.pl
XML_GEN=./generate_relax_xml.py
MAX_RETRIES="${MAX_RETRIES:-3}"
CLASH_THRESHOLD="${CLASH_THRESHOLD:-10}"

# === Input Arguments ===
if [[ $# -lt 5 ]]; then
  echo "Usage: $0 input.pdb output_dir start_res end_res chain1 [chain2 ...]"
  echo "Env vars:"
  echo "  CLASH_THRESHOLD=<value>   # default: 10"
  echo "  MAX_RETRIES=<value>       # default: 3"
  exit 1
fi

INPUT_PDB=$1
OUTPUT_DIR=$2
START_RES=$3
END_RES=$4
shift 4
CHAINS=("$@")

BASENAME=$(basename "$INPUT_PDB" .pdb)
XML_FILE=${OUTPUT_DIR}/relax_${BASENAME}.xml

mkdir -p "$OUTPUT_DIR"

# === Generate Rosetta XML ===
echo "🛠️  Generating XML for chains: ${CHAINS[*]} ($START_RES–$END_RES)"
python3 "$XML_GEN" "${CHAINS[@]}" --start "$START_RES" --end "$END_RES" --out "$XML_FILE"

# === Relax with retries ===
ATTEMPT=1
SUCCESS=0

while [[ $ATTEMPT -le $MAX_RETRIES ]]; do
    echo "🚀 Relaxation attempt #$ATTEMPT"
    SUFFIX="_relaxed_try${ATTEMPT}"
    RELAXED_PDB="${OUTPUT_DIR}/${BASENAME}${SUFFIX}_0001.pdb"

    $ROSETTA_BIN \
        -s "$INPUT_PDB" \
        -parser:protocol "$XML_FILE" \
        -relax:constrain_relax_to_start_coords \
        -relax:coord_constrain_sidechains \
        -nstruct 1 \
        -out:suffix "$SUFFIX" \
        -out:path:all "$OUTPUT_DIR"

    echo "🔍 Checking for residual clashes..."
    if perl "$CHECK_SCRIPT" "$RELAXED_PDB" "$OUTPUT_DIR" "$CLASH_THRESHOLD"; then
        echo "✅ Clash-free structure found on attempt #$ATTEMPT: $RELAXED_PDB"
        SUCCESS=1
        break
    else
        echo "⚠️  Clashes detected on attempt #$ATTEMPT. Retrying..."
        ((ATTEMPT++))
    fi
done

if [[ $SUCCESS -eq 0 ]]; then
    echo "❌ All $MAX_RETRIES relax attempts still contain clashes. See output for diagnostics."
    exit 1
fi
