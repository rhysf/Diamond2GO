=head1 NAME

Text::NSP::Measures::2D::MI::ps - Perl module that implements Poisson-Stirling
                                  measure of association for bigrams.

=head1 SYNOPSIS

=head3 Basic Usage

  use Text::NSP::Measures::2D::MI::ps;

  my $npp = 60; my $n1p = 20; my $np1 = 20;  my $n11 = 10;

  $ps_value = calculateStatistic( n11=>$n11,
                                      n1p=>$n1p,
                                      np1=>$np1,
                                      npp=>$npp);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $errorCode." - ".getErrorMessage()."\n"";
  }
  else
  {
    print getStatisticName."value for bigram is ".$ps_value."\n"";
  }

=head1 DESCRIPTION

The log-likelihood ratio measures the deviation between the observed data
and what would be expected if <word1> and <word2> were independent. The
higher the score, the less evidence there is in favor of concluding that
the words are independent.

Assume that the frequency count data associated with a bigram
<word1><word2> as shown by a 2x2 contingency table:

          word2   ~word2
  word1    n11      n12 | n1p
 ~word1    n21      n22 | n2p
           --------------
           np1      np2   npp

where n11 is the number of times <word1><word2> occur together, and
n12 is the number of times <word1> occurs with some word other than
word2, and n1p is the number of times in total that word1 occurs as
the first word in a bigram.

The expected values for the internal cells are calculated by taking the
product of their associated marginals and dividing by the sample size,
for example:

          np1 * n1p
   m11=   ---------
            npp

The Poisson Stirling measure is a negative logarithmic approximation
of the Poisson-likelihood measure. It uses the Stirling's formula to
approximate the factorial in Poisson-likelihood measure.

Poisson-Stirling = n11 * ( log(n11) - log(m11) - 1)

which is same as

Poisson-Stirling = n11 * ( log(n11/m11) - 1)


=head2 Methods

=over

=cut


package Text::NSP::Measures::2D::MI::ps;


use Text::NSP::Measures::2D::MI;
use strict;
use Carp;
use warnings;
no warnings 'redefine';
require Exporter;

our ($VERSION, @EXPORT, @ISA);

@ISA  = qw(Exporter);

@EXPORT = qw(initializeStatistic calculateStatistic
             getErrorCode getErrorMessage getStatisticName);

$VERSION = '0.97';

=item calculateStatistic() - This method calculates the ps value

INPUT PARAMS  : $count_values       .. Reference of an hash containing
                                       the count values computed by the
                                       count.pl program.

RETURN VALUES : $poissonStirling      .. Poisson-Stirling value for this bigram.

=cut

sub calculateStatistic
{
  my %values = @_;

  # computes and returns the observed and expected values from
  # the frequency combination values. returns 0 if there is an
  # error in the computation or the values are inconsistent.
  if( !(Text::NSP::Measures::2D::MI::getValues(\%values)) ) {
    return;
  }

  #  Now for the actual calculation of Loglikelihood!
  my $poissonStirling = 0;

  # dont want ($nxy / $mxy) to be 0 or less! flag error if so!
  $poissonStirling = $n11 * (Text::NSP::Measures::2D::MI::computePMI($n11,$m11) - 1);

  return $poissonStirling;
}


=item getStatisticName() - Returns the name of this statistic

INPUT PARAMS  : none

RETURN VALUES : $name      .. Name of the measure.

=cut

sub getStatisticName
{
    return "Poisson-Stirling Measure";
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

Last updated: $Id: ps.pm,v 1.9 2008/03/26 17:20:28 tpederse Exp $

=head1 BUGS


=head1 SEE ALSO

L<http://groups.yahoo.com/group/ngram/>

L<http://www.d.umn.edu/~tpederse/nsp.html>

  @article{SmadjaMH96,
          author = {Quasthoff, Uwe and Wolff, Christian},
          title = {The Poisson collocation measure and its application},
          journal = {Workshop on Computational Approaches to Collocations},
          year = {2002},
          url = L<http://www.ofai.at/~brigitte.krenn/colloc02/PoissonCollocationMeasureQuasthoffWolff_final.pdf>}

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