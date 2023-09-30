package Stats::WilsonInterval;
use strict;
use warnings;
use Statistics::Zed;

# Originally from Newcombe. 1998. Two-sided confidence intervals for the single proportion:
# Comparison of seven methods adapted from VassarStats Javascript page
#
# k = successes (int)
# n = trials (int, >=k)
# y = confidence (0-1)
#
# returns (lower bound, upper bound, lower bound with CC, upper bound with CC)
# CC = continuity correction

sub getWilsonInterval {
	my ($k,$n,$y) = @_;

	my $l95a=0; # lower bound
	my $u95a=0; # upper bound
	my $l95b=0; # lower bound with CC
	my $u95b=0; # upper bound with CC
	my $num=0;
	my $denom=0;

	#my $z = 1.95996; ## .95
	#my $z = 1.281551; ## .90
	#my $z = 0.467699; ## .68
	my $zed = Statistics::Zed->new();
	my $z = $zed->p2z(1 - $y);
	my $zsq = $z*$z;

	my $p = int(($k/$n)*10000)/10000;
	my $q = 1-$p;

	#print STDERR "$z $p $q\n";


	#<!--begin l95a-->
	if($p==0) {
		$l95a = 0;
	} else {
		$num = (2*$n*$p)+$zsq-($z*sqrt($zsq+(4*$n*$p*$q)));
		$denom = 2*($n+$zsq);
		$l95a = $num/$denom;
		$l95a = int($l95a*10000)/10000;
	}
	#<!--end l95a-->

	#<!--begin u95a-->
	if ($p==1) {
		$u95a = 1;
	} else {
		$num = (2*$n*$p)+$zsq+($z*sqrt($zsq+(4*$n*$p*$q)));
		$denom = 2*($n+$zsq);
		$u95a = $num/$denom;
		$u95a = int($u95a*10000)/10000;
	}
	#<!--end u95a-->

	#<!--begin l95b-->
	if ($p==0) {
		$l95b = 0;
	} else {
		$num = (2*$n*$p)+$zsq-1-($z*sqrt($zsq-2-(1/$n)+4*$p*(($n*$q)+1)));
		$denom = 2*($n+$zsq);
		$l95b = $num/$denom;
		$l95b = int($l95b*10000)/10000;
	}
	#<!--end l95b-->

	#<!--begin u95b-->
	if ($p==1) {
		$u95b = 1;
	} else {
		$num = (2*$n*$p)+$zsq+1+($z*sqrt($zsq+2-(1/$n)+4*$p*(($n*$q)-1)));
		$denom = 2*($n+$zsq);
		$u95b = $num/$denom;
		$u95b = int($u95b*10000)/10000;
	}
	#<!--end u95b-->

	#print STDERR "$l95a $u95a $l95b $u95b\n";
	return($l95a,$u95a,$l95b,$u95b);
}

1;
