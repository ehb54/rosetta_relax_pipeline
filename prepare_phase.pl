#!/usr/bin/env perl
use strict;
use warnings;

# Usage: prepare_phase.pl input.pdb output.pdb "A B" "C D E" 87 140

die "Usage: $0 input.pdb output.pdb \"A B\" \"C D E\" start end\n" unless @ARGV == 6;

my ($input, $output, $keep_chains, $cut_chains, $start, $end) = @ARGV;
my %keep = map { $_ => 1 } split ' ', $keep_chains;
my %cut  = map { $_ => 1 } split ' ', $cut_chains;

open my $in,  "<", $input  or die "Cannot read $input: $!";
open my $out, ">", $output or die "Cannot write $output: $!";

while (<$in>) {
    if (/^(ATOM|HETATM)/) {
        my $chain = substr($_, 21, 1);
        my $resid = substr($_, 22, 4); $resid =~ s/^\s+//;
        if ($keep{$chain}) {
            print $out $_;
        } elsif ($cut{$chain} && ($resid < $start || $resid > $end)) {
            print $out $_;
        }
    } else {
        print $out $_;
    }
}

close $in;
close $out;

print "✅ Created trimmed PDB: $output\n";
