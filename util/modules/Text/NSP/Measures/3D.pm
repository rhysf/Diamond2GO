=head1 NAME

Text::NSP::Measures::3D - Perl module that provides basic framework for
                          building measure of association for trigrams.

=head1 SYNOPSIS

This module can be used as a foundation for building 3-dimensional
measures of association that can then be used by statistic.pl. In
particular this module provides methods that give convenient access to
3-d (i.e., trigram) frequency counts as created by count.pl, as well as
some degree of error handling that verifies the data.


=head3 Basic Usage

  use Text::NSP::Measures::3D::MI::ll;

  $ll_value = calculateStatistic( n111=>10,
                                  n1pp=>40,
                                  np1p=>45,
                                  npp1=>42,
                                  n11p=>20,
                                  n1p1=>23,
                                  np11=>21,
                                  nppp=>100);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $erroCode." - ".getErrorMessage()."\n";
  }
  else
  {
    print getStatisticName."value for bigram is ".$ll_value."\n";
  }

=head1 DESCRIPTION

The methods in this module retrieve observed trigram frequency counts and
marginal totals, and also compute expected values. They also provide
support for error checking of the output produced by count.pl. These
methods are used in all the trigram (3d) measure modules provided in NSP.
If you are writing your own 3d measure, you can use these methods as well.

With trigram or 3d measures we use a 3x3 contingency table to store the
frequency counts associated with each word in the trigram, as well as the
number of times the trigram occurs. The notation we employ is as follows:

Marginal Frequencies:

 n1pp = the number of trigrams where the first word is word1.
 np1p = the number of trigrams where the second word is word2.
 npp1 = the number of trigrams where the third word is word3
 n2pp = the number of trigrams where the first word is not word1.
 np2p = the number of trigrams where the second word is not word2.
 npp2 = the number of trigrams where the third word is not word3.

Observed Frequencies:

 n111 = number of times word1, word2 and word3 occur together in
        their respective positions, joint frequency.
 n112 = number of times word1 and word2 occur in their respective
        positions but word3 does not.
 n121 = number of times word1 and word3 occur in their respective
        positions but word2 does not.
 n211 = number of times word2 and word3 occur in their respective
        positions but word1 does not.
 n122 = number of times word1 occurs in its respective position
        but word2 and word3 do not.
 n212 = number of times word2 occurs in in its respective position
        but word1 and word3 do not.
 n221 = number of times word3 occurs in its respective position
        but word1 and word2 do not.
 n222 = number of time neither word1, word2 or word3 occur in their
        respective positions.

Expected Frequencies:

 m111 = expected number of times word1, word2 and word3 occur together in
        their respective positions.
 m112 = expected number of times word1 and word2 occur in their respective
        positions but word3 does not.
 m121 = expected number of times word1 and word3 occur in their respective
        positions but word2 does not.
 m211 = expected number of times word2 and word3 occur in their respective
        positions but word1 does not.
 m122 = expected number of times word1 occurs in its respective position
        but word2 and word3 do not.
 m212 = expected number of times word2 occurs in in its respective position
        but word1 and word3 do not.
 m221 = expected number of times word3 occurs in its respective position
        but word1 and word2 do not.
 m222 = expected number of time neither word1, word2 or word3 occur in their
        respective positions.

=head2 Methods

=over

=cut


package Text::NSP::Measures::3D;


use Text::NSP::Measures;
use strict;
use Carp;
use warnings;
require Exporter;

our ($VERSION, @ISA, $marginals, @EXPORT);

our ($n111, $n112, $n121, $n122, $n211, $n212, $n221, $n222);
our ($m111, $m112, $m121, $m122, $m211, $m212, $m221, $m222);
our ($nppp, $n1pp, $np1p, $npp1, $n11p, $n1p1, $np11);
our ($n2pp, $np2p, $npp2);


@ISA  = qw(Exporter);

@EXPORT = qw(initializeStatistic calculateStatistic
             getErrorCode getErrorMessage getStatisticName
             $n111 $n112 $n121 $n122 $n211 $n212 $n221 $n222
             $m111 $m112 $m121 $m122 $m211 $m212 $m221 $m222
             $nppp $n1pp $np1p $npp1 $n11p $n1p1 $np11 $n2pp
             $np2p $npp2 $errorCodeNumber $errorMessage);

$VERSION = '0.97';


=item computeObservedValues($count_values) - A method to
compute observed values, and also to verify that the
computed Observed values are correct, That is they are
positive, less than the marginal totals and the total
bigram count.

INPUT PARAMS  : $count_values     .. Reference to an hash consisting
                                     of the count values passed to
                                     the calculateStatistic() method.

RETURN VALUES : 1/undef           ..returns '1' to indicate success
                                    and an undefined(NULL) value to indicate
                                    failure.

=cut

sub computeObservedValues
{
  my ($values) = @_;

  $n111 = -1;
  if(!defined $values->{n111})
  {
    $errorMessage = "Required trigram (1,1,1) not passed";
    $errorCodeNumber = 200;
    return;
  }
  else
  {
    $n111=$values->{n111};
  }
  # joint frequency should be greater than equal to zero
  if ($n111< 0)
  {
    $errorMessage = "Frequency value (n111=$n111) must not be negative.";
    $errorCodeNumber = 201;
    return;
  }

  # n111 frequency should be less than or equal to totalBigrams
  if ($n111> $nppp)
  {
    $errorMessage = "Frequency value (n111=$n111) must not exceed total number of bigrams.";
    $errorCodeNumber = 202;
    return;
  }
  # joint frequency n111 should be less than or equal to the marginal totals
  if ($n111 > $n1pp || $n111 > $np1p || $n111 > $npp1)
  {
    $errorMessage = "Frequency value of ngram (n111=$n111) must not exceed the marginal totals.";
    $errorCodeNumber = 202;
    return;
  }


   $n112=$n11p-$n111;
  if ($n112< 0)
  {
    $errorMessage = "Frequency value (n112=$n112) must not be negative.";
    $errorCodeNumber = 201;
    return;
  }
  # n111 frequency should be less than or equal to totalBigrams
  if ($n112> $nppp)
  {
    $errorMessage = "Frequency value (n112=$n112) must not exceed total number of bigrams.";
    $errorCodeNumber = 202;
    return;
  }
  # joint frequency n111 should be less than or equal to the marginal totals
  if ($n112 > $n1pp || $n112 > $np1p || $n112 > $npp2)
  {
    $errorMessage = "Frequency value of ngram (n112=$n112) must not exceed the marginal totals.";
    $errorCodeNumber = 202;
    return;
  }


  $n121=$n1p1-$n111;
  if ($n121< 0)
  {
    $errorMessage = "Frequency value (n121=$n121) must not be negative.";
    $errorCodeNumber = 201;
    return;
  }
  # n111 frequency should be less than or equal to totalBigrams
  if ($n121> $nppp)
  {
    $errorMessage = "Frequency value (n121=$n121) must not exceed total number of bigrams.";
    $errorCodeNumber = 202;
    return;
  }
  # joint frequency n111 should be less than or equal to the marginal totals
  if ($n121 > $n1pp || $n121 > $np2p || $n121 > $npp1)
  {
    $errorMessage = "Frequency value of ngram (n121=$n121) must not exceed the marginal totals.";
    $errorCodeNumber = 202;
    return;
  }


  $n211=$np11-$n111;
  if ($n211< 0)
  {
    $errorMessage = "Frequency value (n211=$n211) must not be negative.";
    $errorCodeNumber = 201;
    return;
  }
  # n111 frequency should be less than or equal to totalBigrams
  if ($n211> $nppp)
  {
    $errorMessage = "Frequency value (n211=$n211) must not exceed total number of bigrams.";
    $errorCodeNumber = 202;
    return;
  }
  # joint frequency n111 should be less than or equal to the marginal totals
  if ($n211 > $n2pp || $n211 > $np1p || $n211 > $npp1)
  {
    $errorMessage = "Frequency value of ngram (n211=$n211) must not exceed the marginal totals.";
    $errorCodeNumber = 202;
    return;
  }

  $n212=$np1p-$n111-$n112-$n211;
  if ($n212< 0)
  {
    $errorMessage = "Frequency value (n212=$n212) must not be negative.";
    $errorCodeNumber = 201;
    return;
  }
  # n111 frequency should be less than or equal to totalBigrams
  if ($n212> $nppp)
  {
    $errorMessage = "Frequency value (n212=$n212) must not exceed total number of bigrams.";
    $errorCodeNumber = 202;
    return;
  }
  # joint frequency n111 should be less than or equal to the marginal totals
  if ($n212 > $n2pp || $n212 > $np1p || $n212 > $npp2)
  {
    $errorMessage = "Frequency value of ngram (n212=$n212) must not exceed the marginal totals.";
    $errorCodeNumber = 202;
    return;
  }


  $n122=$n1pp-$n111-$n112-$n121;
  if ($n122< 0)
  {
    $errorMessage = "Frequency value (n122=$n122) must not be negative.";
    $errorCodeNumber = 201;
    return;
  }
  # n111 frequency should be less than or equal to totalBigrams
  if ($n122> $nppp)
  {
    $errorMessage = "Frequency value (n122=$n122) must not exceed total number of bigrams.";
    $errorCodeNumber = 202;
    return;
  }
  # joint frequency n111 should be less than or equal to the marginal totals
  if ($n122 > $n1pp || $n122 > $np2p || $n122 > $npp2)
  {
    $errorMessage = "Frequency value of ngram (n122=$n122) must not exceed the marginal totals.";
    $errorCodeNumber = 202;
    return;
  }


  $n221=$npp1-$n111-$n211-$n121;
  if ($n221< 0)
  {
    $errorMessage = "Frequency value (n221=$n221) must not be negative.";
    $errorCodeNumber = 201;
    return;
  }
  # n111 frequency should be less than or equal to totalBigrams
  if ($n221> $nppp)
  {
    $errorMessage = "Frequency value (n221=$n221) must not exceed total number of bigrams.";
    $errorCodeNumber = 202;
    return;
  }
  # joint frequency n111 should be less than or equal to the marginal totals
  if ($n221 > $n2pp || $n221 > $np2p || $n221 > $npp1)
  {
    $errorMessage = "Frequency value of ngram (n221=$n221) must not exceed the marginal totals.";
    $errorCodeNumber = 202;
    return;
  }


  $n222=$nppp-($n111+$n112+$n121+$n122+$n211+$n212+$n221);
  if ($n222< 0)
  {
    $errorMessage = "Frequency value (n222=$n222) must not be negative.";
    $errorCodeNumber = 201;
    return;
  }
  # n111 frequency should be less than or equal to totalBigrams
  if ($n222> $nppp)
  {
    $errorMessage = "Frequency value (n222=$n222) must not exceed total number of bigrams.";
    $errorCodeNumber = 202;
    return;
  }
  # joint frequency n111 should be less than or equal to the marginal totals
  if ($n222 > $n2pp || $n222 > $np2p || $n222 > $npp2)
  {
    $errorMessage = "Frequency value of ngram (n222=$n222) must not exceed the marginal totals.";
    $errorCodeNumber = 202;
    return;
  }

  return 1;
}





=item computeExpectedValues($count_values) - A method to compute
expected values.

INPUT PARAMS  : $count_values     .. Reference to an hash consisting
                                     of the count output.

RETURN VALUES : 1/undef           ..returns '1' to indicate success
                                    and an undefined(NULL) value to indicate
                                    failure.

=cut

sub computeExpectedValues
{
  my ($values)=@_;

  $m111=$n1pp*$np1p*$npp1/($nppp**2);
  $m112=$n1pp*$np1p*$npp2/($nppp**2);
  $m121=$n1pp*$np2p*$npp1/($nppp**2);
  $m122=$n1pp*$np2p*$npp2/($nppp**2);
  $m211=$n2pp*$np1p*$npp1/($nppp**2);
  $m212=$n2pp*$np1p*$npp2/($nppp**2);
  $m221=$n2pp*$np2p*$npp1/($nppp**2);
  $m222=$n2pp*$np2p*$npp2/($nppp**2);

  return 1;
}






=item computeMarginalTotals($marginal_values) - This method
computes the marginal totals from the valuescomputed by the count.pl
program and are passed to the calculateStatistic() method.

INPUT PARAMS  : $count_values     .. Reference to an hash consisting
                                     of the frequency combination
                                     output.

RETURN VALUES : 1/undef           ..returns '1' to indicate success
                                    and an undefined(NULL) value to indicate
                                    failure.

=cut

sub computeMarginalTotals
{

  my ($values)=@_;

  $nppp = -1;
  if(!defined $values->{nppp})
  {
    $errorMessage = "Total trigram count not passed";
    $errorCodeNumber = 200;
    return;
  }
  elsif($values->{nppp}<=0)
  {
    $errorMessage = "Total trigram count cannot be less than to zero";
    $errorCodeNumber = 200;
    return;
  }
  else
  {
    $nppp = $values->{nppp};
  }


  $n1pp = -1;
  if(!defined $values->{n1pp})
  {
    $errorMessage = "Required marginal total (1,p,p) not passed";
    $errorCodeNumber = 200;
    return;
  }
  else
  {
    $n1pp=$values->{n1pp};
  }
  # n1pp should be greater than or equal to zero
  if ($n1pp< 0)
  {
    $errorMessage = "Marginal total value ($n1pp) must not be negative.";
    $errorCodeNumber = 204;  return;
  }
  # n1pp should be less than or equal to totalBigrams
  if ($n1pp > $nppp)
  {
    $errorMessage = "Marginal total value ($n1pp) must not exceed total number of bigrams.";
    $errorCodeNumber = 203;  return;
  }



  $np1p = -1;
  if(!defined $values->{np1p})
  {
    $errorMessage = "Required marginal total (p,1,p) not passed";
    $errorCodeNumber = 200;
    return;
  }
  else
  {
    $np1p=$values->{np1p};
  }
  # np1p should be greater than or equal to zero
  if ($np1p< 0)
  {
    $errorMessage = "Marginal total value ($np1p) must not be negative.";
    $errorCodeNumber = 204;  return;
  }
  # np1p should be less than or equal to totalBigrams
  if ($np1p > $nppp)
  {
    $errorMessage = "Marginal total value ($np1p) must not exceed total number of trigrams.";
    $errorCodeNumber = 203;  return;
  }


  $npp1 = -1;
  if(!defined $values->{npp1})
  {
    $errorMessage = "Required marginal total (p,p,1) not passed";
    $errorCodeNumber = 200;
    return;
  }
  else
  {
    $npp1=$values->{npp1};
  }
  # npp1 should be greater than or equal to zero
  if ($npp1< 0)
  {
    $errorMessage = "Marginal total value ($npp1) must not be negative.";
    $errorCodeNumber = 204;  return;
  }
  # npp1 should be less than or equal to totalBigrams
  if ($npp1 > $nppp)
  {
    $errorMessage = "Marginal total value ($npp1) must not exceed total number of bigrams.";
    $errorCodeNumber = 203;  return;
  }

  $n11p = -1;
  if(!defined $values->{n11p})
  {
    $errorMessage = "Required marginal total (1,1,p) not passed";
    $errorCodeNumber = 200;
    return;
  }
  else
  {
    $n11p=$values->{n11p};
  }
  # n11p should be greater than or equal to zero
  if ($n11p< 0)
  {
    $errorMessage = "Marginal total value ($n11p) must not be negative.";
    $errorCodeNumber = 204;  return;
  }
  # n11p should be less than or equal to totalBigrams
  if ($n11p > $nppp)
  {
    $errorMessage = "Marginal total value ($n11p) must not exceed total number of bigrams.";
    $errorCodeNumber = 203;  return;
  }

  $np11=-1;
  if(!defined $values->{np11})
  {
    $errorMessage = "Required marginal total (p,1,1) not passed";
    $errorCodeNumber = 200;
    return;
  }
  else
  {
    $np11=$values->{np11};
  }
  # np11 should be greater than or equal to zero
  if ($np11< 0)
  {
    $errorMessage = "Marginal total value ($np11) must not be negative.";
    $errorCodeNumber = 204;  return;
  }
  # np11 should be less than or equal to totalBigrams
  if ($np11 > $nppp)
  {
    $errorMessage = "Marginal total value ($np11) must not exceed total number of trigrams.";
    $errorCodeNumber = 203;  return;
  }

  $n1p1=-1;
  if(!defined $values->{n1p1})
  {
    $errorMessage = "Required marginal total (1,p,1) not passed";
    $errorCodeNumber = 200;
    return;
  }
  else
  {
    $n1p1=$values->{n1p1};
  }
  # n1p1 should be greater than or equal to zero
  if ($n1p1< 0)
  {
    $errorMessage = "Marginal total value ($n1p1) must not be negative.";
    $errorCodeNumber = 204;  return;
  }
  # n1p1 should be less than or equal to totalBigrams
  if ($n1p1 > $nppp)
  {
    $errorMessage = "Marginal total value ($n1p1) must not exceed total number of bigrams.";
    $errorCodeNumber = 203;  return;
  }

  $n2pp=$values->{nppp}-$n1pp;
  $np2p=$values->{nppp}-$np1p;
  $npp2=$values->{nppp}-$npp1;

  return 1;
}

1;
__END__

=back

=head1 AUTHOR

Ted Pedersen,                University of Minnesota Duluth
                             E<lt>tpederse@d.umn.eduE<gt>

Satanjeev Banerjee,          Carnegie Mellon University
                             E<lt>satanjeev@cmu.eduE<gt>

Amruta Purandare,            University of Pittsburgh
                             E<lt>amruta@cs.pitt.eduE<gt>

Bridget Thomson-McInnes,     University of Minnesota Twin Cities
                             E<lt>bthompson@d.umn.eduE<gt>

Saiyam Kohli,                University of Minnesota Duluth
                             E<lt>kohli003@d.umn.eduE<gt>

=head1 HISTORY

Last updated: $Id: 3D.pm,v 1.15 2008/03/26 17:25:13 tpederse Exp $

=head1 BUGS


=head1 SEE ALSO

L<http://groups.yahoo.com/group/ngram/>

L<http://www.d.umn.edu/~tpederse/nsp.html>


=head1 COPYRIGHT

Copyright (C) 2000-2006, Ted Pedersen, Satanjeev Banerjee, Amruta
Purandare, Bridget Thomson-McInnes and Saiyam Kohli

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to

    The Free Software Foundation, Inc.,
    59 Temple Place - Suite 330,
    Boston, MA  02111-1307, USA.

Note: a copy of the GNU General Public License is available on the web
at L<http://www.gnu.org/licenses/gpl.txt> and is included in this
distribution as GPL.txt.

=cut