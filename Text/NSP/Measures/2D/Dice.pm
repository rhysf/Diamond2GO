=head1 NAME

Text::NSP::Measures::2D::Dice  - Perl module that provides the
                                framework to implement the Dice and
                                Jaccard coefficients.

=head1 SYNOPSIS

=head3 Basic Usage

  use Text::NSP::Measures::2D::Dice::dice;

  my $npp = 60; my $n1p = 20; my $np1 = 20;  my $n11 = 10;

  $dice_value = calculateStatistic( n11=>$n11,
                                      n1p=>$n1p,
                                      np1=>$np1,
                                      npp=>$npp);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $errorCode." - ".getErrorMessage()."\n"";
  }
  else
  {
    print getStatisticName."value for bigram is ".$dice_value."\n"";
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

=over

=item The Dice Coefficient is defined as :

     2 * n11
    ---------
    np1 + n1p

=item The Jaccard coefficient is defined as:

          n11
    ---------------
    n11 + n12 + n21

=back

=head2 Methods

=over

=cut


package Text::NSP::Measures::2D::Dice;


use Text::NSP::Measures::2D;
use strict;
use Carp;
use warnings;
# use subs(calculateStatistic);
require Exporter;

our ($VERSION, @EXPORT, @ISA);

@ISA  = qw(Exporter);

@EXPORT = qw(initializeStatistic calculateStatistic
             getErrorCode getErrorMessage getStatisticName);

$VERSION = '0.97';

=item computeVal() - method to calculate the dice coefficient value

INPUT PARAMS  : $count_values       .. Reference of an hash containing
                                       the count values computed by the
                                       count.pl program.

RETURN VALUES : $dice               .. Dice Coefficient value for this bigram.

=cut

sub computeVal
{
  my $values = shift;

  # computes and returns the marginal totals from the frequency
  # combination values. returns undef if there is an error in
  # the computation or the values are inconsistent.
  if(!(Text::NSP::Measures::2D::computeMarginalTotals($values)) ){
    return;
  }

  # computes and returns the observed from the frequency
  # combination values. returns undef if there is an error in
  # the computation or the values are inconsistent.
  if( !(Text::NSP::Measures::2D::computeObservedValues($values)) ) {
      return;
  }

  my $dice = 2 * $n11 / ($n1p + $np1);

  return ($dice);
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

Last updated: $Id: Dice.pm,v 1.6 2006/06/21 11:10:52 saiyam_kohli Exp $

=head1 BUGS


=head1 SEE ALSO

@article{SmadjaMH96,
        author = {Smadja, F. and McKeown, K. and Hatzivassiloglou, V.},
        title = {Translating Collocations for Bilingual Lexicons: A
                 Statistical Approach},
        journal = {Computational Linguistics},
        volume = {22},
        number = {1},
        year = {1996},
        pages = {1-38}
        url = L<http://www.cs.mu.oz.au/acl/J/J96/J96-1001.pdf>}

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