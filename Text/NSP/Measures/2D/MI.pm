=head1 NAME

Text::NSP::Measures::2D::MI - Perl module that provides error checks
                              for Loglikelihood, Total Mutual
                              Information, Pointwise Mutual Information
                              and Poisson-Stirling Measure.

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

This module is the base class for the Loglikelihood, Total Mutual
Information and the Pointwise Mutual Information measures. All these
measure are similar. This module provides error checks specific for
these measures, it also implements the computations that are common
to these measures.

=over

=item Log-Likelihood measure is computed as

Log-Likelihood = 2 * [n11 * log(n11/m11) + n12 * log(n12/m12) +
                 n21 * log(n21/m21) + n22 * log(n22/m22)]

=item Total Mutual Information

TMI =   (1/npp)*[n11 * log(n11/m11)/log 2 + n12 * log(n12/m12)/log 2 +
                 n21 * log(n21/m21)/log 2 + n22 * log(n22/m22)/log 2]

=item Pointwise Mutual Information

PMI =   log (n11/m11)/log 2

=item Poisson Stirling Measures

PS =   n11*(log (n11/m11)-1)

=back

All these methods use the ratio of the observed values to expected values,
for computations, and thus have common error checks, so they have been grouped
together.

=head2 Methods

=over

=cut


package Text::NSP::Measures::2D::MI;


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
             $errorCodeNumber $errorMessage
             $n11 $n12 $n21 $n22 $m11 $m12 $m21 $m22
             $npp $np1 $np2 $n2p $n1p);

$VERSION = '1.03';


=item getValues() - This method calls the computeMarginalTotals(),
computeObservedValues() and the computeExpectedValues() methods to
compute the observed and expected values. It checks these values for
any errors that might cause the Loglikelihood, TMI & PMI measures to
fail.


INPUT PARAMS  : $count_values           .. Reference of an hash containing
                                           the count values computed by the
                                           count.pl program.


RETURN VALUES : 1/undef           ..returns '1' to indicate success
                                    and an undefined(NULL) value to indicate
                                    failure.

=cut

sub getValues
{
  my ($values)=@_;

  if(!(Text::NSP::Measures::2D::computeMarginalTotals($values)) ){
    return;
  }

  if( !(Text::NSP::Measures::2D::computeObservedValues($values)) ) {
      return;
  }

  if( !(Text::NSP::Measures::2D::computeExpectedValues($values)) ) {
      return;
  }

  # dont want ($nxy / $mxy) to be 0 or less! flag error if so and return;
  if ( $n11 )
  {
    if ($m11 == 0)
    {
      $errorMessage = "Expected value in cell (1,1) must not be zero";
      $errorCodeNumber = 211;
      return;
    }
  }
  if ( $n12 )
  {
    if ($m12 == 0)
    {
      $errorMessage = "Expected value in cell (1,2) must not be zero";
      $errorCodeNumber = 211;
      return;
    }
  }
  if ( $n21 )
  {
    if ($m21 == 0)
    {
      $errorMessage = "Expected value in cell (2,1) must not be zero";
      $errorCodeNumber = 211;
      return;
    }
  }
  if ( $n22 )
  {
    if ($m22 == 0)
    {
      $errorMessage = "Expected value in cell (2,2) must not be zero";
      $errorCodeNumber = 211;
      return;
    }
  }
  if ($m11 < 0)
  {
    $errorMessage = "Expected value for cell (1,1) should not be negative";
    $errorCodeNumber = 212;
    return;
  }
  if ($m12 < 0)
  {
    $errorMessage = "Expected value for cell (1,2) should not be negative";
    $errorCodeNumber = 212;
    return;
  }
  if ($m21 < 0)
  {
    $errorMessage = "Expected value for cell (2,1) should not be negative";
    $errorCodeNumber = 212;
    return;
  }
  if ($m22 < 0)
  {
    $errorMessage = "Expected value for cell (2,2) should not be negative";
    $errorCodeNumber = 212;
    return;
  }

  #  Everything looks good so we can return 1
  return 1;
}




=item computePMI() - Computes the pmi of a given observed and expected
value pair.

INPUT PARAMS  : $n         ..Observed value
                $m         ..Expected value

RETURN VALUES : log(n/m)   ..the log of the ratio of
                             observed value to expected
                             value.

=cut

sub computePMI
{
  my $n = shift;
  my $m = shift;
  if($n)
  {
    my $val = $n/$m;
    return log($val);
  }
  else
  {
    return 0;
  }
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

Last updated: $Id: MI.pm,v 1.27 2008/03/26 17:18:26 tpederse Exp $

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