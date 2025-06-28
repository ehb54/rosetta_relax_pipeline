#!/usr/bin/env perl
use strict;
use warnings;

# Usage: reassemble_phase.pl input.pdb relaxed.pdb "C" 87 140 output.pdb

die "Usage: $0 input.pdb relaxed.pdb \"C\" start end output.pdb\n" unless @ARGV == 6;

my ($input, $relaxed, $add_chains, $start, $end, $output) = @ARGV;
my %add = map { $_ => 1 } split ' ', $add_chains;

open my $in_relaxed, "<", $relaxed or die "Cannot read $relaxed: $!";
open my $out,       ">", $output  or die "Cannot write $output: $!";

# Copy relaxed base to output
print $out $_ while <$in_relaxed>;
close $in_relaxed;

open my $in_orig, "<", $input or die "Cannot read $input: $!";

while (<$in_orig>) {
    next unless /^ATOM|^HETATM/;
    my $chain = substr($_, 21, 1);
    my $resid = substr($_, 22, 4); $resid =~ s/^\s+//;
    if ($add{$chain} && $resid >= $start && $resid <= $end) {
        print $out $_;
    }
}

close $in_orig;
close $out;

print "✅ Reassembled PDB with chains @{$add_chains}: $output\n";
