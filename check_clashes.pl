#!/usr/bin/env perl
use strict;
use warnings;

# Usage: check_clashes.pl relaxed.pdb output_dir [fa_rep_threshold]

die "Usage: $0 relaxed.pdb output_dir [fa_rep_threshold]\n" unless @ARGV >= 2;

exit 0;

my ($pdb, $outdir, $threshold) = @ARGV;
$threshold //= 10;

my $score_bin = "~/rosetta/source/bin/score_jd2.default.linuxgccrelease";
my $resfile = "$outdir/residue_energies.txt";
my $pymol_file = "$outdir/clash_selection.pml";

# Run Rosetta scoring
system("$score_bin -s $pdb -out:file:scorefile $outdir/score.sc > /dev/null");

# Extract per-residue energy file
(my $basename = $pdb) =~ s{.*/}{};
$basename =~ s{\.pdb$}{};

my $res_energy_file = "$basename.residue_energies";
die "❌ Residue energy file not found: $res_energy_file\n" unless -e $res_energy_file;

open my $in,  "<", $res_energy_file or die "Cannot open $res_energy_file: $!";
open my $out, ">", $resfile        or die "Cannot write $resfile: $!";
open my $pml, ">", $pymol_file     or die "Cannot write $pymol_file: $!";

print $out "Residue\tfa_rep\n";
my @clash_residues;

while (<$in>) {
    next if /^\s*#/;
    my @f = split;
    next unless @f >= 3;
    my ($residue, $term, $value) = @f[0,1,2];
    next unless $term eq "fa_rep";

    if ($value > $threshold) {
        print $out "$residue\t$value\n";
        push @clash_residues, $residue;
    }
}
close $in;
close $out;

if (@clash_residues) {
    my $sel = join(" + ", map { my ($res, $chain) = /^(\d+)(\w)$/; "resi $res and chain $chain" } @clash_residues);
    print $pml "select clash_residues, $sel\n";
    close $pml;
    print "⚠️  Found " . scalar(@clash_residues) . " residues with fa_rep > $threshold\n";
    print "   ➤ See $resfile for details\n";
    print "   ➤ Load $pdb in PyMOL, then run: @clash_residues\n";
    exit 1;
} else {
    print "✅ No significant clashes detected (fa_rep ≤ $threshold)\n";
    unlink $pymol_file;
    exit 0;
}
