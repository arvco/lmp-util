#!/usr/bin/perl

# Reorder Lammps msd output. The input file is expected to the following shape:
# three rows of descriptions;
# 1 line containing the time step and a number which is equal to the number of
# rows containing values belonging to the same time step. Example:
# -------
# # Time-averaged data for fix msd2
# # TimeStep Number-of-rows
# # Row c_comp2
# 0 4
# 1 1.11526e-25
# 2 4.65289e-25
# 3 6.15345e-23
# 4 6.21113e-23
# -------
#
# The user can specify the values that should be reordered. The values are 
# thereby converted to %1.10f precision. Example:
#
# $ msd_postp.pl $in $out 1 2 3 4
# 
# produces
# -------
# # Time-averaged data for fix msd2
# # TimeStep Number-of-rows
# # Row c_comp2
# 0	0.0000000000	0.0000000000	0.0000000000	0.0000000000
# -------
# 

use strict;
use warnings;

my $filein = $ARGV[0];
my $fileout = $ARGV[1];

# get values to be reordered
my @ctl = ();
foreach my $i ( 2 .. $#ARGV ) {
	push @ctl, $ARGV[$i];
}

open my $in, '<', $filein;
open my $out,'>', $fileout; 

my @head = ();
our $line;

foreach my $i (1 .. 3) {
	$line = <$in>;
	push @head, $line;
	printf $out "%s", $head[$#head];
}

while ( my $line = <$in> ) {
	
	my @tmp = ();
	my @msd = ();

	@tmp = split ' ', $line;
	
	my $tstep = $tmp[0];
	my $nrow = $tmp[1];
	
	for ( my $i=1; $i<=$nrow; $i++ ) {
		$line = <$in>;
		
		@tmp = split ' ', $line;

		push @msd, $tmp[1];
		
	}
	
	printf $out "%7i", $tstep;
	
	foreach my $j ( 0 .. $#ctl ) {
		printf $out "\t%1.10f", $msd[$ctl[$j]-1];
	}
	printf $out "\n";
}
