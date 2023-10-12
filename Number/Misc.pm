package Number::Misc;
use strict;
use Carp;

# version
our $VERSION = '1.2';


#------------------------------------------------------------------------------
# opening POD
#

=head1 NAME

Number::Misc - handy utilities for numbers

=head1 SYNOPSIS

 use Number::Misc ':all';

 is_numeric('x');        # false
 to_number('3,000');     # 3000
 commafie('3000');       # 3,000
 zero_pad(2, 10);        # 0000000002
 rand_in_range(3, 10);   # a random number from 3 to 10, inclusive
 is_even(3)              # true
 is_odd(4);              # true

=head1 DESCRIPTION

Number::Misc provides some miscellaneous handy utilities for handling numbers.
These utilities handle processing numbers as strings, determining basic properties
of numbers, or selecting a random number from a range.

=head1 INSTALLATION

Number::Misc can be installed with the usual routine:

 perl Makefile.PL
 make
 make test
 make install

=head1 FUNCTIONS


=cut

#
# opening POD
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# export
#
use vars qw[@EXPORT_OK %EXPORT_TAGS @ISA];
@ISA = 'Exporter';

@EXPORT_OK = qw[
	is_numeric isnumeric
	to_number tonumber
	commafie
	zero_pad zeropad
	rand_in_range
	is_even is_odd
];

%EXPORT_TAGS = ('all' => [@EXPORT_OK]);
#
# export
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
# is_numeric
#

=head2 is_numeric

Returns true if the given scalar is a number.  An undefined value returns false.
A "number" is defined as consisting solely of numerals (i.e. the characters 0-9),
with at most one decimal, and at most a single leading minus or plus sign.

 is_numeric('3');       # true
 is_numeric('-3');      # true
 is_numeric('+3');      # true
 is_numeric('0003');    # true
 is_numeric('0.003');   # true
 is_numeric('0.00.3');  # false
 is_numeric('3,003');   # false
 is_numeric('  3');     # false
 is_numeric(undef);     # false

=over

=item option: convertible

If you want to test if the string B<could> be a number if it were run through
to_number() then use the convertible option.

 is_numeric('3,003',  convertible=>1);  # true
 is_numeric('  3',    convertible=>1);  # true
 is_numeric('0.00.3', convertible=>1);  # false

=back

=cut

# I changed the name of the the function from isnumeric to is_numeric,
# but still need to support some legacy code.
sub isnumeric { return is_numeric(@_) }

sub is_numeric {
	my ($val, %opts) = @_;
	
	# if not defined, return false
	defined($val) or return 0;
	
	# if convertible
	if ($opts{'convertible'} || $opts{'convertable'})
		{$val = to_number($val)}
	
	if (! defined $val)
		{return 0}
	
	$val =~ s/,//g;
	$val =~ s/^\-//;
	$val =~ s/^\+//;
	$val =~ s/\.//;
	
	if ($val =~ m/^\d+$/)
		{return 1}
	
	return 0;
}
#
# isnumeric
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# to_number
#

=head2 to_number

Converts a string to a number by removing commas and spaces.  If the string
can't be converted, returns undef. Some examples:

 to_number(' 3 ');       # returns 3
 to_number(' 3,000 ');   # returns 3000
 to_number('whatever');  # returns undef

=over

=item option: always_number

If the string cannot be converted to a number, return 0 instead of undef.
For example, this call:

 to_number('whatever', always_number=>1)

returns 0.

=back

=cut

# I changed the name of the the function from to_number to to_number
# but still need to support some legacy code.
sub tonumber { return to_number(@_) }

sub to_number {
	my ($rv, %opts) = @_;
	
	# if not defined, or just spaces, return 0
	unless ( defined($rv) && ($rv =~ m|\S|) ){
		if ($opts{'always_number'})
			{ return 0 }
		
		return undef;
	}
	
	# do some basic cleanup
	$rv =~ s|^\s+||s;
	$rv =~ s|\s+$||s;
	$rv =~ s/,//g;
	$rv =~ s/\-\s+/-/;
	
	# If it's not numeric, but it is requested to always return a number,
	# then return zero.
	if (! isnumeric($rv)) {
		if ($opts{'always_number'})
			{ return 0 }
		
		# else return undef
		return undef;
	}
	
	# return
	return $rv;
}
#
# to_number
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# commafie
#

=head2 commafie

Converts a number to a string representing the same number but with commas

 commafie(2000);     #  2,000
 commafie(-2000);    # -1,000
 commafie(2000.33);  #  2,000.33
 commafie(100);      #    100

B<option: sep>

The C<sep> option lets you set what to use as a separator instead of a comma.
For example, if you want to C<:> instead of C<,> you would do that like this:

 commafie('2000', sep=>':');

which would give you this:

 2:000

=cut

sub commafie {
	my ($val, %opts) = @_;
	my ($int, $dec, $neg, $comma);
	
	# default options
	%opts = (sep=>',', %opts);
	
	# set what to use for comma
	$comma = $opts{'sep'};
	
	# remove and note negation
	$neg = ($val =~ s/^\-//);
	
	# get integer and decimal values
	($int, $dec) = split('\.', $val);
	
	# add commas
	$int = reverse($int);
	$int =~ s/(\d\d\d)/$1$comma/g;
	$int =~ s/,$//;
	$int = reverse($int);
	
	# add back negation if necessary
	if ($neg)
		{$int = "-$int"}
	
	# add back decimal value if it was present
	if (defined $dec)
		{$int .= ".$dec"}	
	
	# return
	return $int;
}
#
# commafie
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# zero_pad
#

=head2 zero_pad

Prepends zeroes to the number to make it a specified length.  The first param is
the  number, the second is the target length.  If the length of the number is
equal to or longer than the given length then nothing is changed.

 zero_pad(2, 3);   # 002
 zero_pad(2, 10);  # 0000000002
 zero_pad(444, 2); # 444

=cut

# support legacy code that uses zeropad (i.e zero_pad without the underscore)
sub zeropad { return zero_pad(@_) }

sub zero_pad {
	my ($int, $length) = @_;
	
	# add zeroes
	while (length($int) < $length) {
		$int = "0$int";
	}
	
	# return
	return $int;
}
#
# zero_pad
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# rand_in_range
#

=head2 rand_in_range

Given lower and upper bounds, returns a random number greater than
or equal to the lower bound and less than or equal to the upper.
Works only on integers.

 rand_in_range(3, 10);   # a random number from 3 to 10, inclusive
 rand_in_range(-1, 10);  # a random number from -1 to 10, inclusive

=cut

sub rand_in_range {
	my ($min, $max, $iter) = @_;
	my (@rv);
	$iter ||= 1;
	
	# switch if necessary
	if ($min > $max)
		{ ($max, $min) = ($min, $max) }
	
	# loop through as many iterations as needed
	for (1..$iter) {
		push @rv, int(rand($max - $min + 1)) + $min;
		
		if (! wantarray)
			{ return $rv[0] }
	}
	
	return @rv;
}
#
# rand_in_range
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# is_even / is_odd
#

=head2 is_even / is_odd

C<is_even> returns true if the number is even.
C<is_odd> returns true if the number is odd.
Nonnumbers and decimals return undef.

=cut

sub is_even {
	my ($number) = @_;
	
	# check if we can determine even/odd
	even_odd_check($number) or return undef;
	
	# if the number isn't even, return 0
	if ($number%2 == 1)
		{ return 0 }
	
	# it's even, return true
	return 1;
}

sub is_odd {
	my ($number) = @_;
	
	# check if we can determine even/odd
	even_odd_check($number) or return undef;
	
	# if it's odd, return true
	if ($number%2 == 1)
		{ return 1 }
	
	# it's not odd, so return false
	return 0;
}

# private method: even_odd_check
sub even_odd_check {
	my ($number) = @_;
	
	# if not number, returns undef
	if (! isnumeric($number)) {
		if (defined $number)
			{ warn qq|cannot determine odd/even for non-number: $number| }
		else
			{ warn qq|cannot determine odd/even for undef| }
		
		# return undef
		return undef;
	}
	
	# decimals return undef
	if ($number =~ m|\,|) {
		warn qq|cannot determine odd/even for decimal|;
		return undef;
	}
	
	# else it's ok
	return 1;
}

#
# is_even / is_odd
#------------------------------------------------------------------------------



# return true
1;


__END__

=head1 Other modules

Here are a few other modules available on CPAN that do many of the same things
as Number::Misc:

L<Number::Format|http://search.cpan.org/~wrw/Number-Format/>

L<Test::Numeric|http://search.cpan.org/~evdb/Test-Numeric/>

L<Math::Random|http://search.cpan.org/~grommel/Math-Random/>

=head1 TERMS AND CONDITIONS

Copyright (c) 2012 by Miko O'Sullivan.  All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same terms
as Perl itself. This software comes with B<NO WARRANTY> of any kind.

=head1 AUTHOR

Miko O'Sullivan
F<miko@idocs.com>



=head1 VERSION

=over

=item Version 1.0    July, 2012

Initial release.

=item Version 1.1  April 25, 2014

Fixed problem in META.yml.

=item Version 1.2 January 2, 2015

Fixed issues in tests.  Added 'sep' option to commafie.

=back


