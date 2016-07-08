#!/usr/bin/perl


# Calculates the msd of snapshots at given time steps from lammps dump file
# and outputs timestep vs msd 


use strict;
use warnings;


my $filein = $ARGV[0];
my $fileout = $ARGV[1];

# turn the center of mass (com) translation correction on (1) or off (0)
my $trlcorr = $ARGV[2];


open my $in, '<', $filein;
open my $out,'>', $fileout;


# create initial structure array; if given use first snapshot of the
# input file if not extra file ($ARGV[2]) is specified 

my $line = <$in>;
my ($tstep0, $natom0, $snap0, $dim0) = readTimestepData($in,$line);

my @snap0 = @$snap0;
my @dim0 = @$dim0;

if ( $#ARGV >= 3 ) {
	my $structin = $ARGV[3];
	open my $inst, '<', $structin;
	
	my $line = <$inst>;
	($tstep0, $natom0, $snap0, $dim0) = readTimestepData($inst,$line);
	
	@snap0 = @$snap0;
	@dim0 = @$dim0;
}

# determine center of mass of the crystal structure
my @com0 = determineCOM($snap0,$natom0);


# compute msd for all other snapshots
while ( my $line = <$in> ) {
	my ($tstep, $natom, $snap, $dim) = readTimestepData($in,$line);
	
	my @snap = @$snap;
	my @dim = @$dim;
	
	my @msd = ();
	my $msdsnap = 0;
	my @comcorr = ();
	
	my @com = determineCOM($snap,$natom);
	
	if ($trlcorr == 1) {
		foreach my $d ( 0 .. $#com ) {
			push @comcorr, ( $com0[$d] - $com[$d] );
		}
	}
	else {
		foreach my $d ( 0 .. $#com ) {
			push @comcorr, 0;
		}
	}
	
	foreach my $i ( 0 .. $#snap ) {
		my $msdtot = 0;
		foreach my $j ( 2 .. $#{$snap[$i]} ) {
			my $msdnow = abs( ($snap[$i][$j] + $comcorr[$j-2] ) * $dim[$j-2] - $snap0[$i][$j]*$dim0[$j-2] );
			
			# correct for atoms moving reentering simulation box on the opposite site
			# due to periodic boundary conditions

			if ( $msdnow > (0.5*$dim[$j-2]) ) {
#				print "$i $msdnow\n";
				$msdnow -= $dim[$j-2];
			}
			$msdnow *= $msdnow;
			$msdtot += $msdnow;
			push @{$msd[$i]}, ($msdnow);
		}
		push @{$msd[$i]}, $msdtot;
		$msdsnap += $msdtot;
	}
	
	$msdsnap /= $natom;
	
#	print "@dim0 \n";
#	print "@dim \n";
#	print "@{$snap[1]}\n";
#	print "$#snap\n";
#	print "@comcorr \n";
#	print "$msdsnap $natom\n";
#	print "@{$msd[1]}\n";
#	print "@com \n@com0 \n";
	
	printf $out "%i %.10f\n", $tstep, $msdsnap;
	
#	die;
}


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



# determine center of mass of the initial snapshot

sub determineCOM {
	# first argument contains reference name to array
	my $snap = $_[0];
	my $natom = $_[1];
	
	my @snap = @$snap;

	my $comx;
	my $comy;
	my $comz;

	foreach my $id ( 0 .. $#snap) {
		$comx += $snap[$id][2];
		$comy += $snap[$id][3];
		$comz += $snap[$id][4];
	}
	$comx /= $natom;
	$comy /= $natom;
	$comz /= $natom;
	my @com = ($comx, $comy, $comz);

	return (@com);
}


