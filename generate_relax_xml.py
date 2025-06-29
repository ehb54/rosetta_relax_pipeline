#!/usr/bin/env python3
import argparse

def generate_relax_xml(chains, res_start, res_end, output_file):
    all_chain_str = ",".join(chains)
    relax_chain = chains[-1]
    res_range = f"{res_start}-{res_end}"

    xml = f"""<ROSETTASCRIPTS>
  <SCOREFXNS>
    <ScoreFunction name="relaxfxn" weights="ref2015"/>
  </SCOREFXNS>

  <RESIDUE_SELECTORS>
    <Chain name="all_chains" chains="{all_chain_str}"/>
    <Chain name="relax_chain" chains="{relax_chain}"/>
    <Index name="relax_range" resnums="{res_range}"/>
    <And name="target_relax" selectors="relax_chain,relax_range"/>
  </RESIDUE_SELECTORS>

  <TASKOPERATIONS>
    <OperateOnResidueSubset name="repack_target" selector="target_relax">
      <RestrictToRepackingRLT/>
    </OperateOnResidueSubset>
  </TASKOPERATIONS>

  <MOVERS>
    <FastRelax name="relax" scorefxn="relaxfxn" task_operations="repack_target"/>
    <ScoreMover name="score" scorefxn="relaxfxn" />
  </MOVERS>

  <PROTOCOLS>
    <Add mover="relax"/>
    <Add mover="score"/>
  </PROTOCOLS>

</ROSETTASCRIPTS>
"""
    with open(output_file, "w") as f:
        f.write(xml)
    print(f"✅ Wrote {output_file} relaxing chain {relax_chain} in range {res_range} (others fixed: {', '.join(chains[:-1])})")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate RosettaScripts XML for relaxing part of a structure.")
    parser.add_argument("chains", nargs="+", help="Chains involved (relaxes last one only)")
    parser.add_argument("--start", type=int, required=True, help="Start residue number")
    parser.add_argument("--end", type=int, required=True, help="End residue number")
    parser.add_argument("--out", type=str, default="relax.xml", help="Output XML filename")

    args = parser.parse_args()
    generate_relax_xml(args.chains, args.start, args.end, args.out)
