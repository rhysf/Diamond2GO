package Stats::RightFisher;
use strict;
use warnings;
use Text::NSP::Measures::2D::Fisher::right;

# conducts right tailed fisher's exact test

sub getRightFisher {
    my ($n11,$n1p,$np1,$npp) = @_;
    my $fisher_p = calculateStatistic( n11=>$n11,
                                       n1p=>$n1p,
                                       np1=>$np1,
                                       npp=>$npp);
    if ((my $errorCode = getErrorCode())) {
        print STDERR $errorCode." - ".getErrorMessage()."\n";
    }
    return $fisher_p;
}

1;
