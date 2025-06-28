#!/bin/bash
set -e

# === Config ===
INPUT_DIR="input"
VARIANT_DIR="variants"
OUTPUT_DIR="output"
INPUT_PDB="${INPUT_DIR}/input.pdb"
START_RES=87
END_RES=140

FIXED_CHAIN="A"
RELAX_ORDER=("B" "C" "D" "E")

CURRENT_CHAINS=("$FIXED_CHAIN")  # Start with just A

for CHAIN in "${RELAX_ORDER[@]}"; do
    CURRENT_CHAINS+=("$CHAIN")
    PREV_CHAINS=("${CURRENT_CHAINS[@]:0:${#CURRENT_CHAINS[@]}-1}")
    NEW_CHAIN="${CHAIN}"

    # Compose filenames
    VARIANT_NAME=$(IFS=; echo "${CURRENT_CHAINS[*]}")
    VARIANT_FILE="${VARIANT_DIR}/${VARIANT_NAME}_variant.pdb"
    PREV_OUTPUT_DIR="${OUTPUT_DIR}/$(IFS=; echo "${PREV_CHAINS[*]}")"
    CURR_OUTPUT_DIR="${OUTPUT_DIR}/${VARIANT_NAME}"

    echo "🔧 Preparing variant: ${VARIANT_NAME}"
    if [[ ${#PREV_CHAINS[@]} -eq 1 ]]; then
        # First phase — cut from original input
        perl prepare_phase.pl "$INPUT_PDB" "$VARIANT_FILE" "${CURRENT_CHAINS[*]}" \
            "$(IFS=\ ; echo "${RELAX_ORDER[@]:1}")" $START_RES $END_RES
    else
        PREV_RELAXED_PDB=$(ls "$PREV_OUTPUT_DIR"/*chain${RELAX_ORDER[${#PREV_CHAINS[@]}-1]}_relaxed_try*_0001.pdb | head -n 1)
        perl reassemble_phase.pl "$INPUT_PDB" "$PREV_RELAXED_PDB" "$NEW_CHAIN" \
            $START_RES $END_RES "$VARIANT_FILE"
    fi

    echo "🧘 Running relax on chain $CHAIN"
    ./relax_run.sh "$VARIANT_FILE" "$CURR_OUTPUT_DIR" $START_RES $END_RES "${CURRENT_CHAINS[@]}"
done

echo "✅ All phases complete!"
