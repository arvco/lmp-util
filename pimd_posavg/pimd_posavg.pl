#!/usr/bin/perl


# Calculates the msd of snapshots at given time steps from lammps dump file
# and outputs timestep vs msd 


use strict;
use warnings;

# Number of lines containing environment information per time step in lammps output
my $nlmphead = 8;


my @filein = ();
my @fileout = ( "pimd_posavg.out" );

# COM correction turned off by default
my $trlcorr = 0;


my ($setin, $setout);

# Make settings
foreach my $i ( 0 .. $#ARGV ) {
    # Recognize which settings are to be made
	if ( $ARGV[$i] =~ /-in/ ) {
		($setin, $setout) = (1, 0);
		next;
	}
	if ( $ARGV[$i] =~ /-out/ ) {
		($setin, $setout) = (0, 1);
		@fileout = ();
		next;
	}
	if ( $ARGV[$i] =~ /-com_on/ ) {
		($setin, $setout) = (0, 0);
		$trlcorr = 1;
		print "COM translation correction turned on\n";
		next;
	}

	# Make settings
	if ( $setin == 1 ) {
		push @filein, $ARGV[$i];
		next;
	}
	if ( $setout == 1 ) {
		push @fileout, $ARGV[$i];
		next;
	}
}

print "INPUT: @filein\n";
print "OUTPUT: @fileout\n";


# create initial structure array; if given use first snapshot of the
# input file

#my $line = <$in>;
#my ($tstep0, $natom0, $snap0, $dim0, $ixyz0) = readTimestepData($in,$line,$nlmphead);

#my @snap0 = @$snap0;
#my @dim0 = @$dim0;
#my @ixyz0 = @$ixyz0;

# determine center of mass of the crystal structure
#my @com0 = determineCOM($snap0,$natom0);
#print "@com0\n";


my @avg = ();
my @boxdim = ();
my @numatom = ();
my @tstepsav = ();

my ($tstep0, $natom0, $coord0, $snap0, $dim0, $ixyz0);
my @coord0 = ();
my @snap0 = ();
my @dim0 = ();
my @ixyz0 = ();

# average all beads
foreach my $file ( @filein ) {
	
	open my $in, '<', $file;
	
	my $line = <$in>;
	($tstep0, $natom0, $coord0, $snap0, $dim0, $ixyz0) = readTimestepData($in,$line,$nlmphead);
	
	@coord0 = @$coord0;
	@snap0 = @$snap0;
	@dim0 = @$dim0;
	@ixyz0 = @$ixyz0;
	
	my @com0 = determineCOM($snap0,$natom0,$ixyz0);
	
	
	if ( $file =~ /$filein[0]/ ) {
		push @tstepsav, $tstep0;
		$boxdim[$tstep0] = [ @dim0 ];
		$numatom[$tstep0] = $natom0;
	}
	
	# Add files together
	foreach my $i ( 0 .. $#snap0 ) {
		foreach my $j ( 0 .. $#ixyz0 ) {
			$avg[$tstep0][$i][$ixyz0[$j]] += $snap0[$i][$ixyz0[$j]];
		}
	}
	
	
	while ( $line = <$in> ) {
		my ($tstep, $natom, $coord, $snap, $dim, $ixyz) = readTimestepData($in,$line,$nlmphead);
		
		my @coord = @$coord;
		my @snap = @$snap;
		my @dim = @$dim;
		my @ixyz = @$ixyz;
		my @comcorr = ();
		
		
		$boxdim[$tstep] = [ @dim ];
		$numatom[$tstep] = $natom;

#		print "@{$snap[0]}\n";
#		print "@{$snap[1]}\n";
#		print "@ixyz0 @ixyz\n";
		
		# correct for atoms reentering simulation box on the opposite site
		# due to periodic boundary conditions
		foreach my $i ( 0 .. $#snap ) {
			foreach my $j ( $ixyz[0] .. $ixyz[$#ixyz] ) {
				my $disp = $snap[$i][$j] - $snap0[$i][$j];
				if ($disp > 0.5) {
					$snap[$i][$j] -= 1;
				}
				if ($disp < (- 0.5) ) {
					$snap[$i][$j] += 1;
				}
			}
		}
		
		# Calculate necessary center of mass correction
		my @com = determineCOM($snap,$natom,$ixyz);
		if ($trlcorr == 1) {
			foreach my $d ( 0 .. $#com ) {
				push @comcorr, ( $com[$d] - $com0[$d] );
			}
		}
		else {
			foreach my $d ( 0 .. $#com ) {
				push @comcorr, 0;
			}
		}
		
		if ( $file =~ /$filein[0]/ ) {
			push @tstepsav, $tstep;
		}
		
		# Add files together
		foreach my $i ( 0 .. $#snap ) {
			foreach my $j ( 0 .. $#ixyz ) {
				$avg[$tstep][$i][$ixyz0[$j]] += $snap[$i][$ixyz[$j]] - $comcorr[$j];
			}
		}
	}
	close ($in);
}


# Output
open my $out, '>', $fileout[0];

my $N = $#filein + 1;

#print "@tstepsav\n";


foreach my $tstep ( @tstepsav ) {
	print $out "ITEM: TIMESTEP\n";
	print $out "$tstep\n";
	print $out "ITEM: NUMBER OF ATOMS\n";
	print $out "$numatom[$tstep]\n";
	print $out "ITEM: BOX BOUNDS pp pp pp\n";
	print $out "0 $boxdim[$tstep][0]\n";
	print $out "0 $boxdim[$tstep][1]\n";
	print $out "0 $boxdim[$tstep][2]\n";
	print $out "ITEM: ATOMS id type xs ys zs\n";
#	print "$#{$avg[$tstep]}\n";
	foreach my $i ( 0 ..  $#{$avg[$tstep]} ) {
#		print "$N $ixyz0[0] $ixyz0[1] $ixyz0[2]\n";
#		print "$avg[$tstep][$i][$_]\n" for @$ixyz0;
		printf $out "%i %i %1.10f %1.10f %1.10f\n", $snap0[$i][0], $snap0[$i][1], $avg[$tstep][$i][$ixyz0[0]]/$N, $avg[$tstep][$i][$ixyz0[1]]/$N, $avg[$tstep][$i][$ixyz0[2]]/$N;
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
	my $nlmphead = $_[2];
	
	chomp($line);
	my @head = ($line);
	
	foreach (1 .. $nlmphead) {
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
	my %data;
	
	my @ixyz = ();
	my $id;
	my @coord;
	
	my @tmp = split ' ', $head[$nlmphead];
	
	foreach my $i ( 0 .. $#tmp ) {
		if ( $tmp[$i] =~ /id/ ) {
			$id = $i;
		}
	}
	
	foreach my $i ( 0 .. $#tmp ) {
		if ( $tmp[$i] =~ /xs/ ) {
			$ixyz[0] = $i - $id;
			$coord[0] = "F";
		}
		if ( $tmp[$i] =~ /^x$/ ) {
			$ixyz[0] = $i - $id;
			$coord[0] = "R";
		}
		if ( $tmp[$i] =~ /ys/ ) {
			$ixyz[1] = $i - $id;
			$coord[1] = "F";
		}
		if ( $tmp[$i] =~ /^y$/ ) {
			$ixyz[1] = $i - $id;
			$coord[1] = "R";
		}
		if ( $tmp[$i] =~ /zs/ ) {
			$ixyz[2] = $i - $id;
			$coord[2] = "F";
		}
		if ( $tmp[$i] =~ /^z$/ ) {
			$ixyz[2] = $i - $id;
			$coord[2] = "R";
		}
	}
	
	foreach my $i ( ($nlmphead-3) .. ($nlmphead-1) ) {
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
	return($tstep, $natom, \@coord, \@snap, \@dim, \@ixyz);
}


# determine center of mass of a given snapshot

sub determineCOM {
	# first argument contains reference name to array
	my $snap = $_[0];
	my $natom = $_[1];
	my $ixyz = $_[2];
	
	my @snap = @$snap;
	my @ixyz = @$ixyz;
	
	my $comx;
	my $comy;
	my $comz;
	
	foreach my $id ( 0 .. $#snap) {
		$comx += $snap[$id][$ixyz[0]];
		$comy += $snap[$id][$ixyz[1]];
		$comz += $snap[$id][$ixyz[2]];
	}
	$comx /= $natom;
	$comy /= $natom;
	$comz /= $natom;
	my @com = ($comx, $comy, $comz);
	
	return (@com);
}


