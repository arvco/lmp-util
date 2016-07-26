#!/usr/bin/perl


# Calculates the msd of snapshots at given time steps from lammps dump file
# and outputs timestep vs msd 


use strict;
use warnings;


my @filein = ();
my @fileout = ( "pimd_posavg.out" );

my ($setin, $setout);


foreach my $i ( 0 .. $#ARGV ) {
    # Recognize which settings are to be made
	if ( $ARGV[$i] =~ /-in/ ) {
		($setin, $setout) = (1, 0
		);
		next;
	}
	if ( $ARGV[$i] =~ /-out/ ) {
		($setin, $setout) = (0, 1);
		@fileout = ();
		next;
	}
	if ( $setin == 1 ) {
		push @filein, $ARGV[$i];
		next;
	}
	if ( $setout == 1 ) {
		push @fileout, $ARGV[$i];
		next;
	}
	
	
}

my @avg = ();
my @boxdim = ();
my @numatom = ();
my @tstepsav = ();
# compute msd for all other snapshots
foreach my $file ( @filein ) {
	
	open my $in, '<', $file;
	
	while ( my $line = <$in> ) {
		my ($tstep, $natom, $snap, $dim) = readTimestepData($in,$line);
		
		my @snap = @$snap;
		my @dim = @$dim;
		
		$boxdim[$tstep] = [ @dim ];
		$numatom[$tstep] = $natom;
		push @tstepsav, $tstep;

		# Add files together
		foreach my $i ( 0 .. $#snap ) {
			foreach my $j ( 0 .. $#{$snap[$i]} ) {
				$avg[$tstep][$i][$j] += $snap[$i][$j];
			}
		}
		print "$tstep @{$avg[$tstep][1]}\n";
	}
	close ($in);
}

# Output
open my $out, '>', $fileout[0];

my $N = $#filein + 1;
foreach my $tstep ( @tstepsav ) {
	print "$tstep\n";
	print $out "ITEM: TIMESTEP\n";
	print $out "$tstep\n";
	print $out "ITEM: NUMBER OF ATOMS\n";
	print $out "$numatom[$tstep]\n";
	print $out "ITEM: BOX BOUNDS pp pp pp\n";
	print $out "0 $boxdim[$tstep][0]\n";
	print $out "0 $boxdim[$tstep][1]\n";
	print $out "0 $boxdim[$tstep][2]\n";
	print $out "ITEM: ATOMS id type xs ys zs\n";
	foreach my $i ( 0 ..  $#{$avg[$tstep]} ) {
		printf $out "%i %i %f %f %f\n", $avg[$tstep][$i][0]/$N, $avg[$tstep][$i][1]/$N,$avg[$tstep][$i][2]/$N,$avg[$tstep][$i][3]/$N,$avg[$tstep][$i][4]/$N;
	}
}
close($out);



# subroutine that reads data for 1 time step from a LAMMPS dump file formatted as:
# ------BEGIN FILE------
# ITEM: TIMESTEP
# 0
# ITEM: NUMBER OF ATOMS
# 34680
# 0.0  62.426 xlo xhi
# 0.0  61.271 ylo yhi
# 0.0 300.165 zlo zhi
# ITEM: ATOMS id type xs ys zs
# 1 1 0.0000000 0.0000000 0.0000000
# 2 1 0.0333333 0.0000000 0.0098039
# ------END FILE ------
# 
# takes 3 arguments. Current input line $line, input file identifier $in and number
# of lines $nhead composing the header

sub readTimestepData {
	my $in = $_[0];
	my $line = $_[1];
	
	chomp($line);
	my @head = ($line);
	
	foreach (1 .. 8) {
		$line = <$in>;
		chomp($line);
		push @head, $line;
	}
	
	# 2nd line of the header contains time step info;
	# 3rd line the number of atoms
	my $tstep = $head[1];
	my $natom = $head[3];
	# arrays for unit cell dimensions, atom data and temporary auxiliary purposes
	my @dim	= ();
	my @snap = ();
	my @tmp = ();
	my %data;
	
	foreach my $i ( 5 .. 7 ) {
		@tmp = split ' ', $head[$i];
		push @dim, ( $tmp[1] - $tmp[0] );
	}
	
	foreach ( 0 .. $natom - 1 ) {
		$line = <$in>;
		chomp($line);
		@tmp = split ' ', $line;
		
		$data{$tmp[0]} = $line;
	}
	
	foreach my $id (1 .. $natom) {
		@tmp = split ' ', $data{$id};
		push @snap, [ @tmp ];
	}
	
	# \@ creates a reference to the array -> see:
	# http://perlmeme.org/faqs/perl_thinking/returning.html
	return($tstep, $natom, \@snap, \@dim);
}


