#!/usr/bin/perl






use strict;
use warnings;


my $filein = $ARGV[0];
my $fileout = $ARGV[1];


open my $in, '<', $filein;
open my $out,'>', $fileout;


if ( $#ARGV >= 2 ) {
	
	my $structin = $ARGV[2];
	
	open my $inst, '<', $structin;
	
	my @head = ();

	foreach my $i (1 .. 9) {
		my $line = <$in>;
		chomp($line);
		push @head, chomp($line);
	}
}


while ( my $line = <$in> ) {
	
	(my $tstep, my $natom, my @data) = readTimestepData($in,$line);
	
#	print "$tstep\n";
#	print "$natom\n";
#	print "@data\n";
#	print "$data[2][2]\n";
	
	
	
	
	
	
	die;	
}


sub readTimestepData {
	my $in = $_[0];
	my $line = $_[1];
	
	my @head = ($line);

	foreach (1 .. 8) {
		$line = <$in>;
		chomp($line);
		push @head, $line;
	}
	
	my $tstep = $head[1];
	my $natom = $head[3];
	my @data = ();
	
	foreach ( 0 .. $natom - 1 ) {
		$line = <$in>;
		push @data, [ split ' ', $line ];
	}
	return($tstep, $natom, @data);
}



