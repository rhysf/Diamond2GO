=head1 NAME

Text::NSP::Measures::3D::MI::pmi - Perl module that implements Pointwise
                                   Mutual Information for trigrams.

=head1 SYNOPSIS

=head3 Basic Usage

  use Text::NSP::Measures::3D::MI::pmi;

  $pmi_value = calculateStatistic( n111=>10,
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
    print getStatisticName."value for bigram is ".$pmi_value."\n";
  }


=head1 DESCRIPTION

The expected values for the internal cells are calculated by taking the
product of their associated marginals and dividing by the sample size,
for example:

            n1pp * np1p * npp1
   m111=   --------------------
              nppp * nppp

Pointwise Mutual Information (pmi) is defined as the log of the devitation
between the observed frequency of a trigram (n111) and the probability of
that trigram if it were independent (m111).

 PMI =   log (n111/m111)

=head2 Methods

=over

=cut


package Text::NSP::Measures::3D::MI::pmi;


use Text::NSP::Measures::3D::MI;
use strict;
use Carp;
use warnings;
no warnings 'redefine';
require Exporter;

our ($VERSION, @EXPORT, @ISA, $exp);

$exp=1;

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

RETURN VALUES : $pmi                .. PMI value for this trigram.

=cut

sub calculateStatistic
{
  my %values = @_;

  # computes and sets the observed and expected values from
  # the frequency combination values. returns 0 if there is an
  # error in the computation or the values are inconsistent.
  if( !(Text::NSP::Measures::3D::MI::getValues(\%values)) ) {
    return(0);
  }

  #  Now the calculations!
  my $pmi = Text::NSP::Measures::3D::MI::computePMI($n111**$exp, $m111);

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

Last updated: $Id: pmi.pm,v 1.9 2009/11/03 14:53:55 tpederse Exp $

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
