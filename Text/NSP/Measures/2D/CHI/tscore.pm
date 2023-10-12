=head1 NAME

Text::NSP::Measures::2D::CHI::tscore  - Perl module that implements T-score
                                        measure of association for bigrams.


=head1 SYNOPSIS

=head3 Basic Usage

  use Text::NSP::Measures::2D::CHI::tscore;

  my $npp = 60; my $n1p = 20; my $np1 = 20;  my $n11 = 10;

  $tscore_value = calculateStatistic( n11=>$n11,
                                      n1p=>$n1p,
                                      np1=>$np1,
                                      npp=>$npp);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $errorCode." - ".getErrorMessage()."\n"";
  }
  else
  {
    print getStatisticName."value for bigram is ".$tscore_value."\n"";
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

The T-score is defined as a ratio of difference between the observed
and the expected mean to the variance of the sample. Note that this
is a variant of the standard t-test that was proposed for use in the
identification of collocations in large samples of text.

Thus, the T-score is defined as follows:

    m11 = n1p * np1 / npp

    T-score = (n11 - m11)/sqrt(n11)

=over

=cut


package Text::NSP::Measures::2D::CHI::tscore;


use Text::NSP::Measures::2D::CHI;
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


=item calculateStatistic() - method to calculate the tscore Coefficient

INPUT PARAMS  : $count_values       .. Reference of an hash containing
                                       the count values computed by the
                                       count.pl program.

RETURN VALUES : $tscore             .. tscore value for this bigram.

=cut

sub calculateStatistic
{
  my %values = @_;

  # computes and returns the observed and expected values from
  # the frequency combination values. returns 0 if there is an
  # error in the computation or the values are inconsistent.
  if( !(Text::NSP::Measures::2D::CHI::getValues(\%values)) ) {
    return;
  }
  #  Now calculate the tscore

  my $tscore = (($n11-$m11)/($n11**0.5));

  return ( $tscore );
}



=item getStatisticName() - Returns the name of this statistic

INPUT PARAMS  : none

RETURN VALUES : $name      .. Name of the measure.

=cut

sub getStatisticName
{
  return "T-score";
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

Last updated: $Id: tscore.pm,v 1.11 2006/06/21 11:10:52 saiyam_kohli Exp $

=head1 BUGS


=head1 SEE ALSO

  @incollection {ChurchGHH91,
          author={Church, K. and Gale, W. and Hanks, P. and Hindle, D. },
          title={Using Statistics in Lexical Analysis},
          booktitle={Lexical Acquisition: Exploiting On-Line Resources
                      to Build a Lexicon},
          editor={Zernik, U.},
          year={1991},
          address={Hillsdale, NJ},
          publisher={Lawrence Erlbaum Associates}
          url = L<http://www.patrickhanks.com/papers/usingStats.pdf>}

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