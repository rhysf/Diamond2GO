=head1 NAME

Text::NSP::Measures::3D::MI - Perl module that provides error checks and
                              framework to implement Loglikelihood,
                              Total Mutual Information, Pointwise Mutual
                              Information and Poisson Stirling Measure
                              for trigrams.

=head1 SYNOPSIS

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
    print getStatisticName."value for trigram is ".$ll_value."\n";
  }

=head1 DESCRIPTION

This module is the base class for the Loglikelihood and the True Mutual
Information measures. All these measure are similar. This module provides
error checks specific for these measures, it also implements the
computations that are common to these measures.

=over

=item Log-Likelihood measure is computed as

 Log-Likelihood = 2 * [n111 * log(n111/m111) + n112 * log(n112/m112) +
           n121 * log(n121/m121) + n122 * log(n122/m122) +
           n211 * log(n211/m211) + n212 * log(n212/m212) +
           n221 * log(n221/m221) + n222 * log(n222/m222)]

=item Total Mutual Information

tmi = [n111/nppp * log(n111/m111) + n112/nppp * log(n112/m112) +
        n121/nppp * log(n121/m121) + n122/nppp * log(n122/m122) +
        n211/nppp * log(n211/m211) + n212/nppp * log(n212/m212) +
        n221/nppp * log(n221/m221) + n222/nppp * log(n222/m222)]

=item Pointwise Mutual Information

pmi =   log (n111/m111)

=item Poisson Stirling Measure

ps = n111 * ( log(n111/m111) - 1)

=back

All these methods use the ratio of the observed values to expected values,
for computations, and thus have common error checks, so they have been grouped
together.

=head2 Methods

=over

=cut


package Text::NSP::Measures::3D::MI;


use Text::NSP::Measures::3D;
use strict;
use Carp;
use warnings;
# use subs(calculateStatistic);
require Exporter;

our ($VERSION, @EXPORT, @ISA);

@ISA  = qw(Exporter);

@EXPORT = qw(initializeStatistic calculateStatistic
             getErrorCode getErrorMessage getStatisticName
             $n111 $n112 $n121 $n122 $n211 $n212 $n221 $n222
             $m111 $m112 $m121 $m122 $m211 $m212 $m221 $m222
             $nppp $n1pp $np1p $npp1 $n11p $n1p1 $np11 $n2pp
             $np2p $npp2 $errorCodeNumber $errorMessage
             getValues computePMI);


$VERSION = '1.03';


=item getValues($count_values) - This method calls
computeMarginalTotals the computeObservedValues() and
the computeExpectedValues() methods to compute the
observed and expected values. It checks these values
for any errors that might cause the Loglikelihood,
TMI and PMI measures to fail.

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

  if( !(Text::NSP::Measures::3D::computeMarginalTotals($values)) ) {
      return;
  }

  if( !(Text::NSP::Measures::3D::computeObservedValues($values)) ) {
      return;
  }

  if( !(Text::NSP::Measures::3D::computeExpectedValues($values)) ) {
      return;
  }

  # dont want ($nxy / $mxy) to be 0 or less! flag error if so and return;
  if ( $n111 )
  {
    if ($m111 == 0)
    {
      $errorMessage = "Expected value in cell (1,1,1) must not be zero";
      $errorCodeNumber = 211;
      return;
    }
  }
  if ( $n112 )
  {
    if ($m112 == 0)
    {
      $errorMessage = "Expected value in cell (1,1,2) must not be zero";
      $errorCodeNumber = 211;         return;
    }
  }
  if ( $n121 )
  {
    if ($m121 == 0)
    {
      $errorMessage = "Expected value in cell (1,2,1) must not be zero";
      $errorCodeNumber = 211;     return;
    }
  }
  if ( $n122 )
  {
    if ($m122 == 0)
    {
      $errorMessage = "Expected value in cell (1,2,2) must not be zero";
      $errorCodeNumber = 211;     return;
    }
  }
  if ( $n211 )
  {
    if ($m211 == 0)
    {
      $errorMessage = "Expected value in cell (2,1,1) must not be zero";
      $errorCodeNumber = 211;
      return;
    }
  }
  if ( $n212 )
  {
    if ($m212 == 0)
    {
      $errorMessage = "Expected value in cell (2,1,2) must not be zero";
      $errorCodeNumber = 211;         return;
    }
  }
  if ( $n221 )
  {
    if ($m221 == 0)
    {
      $errorMessage = "Expected value in cell (2,2,1) must not be zero";
      $errorCodeNumber = 211;     return;
    }
  }
  if ( $n222 )
  {
    if ($m222 == 0)
    {
      $errorMessage = "Expected value in cell (2,2,2) must not be zero";
      $errorCodeNumber = 211;
      return;
    }
  }

  if ($m111 < 0)
  {
    $errorMessage = "Expected Value for cell(1,1,1) should not be negative";
    $errorCodeNumber = 212;     return;
  }
  if ($m112 < 0)
  {
    $errorMessage = "Expected Value for cell (1,1,2) should not be negative";
    $errorCodeNumber = 212;     return;
  }
  if ($m121 < 0)
  {
    $errorMessage = "Expected Value for cell (1,2,1) should not be negative";
    $errorCodeNumber = 212;     return;
  }
  if ($m122 < 0)
  {
    $errorMessage = "Expected Value for cell (1,2,2) should not be negative";
    $errorCodeNumber = 212;     return;
  }
  if ($m211 < 0)
  {
    $errorMessage = "Expected Value for cell (2,1,1) should not be negative";
    $errorCodeNumber = 212;     return;
  }
  if ($m212 < 0)
  {
    $errorMessage = "Expected Value for cell (2,1,2) should not be negative";
    $errorCodeNumber = 212;     return;
  }
  if ($m221 < 0)
  {
    $errorMessage = "Expected Value for cell (2,2,1) should not be negative";
    $errorCodeNumber = 212;     return;
  }
  if ($m222 < 0)
  {
    $errorMessage = "Expected Value for cell (2,2,2) should not be negative";
    $errorCodeNumber = 212;     return;
  }

  #  Everything looks good so we can return 1
  return 1;
}



=item computePMI($n, $m) - Computes the pmi of a given
observed and expected value pair.

INPUT PARAMS  : $n       ..Observed value
                $m       ..Expected value

RETURN VALUES : lognm   .. the log of the ratio of
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
                             E<lt>bthomson@d.umn.eduE<gt>

Saiyam Kohli,                University of Minnesota Duluth
                             E<lt>kohli003@d.umn.eduE<gt>

=head1 HISTORY

Last updated: $Id: MI.pm,v 1.16 2011/12/23 22:25:05 btmcinnes Exp $

=head1 BUGS


=head1 SEE ALSO

L<http://groups.yahoo.com/group/ngram/>

L<http://www.d.umn.edu/~tpederse/nsp.html>


=head1 COPYRIGHT

Copyright (C) 2000-2011, Ted Pedersen, Satanjeev Banerjee, Amruta
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
