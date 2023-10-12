=head1 NAME

Text::NSP::Measures::2D::CHI::phi - Perl module that implements Phi coefficient
                                    measure for bigrams.

=head1 SYNOPSIS

=head3 Basic Usage

  use Text::NSP::Measures::2D::CHI::phi;

  my $npp = 60; my $n1p = 20; my $np1 = 20;  my $n11 = 10;

  $phi_value = calculateStatistic( n11=>$n11,
                                      n1p=>$n1p,
                                      np1=>$np1,
                                      npp=>$npp);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $errorCode." - ".getErrorMessage()."\n"";
  }
  else
  {
    print getStatisticName."value for bigram is ".$phi_value."\n"";
  }

=head1 DESCRIPTION

This function computes the the square of the traditional formulation of
the Phi Coefficient.

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

 PHI^2 = ((n11 * n22) - (n21 * n21))^2/(n1p * np1 * np2 * n2p)

Note that the value of PHI^2 is equivalent to
Pearson's Chi-Squared test multiplied by the sample size, that is:

 Chi-Squared = npp * PHI^2

We use PHI^2 rather than PHI since PHI^2 was employed for collocation
identification in:

Church, K. (1991) Concordances for Parallel Text, Seventh Annual
Conference of the UW Centre for the New OED and Text Research, Oxford,
England.

=over

=cut


package Text::NSP::Measures::2D::CHI::phi;


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


=item calculateStatistic() - method to calculate the Phi Coefficient

INPUT PARAMS  : $count_values       .. Reference of an hash containing
                                       the count values computed by the
                                       count.pl program.

RETURN VALUES : $phi                .. phi value for this bigram.

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

  #  Now calculate the phi coefficient
  my $phi = 0;

  $phi += Text::NSP::Measures::2D::CHI::computeVal($n11, $m11);
  $phi += Text::NSP::Measures::2D::CHI::computeVal($n12, $m12);
  $phi += Text::NSP::Measures::2D::CHI::computeVal($n21, $m21);
  $phi += Text::NSP::Measures::2D::CHI::computeVal($n22, $m22);

  return $phi/$values{npp};
}



=item getStatisticName() - Returns the name of this statistic

INPUT PARAMS  : none

RETURN VALUES : $name      .. Name of the measure.

=cut

sub getStatisticName
{
  return "Phi Coefficient";
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

Last updated: $Id: phi.pm,v 1.12 2006/06/21 11:10:52 saiyam_kohli Exp $

=head1 BUGS


=head1 SEE ALSO

  @inproceedings{GaleC91,
          author = {Gale, W. and Church, K.},
          title = {A Program for Aligning Sentences in Bilingual Corpora},
          booktitle = {Proceedings of the 29th Annual Meeting of the
                      Association for Computational Linguistics},
          address = {Berkeley, CA},
          year = {1991}
          url = L<http://www.cs.mu.oz.au/acl/J/J93/J93-1004.pdf>}


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