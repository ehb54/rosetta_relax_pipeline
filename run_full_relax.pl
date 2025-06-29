#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use File::Path qw(make_path);

# === Usage ===
# run_full_relax.pl input.pdb output_dir start_res end_res chain1 [chain2 ...]
# Example:
#   ./run_full_relax.pl model1.pdb output_model1 1 250 A B C

die "Usage: $0 input.pdb output_dir start_res end_res chain1 [chain2 ...]\n"
    unless @ARGV >= 5;

my ($input_pdb, $output_dir, $start_res, $end_res, @chains) = @ARGV;

# === Derived values ===
my $xml_file = "$output_dir/relax.xml";
my $basename = basename($input_pdb, '.pdb');

# === Setup ===
make_path($output_dir);

print "🛠️  Generating Rosetta XML for chains: @chains ($start_res-$end_res)\n";
system("python3", "generate_relax_xml.py", @chains,
       "--start", $start_res, "--end", $end_res, "--out", $xml_file) == 0
    or die "❌ Failed to generate XML\n";

print "🧘 Running full structure relaxation\n";
system("./relax_run.sh", $input_pdb, $output_dir, $start_res, $end_res, @chains) == 0
    or die "❌ Relaxation failed\n";

print "✅ Full relaxation complete: see $output_dir\n";
