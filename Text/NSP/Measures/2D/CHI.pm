=head1 NAME

Text::NSP::Measures::2D::CHI - Perl module that provides error checks
                               for the Pearson's chi squared, phi coefficient
                               and the Tscore measures.

=head1 SYNOPSIS

=head3 Basic Usage

  use Text::NSP::Measures::2D::CHI::x2;

  my $npp = 60; my $n1p = 20; my $np1 = 20;  my $n11 = 10;

  $x2_value = calculateStatistic( n11=>$n11,
                                      n1p=>$n1p,
                                      np1=>$np1,
                                      npp=>$npp);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $errorCode." - ".getErrorMessage()."\n"";
  }
  else
  {
    print getStatisticName."value for bigram is ".$x2_value."\n"";
  }

=head1 DESCRIPTION

This module is the base class for the Chi-squared and Phi coefficient
measures. This module provides error checks specific for these measures,
it also implements the computations that are common to these measures.

=over

=item Pearson's Chi-Squared

  x2 = 2 * [((n11 - m11)/m11)^2 + ((n12 - m12)/m12)^2 +
           ((n21 - m21)/m21)^2 + ((n22 -m22)/m22)^2]

=item Phi Coefficient

 PHI^2 = ((n11 * n22) - (n21 * n21))^2/(n1p * np1 * np2 * n2p)

=item T-Score

 tscore = (n11 - m11)/sqrt(n11)

=back

Note that the value of PHI^2 is equivalent to
Pearson's Chi-Squared test multiplied by the sample size, that is:

 Chi-Squared = npp * PHI^2

 Although T-score seems quite different from the other two measures we
 have put it in the CHI family because like the other two measures it
 uses the difference between the observed and expected values and is also
 quite similar in ranking the bigrams.

=over

=cut


package Text::NSP::Measures::2D::CHI;


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

$VERSION = '1.03';

=item getValues() - This method calls the computeMarginalTotals(),
computeObservedValues() and the computeExpectedValues() methods to
compute the observed and expected values. It checks thees values for
any errors that might cause the PHI and x2 measures to fail.

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

  if(!(Text::NSP::Measures::2D::computeMarginalTotals($values)) ) {
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
      $errorCodeNumber = 221;
      return;
    }
  }
  if ( $n12 )
  {
    if ($m12 == 0)
    {
      $errorMessage = "Expected value in cell (1,2) must not be zero";
      $errorCodeNumber = 221;
      return;
    }
  }
  if ( $n21 )
  {
    if ($m21 == 0)
    {
      $errorMessage = "Expected value in cell (2,1) must not be zero";
      $errorCodeNumber = 221;
      return;
    }
  }
  if ( $n22 )
  {
    if ($m22 == 0)
    {
      $errorMessage = "Expected value in cell (2,2) must not be zero";
      $errorCodeNumber = 221;
      return;
    }
  }
  #  Everything looks good so we can return 1
  return 1;
}




=item computeVal() - Computes the deviation in observed value with respect
to the expected values

INPUT PARAMS  : $n         ..Observed value
                $m         ..Expected value

RETURN VALUES : (n-m)^2/m  ..the log of the ratio of
                             observed value to expected
                             value.

=cut

sub computeVal
{
  my $n = shift;
  my $m = shift;
  if($m)
  {
    return (($n-$m)**2)/$m;
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

Last updated: $Id: CHI.pm,v 1.14 2008/03/26 17:18:26 tpederse Exp $

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