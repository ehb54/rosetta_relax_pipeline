#!/usr/bin/env python3
import argparse

def generate_relax_xml(chains, res_start, res_end, output_file):
    chain_str = ",".join(chains)
    res_range = f"{res_start}-{res_end}"

    xml = f"""<ROSETTASCRIPTS>
  <SCOREFXNS>
    <ScoreFunction name="relaxfxn" weights="ref2015"/>
  </SCOREFXNS>

  <RESIDUE_SELECTORS>
    <Chain name="selected_chains" chains="{chain_str}"/>
    <Index name="relax_range" resnums="{res_range}"/>
    <And name="target_relax" selectors="selected_chains,relax_range"/>
  </RESIDUE_SELECTORS>

  <TASKOPERATIONS>
    <OperateOnResidueSubset name="repack_target" selector="target_relax">
      <RestrictToRepackingRLT/>
    </OperateOnResidueSubset>
  </TASKOPERATIONS>

  <MOVERS>
    <FastRelax name="relax" scorefxn="relaxfxn" task_operations="repack_target"/>
  </MOVERS>

  <PROTOCOLS>
    <Add mover="relax"/>
  </PROTOCOLS>
</ROSETTASCRIPTS>
"""

    with open(output_file, "w") as f:
        f.write(xml)
    print(f"✅ Wrote {output_file} for chains {chain_str}, residues {res_range}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate RosettaScripts XML for selective relax.")
    parser.add_argument("chains", nargs="+", help="Chains to relax (e.g. A B C)")
    parser.add_argument("--start", type=int, required=True, help="Start residue number")
    parser.add_argument("--end", type=int, required=True, help="End residue number")
    parser.add_argument("--out", type=str, default="relax.xml", help="Output XML filename")

    args = parser.parse_args()
    generate_relax_xml(args.chains, args.start, args.end, args.out)

