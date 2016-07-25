#!/usr/bin/perl


# Calculates the average of columns of data files based on a specified
# range of values for the first column. The data files need to have a 
# similar structure, i.e. the columns must contain the numerical data 
# for the same thing

use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

# Initialize arrays and set defaults
my @filein = ();
my @temp = ();
my @fileout = ( "avg_tool.out" );
my @dataout = ( "avg_tool.dat" );
my @range = (0, 0);
my ($setin, $setout, $setrange, $setdata);


# Loop over arguments and place them into arrays for further use
foreach my $i ( 0 .. $#ARGV ) {
	
	# Recognize which settings are to be made
	if ( $ARGV[$i] =~ /-in/ ) {
		($setin, $setout, $setrange, $setdata) = (1, 0, 0, 0);
		next;
	}
	if ( $ARGV[$i] =~ /-out/ ) {
		($setin, $setout, $setrange, $setdata) = (0, 1, 0, 0);
		@fileout = ();
		next;
	}
	if ( $ARGV[$i] =~ /-range/ ) {
		($setin, $setout, $setrange, $setdata) = (0, 0, 1, 0);
		@range = ();
		next;
	}
	if ( $ARGV[$i] =~ /-dat/ ) {
		($setin, $setout, $setrange, $setdata) = (0, 0, 0, 1);
		@dataout = ();
		next;
	}
	
	# set all the calculation parameters
	if ( $setin == 1 ) {
		push @filein, $ARGV[$i];
		my $tmp = `echo $ARGV[$i] | cut -d "/" -f 2 | cut -d " " -f 2`;
		chomp($tmp);
		push @temp, $tmp; 
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
	if ( $setdata == 1 ) {
		push @dataout, $ARGV[$i];
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
	print "$range[0] @{$range[1]}\n";
}
else {
	my $setrange = $range[1];
	$range[1] = ();
	foreach my $n ( 0 .. $#filein ) {
		if ( $setrange <= $#{$data[$n]} ) {
			$range[1][$n] = $setrange;
		}
		else {
			$range[1][$n] = $#{$data[$n]};
		}
	}
	print "RANGE: START ENDFILE1 ENDFILE 2 ..\n";
	print "$range[0] @{$range[1]}\n\n";
}

print "TEMPERATURES: FILE1 FILE2 .. \n";
print "$_\n" foreach @temp;

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
print "MEANS OF COLUMNS OF INPUT FILES\n";
print "@{$_}\n" foreach @avg;


# Calculate standard deviation and mean error
my @stddev = ();
my @stderror = ();
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

	$stderror[$n][0] = $data[$n][$range[1][$n]][0];
	$stderror[$n][$_] = $stddev[$n][$_] / sqrt($N) for 1 .. $#{$stddev[$n]};
}
print "STDDEV OF AVERAGES\n";
print "@{$_}\n" foreach @stddev;
print "STD ERROR OF THE MEAN\n";
print "@{$_}\n" foreach @stderror;


# Print output files
if ( $#fileout == 0 ) {
	open my $out,'>', $fileout[0];
	
	foreach my $n ( 0 .. $#filein ) {
		print $out "FILE\n";
		print $out "$filein[$n]\n";
		print $out "AVERAGE RANGE\n";
		printf $out "%i %i\n", $range[0], $range[1][$n];
		print $out "COL AVG STDDEV STDERROR\n";
		printf $out "%i %.10f %.10f %.10f\n", ($_, $avg[$n][$_], $stddev[$n][$_], $stderror[$n][$_] ) for 1 ..  $#{$avg[$n]};
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


open my $out,'>', $dataout[0];

foreach my $n ( 0 .. $#filein ) {
	printf $out "%s %.10f %.10f %.10f\n", ($temp[$n], $avg[$n][$_], $stddev[$n][$_], $stderror[$n][$_] ) for 1 ..  $#{$avg[$n]};
}
close($out);
																	#




