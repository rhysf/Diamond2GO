=head1 NAME

Text::NSP::Measures::3D::MI::tmi - Perl implementation for True Mutual
                                   Information for trigrams.

=head1 SYNOPSIS

=head3 Basic Usage

  use Text::NSP::Measures::3D::MI::tmi;

  $tmi_value = calculateStatistic( n111=>10,
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
    print getStatisticName."value for bigram is ".$tmi_value."\n";
  }

=head1 DESCRIPTION

True Mutual Information (tmi) is defined as the weighted average of the
pointwise mutual informations for all the observed and expected value pairs.

 tmi = [n111/nppp * log(n111/m111) + n112/nppp * log(n112/m112) +
        n121/nppp * log(n121/m121) + n122/nppp * log(n122/m122) +
        n211/nppp * log(n211/m211) + n212/nppp * log(n212/m212) +
        n221/nppp * log(n221/m221) + n222/nppp * log(n222/m222)]

 PMI =   log (n111/m111)

Here n111 represents the observed value for the cell (1,1,1) and m111
represents the expected value for that cell. The expected values for
the internal cells are calculated by taking the product of their
associated marginals and dividing by the sample size, for example:

            n1pp * np1p * npp1
   m111=   --------------------
                   nppp

=head2 Methods

=over

=cut


package Text::NSP::Measures::3D::MI::tmi;


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


=item calculateStatistic($count_values) - This method calculates
the tmi value

INPUT PARAMS  : $count_values   .. Reference of an hash containing
                                   the count values computed by the
                                   count.pl program.

RETURN VALUES : $tmi            .. TMI value for this trigram.

=cut

sub calculateStatistic
{
  my %values = @_;

  # computes and returns the observed and expected values from
  # the frequency combination values. returns 0 if there is an
  # error in the computation or the values are inconsistent.
  if( !(Text::NSP::Measures::3D::MI::getValues(\%values)) ) {
    return(0);
  }

  #my $marginals = $self->computeMarginalTotals(@_);

  #  Now for the actual calculation of TMI!
  my $tmi = 0;

  # dont want ($nxy / $mxy) to be 0 or less! flag error if so!
  $tmi += $n111/$nppp * Text::NSP::Measures::3D::MI::computePMI( $n111, $m111 )/ log 2;
  $tmi += $n112/$nppp * Text::NSP::Measures::3D::MI::computePMI( $n112, $m112 )/ log 2;
  $tmi += $n121/$nppp * Text::NSP::Measures::3D::MI::computePMI( $n121, $m121 )/ log 2;
  $tmi += $n122/$nppp * Text::NSP::Measures::3D::MI::computePMI( $n122, $m122 )/ log 2;
  $tmi += $n211/$nppp * Text::NSP::Measures::3D::MI::computePMI( $n211, $m211 )/ log 2;
  $tmi += $n212/$nppp * Text::NSP::Measures::3D::MI::computePMI( $n212, $m212 )/ log 2;
  $tmi += $n221/$nppp * Text::NSP::Measures::3D::MI::computePMI( $n221, $m221 )/ log 2;
  $tmi += $n222/$nppp * Text::NSP::Measures::3D::MI::computePMI( $n222, $m222 )/ log 2;

  return ($tmi);
}


=item getStatisticName() - Returns the name of this statistic

INPUT PARAMS  : none

RETURN VALUES : $name      .. Name of the measure.

=cut

sub getStatisticName
{
    return "True Mutual Information";
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

Last updated: $Id: tmi.pm,v 1.10 2006/06/21 11:10:53 saiyam_kohli Exp $

=head1 BUGS


=head1 SEE ALSO

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