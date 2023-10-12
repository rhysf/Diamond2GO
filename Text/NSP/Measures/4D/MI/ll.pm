=head1 NAME

Text::NSP::Measures::4D::MI::ll - Perl module that implements Loglikelihood
                                  measure of association for 4-grams.

=head1 SYNOPSIS

=head3 Basic Usage
 use Text::NSP::Measures::4D::MI::ll;

  $ll_value = calculateStatistic( 
                                  n1111=>8,
                                  n1ppp=>306,
                                  np1pp=>83,
                                  npp1p=>83,
                                  nppp1=>57,
                                  n11pp=>8,
                                  n1p1p=>8,
                                  n1pp1=>8,
                                  np11p=>83,
                                  np1p1=>56,
                                  npp11=>56,
                                  n111p=>8,
                                  n11p1=>8,
                                  n1p11=>8,
                                  np111=>56,
                                  npppp=>15180);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $erroCode." - ".getErrorMessage()."\n";
  }
  else
  {
    print getStatisticName."value for 4-gram is ".$ll_value."\n";
  }

=head1 DESCRIPTION

The log-likelihood ratio measures the devitation between the observed data
and what would be expected if <word1>, <word2>, <word3>  and <word4> were 
independent.The higher the score, the less evidence there is in favor of 
concluding thatthe words are independent.

The expected values for the internal cells are calculated by taking the
product of their associated marginals and dividing by the sample size,
for example:

            n1ppp * np1pp * npp1p * nppp1
   m111=   -------------------------------
                       npppp ^ 3

Then the deviation between observed and expected values for each internal
cell is computed to arrive at the log-likelihood value.

  Log-Likelihood = 2 * [n1111 * log ( n1111 / m1111 ) + n1112 * log ( n1112 / m1112 ) + 
                       n1121 * log ( n1121 / m1121 ) + n1122 * log ( n1122 / m1122 ) + 
                       n1211 * log ( n1211 / m1211 ) + n1212 * log ( n1212 / m1212 ) + 
                       n1221 * log ( n1221 / m1221 ) + n1222 * log ( n1222 / m1222 ) + 
                       n2111 * log ( n2111 / m2111 ) + n2112 * log ( n2112 / m2112 ) + 
                       n2121 * log ( n2121 / m2121 ) + n2122 * log ( n2122 / m2122 ) + 
                       n2211 * log ( n2211 / m2211 ) + n2212 * log ( n2212 / m2212 ) + 
                       n2221 * log ( n2221 / m2221 ) + n2222 * log ( n2222 / m2222 )];
  
=head2 Methods

=over

=cut


package Text::NSP::Measures::4D::MI::ll;


use Text::NSP::Measures::4D::MI;
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

=item calculateStatistic($count_values) - This method calculates
the ll value

INPUT PARAMS  : $count_values       .. Reference of an hash containing
                                       the count values computed by the
                                       count.pl program.

RETURN VALUES : $loglikelihood      .. Loglikelihood value for this 4-gram.

=cut

sub calculateStatistic
{
  my %values = @_;

  # computes and sets the observed and expected values from
  # the frequency combination values. returns 0 if there is an
  # error in the computation or the values are inconsistent.
  if( !(Text::NSP::Measures::4D::MI::getValues(\%values)) ) {
    return;
  }

  #  Now for the actual calculation of Loglikelihood!
  my $logLikelihood = 0;

   
  # dont want ($nxy / $mxy) to be 0 or less! flag error if so!
  $logLikelihood += $n1111 * Text::NSP::Measures::4D::MI::computePMI ( $n1111, $m1111 );
  $logLikelihood += $n1112 * Text::NSP::Measures::4D::MI::computePMI ( $n1112, $m1112 );
  $logLikelihood += $n1121 * Text::NSP::Measures::4D::MI::computePMI ( $n1121, $m1121 );
  $logLikelihood += $n1122 * Text::NSP::Measures::4D::MI::computePMI ( $n1122, $m1122 );
  $logLikelihood += $n1211 * Text::NSP::Measures::4D::MI::computePMI ( $n1211, $m1211 );
  $logLikelihood += $n1212 * Text::NSP::Measures::4D::MI::computePMI ( $n1212, $m1212 );
  $logLikelihood += $n1221 * Text::NSP::Measures::4D::MI::computePMI ( $n1221, $m1221 );
  $logLikelihood += $n1222 * Text::NSP::Measures::4D::MI::computePMI ( $n1222, $m1222 );
  $logLikelihood += $n2111 * Text::NSP::Measures::4D::MI::computePMI ( $n2111, $m2111 );
  $logLikelihood += $n2112 * Text::NSP::Measures::4D::MI::computePMI ( $n2112, $m2112 );
  $logLikelihood += $n2121 * Text::NSP::Measures::4D::MI::computePMI ( $n2121, $m2121 );
  $logLikelihood += $n2122 * Text::NSP::Measures::4D::MI::computePMI ( $n2122, $m2122 );
  $logLikelihood += $n2211 * Text::NSP::Measures::4D::MI::computePMI ( $n2211, $m2211 );
  $logLikelihood += $n2212 * Text::NSP::Measures::4D::MI::computePMI ( $n2212, $m2212 );
  $logLikelihood += $n2221 * Text::NSP::Measures::4D::MI::computePMI ( $n2221, $m2221 );
  $logLikelihood += $n2222 * Text::NSP::Measures::4D::MI::computePMI ( $n2222, $m2222 ); 
  return ( 2 * $logLikelihood );
}


=item getStatisticName() - Returns the name of this statistic

INPUT PARAMS  : none

RETURN VALUES : $name      .. Name of the measure.

=cut

sub getStatisticName
{
    return "Loglikelihood";
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
                             E<lt>bthomson@cs.umn.eduE<gt>

Saiyam Kohli,                University of Minnesota Duluth
                             E<lt>kohli003@d.umn.eduE<gt>

=head1 HISTORY

Last updated: $Id: ll.pm,v 1.1 2008/11/22 18:53:13 btmcinnes Exp $

=head1 BUGS


=head1 SEE ALSO

  @article{Dunning93,
            author = {Dunning, T.},
            title = {Accurate Methods for the Statistics of
          Surprise and Coincidence},
            journal = {Computational Linguistics},
            volume = {19},
            number = {1},
            year = {1993},
            pages = {61-74}
            url = L<http://www.comp.lancs.ac.uk/ucrel/papers/tedstats.pdf>}

  @inproceedings{moore:2004:EMNLP,
                author    = {Moore, Robert C.},
                title     = {On Log-Likelihood-Ratios and the Significance of Rare
              Events },
                booktitle = {Proceedings of EMNLP 2004},
                editor = {Dekang Lin and Dekai Wu},
                year      = 2004,
                month     = {July},
                address   = {Barcelona, Spain},
                publisher = {Association for Computational Linguistics},
                pages     = {333--340}
                url = L<http://acl.ldc.upenn.edu/acl2004/emnlp/pdf/Moore.pdf>}

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
