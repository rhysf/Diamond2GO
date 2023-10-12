package Statistics::Zed;
use 5.008008;
use strict;
use warnings FATAL => 'all';
use Carp qw(croak);
use base qw(Statistics::Data);
use Math::Cephes qw(:dists);
use Statistics::Lite qw(sum);
use String::Util qw(hascontent nocontent);
use Scalar::Util qw(looks_like_number);
$Statistics::Zed::VERSION = '0.10';

=head1 NAME

Statistics::Zed - Data-handling and calculations for ratio of observed to standard deviation (zscore)

=head1 VERSION

Version 0.10

=head1 SYNOPSIS

 use Statistics::Zed 0.10;

 # new() with optional args:
 $zed = Statistics::Zed->new(
    ccorr    => 1,
    tails    => 2,
    precision_s => 3,
    precision_p => 7,
 );

 # optionally pre-load one or more values with these names:
 $zed->load(observed => [5, 6, 3], expected => [2.5, 3, 3], variance => [8, 8, 9]);
 $zed->add(observed => [3, 6], expected => [2.7, 2.5], variance => [7, 8]); # update loaded arrays
 $z_value = $zed->score(); # calc z_value from pre-loaded data
 
 # alternatively, call zscore() - alias score() - with the required args (with arefs or single values):
 $z_value = $zed->zscore(
    observed => 5,
    expected => 2.5,
    variance => 8,
 );

 # as either of above, but call in array context for more results:
 ($z_value, $p_value, $observed_deviation, $standard_deviation) = $zed->zscore();
 
 # as either of above but with optional args:
 $z_value = $zed->zscore(ccorr => 1, precision_s => 3);

 # get the normal distribution p_value only - alias z2p():
 $p_value = $zed->p_value(); # using pre-loaded data
 $p_value = $zed->p_value(observed => 5, expected => 2.5, variance => 8); # from given data
 $p_value = $zed->p_value(tails => 2, ccorr => 1, precision_p => 5); # same as either with optional args

 # "inverse phi" (wraps to Math::Cephes::ndtri):
 $z_value = $zed->p2z(value => $p_value, tails => 1|2);

=head1 DESCRIPTION

Methods are provided to:

+ L<calculate a z-score|Statistics::Zed/zscore>: ratio of an observed deviation to a standard deviation, with optional continuity correction

+ L<convert z-value to normal p-value|Statistics::Zed/p_value>, and L<convert p-value to normal-equiv z-value|Statistics::Zed/p2z>

+ L<load|Statistics::Zed/load>, L<add|Statistics::Zed/add>, save & retrieve observed, expected and variance values to compute z_score across samples

+ support z-testing in L<Statistics::Sequences|Statistics::Sequences> and other modules.

Optionally, load/add B<observed>, B<expected> and B<variance> values (named as such) and compute a z-score between/after updates. The module uses L<Statistics::Data|Statistics::Data> to cache each observed, expected and variance values, and to provide for the load/add methods, as well as to save/retrieve these values between class calls (not documented here, see L<Statistics::Data|Statistics::Data>). Alternatively, simply call L<zscore|Statistics::Zed/zscore> and L<pvalue|Statistics::Zed/pvalue>, passing them the values by these labels in a hash (or hashref), with either single numerical values or referenced arrays of the same. Optionally, specify tails, where relevant, and precision the returned z-values and p-values as required.

=head1 SUBROUTINES/METHODS

=head2 new

 $zed = Statistics::Zed->new();
 $zed = Statistics::Zed->new(ccorr => NUM, tails => 1|2, precision_s => INT, precision_p => INT);

Returns a Statistics::Zed object. Accepts setting of any of the L<OPTIONS|Statistics::Zed/OPTIONS>.

=cut

sub new {
    my ( $class, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    my $self = $class->SUPER::new();

    # Set default values:
    $self->{'tails'} = 2;
    $self->{'ccorr'} = 0;

    if ( scalar keys %{$args} ) {
        foreach ( keys %{$args} ) {
            $self->{$_} = $args->{$_};
        }
    }
    return $self;
}

=head2 load

 $zed->load(observed => [NUMs], expected => [NUMs], variance => [NUMs]); # labelled list of each required series
 $zed->load({ observed => [NUMs], expected => [NUMs], variance => [NUMs] }); # same but as referenced hash

Optionally load data for each of B<observed>, B<expected> and B<variance> series as arefs (reference to list of numbers), using C<load> in L<Statistics::Data|Statistics::Data/load>. Returns 1 if successful but croaks if data cannot be loaded; see L<DIAGNOSTICS|Statistics::Zed/DIAGNOSTICS>.

=cut

sub load {
    my ( $self, @args ) = @_;
    $self->SUPER::load(@args);

# ensure there are named data for each of 'observed', 'expected' and 'variance':
    my $data = 0;
    foreach (qw/observed expected variance/) {
        $data++ if $self->access( label => $_ );
    }
    croak
'Data for deviation ratio are incomplete: Need arefs of data labelled \'observed\', \'expected\' and \'variance\''
      if $data > 0 and $data != 3;
    return 1;
}

=head2 add

 $zed->add(observed => [NUMs], expected => [NUMs], variance => [NUMs]); # labelled list of each required series
 $zed->add({ observed => [NUMs], expected => [NUMs], variance => [NUMs] }); # same but as referenced hash

Update any existing, previously loaded data, via C<add> in L<Statistics::Data|Statistics::Data/add>. Returns 1 if successful but croaks if data cannot be added; see L<DIAGNOSTICS|Statistics::Zed/DIAGNOSTICS>.

=cut

sub add {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    $self->SUPER::add($args);
    foreach (qw/observed expected variance/) {
        croak
'Data for deviation ratio are incomplete: Need arefs of data labelled \'observed\', \'expected\' and \'variance\''
          if !$self->access( label => $_ );
    }
    return 1;
}

=head2 zscore

 $zval = $zed->zscore(); # assuming observed, expected and variance values already loaded/added, as above
 $zval = $zed->zscore(observed => NUM, expected => NUM, variance => NUM);
 $zval = $zed->zscore(observed => [NUMs], expected => [NUMs], variance => [NUMs]);
 ($zval, $pval, $obs_dev, $stdev) = $zed->zscore(); # same but array context call for more info
 $zscore = $zed->zscore(observed => [12], expected => [5], variance => [16], ccorr => 1); # same but with continuity correction

Returns the I<z>-value for the values of B<observed>, B<expected> and B<variance> sent to L<load|Statistics::Zed/load> and/or L<add|Statistics::Zed/add>, or as sent in a call to this method itself as a hash (or hashref). If called wanting an array, then the I<z>-value, its probability, the observed deviation and the standard deviation are returned.

I<Alias>: score, z_value

As described in L<OPTIONS|Statistics::Zed/OPTIONS>, optionally specify a numerical value for L<ccorr|Statistics::Zed/ccorr> for performing the continuity-correction to the observed deviation, and a value of either 1 or 2 to specify the L<tails|Statistics::Zed/tails> for reading off the normal distribution.

The basic formula is the basic:

=for html <p>&nbsp;&nbsp;&nbsp;<i>Z</i> = ( <i>&times;</i> &ndash; <i><o>X</o></i> ) / SD</p>

where I<X> is the expected value (mean, etc.). If supplying an array of values for each of the required arguments, then the z-score is based on summing their values, i.e., (sum of observeds less sum of expecteds) divided by square-root of the sum of the variances.

=cut

sub zscore {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    my $desc = _get_descriptives( $self, $args );

    # Calc z-value - leave undefined if no expected deviation:
    my ( $z_value, $obs_dev, $exp_dev ) = ();
    $obs_dev = $desc->{'observed'} - $desc->{'expected'};
    $obs_dev = _ccorr( $self, $args, $obs_dev );
    $exp_dev = sqrt $desc->{'variance'};
    $z_value = $obs_dev / $exp_dev if $exp_dev;

# Return array of z-value and p-value etc if wanted, precisioned as wanted, but empty-string if undefined:
    if (wantarray) {
        if ( hascontent($z_value) ) {
            $args->{'value'} = $z_value;
            my $p_value = _precision( $self, $args, 'p', $self->z2p($args) );
            $z_value = _precision( $self, $args, 's', $z_value );
            return ( $z_value, $p_value, $obs_dev, $exp_dev );
        }
        else {
            return ( q{}, q{}, $obs_dev, $exp_dev );
        }
    }
    else {
        return hascontent($z_value)
          ? _precision( $self, $args, 's', $z_value )
          : q{};
    }
}

# aliases:
*score   = \&zscore;
*z_value = \&zscore;
*test    = \&zscore;    # legacy

=head2 p_value

 $p_value = $zed->p_value($z); # assumes 2-tailed
 $p_value = $zed->p_value(value => $z); # assumes 2-tailed
 $p_value = $zed->p_value(value => $z, tails => 1);
 $p_value = $zed->p_value(); # assuming observed, expected and variance values already loaded/added, as above
 $p_value = $zed->p_value(observed => NUM, expected => NUM, variance => NUM);
 $p_value = $zed->p_value(observed => [NUMs], expected => [NUMs], variance => [NUMs]);

I<Alias>: C<pvalue>, C<z2p>

Send a I<z>-value, get its associated I<p>-value, 2-tailed by default, or depending on the value of the optional argument B<tails>. If you pass in just one value (unkeyed), it is taken as the z-value. Alternatively, it can be passed the same arguments as for L<zscore|Statistics::Zed/zscore> so that it will calculate the zscore itself but return only the p-value.

Uses L<Math::Cephes|Math::Cephes> C<ndtr> normal probability function, which returns 0 if the z-value is greater than or equal to 38.

The optional argument B<precision_p> renders the returned p-value to so many decimal places (simply by sprintf).

=cut

sub p_value {
    my ( $self, @args ) = @_;
    my $args =
        ref $args[0]               ? $args[0]
      : ( scalar(@args) % 2 == 0 ) ? {@args}
      :                              { value => $args[0] };
    my $z_value;
    if (    hascontent( $args->{'value'} )
        and looks_like_number( $args->{'value'} ) )
    {
        $z_value = $args->{'value'};
    }
    else {
        $z_value = $self->zscore($args);
    }
    return q{} if nocontent($z_value);
    my $p_value = ndtr($z_value);
    $p_value = 1 - $p_value if $p_value > .5;
    $p_value *= _set_tails( $self, $args );
    return _precision( $self, $args, 'p', $p_value );
}
*pvalue = \&p_value;
*z2p    = \&p_value;

=head2 p2z

 $z_value = $zed->p2z($p_value) # the p-value is assumed to be 2-tailed
 $z_value = $zed->p2z(value => $p_value) # the p-value is assumed to be 2-tailed
 $z_value = $zed->p2z(value => $p_value, tails => 1) # specify 1-tailed probability

Returns the I<z>-value associated with a I<p>-value using the inverse phi function C<ndtri> in L<Math::Cephes|Math::Cephes>. I<The p-value is assumed to be two-tailed>, and so is firstly (before conversion) divided by 2, e.g., .05 becomes .025 so you get I<z> = 1.96.  As a one-tailed probability, it is then assumed to be a probability of being I<greater> than a certain amount, i.e., of getting a I<z>-value I<greater> than or equal to that observed. So the inverse phi function is actually given (1 - I<p>-value) to work on. So .055 comes back as 1.598 (speaking of the top-end of the distribution), and .991 comes back as -2.349 (now going from right to left across the distribution). This is not the same as found in inversion methods in common spreadsheet packages but seems to be expected by humans.

=cut

sub p2z {
    my ( $self, @args ) = @_;
    my $args =
        ref $args[0]               ? $args[0]
      : ( scalar(@args) % 2 == 0 ) ? {@args}
      :                              { value => $args[0] };
    my $p_value;
    if ( hascontent( $args->{'value'} )
        and $self->all_proportions( [ $args->{'value'} ] ) )
    {
        $p_value = $args->{'value'};
    }
    else {
        croak 'Cannot compute z-value from p-value: ' . $args->{'value'};
    }

    # Avoid ndtri errors by first accounting for 0 and 1 ...
    my $z_value;
    if ( $p_value == 0 ) {
        $z_value = undef;
    }
    elsif ( $p_value == 1 ) {
        $z_value = 0;
    }
    else {
        $p_value /= 2
          if _set_tails( $self, $args ) ==
          2;    # p-value has been given as two-tailed - only use 1 side
        $z_value = ndtri( 1 - $p_value );
    }
    return $z_value;
}

=head2 obsdev

 $obsdev = $zed->obsdev(); # assuming observed and expected values already loaded/added, as above
 $obsdev = $zed->obsdev(observed => NUM, expected => NUM);
 $obsdev = $zed->obsdev(observed => [NUMs], expected => [NUMs]);

Returns the observed deviation (only), as would be returned as the third value if calling L<zscore|Statistics::Zed/zscore> in array context. This is simply the (sum of) the observed value(s) less the (sum of) the expected value(s), with the (sum of) the latter given the continuity correction if this is (optionally) also given as an argument, named B<ccorr>; see L<OPTIONS|Statistics::Zed/OPTIONS>.

=cut

sub obsdev {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    my $desc = _get_descriptives( $self, $args );
    return _ccorr( $self, $args,
        ( $desc->{'observed'} - $desc->{'expected'} ) );
}

=head2 ccorr

 $zed->ccorr(value => 1); # will be used in all methods, unless they are given a ccorr value to use
 $val = $zed->ccorr(); # returns any value set in new() or previously here

Set the value of the optional B<ccorr> argument to be used for all statistics methods, or, without a B<value>, return the current value. This might be undef if it has not previously been explicitly set in L<new|Statistics::Zed/new> or via this method. To quash any set value, specify B<value> => 0. When sending a value for B<ccorr> to any other method, this value takes precedence over any previously set, but it does not "re-set" the cached value that is set here or in L<new|Statistics::Zed/new>. See L<OPTIONS|Statistics::Zed/OPTIONS> for how this value is used. It is assumed that the value sent is a valid numerical value.

=cut

sub ccorr {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    if ( defined $args->{'value'} ) {
        $self->{'ccorr'} = $args->{'value'};
    }
    else {
        return $self->{'ccorr'};
    }
    return;
}

=head2 tails

 $zed->tails(value => 1); # will be used in all methods, unless they are given a tails value to use
 $val = $zed->tails(); # returns any value set in new() or previously here

Set the value of the optional B<tails> argument to be used for all statistics methods, or, without a B<value>, return the current value. The default is 2; and this can be overriden by setting its value in L<new|Statistics::Zed/new>, by this method, or as an explicit argument in any method. When sending a value for B<tails> to any other method, this value takes precedence over any previously set, but it does not "re-set" the cached value that is set here or in L<new|Statistics::Zed/new>. See L<p_value|Statistics::Zed/p_value>, L<p2z|Statistics::Zed/p2z> and L<OPTIONS|Statistics::Zed/OPTIONS> for how this value is used. The value set must be either 1 or 2; a croak is heard otherwise.

=cut

sub tails {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    if ( defined $args->{'value'} ) {
        if ( looks_like_number( $args->{'value'} )
            and ( $args->{'value'} == 1 or $args->{'value'} == 2 ) )
        {
            $self->{'tails'} = $args->{'value'};
        }
        else {
            croak
"Cannot set tails() option: value must be numeric and equal either 1 or 2, not '$args->{'value'}'";
        }
    }
    else {
        return $self->{'tails'};
    }
    return;
}

=head2 string

 $str = $zed->string(); # assuming observed, expected and variance values already loaded/added, as above
 $str = $zed->string(observed => NUM, expected => NUM, variance => NUM);
 $str = $zed->string(observed => [NUMs], expected => [NUMs], variance => [NUMs]);

Returns a string giving the zscore and p-value. Takes the same arguments as for L<zscore|Statistics::Zed/zscore>, which it calls itself, taking its returned values to make up a string in the form B<Z = 0.141, 1p = 0.44377>. Accepts the optional arguments B<tails>, B<ccorr>, B<precsion_s> and B<precision_p>; see L<OPTIONS|Statistics::Zed/OPTIONS>. In the example, B<precision_s> has been specified as 3, B<precision_p> has been set to 5, and B<tails> has been set to 1.

=cut

sub string {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    my ( $zval, $pval ) = zscore( $self, $args );
    my $tails = _set_tails( $self, $args );
    return "Z = $zval, " . $tails . "p = $pval";
}

=head2 dump

 $zed->dump(); # assuming observed, expected and variance values already loaded/added, as above
 $zed->dump(observed => NUM, expected => NUM, variance => NUM);
 $zed->dump(observed => [NUMs], expected => [NUMs], variance => [NUMs]);

Prints to STDOUT a line giving the zscore and p-value, being what would be returned by L<string|Statistics::Zed/string> but with a new-line "\n" character appended.

=cut

sub dump {
    my ( $self, @args ) = @_;
    print string( $self, @args ), "\n"
      or croak 'Could not print statistical values';
    return 1;
}

## Private methods:

# Obtain required values by given args or, if not given, by pre-loaded data, or croak:
sub _get_descriptives {
    my ( $self, $args ) = @_;
    my %desc = ();
    for (qw/observed expected variance/) {
        if ( nocontent( $args->{$_} )
            and my $data = $self->access( label => $_ ) )
        {    # try pre-loaded data
            $desc{$_} = sum( @{$data} );
        }
        elsif ( ref $args->{$_} ) {    # assume isa aref
            $desc{$_} = sum( @{$data} );
        }
        elsif ( looks_like_number( $args->{$_} ) ) {    # assume single value
            $desc{$_} = $args->{$_};
        }
        else {
            croak
              "Cannot compute z-value: No defined or numerical '$_' value(s)";
        }
    }
    return \%desc;
}

sub _precision
{   # any $args value takes precedence; try $self value; otherwise, return as is
    my ( $self, $args, $type, $value ) = @_;
    my $precision;
    if ( $args->{ 'precision_' . $type } ) {
        $precision = $args->{ 'precision_' . $type };
    }
    elsif ( $self->{ 'precision_' . $type } ) {
        $precision = $self->{ 'precision_' . $type };
    }
    else {
        return $value;
    }
    return sprintf q{%.} . $precision . 'f',
      $value;    # tried Number::Format but overflows too easily
}

sub _set_tails
{   # any $args value takes precedence; try $self value; otherwise, return as is
    my ( $self, $args, $value ) = @_;
    my $tails;
    if ( $args->{'tails'} ) {
        $tails = $args->{'tails'};
    }
    elsif ( $self->{'tails'} ) {
        $tails = $self->{'tails'};
    }
    if ( !defined $tails )
    {    # what might have been in $self was clobbered by user, perhaps
        $tails = 2;
    }
    elsif ( $tails != 1 && $tails != 2 ) {
        croak
"Cannot compute p-value: Argument \'tails\' should have value of either 1 or 2, not '$tails'";
    }
    return $tails;
}

# Apply continuity correction to deviation:
sub _ccorr {
    my ( $self, $args, $dev ) = @_;
    if ($dev) {
        my $d;
        if ( defined $args->{'ccorr'} ) {
            $d = $args->{'ccorr'};
        }
        elsif ( defined $self->{'ccorr'} ) {
            $d = $self->{'ccorr'};
        }
        if ( !$d ) {
            return $dev;
        }
        else {
            my $cdev = abs($dev) - .5 * $d;
            $cdev *= -1 if $dev < 0;
            return $cdev;
        }
    }
    else {
        return $dev;
    }
}

1;

__END__

=head1 OPTIONS

The following can be set in calls to the above methods, including L<new|Statistics::Zed/new>, where relevant.

=head2 ccorr

Apply the continuity correction. Default = 0. Otherwise, specify a correcting difference value (not necesarily 1), and the procedure is to calculate the observed difference as its absolute value less half of this correcting value, returning the observed difference with its original sign. To clarify for Germans, this is the Stetigkeitskorrektur.

=head2 tails

Tails from which to assess the association I<p>-value (1 or 2). Default = 2.

=head2 precision_s

Precision of the I<z>-value (the statistic). Default is undefined - you get all decimal values available.

=head2 precision_p

Precision of the associated I<p>-value. Default is undefined - you get all decimal values available.

=head1 Deprecated methods

Methods for "series testing" are deprecated. Use L<load|Statistics::Zed/load> and L<add|Statistics::Zed/add> instead to manage keeping a cache of the oberved, expected and variance values; the z- and p-methods will look them up, if available. See L<dump_vals|Statistics::Data/dump_vals> in Statistics::Data for dumping series data using the present class object, which uses Statistics::Data as a base.

=head1 DIAGNOSTICS

=over 4

=item Data for deviation ratio are incomplete

Croaked when L<load|Statistics::Zed/load>ing or L<add|Statistics::Zed/add>ing data. As the croak goes on to say, loading and adding (updating) needs arefs of data labelled B<observed>, B<expected> and B<variance>. Also, if any one of them are loaded/updated at one time, it's expected that all three are loaded/updated. For more info about loading data, see L<Statistics::Data|Statistics::Data/load>.

=item Cannot compute z-value: No defined or numerical '$_' value(s)

Croaked via L<zscore|Statistics::Zed/zscore> if the three required B<observed>, B<expected> and B<variance> values were not defined in the present call (each to a reference to an array of values, or with a single numerical value), or could not be accessed from a previous load/add. See L<access|Statistics::Data/access> in Statistics::Data for any error that might have resulted from a bad load/add. See C<looks_like_number> in L<Scalar::Util|Scalar::Util> for any error that might have resulted from supplying a single value for B<observed>, B<expected> or B<variance>.

=item Cannot compute p-value: Argument 'tails' should have value of either 1 or 2, not '$tails'

Croaked when calling L<p_value|Statistics::Zed/p_value> directly or via L<zscore|Statistics::Zed/zscore>, or when calling L<p2z|Statistics::Zed/p2z>, and any given value for B<tails> is not appropriate.

=item Cannot compute z-value from p-value

Croaked by L<p2z|Statistics::Zed/p2z> if its B<value> attribute is not defined, is empty string, is not numeric, or, if numeric, is greater than 1 or less than zero, as per L<all_proportions|Statistics::Data/all_proportions> in Statistics::Data.

=item Cannot set tails() option: value must be numeric and equal either 1 or 2, not '$_'

Croaked from L<tails|Statistics::Zed/tails> method; self-explanatory.

=item Could not print statistical values

Croaked by the internal L<dump|Statistics::Zed/dump> method if, for some reason, printing to STDOUT is not available.

=back

=head1 DEPENDENCIES

L<Math::Cephes|Math::Cephes> - C<ndtr> and C<ndtri> normal distribution functions

L<Statistics::Lite|Statistics::Lite> - C<sum> method

L<String::Util|String::Util> - C<hascontent> and C<nocontent> methods

L<Scalar::Util|Scalar::Util> - C<looks_like_number> method

L<Statistics::Data|Statistics::Data> - this module uses the latter as a base, for its loading/adding data methods (if required), and a L<p2z|Statistics::Zed/p2z> validity check.

=head1 SEE ALSO

L<Statistics::Sequences|Statistics::Sequences> : for application of this module.

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2006-2014 Roderick Garton.

This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU General Public License as published by the Free Software Foundation; or the Artistic License. See L<perl.org|http://dev.perl.org/licenses/> for more information.

=cut

# End of Statistics::Zed

