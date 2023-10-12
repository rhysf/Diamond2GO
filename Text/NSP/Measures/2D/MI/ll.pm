=head1 NAME

Text::NSP::Measures::2D::MI::ll - Perl module that implements Loglikelihood
                                  measure of association for bigrams.

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
    print STDERR $errorCode." - ".getErrorMessage();
  }
  else
  {
    print getStatisticName."value for bigram is ".$ll_value;
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

Then the deviation between observed and expected values for each internal
cell is computed to arrive at the log-likelihood value.

 Log-Likelihood = 2 * [n11 * log(n11/m11) + n12 * log(n12/m12) +
           n21 * log(n21/m21) + n22 * log(n22/m22)]

=head2 Methods

=over

=cut


package Text::NSP::Measures::2D::MI::ll;


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

=item calculateStatistic() - This method calculates the ll value

INPUT PARAMS  : $count_values       .. Reference of an hash containing
                                       the count values computed by the
                                       count.pl program.

RETURN VALUES : $loglikelihood      .. Loglikelihood value for this bigram.

=cut

sub calculateStatistic
{
  my %values = @_;

  # computes and sets the observed and expected values from
  # the frequency combination values. returns 0 if there is an
  # error in the computation or the values are inconsistent.
  if( !Text::NSP::Measures::2D::MI::getValues(\%values) )
  {
    return;
  }

  #  Now for the actual calculation of Loglikelihood!
  my $logLikelihood = 0;

  # dont want ($nxy / $mxy) to be 0 or less! flag error if so!
  $logLikelihood += $n11 * Text::NSP::Measures::2D::MI::computePMI( $n11, $m11 );
  $logLikelihood += $n12 * Text::NSP::Measures::2D::MI::computePMI( $n12, $m12 );
  $logLikelihood += $n21 * Text::NSP::Measures::2D::MI::computePMI( $n21, $m21 );
  $logLikelihood += $n22 * Text::NSP::Measures::2D::MI::computePMI( $n22, $m22 );

  return ( 2 * $logLikelihood );
}


=item getStatisticName() - Returns the name of this statistic

INPUT PARAMS  : none

RETURN VALUES : $name      .. Name of the measure.

=cut

sub getStatisticName
{
    return "Log-likelihood";
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

Last updated: $Id: ll.pm,v 1.23 2008/03/26 17:20:27 tpederse Exp $

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