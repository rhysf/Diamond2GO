=head1 NAME

Text::NSP::Measures::2D::Fisher - Perl module that provides methods
                                  to compute the Fishers exact tests.

=head1 SYNOPSIS

=head3 Basic Usage

  use Text::NSP::Measures::2D::Fisher::left;

  my $npp = 60; my $n1p = 20; my $np1 = 20;  my $n11 = 10;

  $left_value = calculateStatistic( n11=>$n11,
                                      n1p=>$n1p,
                                      np1=>$np1,
                                      npp=>$npp);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $errorCode." - ".getErrorMessage();
  }
  else
  {
    print getStatisticName."value for bigram is ".$left_value;
  }


=head1 DESCRIPTION

Assume that the frequency count data associated with a bigram
<word1><word2> is stored in a 2x2 contingency table:

          word2   ~word2
  word1    n11      n12 | n1p
 ~word1    n21      n22 | n2p
           --------------
           np1      np2   npp

where n11 is the number of times <word1><word2> occur together, and
n12 is the number of times <word1> occurs with some word other than
word2, and n1p is the number of times in total that word1 occurs as
the first word in a bigram.

The fishers exact tests are calculated by fixing the marginal totals
and computing the hypergeometric probabilities for all the possible
contingency tables,

A left sided test is calculated by adding the probabilities of all
the possible two by two contingency tables formed by fixing the
marginal totals and changing the value of n11 to less than the given
value. A left sided Fisher's Exact Test tells us how likely it is to
randomly sample a table where n11 is less than observed. In other words,
it tells us how likely it is to sample an observation where the two words
are less dependent than currently observed.

A right sided test is calculated by adding the probabilities of all
the possible two by two contingency tables formed by fixing the
marginal totals and changing the value of n11 to greater than or
equal to the given value. A right sided Fisher's Exact Test tells us
how likely it is to randomly sample a table where n11 is greater
than observed. In other words, it tells us how likely it is to sample
an observation where the two words are more dependent than currently
observed.

A two-tailed fishers test is calculated by adding the probabilities of
all the contingency tables with probabilities less than the probability
of the observed table. The two-tailed fishers test tells us how likely
it would be to observe an contingency table which is less probable than
the current table.

=head2 Methods

=over

=cut


package Text::NSP::Measures::2D::Fisher;


use Text::NSP::Measures::2D;
use strict;
use Carp;
use warnings;
# use subs(calculateStatistic);
require Exporter;

our ($VERSION, @EXPORT, @ISA);

@ISA  = qw(Exporter);

@EXPORT = qw(initializeStatistic calculateStatistic
             getErrorCode getErrorMessage getStatisticName
             $n11 $n12 $n21 $n22 $m11 $m12 $m21 $m22
             $npp $np1 $np2 $n2p $n1p $errorCodeNumber
             $errorMessage);

$VERSION = '0.97';


=item getValues() -This method calls the
computeObservedValues() and the computeExpectedValues() methods to
compute the observed and marginal total values. It checks these values
for any errors that might cause the Fishers Exact test measures to
fail.

INPUT PARAMS  : $count_values       .. Reference of an array containing
                                       the count values computed by the
                                       count.pl program.

RETURN VALUES : 1/undef           ..returns '1' to indicate success
                                    and an undefined(NULL) value to indicate
                                    failure.

=cut

sub getValues
{
  my $values = shift;

  # computes and returns the marginal totals from the frequency
  # combination values. returns undef if there is an error in
  # the computation or the values are inconsistent.
  if(!(Text::NSP::Measures::2D::computeMarginalTotals($values)) ){
    return;
  }

  # computes and returns the observed and marginal values from
  # the frequency combination values. returns 0 if there is an
  # error in the computation or the values are inconsistent.
  if( !(Text::NSP::Measures::2D::computeObservedValues($values)) ) {
      return;
  }

  return 1;
}


=item computeDistribution() - This method calculates the probabilities
                              for all the possible tables

INPUT PARAMS  : $n11_start          .. the value for the cell 1,1 in the first contingency
                                       table
                $final_limit        .. the value of cell 1,1 in the last contingency table
                                       for which we have to compute the probability.

RETURN VALUES : $probability        .. Reference to a hash containing hypergeometric
                                       probabilities for all the possible contingency
                                       tables

=cut

sub computeDistribution
{
  my $n11_start = shift @_;
  my $final_limit = shift @_;

  # first sort the numerator array in the descending order.
  my @numerator = sort { $b <=> $a } ($n1p, $np1, $n2p, $np2);

  # initialize the hash to store the probability distribution values.
  my %probability = ();

  # declare some temporary variables for use in loops and computing the values.
  my $i;
  my $j=0;

  # initialize the product variable to be used in the probability computation.
  my $product = 0;

  # set the values for the first contingency table.
  $n11 = $n11_start;
  $n12 = $n1p-$n11;
  $n21 = $np1-$n11;
  $n22 = $n2p - $n21;

  while($n22 < 0)
  {
    $n11++;
    $n12 = $n1p - $n11;
    $n21 = $np1 - $n11;
    $n22 = $n2p - $n21;
  }

  # declare the denominator array.
  my @denominator = ();

  $product = 0;

  my $prob = 0;

  $i = $n11;
  $n12 = $n1p - $i;
  $n21 = $np1 - $i;
  $n22 = $n2p - $n21;

  # initialize the denominator array with values sorted in the descending order.
  @denominator = sort { $b <=> $a } ($npp, $n22, $n12, $n21, $i);

  #decalare other variables for use in computation.
  my @dLimits = ();
  my @nLimits = ();
  my $dIndex = 0;
  my $nIndex = 0;

  # set the dLimits and nLimits arrays to be used in the cancellation of factorials
  # and to be used in the computation of factorial.
  # the dLimits and the nLimits allow us to cancel out factorials in the numerator
  # and the denominator. for example:
  #       6!        1*2*3*4*5*6
  #      ---  =  ---------------  =  5*6
  #       4!          1*2*3*4
  #
  # we achieve this by defining a range within which all the
  # nos must be multiplied. So every pair of entries in the nLimits array defines a range
  # so for the above case the entries would be:
  #     5,6
  #
  for ( $j = 0; $j < 4; $j++ )
  {
    if ( $numerator[$j] > $denominator[$j] )
    {
      $nLimits[$nIndex] = $denominator[$j] + 1;
      $nLimits[$nIndex+1] = $numerator[$j];
      $nIndex += 2;
    }
    elsif ( $denominator[$j] > $numerator[$j] )
    {
      $dLimits[$dIndex] = $numerator[$j] + 1;
      $dLimits[$dIndex+1] = $denominator[$j];
      $dIndex += 2;
    }
  }
  $dLimits[$dIndex] = 1;
  $dLimits[$dIndex+1] = $denominator[4];

  # since, all the variables have been initialized, we start the computations.
  $product = computeHyperGeometric(\@dLimits, \@nLimits);
  $probability{$i} = $product;
  $prob = $probability{$i};

  # to reduce the no. of computations and the make the measure more efficient
  # we use the previous tables probabilities to compute the new tables probabilities
  # we can do this because the counts in the table will change by only a factor of 1
  # thus instead of repeating all those multiplications we have to perform only
  # 4 multiplications.
  my $subproduct = 0;

  for ($i = $n11+1; $i <= $final_limit; $i++ )
  {
    $subproduct += log $n12;
    $n22++;
    $subproduct -= log $n22;
    $subproduct += log $n21;
    $n12--;
    $n21--;
    $subproduct -= log $i;
    $probability{$i} = $product+$subproduct;
    if($probability{$i} != 0)
    {
      $product = $product+$subproduct;
      $subproduct=0;
    }
  }


  return (\%probability);
}



sub computeHyperGeometric
{
  my $dLimits = shift @_;
  my $nLimits = shift @_;
  my $product = 0;

  # compute the probability now, since all the variables have been initialized.
  while ( defined ( $nLimits->[0] ) )
  {
    while ( defined ( $nLimits->[0] ) )
    {
      $product += log $nLimits->[0];
      $nLimits->[0]++;
      if ( $nLimits->[0] > $nLimits->[1] )
      {
        shift @{$nLimits};
        shift @{$nLimits};
      }
    }
    while ( defined ( $dLimits->[0] ) )
    {
      $product -= log $dLimits->[0];
      $dLimits->[0]++;
      if ( $dLimits->[0] > $dLimits->[1] )
      {
        shift @{$dLimits};
        shift @{$dLimits};
      }
    }
  }
  return  $product;
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

Last updated: $Id: Fisher.pm,v 1.21 2008/03/26 17:18:26 tpederse Exp $

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