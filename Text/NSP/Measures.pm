package Text::NSP::Measures;

# moved this version information to the top of the file to avoid 
# confusion with the documentation below, that includes code examples 
# that set versions, etc.

use Text::NSP;
use strict;
use Carp;
use warnings;
require Exporter;

our ($VERSION, @ISA, @EXPORT, $errorCodeNumber, $errorMessage);

@ISA  = qw(Exporter);

@EXPORT = qw(initializeStatistic calculateStatistic
             getErrorCode getErrorMessage getStatisticName
             $errorCodeNumber $errorMessage);

$VERSION = '0.97';

=cut

=head1 NAME

Text::NSP::Measures - Perl modules for computing association scores of
                      Ngrams. This module provides the basic framework
                      for these measures.

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



=head2 Introduction

These modules provide perl implementations of mathematical functions
(association measures) that can be used to interpret the co-occurrence
frequency data for Ngrams. We define an Ngram as a sequence of 'n'
tokens that occur within a window of at least 'n' tokens in the text;
what constitutes a "token" can be defined by the user.

The measures that have been implemented in this distribution are:

=over

=item 1) MI (Mutual Information based Measures)

=over

=item a) Loglikelihood (for Bigrams and Trigrams)

=item b) True Mutual Information (for Bigrams and Trigrams)

=item c) Pointwise Mutual Information (for Bigrams and Trigrams)

=item d) Poisson Stirling Measure (for Bigrams and Trigrams)

=back

=item 2) CHI (Measures belonging to the CHI family)

=over

=item a) Chi-squared Measure

=item b) Phi Coefficient

=item c) T-Score

=back

=item 3) Dice (Measures belonging to the Dice family)

=over

=item a) Dice Coefficient

=item b) Jaccard Measure

=back

=item 4) Fishers Exact Tests

=over

=item a) Left Fishers Exact Test

=item b) Right Fishers Exact Test

=item c) Two-Tailed Fishers Exact Test

=back

=item 5) Odds Ratio

=back

Further discussion about these measures is in their respective
documentations.

=head2 Writing your own association measures

This module also provides a basic framework for building new measures
of association for Ngrams. The new Measure should either inherit from
Text::NSP::Measures::2D or Text::NSP::Measures::3D modules, depending
on whether it is a bigram or a trigram measure. Both these modules
implement methods that retrieve observed frequency counts, marginal
totals, and also compute expected values. They also provide error
checks for these counts.

You can either write your new measure as a new module, or you can
simply write a perl program. Here we will describe how to write a
new measure as a perl module Perl.

=over 4

=item 1


To create a new Perl module for the measure issue the following
command (replace 'NewMeasure' with the name of your measure):

=over

h2xs -AXc -n Text::NSP::Measures::2D::NewMeasure
(for bigram measures)

                      or

h2xs -AXc -n Text::NSP::Measures::3D::NewMeasure
(for trigram measures)

=back

This will create a new folder namely...

=over

Text-NSP-Measures-2D-NewMeasure (for bigram)

            or

Text-NSP-Measures-3D-NewMeasure (for trigram)

=back

This will create an empty framework for the new association measure.
Once you are done completing the changes you will have to install the
module before you can use it.

To make changes to the module open:

=over

Text-NSP-Measures-2D-NewMeasure/lib/Text/NSP/Measures/2D/NewMeasure/
NewMeasure.pm

                        or

Text-NSP-Measures-3D-NewMeasure/lib/Text/NSP/Measures/3D/NewMeasure/
NewMeasure.pm

=back

in your favorite text editor, and do as follows.

=item 2

Let us say you have named your module NewMeasure. The first line of
the file should declare that it is a package. Thus the first line of
the file NewMeasure.pm should be...

=over

package Text::NSP::Measures::2D::NewMeasure; (for bigram measures)

                  or

package Text::NSP::Measures::3D::NewMeasure; (for trigram measures)

=back

To inherit the functionality from the 2D or 3D module you need to
include it in your NewMeasure.pm module.

A small code snippet to ensure that it is included is as follows:

=over

=item 1 For Bigrams

use Text::NSP::Measures::2D::MI;

=item 2 For Trigrams

use Text::NSP::Measures::2D::MI;

=back

You also need to insert the following lines to make sure that the required
functions are visible to the programs using your module. These lines are
same for bigrams and trigrams. The "no warnings 'redefine';" statement is
used to suppress perl warnings about method overriding.

=over

use strict;
use Carp;
use warnings;
no warnings 'redefine';
require Exporter;

our ($VERSION, @EXPORT, @ISA);

@ISA  = qw(Exporter);

@EXPORT = qw(initializeStatistic calculateStatistic
             getErrorCode getErrorMessage getStatisticName);

=back

=item 3
You need to implement at least one method in your package

=over

=item i)  calculateStatistic()

=back

This method is passed reference to a hash containing the
frequency values for a Ngram as found in the input Ngram file.

method calculateStatistic() is expected to return a (possibly
floating point) value as the value of the statistical measure calculated
using the frequency values passed to it.

There exist three methods in the modules Text::NSP::Measures::2d and
Text::NSP::Measures::3D in order to help calculate the ngram
statistic.

=over

=item 1.  computeMarginalTotals($frequencies);

=item 2.  computeObservedValues($frequencies);

=item 3.  computeExpectedValues($frequencies);

=back

These methods return the observed and expected values of the cells in
the contingency table. A 2D contingency table looks like:

            |word2  | not-word2|
            --------------------
    word1   | n11   |   n12    |  n1p
  not-word1 | n21   |   n22    |  n2p
            --------------------
              np1       np2       npp

Here the marginal totals are np1, n1p, np2, n2p, the Observed values
are n11, n12, n21, n22 and the expected values for the corresponding
observed values are represented using m11, m12, m21, m22, here m11
represents the expected value for the cell (1,1), m12 for the cell
(1,2) and so on.

Before calling either computeObservedValues() or computeExpectedValues()
you MUST call computeMarginalTotals(), since these methods require the
marginal to be set. The computeMarginalTotals method computes the marginal
totals in the contingency table based on the observed frequencies. It
returns an undefined value in case of some error. In case success it
returns '1'. An example of usage for the computeMarginalTotals() method is

=over

my %values = @_;

if(!(Text::NSP::Measures::2D::computeMarginalTotals(\%values)) ){
  return;
}

=back

@_ is the parameters passed to calculateStatistic. After this call the
marginal totals will be available in the following variables

=over

=item 1. For bigrams
         $npp , $n1p, $np1, $n2p, $np2

=item 1. For trigrams
             $nppp, $n1pp, $np1p, $npp1, $n11p, $n1p1, $np11, $n2pp,
             $np2p, $npp2

=back

computeObservedValues() computes the observed values of a ngram, It can be
called using the following code snippet. Please remember that you should call
computeMarginalTotals() before calling computeObservedValues().

=over

  if( !(Text::NSP::Measures::2D::computeObservedValues(\%values)) ) {
      return;
  }

=back

%value is the same hash that was initialized earlier for computeMarginalTotals.

If successful it returns 1 otherwise an undefined value is returned. The
computed observed values will be available in the following variables:

=over

=item 1. For bigrams
         $n11 , $n12, $n21, $n22

=item 1. For trigrams
             $n111, $n112, $n121, $n122, $n211, $n212, $n221, $n222,

=back

Similarly, computeExpectedValues() computes the expected values for each of
the cells in the contingency table. You should call computeMarginalTotals()
before calling computeExpectedValues(). The following code snippet
demonstrates its usage.

=over

if( !(Text::NSP::Measures::2D::computeExpectedValues()) ) {
    return;
}

=back

If successful it returns 1 otherwise an undefined value is returned. The
computed expected values will be available in the following variables:

=over

=item 1. For bigrams
         $m11 , $m12, $m21, $m22

=item 1. For trigrams
             $m111, $m112, $m121, $m122, $m211, $m212, $m221, $m222,

=back

=item 4

The last lines of a module should always return true, to achieve this
make sure that the last two lines of the are:

  1;
  __END__

Please see, that you can put in documentation after these lines.

=item 5

There are four other methods that are not mandatory, but may be
implemented. These are:

     i) initializeStatistic()
    ii) getErrorCode
   iii) getErrorMessage
   iv) getStatisticName()

statistical.pl calls initializeStatistic before calling any
other method, if there is no need for any specific initialization
in the measure you need not define this method, and the
initialization will be handled by the Text::NSP::Measures modules
initializeStatistic() method.

The getErrorCode method is called immediately after every call to
method calculateStatistic(). This method is used to return the
errorCode, if any, in the previous operations. To view all the
possible error codes and the corresponding error message please refer
to the Text::NSP documentation (perldoc Text::NSP).You can create new
error codes in your measure, if the existing error codes are not
sufficient.

The Text::NSP::Measures module implements both getErrorCode()
and getErrorMessage() methods and these implementations of the method
will be invoked if the user does not define these methods. But if you
want to add some other actions that need to be performed in case
of an error you must override these methods by implementing them in
your module. You can invoke the Text::NSP::Measures getErrorCode()
methods from your measures getErrorCode() method.

An example of this is below:

  sub getErrorCode
  {
    my $code = Text::NSP::Measures::getErrorCode();

    #your code here

    return $code; #(or any other value)
  }

  sub getErrorMessage
  {
    my $message = Text::NSP::MeasuresgetErrorMessage();

    #your code here

    return $message; #(or any other value)
  }

The fourth method that may be implemented is getStatisticName().
If this method is implemented, it is expected to return a string
containing the name of the statistic being implemented. This string
is used in the formatted output of statistic.pl. If this method
is not implemented, then the statistic name entered on the
commandline is used in the formatted output.

Note that all the methods described in this section are optional.
So, if the user elects to not implement these methods, no harm will
be done.

The user may implement other methods too, but since statistic.pl is
not expecting anything besides the five methods above, doing so would
have no effect on statistic.pl.

=item 6

You will need to install your module before you can use it. You can do
this by

  Change to the base directory for the module, i.e.
  NewMeasure

  Then issue the following commands:

    perl Makefile.PL
    make
    make test
    make install

        or

    perl Makefile.PL PREFIX=<destination directory>
    make
    make test
    make install


If you get any errors in the installation process, please make sure
that you have not made any syntactical error in your code and also
make sure that you have already installed the Text-NSP package.

=back

=head2 An Example

To tie it all together here is an example of a measure that computes
the sum of ngram frequency counts.

=over

package Text::NSP::Measures::2D::sum;


use Text::NSP::Measures::2D::MI::2D;
use strict;
use Carp;
use warnings;
no warnings 'redefine';
require Exporter;

our ($VERSION, @EXPORT, @ISA);

@ISA  = qw(Exporter);

@EXPORT = qw(initializeStatistic calculateStatistic
             getErrorCode getErrorMessage getStatisticName);

$VERSION = '0.01';

sub calculateStatistic
{
  my %values = @_;

  # computes and returns the marginal totals from the frequency
  # combination values. returns undef if there is an error in
  # the computation or the values are inconsistent.
  if(!(Text::NSP::Measures::2D::computeMarginalTotals($values)) ){
    return;
  }

  # computes and returns the observed and marginal values from
  # the frequency combination values. returns 0 if there is an
  # error in the computation or the values are inconsistent.
  if( !(Text::NSP::Measures::2D::computeObservedValues($values)) ) {
      return;
  }


  #  Now for the actual calculation of the association measure
  my $NewMeasure = 0;

  $NewMeasure += $n11;
  $NewMeasure += $n12;
  $NewMeasure += $n21;
  $NewMeasure += $n22;

  return ( $NewMeasure );
}

sub getStatisticName
{
  return "Sum";
}

1;
__END__


=back

=head2 Errors to look out for:

=over 4

=item 1

The Text-NSP package is not installed - Make sure that Text-NSP
package is installed and you have inherited the correct module
(Text::NSP::Measures::2D or Text::NSP::Measures::3D).

=item 2

The five methods (1 mandatory, 4 non-mandatory) must have their
names match EXACTLY with those shown above. Again, names are all
case sensitive.

=item 3

This statement is present at the end of the module:
1;

=back

=head2 Methods

=over

=item initializeStatistic() - Provides an empty method which is called in case
                              the measures do not override this method. If you
                              need some measure specific initialization, override
                              this method in the implementation of your measure.

INPUT PARAMS  : none

RETURN VALUES : none

=cut

sub initializeStatistic
{
  undef $errorCodeNumber;
  undef $errorMessage;
}



=item calculateStatistic() - Provides an empty framework. Your Measure should
                             override this method.
INPUT PARAMS  : none

RETURN VALUES : none

=cut

sub calculateStatistic
{
  $errorMessage .= "Error calculateStatistic() - ";
  $errorMessage .= "Mandatory function calculateStatistic() not defined.\n";
  $errorMessage .= "Your implementation should override this method. Aborting....\n";
  $errorCodeNumber = 101;
}



=item getErrorCode() - Returns the error code in the last operation if
any and resets the errorCode to 0.

# INPUT PARAMS  : none

# RETURN VALUES : errorCode  .. The current error code.

=cut

sub getErrorCode
{
  my $temp = $errorCodeNumber;
  undef $errorCodeNumber;
  return $temp;
}



=item getErrorMessage() - Returns the error message in the last
operation if any and resets the string to ''.

# INPUT PARAMS  : none

# RETURN VALUES : errorMessage  .. The current error message.

=cut

sub getErrorMessage
{
  my $temp = $errorMessage;
  undef $errorMessage;
  return($temp);
}




=item getStatisticName() - Provides an empty method which is called in case
                              the measures do not override this method.

INPUT PARAMS  : none

RETURN VALUES : none

=cut

sub getStatisticName
{
    return;
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

Last updated: $Id: Measures.pm,v 1.15 2006/03/25 04:21:22 saiyam_kohli
Exp $

=head1 BUGS


=head1 SEE ALSO

L<http://groups.yahoo.com/group/Ngram/>

L<http://www.d.umn.edu/~tpederse/nsp.html>


=head1 COPYRIGHT

Copyright (C) 2000-2006, Ted Pedersen, Satanjeev Banerjee,
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
