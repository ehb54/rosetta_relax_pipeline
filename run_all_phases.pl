#!/usr/bin/env perl
use strict;
use warnings;
use File::Basename;
use File::Path qw(make_path);
use Cwd qw(abs_path);
use File::Glob ':glob';
use Getopt::Long;

# === Config ===
my $input_dir   = "input";
my $variant_dir = "variants";
my $output_dir  = "output";
my $input_pdb   = "$input_dir/input.pdb";
my $start_res   = 87;
my $end_res     = 140;
my $resume_chain;

# === Parse options ===
GetOptions("resume-chain=s" => \$resume_chain);

my $fixed_chain = "A";
my @relax_order = qw(B C D E);

# Track if we're past the resume point
my $resuming = !$resume_chain;

# Start with fixed chain
my @current_chains = ($fixed_chain);

for my $chain (@relax_order) {
    push @current_chains, $chain;

    my @prev_chains = @current_chains[0 .. $#current_chains - 1];
    my $new_chain   = $chain;

    my $variant_name     = join("", @current_chains);
    my $prev_variant     = join("", @prev_chains);
    my $variant_file     = "$variant_dir/${variant_name}_variant.pdb";
    my $prev_output_dir  = "$output_dir/$prev_variant";
    my $curr_output_dir  = "$output_dir/$variant_name";

    if (!$resuming) {
        if ($chain eq $resume_chain) {
            $resuming = 1;
        } else {
            print "⏩ Skipping $variant_name (before resume point: $resume_chain)\n";
            next;
        }
    }

    print "🔧 Preparing variant: $variant_name\n";

    make_path($variant_dir);
    make_path($curr_output_dir);

    if (@prev_chains == 1) {
        # First phase — cut from original input
        my $fixed_range = join(" ", @relax_order[1 .. $#relax_order]);
        system("perl", "prepare_phase.pl", $input_pdb, $variant_file, join("", @current_chains),
               $fixed_range, $start_res, $end_res) == 0
            or die "❌ prepare_phase.pl failed\n";
    } else {
        # Find relaxed structure for previous chain
        my $last_chain = $prev_chains[-1];
        my $last_output_dir = "$output_dir/$prev_variant";

        my @candidates = bsd_glob("$last_output_dir/*chain${last_chain}_relaxed_try*_0001.pdb");
        die "❌ No relaxed structure found for chain $last_chain in $last_output_dir\n" unless @candidates;
        my $prev_relaxed_pdb = $candidates[0];

        system("perl", "reassemble_phase.pl", $input_pdb, $prev_relaxed_pdb, $new_chain,
               $start_res, $end_res, $variant_file) == 0
            or die "❌ reassemble_phase.pl failed\n";
    }

    print "🧘 Running relax on chain $chain\n";
    system("./relax_run.sh", $variant_file, $curr_output_dir, $start_res, $end_res, @current_chains) == 0
        or die "❌ Relaxation failed for $variant_name\n";
}

print "✅ All phases complete!\n";
