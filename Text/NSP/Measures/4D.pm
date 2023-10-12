=head1 NAME

Text::NSP::Measures::4D - Perl module that provides basic framework for
                          building measure of association for 4-grams.

=head1 SYNOPSIS

This module can be used as a foundation for building 4-dimensional
measures of association that can then be used by statistic.pl. In
particular this module provides methods that give convenient access to
4-d (i.e., 4-gram) frequency counts as created by count.pl, as well as
some degree of error handling that verifies the data.

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

The methods in this module retrieve observed 4-gram frequency counts and
marginal totals, and also compute expected values. They also provide
support for error checking of the output produced by count.pl. These
methods are used in all the 4-gram (4d) measure modules provided in NSP.
If you are writing your own 4d measure, you can use these methods as well.

With 4-gram or 4d measures we use a 4x4 contingency table to store the
frequency counts associated with each word in the trigram, as well as the
number of times the trigram occurs. The notation we employ is as follows:

Marginal Frequencies:
    
 n1ppp = the number of ngrams where the first word is word1.
 np1pp = the number of ngrams where the second word is word2.
 npp1p = the number of ngrams where the third word is word3
 nppp1 = the number of ngrams where the fourth word is word4
 n2ppp = the number of ngrams where the first word is not word1. 
 np2pp = the number of ngrams where the second word is not word2.
 npp2p = the number of ngrams where the third word is not word3.
 nppp2 = the number of ngrams where the fourth words is not word4

Observed Frequencies:

 n1111 = number of times word1, word2 and word3 occur together in
         their respective positions, joint frequency.
 n1112 = number of times word1, word 2 and word3 occur in their respective
         positions but word4 does not.
 n1121 = number of times word1, word2 and word4 occur in their respective
         positions but word3 does not.
 n1122 = number of times word1 and word2 occur in their repsective positions
         but word3 and word4 do not.
 n1211 = number of times word1, word3 and word4 occur in their respective 
         positions but word2 does not.
 n1212 = number of times word1 and word3 occur in their respective positions
         but word2 and word4 do not.
 n1221 = number of times word1 and word4 occur in their respective positions
         but word2 and word3 do not
 n1222 = number of times word1 occurs in its respective position but word2, 
         word3 and word4 do not.
 n2111 = number of times word2, word3 and word4 occur in their respective 
         positions but word1 does not.
 n2112 = number of times word2 and word3 occur in their respective positions
         but word1 and word4 do not.
 n2121 = number of times word2 and word4 occur in their respective positions
         but word1 and word3 do not.
 n2122 = number of times word2 occurs in its respective position but word1, 
         word3 and word4 do not.
 n2211 = number of times word3 and word4 occur in their respective positions
         but word1 and word2 do not.
 n2212 = number of times word3 occurs in its respective position but word1, 
         word2 and word4 do not.
 n2221 = number of times word4 occurs in its respective position but word1,
         word2, and word3 do not.
 n2222 = number of times neither word1, word2, word3 or word4 occur in their
         respective positions.

Expected Frequencies:

 m1111 = expected number of times word1, word2 and word3 occur together in
         their respective positions, joint frequency.
 m1112 = expected number of times word1, word 2 and word3 occur in their respective
         positions but word4 does not.
 m1121 = expected number of times word1, word2 and word4 occur in their respective
         positions but word3 does not.
 m1122 = expected number of times word1 and word2 occur in their repsective positions
         but word3 and word4 do not.
 m1211 = expected number of times word1, word3 and word4 occur in their respective 
         positions but word2 does not.
 m1212 = expected number of times word1 and word3 occur in their respective positions
         but word2 and word4 do not.
 m1221 = expected number of times word1 and word4 occur in their respective positions
         but word2 and word3 do not
 m1222 = expected number of times word1 occurs in its respective position but word2, 
         word3 and word4 do not.
 m2111 = expected number of times word2, word3 and word4 occur in their respective 
         positions but word1 does not.
 m2112 = expected number of times word2 and word3 occur in their respective positions
         but word1 and word4 do not.
 m2121 = expected number of times word2 and word4 occur in their respective positions
         but word1 and word3 do not.
 m2122 = expected number of times word2 occurs in its respective position but word1, 
         word3 and word4 do not.
 m2211 = expected number of times word3 and word4 occur in their respective positions
         but word1 and word2 do not.
 m2212 = expected number of times word3 occurs in its respective position but word1, 
         word2 and word4 do not.
 m2221 = expected number of times word4 occurs in its respective position but word1,
         word2, and word3 do not.
 m2222 = expected number of times neither word1, word2, word3 or word4 occur in their
         respective positions.
=head2 Methods

=over

=cut


package Text::NSP::Measures::4D;


use Text::NSP::Measures;
use strict;
use Carp;
use warnings;
require Exporter;


our ($VERSION, @ISA, $marginals, @EXPORT);
our ($n1111, $n1112, $n1121, $n1122, $n1211, $n1212, $n1221, $n1222);
our ($n2111, $n2112, $n2121, $n2122, $n2211, $n2212, $n2221, $n2222);
our ($m1111, $m1112, $m1121, $m1122, $m1211, $m1212, $m1221, $m1222);
our ($m2111, $m2112, $m2121, $m2122, $m2211, $m2212, $m2221, $m2222);
our ($nppp1, $npp1p, $npp11, $np1pp, $np1p1, $np11p, $np111, $n1ppp);
our ($n1pp1, $n1p1p, $n1p11, $n11pp, $n11p1, $n111p, $npppp);
our ($nppp2, $npp2p, $npp22, $np2pp, $np2p2, $np22p, $np222, $n2ppp);
our ($n2pp2, $n2p2p, $n2p22, $n22pp, $n22p2, $n222p);
our ($np112, $np121, $np122, $np211, $np212, $np221);
our ($expected_values);
our ($n2p1p, $n1p2p, $n2pp1, $n1pp2, $npp21, $npp12, $n21pp, $n12pp);
our ($n22p1, $n21p2, $n21p1, $n12p2, $n12p1, $n11p2, $n2p21, $n2p11);
our ($n2p12, $n1p22, $n1p21, $n1p12, $np21p, $np12p, $np2p1, $np1p2);
our ($n221p, $n212p, $n211p, $n122p, $n121p, $n112p);
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
             $np112 $np121 $np122 $np211 $np212 $np221 $expected_values 
             $errorCodeNumber $errorMessage);

$VERSION = '0.97';


=item computeObservedValues($count_values) - A method to
compute observed values, and also to verify that the
computed Observed values are correct, That is they are
positive, less than the marginal totals and the total
bigram count.

INPUT PARAMS  : $count_values     .. Reference to an hash consisting
                                     of the count values passed to
                                     the calculateStatistic() method.

RETURN VALUES : 1/undef           ..returns '1' to indicate success
                                    and an undefined(NULL) value to indicate
                                    failure.

=cut

sub computeObservedValues
{
  my ($values) = @_;

  $n1111=$values->{n1111};
  $n1ppp=$values->{n1ppp};
  $np1pp=$values->{np1pp};
  $npp1p=$values->{npp1p};
  $nppp1=$values->{nppp1};
  $n11pp=$values->{n11pp};
  $n1p1p=$values->{n1p1p};
  $n1pp1=$values->{n1pp1};
  $np11p=$values->{np11p};
  $np1p1=$values->{np1p1};
  $npp11=$values->{npp11};
  $n111p=$values->{n111p};
  $n11p1=$values->{n11p1};
  $n1p11=$values->{n1p11};
  $np111=$values->{np111};
  $npppp=$values->{npppp};

  #  we do not have the model fully implemented yet
  #$expected_values=$values->{expected_values};

  #  Check that all the values are defined
  if(!defined $values->{n1111})
  {
      $errorMessage = "Required 4-gram (1,1,1,1) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{n1ppp})
  {
      $errorMessage = "Required 4-gram (1,p,p,p) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{np1pp})
  {
      $errorMessage = "Required 4-gram (p,1,p,p) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{npp1p})
  {
      $errorMessage = "Required 4-gram (p,p,1,p) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{nppp1})
  {
      $errorMessage = "Required 4-gram (p,p,p,1) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{n11pp})
  {
      $errorMessage = "Required 4-gram (1,1,p,p) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{n1p1p})
  {
      $errorMessage = "Required 4-gram (1,p,1,p) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{n1pp1})
  {
      $errorMessage = "Required 4-gram (1,p,p,1) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{np11p})
  {
      $errorMessage = "Required 4-gram (p,1,1,p) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{np1p1})
  {
      $errorMessage = "Required 4-gram (p,1,p,1) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{npp11})
  {
      $errorMessage = "Required 4-gram (p,p,1,1) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{n111p})
  {
      $errorMessage = "Required 4-gram (1,1,1,p) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{n11p1})
  {
      $errorMessage = "Required 4-gram (1,1,p,1) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{n1p11})
  {
      $errorMessage = "Required 4-gram (1,p,1,1) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{np111})
  {
      $errorMessage = "Required 4-gram (p,1,1,1) not passed";
      $errorCodeNumber = 200;
      return;
  }
  if(!defined $values->{npppp})
  {
      $errorMessage = "Required 4-gram (p,p,p,p) not passed";
      $errorCodeNumber = 200;
      return;
  }

  # n1111 should be greater than equal to zero
  if ($n1111 <= 0)    {
      $errorMessage = "Frequency value ($n1111) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # n1111 frequency should be less than or equal to total 4grams
  if ($n1111 > $npppp) {
      $errorMessage = "Frequency value ($n1111) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }
  
  # joint frequency n1111 should be less than or equal to the marginal totals
  if ($n1111 > $n1ppp || $n1111 > $np1pp || $n1111 > $npp1p || $n1111 > $nppp1) {
      $errorMessage = "Frequency value of ngram ($n1111) must not exceed the marginal totals.";
      $errorCodeNumber = 202;  return;
  }

  # n1ppp should be greater than equal to zero
  if ($n1ppp <= 0)    {
      $errorMessage = "Frequency value ($n1ppp) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # n1ppp frequency should be less than or equal to total 4grams
  if ($n1ppp > $npppp) {
      $errorMessage = "Frequency value ($n1ppp) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # np1pp should be greater than equal to zero
  if ($np1pp <= 0)    {
      $errorMessage = "Frequency value ($np1pp) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # np1pp frequency should be less than or equal to total 4grams
  if ($np1pp > $npppp) {
      $errorMessage = "Frequency value ($np1pp) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # npp1p should be greater than equal to zero
  if ($npp1p <= 0)    {
      $errorMessage = "Frequency value ($npp1p) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # npp1p frequency should be less than or equal to total 4grams
  if ($npp1p > $npppp) {
      $errorMessage = "Frequency value ($npp1p) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # nppp1 should be greater than equal to zero
  if ($nppp1 <= 0)    {
      $errorMessage = "Frequency value ($nppp1) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # nppp1 frequency should be less than or equal to total 4grams
  if ($nppp1 > $npppp) {
      $errorMessage = "Frequency value ($nppp1) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # n11pp should be greater than equal to zero
  if ($n11pp <= 0)    {
      $errorMessage = "Frequency value ($n11pp) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # n11pp frequency should be less than or equal to total 4grams
  if ($n11pp > $npppp) {
      $errorMessage = "Frequency value ($n11pp) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # n1p1p should be greater than equal to zero
  if ($n1p1p <= 0)    {
      $errorMessage = "Frequency value ($n1p1p) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # n1p1p frequency should be less than or equal to total 4grams
  if ($n1p1p > $npppp) {
      $errorMessage = "Frequency value ($n1p1p) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # n1pp1 should be greater than equal to zero
  if ($n1pp1 <= 0)    {
      $errorMessage = "Frequency value ($n1pp1) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # n1pp1 frequency should be less than or equal to total 4grams
  if ($n1pp1 > $npppp) {
      $errorMessage = "Frequency value ($n1pp1) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # np11p should be greater than equal to zero
  if ($np11p <= 0)    {
      $errorMessage = "Frequency value ($np11p) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # np11p frequency should be less than or equal to total 4grams
  if ($np11p > $npppp) {
      $errorMessage = "Frequency value ($np11p) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # np1p1 should be greater than equal to zero
  if ($np1p1 <= 0)    {
      $errorMessage = "Frequency value ($np1p1) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # np1p1 frequency should be less than or equal to total 4grams
  if ($np1p1 > $npppp) {
      $errorMessage = "Frequency value ($np1p1) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # npp11 should be greater than equal to zero
  if ($npp11 <= 0)    {
      $errorMessage = "Frequency value ($npp11) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # npp11 frequency should be less than or equal to total 4grams
  if ($npp11 > $npppp) {
      $errorMessage = "Frequency value ($npp11) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # n111p should be greater than equal to zero
  if ($n111p <= 0)    {
      $errorMessage = "Frequency value ($n111p) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # n111p frequency should be less than or equal to total 4grams
  if ($n111p > $npppp) {
      $errorMessage = "Frequency value ($n111p) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # n11p1 should be greater than equal to zero
  if ($n11p1 <= 0)    {
      $errorMessage = "Frequency value ($n11p1) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # n11p1 frequency should be less than or equal to total 4grams
  if ($n11p1 > $npppp) {
      $errorMessage = "Frequency value ($n11p1) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # n1p11 should be greater than equal to zero
  if ($n1p11 <= 0)    {
      $errorMessage = "Frequency value ($n1p11) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # n1p11 frequency should be less than or equal to total 4grams
  if ($n1p11 > $npppp) {
      $errorMessage = "Frequency value ($n1p11) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }

  # np111 should be greater than equal to zero
  if ($np111 <= 0)    {
      $errorMessage = "Frequency value ($np111) must not be negative.";
      $errorCodeNumber = 201;  return;
  }
  
  # np111 frequency should be less than or equal to total 4grams
  if ($np111 > $npppp) {
      $errorMessage = "Frequency value ($np111) must not exceed total number of 4grams.";
      $errorCodeNumber = 201;  return;
  }


  #  observed
  $n1112=$n111p-$n1111;
  $n1121=$n11p1-$n1111;

    
  $n1122=$n11pp-$n1111-$n1121-$n1112;
  $n2111=$np111-$n1111; 

  $n1211=$n1p11-$n1111;
  $n1212=$n1p1p-$n1111-$n1112-$n1211;
  $n1221=$n1pp1-$n1111-$n1211-$n1121;
  $n1222=$n1ppp-$n1111-$n1211-$n1121-$n1112;
  
  $n2112=$np11p-$n1111-$n2111-$n1112;
  $n2121=$np1p1-$n1111-$n2111-$n1121;
  $n2122=$np1pp-$n1111-$n2111-$n1121-$n1112;
  $n2211=$npp11-$n1111-$n2111-$n1211;

  $n2212=$npp1p-$n1111-$n2111-$n1211-$n1112;

  $n2221=$nppp1-$n1111-$n2111-$n1211-$n1121;
  $n2222=$npppp-$n1111-$n2111-$n1211-$n1121-$n1112;
  
  
  # n1112 should be greater than equal to zero 
  if ($n1112 < 0)    {
      $errorMessage = "Frequency value n1112 ($n1112) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n1112 frequency should be less than or equal to total4grams
  if ($n1112 > $npppp) {
      $errorMessage = "Frequency value n1112 ($n1112) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }
  
  # n1121 should be greater than equal to zero
  if ($n1121 < 0)    {
      $errorMessage = "Frequency value n1121 ($n1121) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n1121 frequency should be less than or equal to total 4grams
  if ($n1121 > $npppp) {
      $errorMessage = "Frequency value n1121 ($n1121) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }

  # n1122 should be greater than equal to zero
  if ($n1122 < 0)    {
      $errorMessage = "Frequency value n1122 ($n1122) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n1122 frequency should be less than or equal to total 4grams
  if ($n1122 > $npppp) {
      $errorMessage = "Frequency value n1122 ($n1122) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }

  # n1211 should be greater than equal to zero
  if ($n1211 < 0)    {
      $errorMessage = "Frequency value n1211 ($n1211) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n1211 frequency should be less than or equal to total 4grams
  if ($n1211 > $npppp) {
      $errorMessage = "Frequency value n1211 ($n1211) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }

  # n1221 should be greater than equal to zero
  if ($n1221 < 0)    {
      $errorMessage = "Frequency value n1221 ($n1221) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n1221 frequency should be less than or equal to total 4grams
  if ($n1221 > $npppp) {
      $errorMessage = "Frequency value n1221 ($n1221) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }

  # n1222 should be greater than equal to zero
  if ($n1222 < 0)    {
      $errorMessage = "Frequency value n1222 ($n1222) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n1222 frequency should be less than or equal to total 4grams
  if ($n1222 > $npppp) {
      $errorMessage = "Frequency value n1222 ($n1222) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }

  # n2111 should be greater than equal to zero
  if ($n2111 < 0)    {
      $errorMessage = "Frequency value n2111 ($n2111) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n2111 frequency should be less than or equal to total 4grams
  if ($n2111 > $npppp) {
      $errorMessage = "Frequency value n2111 ($n2111) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }

  # n2112 should be greater than equal to zero
  if ($n2112 < 0)    {
      $errorMessage = "Frequency value n2112  ($n2112) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n2112 frequency should be less than or equal to total 4grams
  if ($n2112 > $npppp) {
      $errorMessage = "Frequency value n2112 ($n2112) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }

  # n2121 should be greater than equal to zero
  if ($n2121 < 0)    {
      $errorMessage = "Frequency value n2121 ($n2121) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n2121 frequency should be less than or equal to total 4grams
  if ($n2121 > $npppp) {
      $errorMessage = "Frequency value n2121 ($n2121) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }

  # n2122 should be greater than equal to zero
  if ($n2122 < 0)    {
      $errorMessage = "Frequency value n2122 ($n2122) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n2122 frequency should be less than or equal to total 4grams
  if ($n2122 > $npppp) {
      $errorMessage = "Frequency value n2122 ($n2122) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }


  # n2211 should be greater than equal to zero
  if ($n2211 < 0)    {
      $errorMessage = "Frequency value n2211 ($n2211) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n2211 frequency should be less than or equal to total 4grams
  if ($n2211 > $npppp) {
      $errorMessage = "Frequency value n2211 ($n2211) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }


  # n2212 should be greater than equal to zero
  if ($n2212 < 0)    {
      $errorMessage = "Frequency value n2212 ($n2212) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n2212 frequency should be less than or equal to total 4grams
  if ($n2212 > $npppp) {
      $errorMessage = "Frequency value n2212 ($n2212) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }

  # n2221 should be greater than equal to zero
  if ($n2221 < 0)    {
      $errorMessage = "Frequency value n2221 ($n2221) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n2221 frequency should be less than or equal to total 4grams
  if ($n2221 > $npppp) {
      $errorMessage = "Frequency value n2221 ($n2221) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }


  # n2222 should be greater than equal to zero
  if ($n2222 < 0)    {
      $errorMessage = "Frequency value n2222 ($n2222) must not be negative.";
      $errorCodeNumber = 202;  return;
  }
  
  # n2222 frequency should be less than or equal to total 4grams
  if ($n2222 > $npppp) {
      $errorMessage = "Frequency value n2222 ($n2222) must not exceed total number of 4grams.";
      $errorCodeNumber = 202;  return;
  }

  return 1;
}





=item computeExpectedValues($count_values) - A method to compute
expected values.

INPUT PARAMS  : $count_values     .. Reference to an hash consisting
                                     of the count output.

RETURN VALUES : 1/undef           ..returns '1' to indicate success
                                    and an undefined(NULL) value to indicate
                                    failure.

=cut

sub computeExpectedValues
{
    my ($values)=@_;

    if(! (defined $expected_values) ) {
	$expected_values = "0 1 2 3";
    }

    #  the expected values can be calculated based on 
    #  a number of different models. I have the code
    #  for the models here but we do not have the option
    #  to change them implemented in the statistic.pl 
    #  


    #  calculate the expected values for : "0 123" check
    if($expected_values eq "0 123") {	
	#print "0 123\n";
	
	$np111 = $n1111 + $n2111;
	$np112 = $n1112 + $n2112;
	$np121 = $n1121 + $n2121;
	$np122 = $n1122 + $n2122;
	$np211 = $n1211 + $n2211;
	$np212 = $n1212 + $n2212;
	$np221 = $n1221 + $n2221;
	$np222 = $n1222 + $n2222;

	$m1111=$n1ppp*$np111/($npppp);  
	$m1112=$n1ppp*$np112/($npppp);
	$m1121=$n1ppp*$np121/($npppp);
	$m1122=$n1ppp*$np122/($npppp);
	$m1211=$n1ppp*$np211/($npppp);
	$m1212=$n1ppp*$np212/($npppp);
	$m1221=$n1ppp*$np221/($npppp);
	$m1222=$n1ppp*$np222/($npppp);
	$m2111=$n2ppp*$np111/($npppp);  
	$m2112=$n2ppp*$np112/($npppp);
	$m2121=$n2ppp*$np121/($npppp);
	$m2122=$n2ppp*$np122/($npppp);
	$m2211=$n2ppp*$np211/($npppp);
	$m2212=$n2ppp*$np212/($npppp);
	$m2221=$n2ppp*$np221/($npppp);
	$m2222=$n2ppp*$np222/($npppp);
    }

    #  calculate the expected values for : "01 2 3" check
    elsif($expected_values eq "01 2 3") {
	#print "01 2 3\n";

	$n12pp = $n1211 + $n1212 + $n1221 + $n1222;
	$n21pp = $n2111 + $n2112 + $n2121 + $n2122;
	$n22pp = $n2211 + $n2212 + $n2221 + $n2222;
       
	$m1111=$n11pp*$npp1p*$nppp1/($npppp**2);
	$m1112=$n11pp*$npp1p*$nppp2/($npppp**2);
	$m1121=$n11pp*$npp2p*$nppp1/($npppp**2);
	$m1122=$n11pp*$npp2p*$nppp2/($npppp**2);
	$m1211=$n12pp*$npp1p*$nppp1/($npppp**2);
	$m1212=$n12pp*$npp1p*$nppp2/($npppp**2);
	$m1221=$n12pp*$npp2p*$nppp1/($npppp**2);
	$m1222=$n12pp*$npp2p*$nppp2/($npppp**2);
	$m2111=$n21pp*$npp1p*$nppp1/($npppp**2);
	$m2112=$n21pp*$npp1p*$nppp2/($npppp**2);
	$m2121=$n21pp*$npp2p*$nppp1/($npppp**2);
	$m2122=$n21pp*$npp2p*$nppp2/($npppp**2);
	$m2211=$n22pp*$npp1p*$nppp1/($npppp**2);
	$m2212=$n22pp*$npp1p*$nppp2/($npppp**2);
	$m2221=$n22pp*$npp2p*$nppp1/($npppp**2);
	$m2222=$n22pp*$npp2p*$nppp2/($npppp**2);
		
    }

    #  calculate the expected values for : "0 1 23" check
    elsif($expected_values eq "0 1 23") {	
	#print "0 1 23\n";
	
	$npp12 = $n1112 + $n1212 + $n2112 + $n2212;
	$npp21 = $n1121 + $n1221 + $n2121 + $n2221;
	$npp22 = $n1122 + $n1222 + $n2122 + $n2222;
	
	$m1111=$n1ppp*$np1pp*$npp11/($npppp**2);  
	$m1112=$n1ppp*$np1pp*$npp12/($npppp**2);  
	$m1121=$n1ppp*$np1pp*$npp21/($npppp**2);  
	$m1122=$n1ppp*$np1pp*$npp22/($npppp**2);
	$m1211=$n1ppp*$np2pp*$npp11/($npppp**2);
	$m1212=$n1ppp*$np2pp*$npp12/($npppp**2);  
	$m1221=$n1ppp*$np2pp*$npp21/($npppp**2);  
	$m1222=$n1ppp*$np2pp*$npp22/($npppp**2);
	$m2111=$n2ppp*$np1pp*$npp11/($npppp**2);
	$m2112=$n2ppp*$np1pp*$npp12/($npppp**2);  
	$m2121=$n2ppp*$np1pp*$npp21/($npppp**2);  
	$m2122=$n2ppp*$np1pp*$npp22/($npppp**2);
	$m2211=$n2ppp*$np2pp*$npp11/($npppp**2);
	$m2212=$n2ppp*$np2pp*$npp12/($npppp**2);  
	$m2221=$n2ppp*$np2pp*$npp21/($npppp**2);  
	$m2222=$n2ppp*$np2pp*$npp22/($npppp**2);
    }
    # calculate the expected values for : "0 12 3" check
    elsif($expected_values eq "0 12 3") {	
	#print "0 12 3\n";
	
	$np12p = $n1121 + $n1122 + $n2121 + $n2122;
	$np21p = $n1211 + $n1212 + $n2211 + $n2212;
	$np22p = $n1221 + $n1222 + $n2221 + $n2222;
	
	$m1111=$n1ppp*$np11p*$nppp1/($npppp**2);  
	$m1112=$n1ppp*$np11p*$nppp2/($npppp**2);
	$m1121=$n1ppp*$np12p*$nppp1/($npppp**2);  
	$m1122=$n1ppp*$np12p*$nppp2/($npppp**2);  
	$m1211=$n1ppp*$np21p*$nppp1/($npppp**2);  
	$m1212=$n1ppp*$np21p*$nppp2/($npppp**2);  
	$m1221=$n1ppp*$np22p*$nppp1/($npppp**2);
	$m1222=$n1ppp*$np22p*$nppp2/($npppp**2);
	$m2111=$n2ppp*$np11p*$nppp1/($npppp**2);
	$m2112=$n2ppp*$np11p*$nppp2/($npppp**2);
	$m2121=$n2ppp*$np12p*$nppp1/($npppp**2);  
	$m2122=$n2ppp*$np12p*$nppp2/($npppp**2);  
	$m2211=$n2ppp*$np21p*$nppp1/($npppp**2);  
	$m2212=$n2ppp*$np21p*$nppp2/($npppp**2);  
	$m2221=$n2ppp*$np22p*$nppp1/($npppp**2);
	$m2222=$n2ppp*$np22p*$nppp2/($npppp**2);
    }
    
    #  calculate the expected values for : "012 3" check
    elsif($expected_values eq "012 3") {
	#print "012 3\n";
	
	$n112p = $n1121 + $n1122;
	$n121p = $n1211 + $n1212;
	$n122p = $n1221 + $n1222;
	$n211p = $n2111 + $n2112;
	$n212p = $n2121 + $n2122;
	$n221p = $n2211 + $n2212;
	$n222p = $n2221 + $n2222;
	
	$m1111=$n111p*$nppp1/($npppp);
	$m1112=$n111p*$nppp2/($npppp);
	$m1121=$n112p*$nppp1/($npppp);
	$m1122=$n112p*$nppp2/($npppp);
	$m1211=$n121p*$nppp1/($npppp);
	$m1212=$n121p*$nppp2/($npppp);
	$m1221=$n122p*$nppp1/($npppp);
	$m1222=$n122p*$nppp2/($npppp);
	$m2111=$n211p*$nppp1/($npppp);
	$m2112=$n211p*$nppp2/($npppp);
	$m2121=$n212p*$nppp1/($npppp);
	$m2122=$n212p*$nppp2/($npppp);
	$m2211=$n221p*$nppp1/($npppp);
	$m2212=$n221p*$nppp2/($npppp);
	$m2221=$n222p*$nppp1/($npppp);
	$m2222=$n222p*$nppp2/($npppp);
    }

    #  calculate the expected values for : "0 13 2" check
    elsif($expected_values eq "0 13 2") {	
	#print "0 13 2\n";

	$np1p2 = $n1112 + $n1122 + $n2112 + $n2122;
	$np2p1 = $n1211 + $n1221 + $n2211 + $n2221;
	$np2p2 = $n1212 + $n1222 + $n2212 + $n2222;

	$m1111=$n1ppp*$np1p1*$npp1p/($npppp**2);
	$m1112=$n1ppp*$np1p2*$npp1p/($npppp**2);
	$m1121=$n1ppp*$np1p1*$npp2p/($npppp**2);
	$m1122=$n1ppp*$np1p2*$npp2p/($npppp**2);
	$m1211=$n1ppp*$np2p1*$npp1p/($npppp**2);
	$m1212=$n1ppp*$np2p2*$npp1p/($npppp**2);
	$m1221=$n1ppp*$np2p1*$npp2p/($npppp**2);
	$m1222=$n1ppp*$np2p2*$npp2p/($npppp**2);
	$m2111=$n2ppp*$np1p1*$npp1p/($npppp**2);
	$m2112=$n2ppp*$np1p2*$npp1p/($npppp**2);
	$m2121=$n2ppp*$np1p1*$npp2p/($npppp**2);
	$m2122=$n2ppp*$np1p2*$npp2p/($npppp**2);
	$m2211=$n2ppp*$np2p1*$npp1p/($npppp**2);
	$m2212=$n2ppp*$np2p2*$npp1p/($npppp**2);
	$m2221=$n2ppp*$np2p1*$npp2p/($npppp**2);
	$m2222=$n2ppp*$np2p2*$npp2p/($npppp**2);

    }

    #  calculate the expected values for : "02 13"
    elsif($expected_values eq "02 13") {	
	#print "02 13\n";
	
	$n1p2p = $n1121 + $n1122 + $n1221 + $n1222;
	$n2p1p = $n2111 + $n2112 + $n2211 + $n2212;
	$n2p2p = $n2121 + $n2122 + $n2221 + $n2222;
	
	$np1p2 = $n1112 + $n1122 + $n2112 + $n2122;
	$np2p1 = $n1211 + $n1221 + $n2211 + $n2221;
	$np2p2 = $n1212 + $n1222 + $n2212 + $n2222;
	

	$m1111=$n1p1p*$np1p1/($npppp);
	$m1112=$n1p1p*$np1p2/($npppp);
	$m1121=$n1p2p*$np1p1/($npppp);
	$m1122=$n1p2p*$np1p2/($npppp);
	$m1211=$n1p1p*$np2p1/($npppp);
	$m1212=$n1p1p*$np2p2/($npppp);
	$m1221=$n1p2p*$np2p1/($npppp);
	$m1222=$n1p2p*$np2p2/($npppp);
	$m2111=$n2p1p*$np1p1/($npppp);
	$m2112=$n2p1p*$np1p2/($npppp);
	$m2121=$n2p2p*$np1p1/($npppp);
	$m2122=$n2p2p*$np1p2/($npppp);
	$m2211=$n2p1p*$np2p1/($npppp);
	$m2212=$n2p1p*$np2p2/($npppp);
	$m2221=$n2p2p*$np2p1/($npppp);
	$m2222=$n2p2p*$np2p2/($npppp);
      
    }

    #  calculate the expected values for : "03 12" check
    elsif($expected_values eq "03 12") {	
	#print "03 12\n";
	
	$n1pp2 = $n1112 + $n1122 + $n1212 + $n1222;
	$n2pp1 = $n2111 + $n2121 + $n2211 + $n2221;
	$n2pp2 = $n2112 + $n2122 + $n2212 + $n2222;

	$np12p = $n1121 + $n1122 + $n2121 + $n2122;
	$np21p = $n1211 + $n1212 + $n2211 + $n2212;
	$np22p = $n1221 + $n1222 + $n2221 + $n2222;

	$m1111=$n1pp1*$np11p/($npppp);
	$m1112=$n1pp2*$np11p/($npppp);
	$m1121=$n1pp1*$np12p/($npppp);
	$m1122=$n1pp2*$np12p/($npppp);
	$m1211=$n1pp1*$np21p/($npppp);
	$m1212=$n1pp2*$np21p/($npppp);
	$m1221=$n1pp1*$np22p/($npppp);
	$m1222=$n1pp2*$np22p/($npppp);
	$m2111=$n2pp1*$np11p/($npppp);
	$m2112=$n2pp2*$np11p/($npppp);
	$m2121=$n2pp1*$np12p/($npppp);
	$m2122=$n2pp2*$np12p/($npppp);
	$m2211=$n2pp1*$np21p/($npppp);
	$m2212=$n2pp2*$np21p/($npppp);
	$m2221=$n2pp1*$np22p/($npppp);
	$m2222=$n2pp2*$np22p/($npppp);
    }

    #  calculate the expected values for : "023 1" check
    elsif($expected_values eq "023 1") {	
	#print "023 1\n";
	
	$n1p12 = $n1112 + $n1212;
	$n1p21 = $n1121 + $n1221;
	$n1p22 = $n1122 + $n1222;
	$n2p11 = $n2111 + $n2211;
	$n2p12 = $n2112 + $n2212;
	$n2p21 = $n2121 + $n2221;
	$n2p22 = $n2122 + $n2222;

	$m1111=$n1p11*$np1pp/($npppp);
	$m1112=$n1p12*$np1pp/($npppp);
	$m1121=$n1p21*$np1pp/($npppp);
	$m1122=$n1p22*$np1pp/($npppp);
	$m1211=$n1p11*$np2pp/($npppp);
	$m1212=$n1p12*$np2pp/($npppp);
	$m1221=$n1p21*$np2pp/($npppp);
	$m1222=$n1p22*$np2pp/($npppp);
	$m2111=$n2p11*$np1pp/($npppp);
	$m2112=$n2p12*$np1pp/($npppp);
	$m2121=$n2p21*$np1pp/($npppp);
	$m2122=$n2p22*$np1pp/($npppp);
	$m2211=$n2p11*$np2pp/($npppp);
	$m2212=$n2p12*$np2pp/($npppp);
	$m2221=$n2p21*$np2pp/($npppp);
	$m2222=$n2p22*$np2pp/($npppp);
    }
    
    #  calculate the expected values for : "013 2" check
    elsif($expected_values eq "013 2") {	
	#print "013 2\n";
	
	$n11p2 = $n1112 + $n1122;
	$n12p1 = $n1211 + $n1221;
	$n12p2 = $n1212 + $n1222;
	$n21p1 = $n2111 + $n2121;
	$n21p2 = $n2112 + $n2122;
	$n22p1 = $n2211 + $n2221;
	$n22p2 = $n2212 + $n2222;

	$m1111=$n11p1*$npp1p/($npppp);
	$m1112=$n11p2*$npp1p/($npppp);
	$m1121=$n11p1*$npp2p/($npppp);
	$m1122=$n11p2*$npp2p/($npppp);
	$m1211=$n12p1*$npp1p/($npppp);
	$m1212=$n12p2*$npp1p/($npppp);
	$m1221=$n12p1*$npp2p/($npppp);
	$m1222=$n12p2*$npp2p/($npppp);
	$m2111=$n21p1*$npp1p/($npppp);
	$m2112=$n21p2*$npp1p/($npppp);
	$m2121=$n21p1*$npp2p/($npppp);
	$m2122=$n21p2*$npp2p/($npppp);
	$m2211=$n22p1*$npp1p/($npppp);
	$m2212=$n22p2*$npp1p/($npppp);
	$m2221=$n22p1*$npp2p/($npppp);
	$m2222=$n22p2*$npp2p/($npppp);
    }

    #  calculate the expected values for : "01 23" check
    elsif($expected_values eq "01 23") {	
	#print "01 23\n";
	
	$n12pp = $n1211+ $n1212 + $n1221 + $n1222;
	$n21pp = $n2111+ $n2112 + $n2121 + $n2122;
	$n22pp = $n2211+ $n2212 + $n2221 + $n2222;

	$npp12 = $n1112 + $n1212 + $n2112 + $n2212;
	$npp21 = $n1121 + $n1221 + $n2121 + $n2221;
	$npp22 = $n1122 + $n1222 + $n2122 + $n2222;
	

	$m1111=$n11pp*$npp11/($npppp);
	$m1112=$n11pp*$npp12/($npppp);
	$m1121=$n11pp*$npp21/($npppp);
	$m1122=$n11pp*$npp22/($npppp);
	$m1211=$n12pp*$npp11/($npppp);
	$m1212=$n12pp*$npp12/($npppp);
	$m1221=$n12pp*$npp21/($npppp);
	$m1222=$n12pp*$npp22/($npppp);
	$m2111=$n21pp*$npp11/($npppp);
	$m2112=$n21pp*$npp12/($npppp);
	$m2121=$n21pp*$npp21/($npppp);
	$m2122=$n21pp*$npp22/($npppp);
	$m2211=$n22pp*$npp11/($npppp);
	$m2212=$n22pp*$npp12/($npppp);
	$m2221=$n22pp*$npp21/($npppp);
	$m2222=$n22pp*$npp22/($npppp);
    }

    #  calculate the expected values for : "03 1 2" check
    elsif($expected_values eq "03 1 2") {	
	#print "03 1 2\n";
	
	$n1pp2 = $n1112 + $n1122 + $n1212 + $n1222;
	$n2pp1 = $n2111 + $n2121 + $n2211 + $n2221;
	$n2pp2 = $n2112 + $n2122 + $n2212 + $n2222;
	
	
	$m1111=$n1pp1*$np1pp*$npp1p/($npppp**2);
	$m1112=$n1pp2*$np1pp*$npp1p/($npppp**2);
	$m1121=$n1pp1*$np1pp*$npp2p/($npppp**2);
	$m1122=$n1pp2*$np1pp*$npp2p/($npppp**2);
	$m1211=$n1pp1*$np2pp*$npp1p/($npppp**2);
	$m1212=$n1pp2*$np2pp*$npp1p/($npppp**2);
	$m1221=$n1pp1*$np2pp*$npp2p/($npppp**2);
	$m1222=$n1pp2*$np2pp*$npp2p/($npppp**2);
	$m2111=$n2pp1*$np1pp*$npp1p/($npppp**2);
	$m2112=$n2pp2*$np1pp*$npp1p/($npppp**2);
	$m2121=$n2pp1*$np1pp*$npp2p/($npppp**2);
	$m2122=$n2pp2*$np1pp*$npp2p/($npppp**2);
	$m2211=$n2pp1*$np2pp*$npp1p/($npppp**2);
	$m2212=$n2pp2*$np2pp*$npp1p/($npppp**2);
	$m2221=$n2pp1*$np2pp*$npp2p/($npppp**2);
	$m2222=$n2pp2*$np2pp*$npp2p/($npppp**2);
    }

    #  calculate the expected values for : "02 1 3" check
    elsif($expected_values eq "02 1 3") {	
	#print "02 1 3\n";
	
	$n1p2p = $n1121 + $n1122 + $n1221 + $n1222;
	$n2p1p = $n2111 + $n2112 + $n2211 + $n2212;
	$n2p2p = $n2121 + $n2122 + $n2221 + $n2222;
	

	$m1111=$n1p1p*$np1pp*$nppp1/($npppp**2);
	$m1112=$n1p1p*$np1pp*$nppp2/($npppp**2);
	$m1121=$n1p2p*$np1pp*$nppp1/($npppp**2);
	$m1122=$n1p2p*$np1pp*$nppp2/($npppp**2);
	$m1211=$n1p1p*$np2pp*$nppp1/($npppp**2);
	$m1212=$n1p1p*$np2pp*$nppp2/($npppp**2);
	$m1221=$n1p2p*$np2pp*$nppp1/($npppp**2);
	$m1222=$n1p2p*$np2pp*$nppp2/($npppp**2);
	$m2111=$n2p1p*$np1pp*$nppp1/($npppp**2);
	$m2112=$n2p1p*$np1pp*$nppp2/($npppp**2);
	$m2121=$n2p2p*$np1pp*$nppp1/($npppp**2);
	$m2122=$n2p2p*$np1pp*$nppp2/($npppp**2);
	$m2211=$n2p1p*$np2pp*$nppp1/($npppp**2);
	$m2212=$n2p1p*$np2pp*$nppp2/($npppp**2);
	$m2221=$n2p2p*$np2pp*$nppp1/($npppp**2);
	$m2222=$n2p2p*$np2pp*$nppp2/($npppp**2);
    }
     
    else {

	#print "0 1 2 3\n";

	$m1111=$n1ppp*$np1pp*$npp1p*$nppp1/($npppp**3);
	$m1112=$n1ppp*$np1pp*$npp1p*$nppp2/($npppp**3);
	$m1121=$n1ppp*$np1pp*$npp2p*$nppp1/($npppp**3);
	$m1122=$n1ppp*$np1pp*$npp2p*$nppp2/($npppp**3);
	$m1211=$n1ppp*$np2pp*$npp1p*$nppp1/($npppp**3);
	$m1212=$n1ppp*$np2pp*$npp1p*$nppp2/($npppp**3);
	$m1221=$n1ppp*$np2pp*$npp2p*$nppp1/($npppp**3);
	$m1222=$n1ppp*$np2pp*$npp2p*$nppp2/($npppp**3);
	$m2111=$n2ppp*$np1pp*$npp1p*$nppp1/($npppp**3);
	$m2112=$n2ppp*$np1pp*$npp1p*$nppp2/($npppp**3);
	$m2121=$n2ppp*$np1pp*$npp2p*$nppp1/($npppp**3);
	$m2122=$n2ppp*$np1pp*$npp2p*$nppp2/($npppp**3);
	$m2211=$n2ppp*$np2pp*$npp1p*$nppp1/($npppp**3);
	$m2212=$n2ppp*$np2pp*$npp1p*$nppp2/($npppp**3);
	$m2221=$n2ppp*$np2pp*$npp2p*$nppp1/($npppp**3);
	$m2222=$n2ppp*$np2pp*$npp2p*$nppp2/($npppp**3);
    }

    return 1;
}


=item computeMarginalTotals($marginal_values) - This method
computes the marginal totals from the valuescomputed by the count.pl
program and are passed to the calculateStatistic() method.

INPUT PARAMS  : $count_values     .. Reference to an hash consisting
                                     of the frequency combination
                                     output.

RETURN VALUES : 1/undef           ..returns '1' to indicate success
                                    and an undefined(NULL) value to indicate
                                    failure.

=cut

sub computeMarginalTotals
{

  my ($values)=@_;

  #  marginal values
  $np112 = $n1112 + $n2112;
  $np121 = $n1121 + $n2121;
  $np122 = $n1122 + $n2122;
  $np211 = $n1211 + $n2211;
  $np212 = $n1212 + $n2212;
  $np221 = $n1221 + $n2221;
  $np222 = $n1222 + $n2222;
  $n2ppp=$npppp-$n1ppp;
  $np2pp=$npppp-$np1pp;
  $npp2p=$npppp-$npp1p;
  $nppp2=$npppp-$nppp1;  

  # n1ppp should be greater than or equal to zero 
  if ($n1ppp <= 0) {
	$errorMessage = "Marginal total value ($n1ppp) must not be negative.";
	$errorCodeNumber = 203;  return;
  }
  
  # n1ppp should be less than or equal to total4grams
  if ($n1ppp > $npppp) {
      $errorMessage = "Marginal total value ($n1ppp) must not exceed total number of 4grams ($npppp).";
      $errorCodeNumber = 204;  return;
  }
  
  # np1pp should be greater than or equal to zero
  if ($np1pp <= 0) {
      $errorMessage = "Marginal total value ($np1pp) must not be negative.";
      $errorCodeNumber = 205;  return;
  }
  
  # np1pp should be less than or equal to total4grams
  if ($np1pp > $npppp) {
      $errorMessage = "Marginal total value ($np1pp) must not exceed total number of 4grams.";
      $errorCodeNumber = 206;  return;
  }
  
  # npp1p should be greater than or equal to zero 
  if ($npp1p <= 0) {
      $errorMessage = "Marginal total value ($npp1p) must not be negative.";
      $errorCodeNumber = 207;  return;
    }
  
  # npp1p should be less than or equal to total4grams
  if ($npp1p > $npppp) {
      $errorMessage = "Marginal total value ($npp1p) must not exceed total number of 4grams.";
      $errorCodeNumber = 208;  return;
  }
  
  # nppp1p should be greater than or equal to zero 
  if ($nppp1 <= 0) {
      $errorMessage = "Marginal total value ($nppp1) must not be negative.";
      $errorCodeNumber = 209;  return;
  }
  
  # nppp1p should be less than or equal to total4grams
  if ($nppp1 > $npppp) {
      $errorMessage = "Marginal total value ($nppp1) must not exceed total number of 4grams.";
      $errorCodeNumber = 210;  return;
  }
  
  return 1;
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
                             E<lt>bthomson@cs.umn.eduE<gt>

Saiyam Kohli,                University of Minnesota Duluth
                             E<lt>kohli003@d.umn.eduE<gt>

=head1 HISTORY

Last updated: $Id: 4D.pm,v 1.3 2010/11/12 18:40:23 btmcinnes Exp $

=head1 BUGS


=head1 SEE ALSO

L<http://groups.yahoo.com/group/ngram/>

L<http://www.d.umn.edu/~tpederse/nsp.html>


=head1 COPYRIGHT

Copyright (C) 2000-2008, Ted Pedersen, Satanjeev Banerjee, Amruta
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
