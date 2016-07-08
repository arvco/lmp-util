#!/usr/bin/perl


# Calculates the average of columns of data files based on a specified
# range of values for the first column. The data files need to have a 
# similar structure, i.e. the columns must contain the numerical data 
# for the same thing

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);


my @filein = ();
my @fileout = ( "avg_tool.out" );
my @range = (0, 0);
my ($setin, $setout, $setrange);


# Loop over arguments and place them into arrays for further use
foreach my $i ( 0 .. $#ARGV ) {
	
	# Recognize which settings are to be made
	if ( $ARGV[$i] =~ /-in/ ) {
		($setin, $setout, $setrange) = (1, 0, 0);
		next;
	}
	if ( $ARGV[$i] =~ /-out/ ) {
		($setin, $setout, $setrange) = (0, 1, 0);
		next;
	}
	if ( $ARGV[$i] =~ /-range/ ) {
		($setin, $setout, $setrange) = (0, 0, 1);
		next;
	}
	
	# set all the calculation parameters
	if ( $setin == 1 ) {
		push @filein, $ARGV[$i];
		next;
	}
	if ( $setout == 1 ) {
		push @fileout, $ARGV[$i];
		next;
	}
	if ( $setrange == 1 ) {
		push @range, $ARGV[$i];
		next;
	}
}
print "\nINPUT FILES: @filein \n\n";
print "OUTPUT FILES: @fileout \n\n";
print "RANGE FOR AVG: @range \n\n";


# Read all input data & Calculate average
my @data;
my @text;
foreach my $n ( 0 .. $#filein ) {
	open my $in, '<', $filein[$n];
	my @tmp;
	while ( my $line = <$in> ) {
		my $isnum = 0;
		
		chomp($line);
		@tmp = split ' ', $line;
		
		foreach my $i ( 0 .. $#tmp ) {
			if ( looks_like_number($tmp[$i]) ) {
				$isnum += 1;
			}
		}
		if ( $#tmp == $isnum - 1 ) {
			push @{$data[$n]}, [ @tmp ];
		}
		else {
			push @{$text[$n]}, [ @tmp ];
		}
	}
}


# Set beginning of averaging to the first line and the end of range to the last
# line of input by default if no range was specified
if ( $range[0] != 0 ) {
	$range[0] -= 1;
}
if ( $range[1] == 0 ) {
	$range[1] = ();
	foreach my $n ( 0 .. $#filein ) {
		$range[1][$n] = $#{$data[$n]};
	}
}
print "$range[0] @{$range[1]}\n";


# Calculate averages
my @avg = ();
foreach my $n ( 0 .. $#filein ) {
	@{$avg[$n]} = ( (0) x @{$data[$n][0]} );
	
	foreach my $line ( $range[0] .. $range[1][$n] ) {
		foreach my $col ( 1 .. $#{$data[$n][$line]} ) {
			$avg[$n][$col] += $data[$n][$line][$col];
		}
	}
	my $N = ($range[1][$n] - $range[0] + 1);

	$avg[$n][0] = $data[$n][$range[1][$n]][0];
	$avg[$n][$_] /= $N for 1 .. $#{$avg[$n]};
}
print "AVERAGES OF INPUT FILES\n";
print "@{$_}\n" foreach @avg;


# Calculate standard deviation and mean error
my @stddev = ();
my @merror = ();
foreach my $n ( 0 .. $#filein ) {
	@{$stddev[$n]} = ( (0) x @{$avg[$n]} );
	
	foreach my $line ( $range[0] .. $range[1][$n] ) {
		foreach my $col ( 1 .. $#{$data[$n][$line]} ) {
			$stddev[$n][$col] += ( $data[$n][$line][$col] - $avg[$n][$col] )**2;
		}
	}
	my $N = ($range[1][$n] - $range[0] + 1);
	
	$stddev[$n][0] = $data[$n][$range[1][$n]][0];
	$stddev[$n][$_] /= $N for 1 .. $#{$stddev[$n]};
	$stddev[$n][$_] = sqrt($stddev[$n][$_]) for 1 .. $#{$stddev[$n]};

	$merror[$n][0] = $data[$n][$range[1][$n]][0];
	$merror[$n][$_] = $stddev[$n][$_] / sqrt($N) for 1 .. $#{$stddev[$n]};
}
print "STDDEV OF AVERAGES\n";
print "@{$_}\n" foreach @stddev;
print "MEAN ERROR OF AVERAGES\n";
print "@{$_}\n" foreach @merror;


# Print output files
if ( $#fileout == 0 ) {
	open my $out,'>', $fileout[0];
	
	foreach my $n ( 0 .. $#filein ) {
		print $out "FILE\n";
		print $out "$filein[$n]\n";
		print $out "AVERAGE RANGE\n";
		printf $out "%i %i\n", $range[0], $range[1][$n];
		print $out "COL AVG STDDEV MERROR\n";
		printf $out "%i %.10f %.10f %.10f\n", ($_, $avg[$n][$_], $stddev[$n][$_], $merror[$n][$_] ) for 1 ..  $#{$avg[$n]};
		print $out "\n";
	}
#	printf $out "%i %.10f\n", $tstep, $msdsnap;
	close($out);
}
else {
	foreach my $o ( 0 .. $#fileout ) {
		open my $out,'>', $fileout[$o];
#		printf $out "%i %.10f\n", $tstep, $msdsnap;
		
		close($out);
	}
}


