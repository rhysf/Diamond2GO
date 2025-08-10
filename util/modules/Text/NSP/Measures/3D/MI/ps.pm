=head1 NAME

Text::NSP::Measures::3D::MI::ps - Perl module that implements
                                  Poisson Stirling Measure for trigrams.

=head1 SYNOPSIS

=head3 Basic Usage

  use Text::NSP::Measures::3D::MI::ps;

  $ps_value = calculateStatistic( n111=>10,
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
    print getStatisticName."value for bigram is ".$ps_value."\n";
  }


=head1 DESCRIPTION

The log-likelihood ratio measures the devitation between the observed data
and what would be expected if <word1>, <word2> and <word3> were independent.
The higher the score, the less evidence there is in favor of concluding that
the words are independent.

The expected values for the internal cells are calculated by taking the
product of their associated marginals and dividing by the sample size,
for example:

            n1pp * np1p * npp1
   m111=   --------------------
                   nppp

The poisson stirling measure is a negative lograthimic approximation
of the poisson-likelihood measure. It uses the stirlings firmula to
approximate the factorial in poisson-likelihood measure. It is
computed as follows:

Posson-Stirling = n111 * ( log(n111) - log(m111) - 1)

=head2 Methods

=over

=cut

package Text::NSP::Measures::3D::MI::ps;


use Text::NSP::Measures::3D::MI;
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

RETURN VALUES : $poissonStirling      .. Poisson-Stirling value for this trigram.

=cut

sub calculateStatistic
{
  my %values = @_;

  # computes and returns the observed and expected values from
  # the frequency combination values. returns 0 if there is an
  # error in the computation or the values are inconsistent.
  if( !(Text::NSP::Measures::3D::MI::getValues(\%values)) ) {
    return;
  }

  #  Now for the actual calculation of Loglikelihood!
  my $poissonStirling = 0;

  # dont want ($nxy / $mxy) to be 0 or less! flag error if so!
  $poissonStirling = $n111 * (Text::NSP::Measures::3D::MI::computePMI($n111, $m111) - 1);

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

Last updated: $Id: ps.pm,v 1.7 2006/06/21 11:10:53 saiyam_kohli Exp $

=head1 BUGS


=head1 SEE ALSO

  @inproceedings{ church89word,
      author = {Kenneth W. Church and Patrick Hanks},
      title = {Word association norms, mutual information, and Lexicography},
      booktitle = {Proceedings of the 27th. Annual Meeting of the Association for Computational Linguistics},
      publisher = {Association for Computational Linguistics},
      address = {Vancouver, B.C.},
      pages = {76--83},
      year = {1989},
      url = L<http://acl.ldc.upenn.edu/J/J90/J90-1003.pdf> }


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