=head1 NAME

Text::NSP::Measures::4D::MI - Perl module that provides error checks and
                              framework to implement Loglikelihood
                              for 4-grams.

=head1 SYNOPSIS

=head3 Basic Usage

  use Text::NSP::Measures::4D::MI::ll;

  $ll_value = calculateStatistic( 
                                  n1111=>8,
                                  n1ppp=>306,
                                  np1pp=>83,
                                  npp1p=>83,
                                  nppp1=>57,
                                  n11pp=>8,
                                  n1p1p=>8,
                                  n1pp1=>8,
                                  np11p=>83,
                                  np1p1=>56,
                                  npp11=>56,
                                  n111p=>8,
                                  n11p1=>8,
                                  n1p11=>8,
                                  np111=>56,
                                  npppp=>15180);

  if( ($errorCode = getErrorCode()))
  {
    print STDERR $erroCode." - ".getErrorMessage()."\n";
  }
  else
  {
    print getStatisticName."value for 4-gram is ".$ll_value."\n";
  }

=head1 DESCRIPTION

This module is the base class for the Loglikelihood and the True Mutual
Information measures. All these measure are similar. This module provides
error checks specific for these measures, it also implements the
computations that are common to these measures.

=over

=item Log-Likelihood measure is computed as
 Log-Likelihood = 2 * [n1111 * log ( n1111 / m1111 ) + n1112 * log ( n1112 / m1112 ) + 
                       n1121 * log ( n1121 / m1121 ) + n1122 * log ( n1122 / m1122 ) + 
                       n1211 * log ( n1211 / m1211 ) + n1212 * log ( n1212 / m1212 ) + 
                       n1221 * log ( n1221 / m1221 ) + n1222 * log ( n1222 / m1222 ) + 
                       n2111 * log ( n2111 / m2111 ) + n2112 * log ( n2112 / m2112 ) + 
                       n2121 * log ( n2121 / m2121 ) + n2122 * log ( n2122 / m2122 ) + 
                       n2211 * log ( n2211 / m2211 ) + n2212 * log ( n2212 / m2212 ) + 
                       n2221 * log ( n2221 / m2221 ) + n2222 * log ( n2222 / m2222 )];
  

=back

All these methods use the ratio of the observed values to expected values,
for computations, and thus have common error checks, so they have been grouped
together.

=head2 Methods

=over

=cut


package Text::NSP::Measures::4D::MI;

 
use Text::NSP::Measures::4D;
use strict;
use Carp;
use warnings;
require Exporter;

our ($VERSION, @EXPORT, @ISA);

@ISA  = qw(Exporter);

@EXPORT = qw(initializeStatistic calculateStatistic
             getErrorCode getErrorMessage getStatisticName
             $n1111 $n1112 $n1121 $n1122 $n1211 $n1212 $n1221 $n1222 
	     $n2111 $n2112 $n2121 $n2122 $n2211 $n2212 $n2221 $n2222
             $m1111 $m1112 $m1121 $m1122 $m1211 $m1212 $m1221 $m1222 
	     $m2111 $m2112 $m2121 $m2122 $m2211 $m2212 $m2221 $m2222
             $nppp1 $npp1p $npp11 $np1pp $np1p1 $np11p $np111 $n1ppp
             $n1pp1 $n1p1p $n1p11 $n11pp $n11p1 $n111p $npppp
             $nppp2 $npp2p $npp22 $np2pp $np2p2 $np22p $np222 $n2ppp
             $n2pp2 $n2p2p $n2p22 $n22pp $n22p2 $n222p
             $np112 $np121 $np122 $np211 $np212 $np221
             $errorCodeNumber $errorMessage
             getValues computePMI);

$VERSION = '1.03';


=item getValues($count_values) - This method calls
computeMarginalTotals the computeObservedValues() and
the computeExpectedValues() methods to compute the
observed and expected values. It checks these values
for any errors that might cause the Loglikelihood,
TMI and PMI measures to fail.

INPUT PARAMS  : $count_values           .. Reference of an hash containing
                                           the count values computed by the
                                           count.pl program.

RETURN VALUES : 1/undef           ..returns '1' to indicate success
                                    and an undefined(NULL) value to indicate
                                    failure.

=cut

sub getValues
{
  my ($values)=@_;

  if( !(Text::NSP::Measures::4D::computeObservedValues($values)) ) {
      return;
  }
  
  if( !(Text::NSP::Measures::4D::computeMarginalTotals($values)) ) {
      return;
  }
  
  if( !(Text::NSP::Measures::4D::computeExpectedValues($values)) ) {
      return; 
  }

   # dont want ($n1111 / $m1111) to be 0 or less! flag error if so!
    if ( $n1111 )  
    { 
	if ($m1111 == 0) {
	    $errorMessage = "Expected value in cell (1,1,1,1) must not be zero";
	    $errorCodeNumber = 231;  return;
	}

	if (($n1111 / $m1111)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (1,1,1,1)";
	    $errorCodeNumber = 232;  return;
	}
    }

    # dont want ($n1112 / $m1112) to be 0 or less! flag error if so!
    if ( $n1112 )  
    { 
	if ($m1112 == 0) {
	    $errorMessage = "Expected value in cell (1,1,1,2) must not be zero";
	    $errorCodeNumber = 233;  return;
	}

	if (($n1112 / $m1112)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (1,1,1,2)";
	    $errorCodeNumber = 234;  return;
	}
    }

    # dont want ($n1121 / $m1121) to be 0 or less! flag error if so!
    if ( $n1121 )  
    { 
	if ($m1121 == 0) {
	    $errorMessage = "Expected value in cell (1,1,2,1) must not be zero";
	    $errorCodeNumber = 235;  return;
	}

	if (($n1121 / $m1121)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (1,1,2,1)";
	    $errorCodeNumber = 236;  return;
	}
    }


    # dont want ($n1122 / $m1122) to be 0 or less! flag error if so!
    if ( $n1122 )  
    { 
	if ($m1122 == 0) {
	    $errorMessage = "Expected value in cell (1,1,2,2) must not be zero";
	    $errorCodeNumber = 237;  return;
	}

	if (($n1122 / $m1122)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (1,1,2,2)";
	    $errorCodeNumber = 238;  return;
	}
    }

    # dont want ($n1211 / $m1211) to be 0 or less! flag error if so!
    if ( $n1211 )  
    { 
	if ($m1211 == 0) {
	    $errorMessage = "Expected value in cell (1,2,1,1) must not be zero";
	    $errorCodeNumber = 239;  return;
	}

	if (($n1211 / $m1211)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (1,2,1,1)";
	    $errorCodeNumber = 240;  return;
	}
    }

    # dont want ($n1212 / $m1212) to be 0 or less! flag error if so!
    if ( $n1212 )  
    { 
	if ($m1212 == 0) {
	    $errorMessage = "Expected value in cell (1,2,1,2) must not be zero";
	    $errorCodeNumber = 241;  return;
	}

	if (($n1212 / $m1212)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (1,2,1,2)";
	    $errorCodeNumber = 242;  return;
	}
    }

    # dont want ($n1221 / $m1221) to be 0 or less! flag error if so!
    if ( $n1221 )  
    { 
	if ($m1221 == 0) {
	    $errorMessage = "Expected value in cell (1,2,2,1) must not be zero";
	    $errorCodeNumber = 243;  return;
	}

	if (($n1221 / $m1221)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (1,2,2,1)";
	    $errorCodeNumber = 244;  return;
	}
    }

    # dont want ($n1222 / $m1222) to be 0 or less! flag error if so!
    if ( $n1222 )  
    { 
	if ($m1222 == 0) {
	    $errorMessage = "Expected value in cell (1,2,2,2) must not be zero";
	    $errorCodeNumber = 245;  return;
	}

	if (($n1222 / $m1222)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (1,2,2,2)";
	    $errorCodeNumber = 246;  return;
	}
    }

    # dont want ($n2111 / $m2111) to be 0 or less! flag error if so!
    if ( $n2111 )  
    { 
	if ($m2111 == 0) {
	    $errorMessage = "Expected value in cell (2,1,1,1) must not be zero";
	    $errorCodeNumber = 247;  return;
	}

	if (($n2111 / $m2111)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (2,1,1,1)";
	    $errorCodeNumber = 248;  return;
	}
    }

    # dont want ($n2112 / $m2112) to be 0 or less! flag error if so!
    if ( $n2112 )  
    { 
	if ($m2112 == 0) {
	    $errorMessage = "Expected value in cell (2,1,1,2) must not be zero";
	    $errorCodeNumber = 249;  return;
	}

	if (($n2112 / $m2112)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (2,1,1,2)";
	    $errorCodeNumber = 250;  return;
	}
    }

    # dont want ($n2121 / $m2121) to be 0 or less! flag error if so!
    if ( $n2121 )  
    { 
	if ($m2121 == 0) {
	    $errorMessage = "Expected value in cell (2,1,2,1) must not be zero";
	    $errorCodeNumber = 251;  return;
	}

	if (($n2121 / $m2121)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (2,1,2,1)";
	    $errorCodeNumber = 252;  return;
	}
    }

    # dont want ($n2122 / $m2122) to be 0 or less! flag error if so!
    if ( $n2122 )  
    { 
	if ($m2122 == 0) {
	    $errorMessage = "Expected value in cell (2,1,2,2) must not be zero";
	    $errorCodeNumber = 253;  return;
	}

	if (($n2122 / $m2122)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (2,1,2,2)";
	    $errorCodeNumber = 254;  return;
	}
    }

    # dont want ($n2211 / $m2211) to be 0 or less! flag error if so!
    if ( $n2211 )  
    { 
	if ($m2211 == 0) {
	    $errorMessage = "Expected value in cell (2,2,1,1) must not be zero";
	    $errorCodeNumber = 255;  return;
	}

	if (($n2211 / $m2211)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (2,2,1,1)";
	    $errorCodeNumber = 256;  return;
	}
    }

    # dont want ($n1111 / $m1111) to be 0 or less! flag error if so!
    if ( $n2212 )  
    { 
	if ($m2212 == 0) {
	    $errorMessage = "Expected value in cell (2,2,1,2) must not be zero";
	    $errorCodeNumber = 257;  return;
	}

	if (($n2212 / $m2212)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (2,2,1,2)";
	    $errorCodeNumber = 258;  return;
	}
    }

    # dont want ($n2221 / $m2221) to be 0 or less! flag error if so!
    if ( $n2221 )  
    { 
	if ($m2221 == 0) {
	    $errorMessage = "Expected value in cell (2,2,2,1) must not be zero";
	    $errorCodeNumber = 259;  return;
	}

	if (($n2221 / $m2221)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (2,2,2,1)";
	    $errorCodeNumber = 260;  return;
	}
    }

    # dont want ($n2222 / $m2222) to be 0 or less! flag error if so!
    if ( $n2222 )  
    { 
	if ($m2222 == 0) {
	    $errorMessage = "Expected value in cell (2,2,2,2) must not be zero";
	    $errorCodeNumber = 261;  return;
	}

	if (($n2222 / $m2222)  <= 0) {
	    $errorMessage = "About to take log of negative value for cell (2,2,2,2)";
	    $errorCodeNumber = 262;  return;
	}
    }

  #  Everything looks good so we can return 1
  return 1;
}



=item computePMI($n, $m) - Computes the pmi of a given
observed and expected value pair.

INPUT PARAMS  : $n       ..Observed value
                $m       ..Expected value

RETURN VALUES : lognm   .. the log of the ratio of
                           observed value to expected
                           value.

=cut

sub computePMI
{
    my $n = shift;
    my $m = shift;
    if($n)
    {
	my $val = $n/$m;

	return log($val);
    }
    else
    {
	return 0;
    }
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
                             E<lt>bthomson@d.umn.eduE<gt>

Saiyam Kohli,                University of Minnesota Duluth
                             E<lt>kohli003@d.umn.eduE<gt>

=head1 HISTORY

Last updated: $Id: MI.pm,v 1.3 2011/12/23 22:25:05 btmcinnes Exp $

=head1 BUGS


=head1 SEE ALSO

L<http://groups.yahoo.com/group/ngram/>

L<http://www.d.umn.edu/~tpederse/nsp.html>


=head1 COPYRIGHT

Copyright (C) 2000-2011, Ted Pedersen, Satanjeev Banerjee, Amruta
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
