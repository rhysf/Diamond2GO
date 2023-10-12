=head1 NAME

Text::NSP::Measures::2D::Fisher::twotailed - Perl module implementation of the two-sided
                                             Fisher's exact test.

=head1 SYNOPSIS

=head3 Basic Usage

  use Text::NSP::Measures::2D::Fisher::twotailed;

  my $npp = 60; my $n1p = 20; my $np1 = 20;  my $n11 = 10;

  $twotailed_value = calculateStatistic( n11=>$n11,
                                      n1p=>$n1p,
                                      np1=>$np1,
                                      npp=>$npp);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $errorCode." - ".getErrorMessage();
  }
  else
  {
    print getStatisticName."value for bigram is ".$twotailed_value;
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

The fishers exact tests are calculated by fixing the marginal totals
and computing the hypergeometric probabilities for all the possible
contingency tables,

A twotailed fishers test is calculated by adding the probabilities of
all the contingency tables with probabilities less than the probability
of the observed table. The twotailed fishers test tells us how likely
it would be to observe an contingency table which is less probable than
the current table.

=head2 Methods

=over

=cut

package Text::NSP::Measures::2D::Fisher::twotailed;


use Text::NSP::Measures::2D::Fisher;
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


=item calculateStatistic() - This method calculates the twotailed
Fisher value

INPUT PARAMS  : $count_values       .. Reference of an array containing
                                       the count values computed by the
                                       count.pl program.

RETURN VALUES : $twotailed          .. Twotailed Fisher value.

=cut

sub calculateStatistic
{
  my %values = @_;

  my $probabilities;

  # computes and returns the observed and marginal values from
  # the frequency combination values. returns 0 if there is an
  # error in the computation or the values are inconsistent.
  if( !(Text::NSP::Measures::2D::Fisher::getValues(\%values)) )
  {
    return;
  }

  my $final_limit = ($n1p < $np1) ? $n1p : $np1;

  my $n11_org = $n11;
  my $n11_start = $n1p + $np1 - $npp;
  if($n11_start<0)
  {
    $n11_start = 0;
  }

  if( !($probabilities = Text::NSP::Measures::2D::Fisher::computeDistribution($n11_start, $final_limit)))
  {
      return;
  }

  my $value;

  my $ttfisher=0;

  foreach $value (sort { $a <=> $b } values %$probabilities)
  {
    if($value > $probabilities->{$n11_org})
    {
      next;
    }
    $ttfisher += exp($value);
  }

  return $ttfisher;
}


=item getStatisticName() - Returns the name of this statistic

INPUT PARAMS  : none

RETURN VALUES : $name      .. Name of the measure.

=cut

sub getStatisticName
{
    return "Two Tailed Fisher";
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

Last updated: $Id: twotailed.pm,v 1.13 2008/03/26 17:21:19 tpederse Exp $

=head1 BUGS


=head1 SEE ALSO

  @inproceedings{Pedersen96,
          author = {Pedersen, T.},
          title = {Fishing For Exactness},
          booktitle = {Proceedings of the South Central SAS User's
                      Group (SCSUG-96) Conference},
          year = {1996},
          pages = {188--200},
          month ={October},
          address = {Austin, TX}
          url = L<http://www.d.umn.edu/~tpederse/pubs.html>}

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