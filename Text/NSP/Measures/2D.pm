=head1 NAME

Text::NSP::Measures::2D - Perl module that provides basic framework
                          for building measure of association for
                          bigrams.

=head1 SYNOPSIS

=head3 Basic Usage

 use Text::NSP::Measures::2D::MI::ll;

  my $npp = 60; my $n1p = 20; my $np1 = 20;  my $n11 = 10;

  $ll_value = calculateStatistic( n11=>$n11,
                                      n1p=>$n1p,
                                      np1=>$np1,
                                      npp=>$npp);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $errorCode." - ".getErrorMessage()."\n"";
  }
  else
  {
    print getStatisticName."value for bigram is ".$ll_value."\n"";
  }


=head1 DESCRIPTION

This module is to be used as a foundation for building 2-dimensional
measures of association. The methods in this module retrieve observed
bigram frequency counts, marginal totals, and also compute expected
values. They also provide error checks for these counts.

With bigram or 2d measures we use variables with corresponding names
to store the 2x2 contingency table to store the frequency counts
associated with each word in the bigram, as well as the number of
times the bigram occurs. A contingency table looks like

            |word2  | not-word2|
            --------------------
    word1   | n11   |   n12    |  n1p
  not-word1 | n21   |   n22    |  n2p
            --------------------
              np1       np2       npp

Marginal Frequencies:

  n1p = the number of bigrams where the first word is word1.
  np1 = the number of bigrams where the second word is word2.
  n2p = the number of bigrams where the first word is not word1.
  np2 = the number of bigrams where the second word is not word2.

  These marginal totals are stored in variables which have names
  corresponding to the cell they represent. These values may then be
  referred to as follows:

        $n1p,
        $np1,
        $n2p,
        $np2,
        $npp

Observed Frequencies:

  n11 = number of times the bigram occurs, joint frequency
  n12 = number of times word1 occurs in the first position of a bigram
        when word2 does not occur in the second position.
  n21 = number of times word2 occurs in the second position of a
        bigram when word1 does not occur in the first position.
  n22 = number of bigrams where word1 is not in the first position and
        word2 is not in the second position.

  The observed frequencies are also stored in variables with corresponding names.
  These values may then be referred to as follows:


        $n11,
        $n12,
        $n21,
        $n22

Expected Frequencies:

  m11 = expected number of times both words in the bigram occur
        together if they are independent. (n1p*np1/npp)
  m12 = expected number of times word1 in the bigram will occur in
        the first position when word2 does not occur in the second
        position given that the words are independent. (n1p*np2/npp)
  m21 = expected number of times word2 in the bigram will occur
        in the second position when word1 does not occur in the first
        position given that the words are independent. (np1*n2p/npp)
  m22 = expected number of times word1 will not occur in the first
        position and word2 will not occur in the second position
        given that the words are independent. (n2p*np2/npp)

  Similarly the expected values are stored as

        $m11,
        $m12,
        $m21,
        $m22

=head2 Methods

=over

=cut


package Text::NSP::Measures::2D;


use Text::NSP::Measures;
use strict;
use Carp;
use warnings;
require Exporter;

our ($VERSION, @ISA, @EXPORT);

@ISA  = qw(Exporter);

our ($n11, $n12, $n21, $n22);
our ($m11, $m12, $m21, $m22);
our ($npp, $n1p, $np1, $n2p, $np2);
# $npp = -1; $n1p = -1; $np1 = -1;
# $n2p = -1; $np2 = -1;


@EXPORT = qw(initializeStatistic calculateStatistic
             getErrorCode getErrorMessage getStatisticName
             $errorCodeNumber $errorMessage
             $n11 $n12 $n21 $n22 $m11 $m12 $m21 $m22
             $npp $np1 $np2 $n2p $n1p);

$VERSION = '0.97';


=item computeObservedValues() - A method to compute observed values,
and also to verify that the computed Observed values are correct,
That is they are positive, less than the marginal totals and the
total bigram count.


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

  if(!defined $values->{n11})
  {
    $errorMessage = "Required frequency count (1,1) not passed";
    $errorCodeNumber = 200;
    return;
  }
  else
  {
    $n11 = $values->{n11};
  }
  # joint frequency should be greater than equal to zero
  if ($n11 < 0)
  {
    $errorMessage = "Frequency value 'n11' must not be negative.";
    $errorCodeNumber = 201;
    return;
  }

  # joint frequency (n11) should be less than or equal to the
  # total number of bigrams (npp)
  if($n11 > $npp)
  {
    $errorMessage = "Frequency value 'n11' must not exceed total number of bigrams.";
    $errorCodeNumber = 202;
    return;
  }

  # joint frequency should be less than or equal to the marginal totals
  if ($n11 > $np1 || $n11 > $n1p)
  {
    $errorMessage = "Frequency value of ngram 'n11' must not exceed the marginal totals.";
    $errorCodeNumber = 202;
    return;
  }

  #  The marginal totals are reasonable so we can
  #  calculate the observed frequencies
  $n12 = $n1p - $n11;
  $n21 = $np1 - $n11;
  $n22 = $np2 - $n12;

  if ($n12 < 0)
  {
    $errorMessage = "Frequency value 'n12' must not be negative.";
    $errorCodeNumber = 201;
    return;
  }

  if ($n21 < 0)
  {
    $errorMessage = "Frequency value 'n21' must not be negative.";
    $errorCodeNumber = 201;
    return;
  }

  if ($n22 < 0)
  {
    $errorMessage = "Frequency value 'n22' must not be negative.";
    $errorCodeNumber = 201;
    return;
  }

  return 1;
}



=item computeExpectedValues() - A method to compute expected values.


INPUT PARAMS  :none

RETURN VALUES : 1/undef           ..returns '1' to indicate success
                                    and an undefined(NULL) value to indicate
                                    failure.

=cut

sub computeExpectedValues
{
  #  calculate the expected values
  $m11 = $n1p * $np1 / $npp;
  $m12 = $n1p * $np2 / $npp;
  $m21 = $n2p * $np1 / $npp;
  $m22 = $n2p * $np2 / $npp;

  return 1;
}



=item computeMarginalTotals() - This method computes the marginal totals from the count values as
passed to it.


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

  if(!defined $values->{npp})
  {
    $errorMessage = "Total bigram count not passed";
    $errorCodeNumber = 200;
    return;
  }
  elsif($values->{npp}<=0)
  {
    $errorMessage = "Total bigram count cannot be less than to zero";
    $errorCodeNumber = 204;
    return;
  }
  else
  {
    $npp = $values->{npp};
  }

  $n1p=-1;
  if(!defined $values->{n1p})
  {
    $errorMessage = "Required Marginal total (1,p) count not passed";
    $errorCodeNumber = 200;
    return;
  }
  else
  {
    $n1p=$values->{n1p};
  }
  # right frequency (n1p) should be greater than or equal to zero
  if ($n1p < 0)
  {
    $errorMessage = "Marginal total value 'n1p' must not be negative.";
    $errorCodeNumber = 204;
    return;
  }
  # right frequency (n1p) should be less than or equal to the total
  # number of bigrams (npp)
  if ($n1p > $npp)
  {
    $errorMessage = "Marginal total value 'n1p' must not exceed total number of bigrams.";
    $errorCodeNumber = 203;
    return;
  }


  $np1 = -1;
  if(!defined $values->{np1})
  {
    $errorMessage = "Required Marginal total (p,1) count not passed";
    $errorCodeNumber = 200;
    return;
  }
  else
  {
    $np1=$values->{np1};
  }
  # left frequency (np1) should be greater than or equal to zero
  if ($np1 < 0)
  {
    $errorMessage = "Marginal total value 'np1' must not be negative.";
    $errorCodeNumber = 204;
    return;
  }
  # left frequency (np1) should be less than or equal to the total
  #  number of bigrams (npp)
  if ($np1 > $npp)
  {
    $errorMessage = "Marginal total value 'np1' must not exceed total number of bigrams.";
    $errorCodeNumber = 203;
    return;
  }

  $np2 = $npp - $np1;
  $n2p = $npp - $n1p;

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

Last updated: $Id: 2D.pm,v 1.28 2008/03/26 17:25:13 tpederse Exp $

=head1 BUGS


=head1 SEE ALSO

L<http://groups.yahoo.com/group/ngram/>

L<http://www.d.umn.edu/~tpederse/nsp.html>


=head1 COPYRIGHT

Copyright (C) 2000-2006, Ted Pedersen, Satanjeev Banerjee,
Amruta Purandare, Bridget Thomson-McInnes and Saiyam Kohli

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to

    The Free Software Foundation, Inc.,
    59 Temple Place - Suite 330,
    Boston, MA  02111-1307, USA.

Note: a copy of the GNU General Public License is available on the web
at L<http://www.gnu.org/licenses/gpl.txt> and is included in this
distribution as GPL.txt.

=cut
