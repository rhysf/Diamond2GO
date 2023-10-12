package Statistics::Multtest;
use FindBin qw($Bin);
use lib "$Bin/../";
use List::Vectorize;
use Carp;
use strict;
use constant {EPS => 1e-10};

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(bonferroni holm hommel hochberg BH BY qvalue);
our %EXPORT_TAGS = (all => [qw(bonferroni holm hommel hochberg BH BY qvalue)]);

our $VERSION = '0.14';

1;

BEGIN {
    no strict 'refs';
    for my $adjp (qw(bonferroni holm hommel hochberg BH BY qvalue)) {
        *{$adjp} = sub {
            my $p = shift;
            my $name;
            ($name, $p) = initial($p);
            *private = *{"_$adjp"};
            my $adjp = private($p, @_);
            return get_result($adjp, $name);
        }
    }
}

sub initial {
    my $p = shift;
    
    if(! List::Vectorize::is_array_ref($p) and ! List::Vectorize::is_hash_ref($p)) {
        croak "ERROR: P-values should be stored in an array reference or a hash reference.\n";
    }
    
    my $name = [];
    if(List::Vectorize::is_hash_ref($p)) {
        $name = [ keys %{$p} ];
        $p = [ values %{$p} ];
    }
    
    if(max($p) > 1 or min($p) < 0) {
        croak "ERROR: P-values should between 0 and 1.\n";
    }
    
    return ($name, $p);
}

sub get_result {
    my ($adjp, $name) = @_;
    
    if(is_empty($name)) {
        return $adjp;
    }
    else {
        my $result;
        for (0..$#$name) {
            $result->{$name->[$_]} = $adjp->[$_];
        }
        return $result;
    }
}

# R code: pmin(1, n * p)
sub _bonferroni {
    my $p = shift;
    my $n = len($p);
    
    my $adjp = multiply($n, $p);
    
    return pmin(1, $adjp);
}

# R code: i = 1:n
#         o = order(p)
#         ro = order(o)
#         pmin(1, cummax((n - i + 1) * p[o]))[ro]
sub _holm {
    my $p = shift;
    my $n = len($p);
    
    my $i = seq(1, $n);
    my $o = order($p);
    my $ro = order($o);
    
    my $adjp = multiply(minus($n + 1, $i), subset($p, $o));
    $adjp = cumf($adjp, \&max);
    $adjp = pmin(1, $adjp);
    
    return subset($adjp, $ro);
}

# R code: i = 1:n
#         o = order(p)
#         p = p[o]
#         ro = order[o]
#         q = pa = rep.int(min(n * p/i), n)
#         for (j in (n - 1):2) {
#             ij = 1:(n - j + 1)
#             i2 = (n - j + 2):n
#             q1 <- min(j * p[i2]/(2:j))
#             q[ij] <- pmin(j * p[ij], q1)
#             q[i2] <- q[n - j + 1]
#             pa <- pmax(pa, q)
#         }
#         pmax(pa, p)[ro]
sub _hommel {
    my $p = shift;
    my $n = len($p);
    
    my $i = seq(1, $n);
    my $o = order($p);
    $p = subset($p, $o);
    my $ro = order($o);
    
    my $pa = rep(min(divide(multiply($n, $p), $i)), $n);
    my $q = copy($pa);
    
    # set the first index as 1
    unshift(@$p, 0);
    unshift(@$q, 0);
    unshift(@$pa, 0);
    
    my $ij;
    my $i2;
    my $q1;
    for my $j (@{seq($n - 1, 2)}) {
        
        $ij = seq(1, $n - $j + 1);
        $i2 = seq($n - $j + 2, $n);
        $q1 = min(divide(multiply($j, subset($p, $i2)), seq(2, $j)));
        subset_value($q, $ij, pmin(multiply($j, subset($p, $ij)), $q1));
        subset_value($q, $i2, $q->[$n - $j + 1]);
        $pa = pmax($pa, $q);
    }
    
    shift(@$p);
    shift(@$q);
    shift(@$pa);
    
    my $adjp = pmax($pa, $p);
    return subset($adjp, $ro);    
}

# R code: i = n:1
#         o <- order(p, decreasing = TRUE)
#         ro <- order(o)
#         pmin(1, cummin((n - i + 1) * p[o]))[ro]
sub _hochberg {
    
    my $p = shift;
    my $n = len($p);
    my $i = seq($n, 1);
    
    my $o = order($p, sub {$_[1] <=> $_[0]});
    my $ro = order($o);
    
    my $adjp = multiply(minus($n+1, $i), subset($p, $o));
    $adjp = cumf($adjp, \&min);
    $adjp = pmin(1, $adjp);
    return subset($adjp, $ro);
}

# R code: i <- n:1
#         o <- order(p, decreasing = TRUE)
#         ro <- order(o)
#         pmin(1, cummin(n/i * p[o]))[ro]
sub _BH {
    my $p = shift;
    my $n = len($p);
    my $i = seq($n, 1);
    
    my $o = order($p, sub {$_[1] <=> $_[0]});
    my $ro = order($o);
    
    my $adjp = multiply(divide($n, $i), subset($p, $o));
    $adjp = cumf($adjp, \&min);
    $adjp = pmin(1, $adjp);
    return subset($adjp, $ro);

}

# R code: i <- n:1
#         o <- order(p, decreasing = TRUE)
#         ro <- order(o)
#         q <- sum(1/(1L:n))
#         pmin(1, cummin(q * n/i * p[o]))[ro]
sub _BY {
    
    my $p = shift;
    my $n = len($p);
    my $i = seq($n, 1);
    
    my $o = order($p, sub {$_[1] <=> $_[0]});
    my $ro = order($o);
    
    my $q = sum(divide(1, seq(1, $n)));
    my $adjp = multiply(divide($q*$n, $i), subset($p, $o));
    $adjp = cumf($adjp, \&min);
    $adjp = pmin(1, $adjp);
    return subset($adjp, $ro);
}

sub pmin {
    my $array1 = shift;
    my $array2 = shift;
    
    return mapply($array1, $array2, sub {min(\@_)});
}

sub pmax {
    my $array1 = shift;
    my $array2 = shift;
    
    return mapply($array1, $array2, sub {max(\@_)});
}


# the default setting can not assure the success of calculation
# so this function should run under eval
# eval(q(qvalue $p));
# if ($@) change_other_settings
# @p = qw(0.76 0.30 0.40 0.43 0.27 0.79 0.66 0.36 0.12 0.16 0.52 0.04 0.67 0.44 0.40 0.09 0.51 0.38 0.49 0.68)
sub _qvalue {
    my $p = shift;
    my %setup = ('lambda'         => multiply(seq(0, 90, 5), 0.01),
                 'robust'         => 0,
                 @_ );
    
    my $lambda = $setup{'lambda'};
    my $robust = $setup{'robust'};

    if(! List::Vectorize::is_array_ref($lambda)) {
        croak "ERROR: lambda should be an array reference. If your lambda is a single number, you should set it as an array reference containing one element, such as [0.1].";
    }
    
    if(len($lambda) > 1 and len($lambda) < 4) {
        croak "ERROR: If length of lambda greater than 1, you need at least 4 values.";
    }
    if(len($lambda) > 1 and (min($lambda) < 0 or max($lambda) >= 1)) {
        croak "ERROR: Lambda must be within [0, 1).";
    }
    
    # m <- length(p)
    my $m = len($p);
    my $pi0;
    
    if(len($lambda) == 1) {
        $lambda = $lambda->[0];
        if($lambda < 0 or $lambda >= 1) {
            croak "ERROR: Lambda must be within [0, 1).";
        }
        # pi0 <- mean(p >= lambda)/(1-lambda)
        $pi0 = mean(test($p, sub {_approximately_compare($_[0], ">=", $lambda)})) / (1 - $lambda);
        # pi0 <- min(pi0,1)
        $pi0 = min(c($pi0, 1));
    }
    else {
        # pi0 <- rep(0,length(lambda))
        $pi0 = rep(0, len($lambda));
        # for(i in 1:length(lambda)) {
        #     pi0[i] <- mean(p >= lambda[i])/(1-lambda[i])
        # }
        $pi0 = sapply(seq(0, len($lambda) - 1),
                      sub {
                          my $current_lambda = $lambda->[$_[0]]; 
                          mean(test($p, sub {_approximately_compare($_[0], ">=", $current_lambda)})) / (1 - $current_lambda);
                      });

        # minpi0 <- min(pi0)
        my $minpi0 = min($pi0);
        
        # mse <- rep(0,length(lambda))
        my $mse = rep(0, len($lambda));
        # pi0.boot <- rep(0,length(lambda))
        my $pi0_boot = rep(0, len($lambda));
        for (1..100) {
            #  p.boot <- sample(p,size=m,replace=TRUE)
            my $p_boot = sample($p, $m, 'replace' => 1);
            # for(i in 1:length(lambda)) {
            #     pi0.boot[i] <- mean(p.boot>lambda[i])/(1-lambda[i])
            # }
            $pi0_boot = sapply(seq(0, len($lambda) - 1),
                               sub {
                                    my $current_lambda = $lambda->[$_[0]];
                                    mean(test($p_boot, sub {$_[0] > $current_lambda})) / (1 - $current_lambda);
                               });
            # mse <- mse + (pi0.boot-minpi0)^2
            $mse = plus($mse, power(minus($pi0_boot, $minpi0), 2));
        }
        
        # pi0 <- min(pi0[mse==min(mse)])
        my $min_mse = min($mse);
        
        $pi0 = min(subset($pi0, which(test($mse, sub {_approximately_compare($_[0], "==", $min_mse)}))));
        $pi0 = min(c($pi0, 1));
    }
    
    if($pi0 <= 0) {
        croak "ERROR: The estimated pi0 ($pi0) <= 0. Check that you have valid p-values or use another lambda method.";
    }

    # u <- order(p)
    my $u = order($p);

    # this function is not the same to the function in qvalue
    # but returns the same result
    # returns number of observations less than or equal to
    sub qvalue_rank {
        my $x = shift;
        return sapply($x, sub {
                          my $current_x = $_[0];
                          sum(test($x, sub {$_[0] <= $current_x}));
                      });
    }
    
    # v <- qvalue.rank(p)
    my $v = qvalue_rank($p);
    # qvalue <- pi0*m*p/v
    my $qvalue = divide(multiply($pi0, $m, $p), $v);
    
    if($robust) {
        # qvalue <- pi0*m*p/(v*(1-(1-p)^m))
        $qvalue = divide(multiply($pi0, $m, $p), multiply($v, minus(1, power(minus(1, $p), $m))));
    }
   
    # qvalue[u[m]] <- min(qvalue[u[m]],1)
    $qvalue->[$u->[$#$u]] = min(c($qvalue->[$u->[$#$u]], 1));
    # for(i in (m-1):1) {
    #     qvalue[u[i]] <- min(qvalue[u[i]],qvalue[u[i+1]],1)
    # }
    for my $i (@{seq($#$u-1, 0)}) {
        $qvalue->[$u->[$i]] = min([$qvalue->[$u->[$i]], $qvalue->[$u->[$i+1]], 1]);
    }
    
    return $qvalue;
}

# vectorized power calculation
sub power {
    my $array = shift;
    my $power = shift;
    
    my $res = sapply($array, sub {$_[0]**($power)});
    return $res;
}

# approximately
sub _approximately_compare {
    my $left = shift;
    my $sign = shift;
    my $right = shift;

    if($sign eq ">" or $sign eq ">=") {
        if($left > $right) {
            return 1;
        }
        elsif(abs($left - $right) < EPS) {
            return 1;
        }
        else {
            return 0;
        }
    }
    elsif($sign eq "<" or $sign eq "<=") {
        if($left < $right) {
            return 1;
        }
        elsif(abs($left - $right) < EPS) {
            return 1;
        }
        else {
            return 0;
        }
    }
    elsif($sign eq "==") {
        if(abs($left - $right) < EPS) {
            return 1;
        }
        else {
            return 0;
        }
    }
}

__END__

=pod

=head1 NAME

Statistics::Multtest - Control false discovery rate in multiple test problem

=head1 SYNOPSIS

  use Statistics::Multtest qw(bonferroni holm hommel hochberg BH BY qvalue);
  use Statistics::Multtest qw(:all);
  use strict;
  
  my $p;
  # p-values can be stored in an array by reference
  $p = [0.01, 0.02, 0.05,0.41,0.16,0.51];
  # @$res has the same order as @$p
  my $res = BH($p);
  print join "\n", @$res;
  
  # p-values can also be stored in a hash by reference
  $p = {"a" => 0.01,
        "b" => 0.02,
        "c" => 0.05,
        "d" => 0.41,
        "e" => 0.16,
        "f" => 0.51 };
  # $res is also a hash reference which is the same as $p
  $res = holm($p);
  foreach (sort {$res->{a} <=> $res->{$b}} keys %$res) {
      print "$_ => $res->{$_}\n";
  }
  
  # since qvalue does not always run successfully,
  # it should be embeded in 'eval'
  $res = eval 'qvalue($p)';
  if($@) {
      print $@;
  }
  else {
      print join "\n", @$res;
  }

=head1 DESCRIPTION

For statistical test, p-value is the probability of false positives. While there
are many hypothesis for testing simultaneously, the probability of getting at least one
false positive would be large. Therefore the origin p-values should be adjusted to decrease
the false discovery rate.

Seven procedures to controlling false positive rates is provided. 
The names of the methods are derived from C<p.adjust> in 
C<stat> package and C<qvalue> in C<qvalue> package (http://www.bioconductor.org/packages/release/bioc/html/qvalue.html) in R. Code is translated 
directly from R to Perl using L<List::Vectorize> module.

All seven subroutines receive one argument which can either be an array reference
or a hash reference, and return the adjusted p-values in corresponding data structure. The order
of items in the array does not change after the adjustment.

=head2 Subroutines

=over 4

=item C<bonferroni($pvalue)>

Bonferroni single-step process.

=item C<hommel($pvalue)>

Hommel singlewise process.

Hommel, G. (1988). A stagewise rejective multiple test procedure based on a modified Bonferroni test. Biometrika, 75, 383每386. 

=item C<holm($pvalue)>

Holm step-down process.

Holm, S. (1979). A simple sequentially rejective multiple test procedure. Scandinavian Journal of Statistics, 6, 65每70. 

=item C<hochberg($pvalue)>

Hochberg step-up process.

Hochberg, Y. (1988). A sharper Bonferroni procedure for multiple tests of significance. Biometrika, 75, 800每803. 

=item C<BH($pvalue)>

Benjamini and Hochberg, controlling the FDR.

Benjamini, Y., and Hochberg, Y. (1995). Controlling the false discovery rate: a practical and powerful approach to multiple testing. Journal of the Royal Statistical Society Series B, 57, 289每300. 

=item C<BY($pvalue)>

Use Benjamini and Yekutieli.

Benjamini, Y., and Yekutieli, D. (2001). The control of the false discovery rate in multiple testing under dependency. Annals of Statistics 29, 1165每1188. 

=item C<qvalue($pvalue, %setup)>

Storey and Tibshirani.

Storey JD and Tibshirani R. (2003) Statistical significance for genome-wide experiments. Proceedings of the National Academy of Sciences, 100: 9440-9445. 

The default method for estimating pi0 in the origin C<qvalue> package is to utilize
cubic spline interpolation. However, there is no suitable perl module to do such work
(external libraries should be installed if using L<Math::GSL::Spline> and there seems
to be some mistakes when I using L<Math::Spline>). Therefore, in this module, we only
provide 'bootstrap' method to estimate pi0, which is also the second pi0 method in 
C<qvalue> package. Some arguments which are the same in C<qvalue> package can be 
set in C<%setup> as follows. 

  lambda => multiply(seq(0, 90, 5), # The value of the tuning parameter
                     0.01),         # to estimate pi_0. Must be in [0,1).
                                    # It should be an array reference
  robust => 0, # An indicator of whether it is desired to make the estimate 
               # more robust for small p-values and a direct finite sample
               # estimate of pFDR

For details, please see the Storey (2003) and the C<qvalue> document in R.

NOTE: The results of this subroutine are not always exactly consistent to the C<qvalue>
package due to the floating point number calculation.

In some circumstance, the estimated pi0 <= 0, and the subroutine would throw an error.
(try p-value list: [0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]). So
you should embeded this subroutine in 'eval' such as:

  my $qvalue;
  eval '$qvalue = qvalue($pvalue, %setup)';
  if($@) {
    # do something
  }
  else {
      print join ", ", @$qvalue;
  }
               
=back

=head1 AUTHOR

Zuguang Gu E<lt>jokergoo@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2012 by Zuguang Gu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<List::Vectorize>

=cut
