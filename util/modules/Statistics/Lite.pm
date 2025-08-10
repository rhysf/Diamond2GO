package Statistics::Lite;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
require Exporter;

$VERSION = '3.62';
@ISA = qw(Exporter);
@EXPORT = ();
@EXPORT_OK = qw(min max range sum count mean median mode variance stddev variancep stddevp statshash statsinfo frequencies);
%EXPORT_TAGS=
(
	all   => [ @EXPORT_OK ],
	funcs => [qw<min max range sum count mean median mode variance stddev variancep stddevp>],
	stats => [qw<statshash statsinfo>],
);

sub definedvals
{
	return grep{defined}@_;
}

sub count
{
	return scalar definedvals @_;
}

sub min
{
	my @data = definedvals @_;
	return unless @data;
	return $data[0] unless @data > 1;
	my $min= shift @data;
	foreach(@data) { $min= $_ if $_ < $min; }
	return $min;
}

sub max
{
	my @data = definedvals @_;
	return unless @data;
	return $data[0] unless @data > 1;
	my $max= shift @data;
	foreach(@data) { $max= $_ if $_ > $max; }
	return $max;
}

sub range
{
	my @data = definedvals @_;
	return unless @data;
	return 0 unless @data > 1;
	return abs($data[1]-$data[0]) unless @data > 2;
	my $min= shift @data; my $max= $min;
	foreach(@data) { $min= $_ if $_ < $min; $max= $_ if $_ > $max; }
	return $max - $min;
}

sub sum
{
	my @data = definedvals @_;
	return unless @data;
	return $data[0] unless @data > 1;
	my $sum;
	foreach(@data) { $sum+= $_; }
	return $sum;
}

sub mean
{
	my @data = definedvals @_;
	return unless @data;
	return $data[0] unless @data > 1;
	return sum(@data)/scalar(@data);
}

sub median
{
	my @data = definedvals @_;
	return unless @data;
	return $data[0] unless @data > 1;
	@data= sort{$a<=>$b}@data;
	return $data[$#data/2] if @data&1;
	my $mid= @data/2;
	return ($data[$mid-1]+$data[$mid])/2;
}

sub mode
{
	my @data = definedvals @_;
	return unless @data;
	return $data[0] unless @data > 1;
	my %count;
	foreach(@data) { $count{$_}++; }
	my $maxhits= max(values %count);
	foreach(keys %count) { delete $count{$_} unless $count{$_} == $maxhits; }
	return mean(keys %count);
}

sub variance
{
	my @data = definedvals @_;
	return unless @data;
	return 0 unless @data > 1;
	my $mean= mean @data;
	return (sum map { ($_ - $mean)**2 } @data) / $#data;
}

sub variancep
{
	my @data = definedvals @_;
	return unless @data;
	return 0 unless @data > 1;
	my $mean= mean @data;
	return (sum map { ($_ - $mean)**2 } @data) / ( $#data +1 );
}

sub stddev
{
	my @data = definedvals @_;
	return unless @data;
	return 0 unless @data > 1;
	return sqrt variance @data;
}

sub stddevp
{
	my @data = definedvals @_;
	return unless @data;
	return 0 unless @data > 1;
	return sqrt variancep @data;
}

sub statshash
{
	my @data = definedvals @_;
	return unless @data;
	return
	(
		count     => 1,
		min       => $data[0],
		max       => $data[0],
		range     => 0,
		sum       => $data[0],
		mean      => $data[0],
		median    => $data[0],
		mode      => $data[0],
		variance  => 0,
		stddev    => 0,
		variancep => 0,
		stddevp   => 0
	) unless @data > 1;
	my $count= scalar(@data);
	@data= sort{$a<=>$b}@data;
	my $median;
	if(@data&1) { $median= $data[$#data/2]; }
	else { my $mid= @data/2; $median= ($data[$mid-1]+$data[$mid])/2; }
	my $sum= 0;
	my %count;
	foreach(@data) { $sum+= $_; $count{$_}++; }
	my $mean= $sum/$count;
	my $maxhits= max(values %count);
	foreach(keys %count)
	{ delete $count{$_} unless $count{$_} == $maxhits; }
	return
	(
		count     => $count,
		min       => $data[0],
		max       => $data[-1],
		range     => ($data[-1] - $data[0]),
		sum       => $sum,
		mean      => $mean,
		median    => $median,
		mode      => mean(keys %count),
		variance  => variance(@data),
		stddev    => stddev(@data),
		variancep => variancep(@data),
		stddevp   => stddevp(@data)
	);
}

sub statsinfo
{
	my %stats= statshash(@_);
	return <<".";
min       = $stats{min}
max       = $stats{max}
range     = $stats{range}
sum       = $stats{sum}
count     = $stats{count}
mean      = $stats{mean}
median    = $stats{median}
mode      = $stats{mode}
variance  = $stats{variance}
stddev    = $stats{stddev}
variancep = $stats{variancep}
stddevp   = $stats{stddevp}
.
}

sub frequencies
{
	my @data = definedvals @_;
	return unless @data;
	return ( $data[0], 1 ) unless @data > 1;
	my %count;
	foreach(@data) { $count{$_}++; }
	return %count;
}

1;
__END__

=head1 NAME

Statistics::Lite - Small stats stuff.

=head1 SYNOPSIS

	use Statistics::Lite qw(:all);

	$min= min @data;
	$mean= mean @data;

	%data= statshash @data;
	print "sum= $data{sum} stddev= $data{stddev}\n";

	print statsinfo(@data);

=head1 DESCRIPTION

This module is a lightweight, functional alternative to larger, more complete,
object-oriented statistics packages.
As such, it is likely to be better suited, in general, to smaller data sets.

This is also a module for dilettantes.

When you just want something to give some very basic, high-school-level statistical values,
without having to set up and populate an object first, this module may be useful.

=head2 NOTE

This module implements standard deviation and variance calculated by both the unbiased and biased estimators.

=head1 FUNCTIONS

=over 4

=item C<min(@data)>, C<max(@data)>, C<range(@data)>, C<sum(@data)>, C<count(@data)>

Returns the minimum value, maximum value, range (max - min),
sum, or count of values in C<@data>. Undefined values are ignored.

C<count(@data)> simply returns C<scalar(@data)>.

B<Please note> that this module does B<not> ignore undefined values in your
data; instead, those are B<treated as zero>.

=item C<mean(@data)>, C<median(@data)>, C<mode(@data)>

Calculates the mean, median, or mode average of the values in C<@data>. Undefined values are ignored.
(In the event of ties in the mode average, their mean is returned.)

=item C<variance(@data)>, C<stddev(@data)>

Returns the standard deviation or variance of C<@data> for a sample (same as Excel's STDEV).
This is also called the Unbiased Sample Variance and involves dividing the
sample's squared deviations by N-1 (the sample count minus 1).
The standard deviation is just the square root of the variance.

=item C<variancep(@data)>, C<stddevp(@data)>

Returns the standard deviation or variance of C<@data> for the population (same as Excel's STDEVP).
This involves dividing the squared deviations of the population by N (the population size).
The standard deviation is just the square root of the variance.

=item C<statshash(@data)>

Returns a hash whose keys are the names of all the functions listed above,
with the corresponding values, calculated for the data set.

=item C<statsinfo(@data)>

Returns a string describing the data set, using the values detailed above.

=item C<frequencies(@data)>

Returns a hash. The keys are the distinct values in the data set,
and the values are the number of times that value occurred in the data set.

=back

=head2 Import Tags

The C<:all> import tag imports all exportable functions from this module into
the current namespace (use with caution). More specifically, these functions
are the following: C<min>, C<max>, C<range>, C<sum>, C<count>, C<mean>,
C<median>, C<mode>, C<variance>, C<stddev>, C<variancep>, C<stddevp>,
C<statshash>, C<statsinfo>, and C<frequencies>.

To import the statistical functions, use the import tag C<:funcs>.  This
imports all of the above-mentioned functions, except for C<statshash>,
C<statsinfo>, and C<frequencies>.

Use C<:stats> to import C<statshash(@data)> and C<statsinfo(@data)>.

=head1 REPOSITORY

L<https://github.com/brianary/Statistics-Lite>

=head1 AUTHOR

Brian Lalonde E<lt>brian@webcoder.infoE<gt>,
C<stddev(@data)>, C<stddevp(@data)>, C<variance(@data)>, C<variancep(@data)>,
additional motivation by Nathan Haigh, with kind support from Alexander Zangerl.

The project lives at https://github.com/brianary/Statistics-Lite

=head1 COPYRIGHT AND LICENSE

Copyright 2000 Brian Lalonde E<lt>brian@webcoder.infoE<gt>, Nathan Haigh,
Alexander Zangerl, and Ton Voon.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

=head1 SEE ALSO

perl(1).

=cut
