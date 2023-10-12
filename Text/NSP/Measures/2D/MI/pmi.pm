=head1 NAME

Text::NSP::Measures::2D::MI::pmi - Perl module that implements Pointwise
                                   Mutual Information.

=head1 SYNOPSIS

=head3 Basic Usage

  use Text::NSP::Measures::2D::MI::pmi;

  my $npp = 60; my $n1p = 20; my $np1 = 20;  my $n11 = 10;

  $pmi_value = calculateStatistic( n11=>$n11,
                                      n1p=>$n1p,
                                      np1=>$np1,
                                      npp=>$npp);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $errorCode." - ".getErrorMessage()."\n"";
  }
  else
  {
    print getStatisticName."value for bigram is ".$pmi_value."\n"";
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

The expected values for the internal cells are calculated by taking the
product of their associated marginals and dividing by the sample size,
for example:

          np1 * n1p
   m11=   ---------
            npp

Pointwise Mutual Information (pmi) is defined as the log of the deviation
between the observed frequency of a bigram (n11) and the probability of
that bigram if it were independent (m11).

 PMI =   log (n11/m11)

 The Pointwise Mutual Information tends to overestimate bigrams with low
 observed frequency counts. To prevent this sometimes a variation of pmi
 is used which increases the influence of the observed frequency.

 PMI = log((n11^$exp)/m11)

 The $exp is 1 by default, so by default the measure will compute the
 Pointwise Mutual Information for the given bigram. To use a variation of
 the measure, users can pass the $exp parameter using the --pmi_exp
 command line option in statistic.pl or by passing the $exp to the
 initializeStatistic() method from their program.

 The usage for statistic.pl is

 statistic.pl pmi out_pmi.stt out.cnt    - for Point Wise Mutual Information
                                           $exp is 1 in this case.

 statistic.pl --pmi_exp 2 pmi out_pmi2.stt out.cnt   - for the variant with
                                                       $exp set to 2.

=head2 Methods

=over

=cut


package Text::NSP::Measures::2D::MI::pmi;


use Text::NSP::Measures::2D::MI;
use strict;
use Carp;
use warnings;
no warnings 'redefine';
require Exporter;

our ($VERSION, @EXPORT, @ISA, $exp);

$exp = 1;

@ISA  = qw(Exporter);

@EXPORT = qw(initializeStatistic calculateStatistic
             getErrorCode getErrorMessage getStatisticName);

$VERSION = '0.97';


=item initializeStatistic() -Initialization of the pmi_exp parameter if required

INPUT PARAMS  : none

RETURN VALUES : none

=cut

sub initializeStatistic
{
  $exp = shift;
}



=item calculateStatistic() - This method calculates the pmi value

INPUT PARAMS  : $count_values       .. Reference of a hash containing
                                       the count values computed by the
                                       count.pl program.

RETURN VALUES : $pmi                .. PMI value for this bigram.

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

  #  Now the calculations!
  my $pmi = Text::NSP::Measures::2D::MI::computePMI($n11**$exp,$m11);

  return($pmi/log(2));
}



=item getStatisticName() - Returns the name of this statistic

INPUT PARAMS  : none

RETURN VALUES : $name      .. Name of the measure.

=cut

sub getStatisticName
{
    return "Pointwise Mutual Information";
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

Last updated: $Id: pmi.pm,v 1.24 2008/03/26 17:20:28 tpederse Exp $

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