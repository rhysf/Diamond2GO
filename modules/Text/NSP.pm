=head1 NAME

Text::NSP - Extract collocations and Ngrams from text

=head1 SYNOPSIS

=head2 Basic Usage

  use Text::NSP::Measures::2D::MI::ll;

  my $npp = 60; my $n1p = 20; my $np1 = 20;  my $n11 = 10;

  $ll_value = calculateStatistic( n11=>$n11,
                                      n1p=>$n1p,
                                      np1=>$np1,
                                      npp=>$npp);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $errorCode." - ".getErrorMessage()."\n"";
  }
  else
  {
    print getStatisticName."value for bigram is ".$ll_value."\n"";
  }

=head1 DESCRIPTION

The Ngram Statistics Package (NSP) is a collection of perl modules
that aid in analyzing Ngrams in text files. We define an Ngram as a
sequence of 'n' tokens that occur within a window of at least 'n'
tokens in the text; what constitutes a "token" can be defined by the
user.

NSP.pm is a stub that doesn't have any real functionality. It serves
as a top level module in the hierarchy and allows us to group the
Text::NSP::Count and Text::NSP::Measures modules.

The modules under Text::NSP::Measures implement measures of
association that are used to evaluate whether the co-occurrence of the
words in a Ngram is purely by chance or statistically significant.
These measures compute a numerical score for Ngrams. This score can be
used to decide whether or not there is enough evidence to reject the
null hypothesis (that the Ngram is not statistically significant) for
that Ngram.

To use one of the measures you can either use the program statistic.pl
provided under the utils directory, or write your own driver program.
Program statistic.pl takes as input a list of Ngrams with their
frequencies (in the format output by count.pl) and runs a
user-selected statistical measure of association to compute the score
for each Ngram. The Ngrams, along with their scores, are output in
descending order of this score. For help on using utils/statistic.pl
please refer to its perldoc (perldoc utils/statistic.pl).

If you are writing your own driver program, a basic usage example is
provided above under SYNOPSIS. For further clarification please refer
to the documentation of Text::NSP::Measures (perldoc
Text::NSP::Measures).


=head2 Error Codes

The following table describes the error codes use in the
implementation,

Error codes common to all the association measures.

 100 - Trying to create an object of a abstract class.

 200 - one of the required values is missing.

 201 - one of the observed frequency comes out to be -ve.

 202 - one of the frequency values(n11) exceeds the total no of
       bigrams(npp) or a marginal total(n1p, np1).

 203 - one of the marginal totals(n1p, np1) exceeds the total bigram
       count(npp).

 204 - one of the marginal totals is -ve.

Error Codes required by the mutual information measures

 211 - one of the expected values is zero.

 212 - one of the expected values is -ve.


Error codes required by the CHI measures.

 221 - one of the expected values is zero.

=head2 Methods

=over

=cut

package Text::NSP;

use strict;
use Carp;
use warnings;

our ($VERSION, @ISA);

@ISA  = qw(Exporter);

$VERSION = '1.31';

1;

__END__


=back

=head1 AUTHORS

Ted Pedersen,                University of Minnesota Duluth
                             E<lt>tpederse at d.umn.eduE<gt>

Satanjeev Banerjee,          Carnegie Mellon University

Amruta Purandare,            University of Pittsburgh

Bridget Thomson-McInnes,     University of Minnesota Twin Cities

Saiyam Kohli,                University of Minnesota Duluth

=head1 HISTORY

Last updated: $Id: NSP.pm,v 1.44 2015/10/04 16:22:27 btmcinnes Exp $

=head1 BUGS

=head1 SEE ALSO

L<http://groups.yahoo.com/group/ngram/>

L<http://ngram.sourceforge.net>

=head1 COPYRIGHT

Copyright (C) 2000-2008, Ted Pedersen, Satanjeev Banerjee,
Amruta Purandare, Bridget Thomson-McInnes and Saiyam Kohli

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to

    The Free Software Foundation, Inc.,
    59 Temple Place - Suite 330,
    Boston, MA  02111-1307, USA.

Note: a copy of the GNU General Public License is available on the web
at L<http://www.gnu.org/licenses/gpl.txt> and is included in this
distribution as GPL.txt.

=cut
