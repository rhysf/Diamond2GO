package Statistics::Data;
use strict;
use warnings FATAL => 'all';
use FindBin qw($Bin);
use lib "$Bin/../";
use Carp qw(carp croak);
use List::AllUtils qw(all first)
  ;    # i.e., single method 'all', not ':all' methods
use Number::Misc qw(is_even);
use Scalar::Util qw(looks_like_number);
use String::Util qw(hascontent nocontent);
our $VERSION = '0.11';

=head1 NAME

Statistics::Data - Load, access, update one or more data lists for statistical analysis

=head1 VERSION

This is documentation for B<Version 0.11> of Statistics/Data.pm, released Jan 2017.

=head1 SYNOPSIS

 use Statistics::Data 0.11;
 my $dat = Statistics::Data->new();

 # with named arrays:
 $dat->load({'aname' => \@data1, 'anothername' => \@data2}); # names are arbitrary
 $aref = $dat->access(name => 'aname'); # gets back a copy of @data1
 $dat->add('aname' => [2, 3]); # pushes new values onto loaded copy of @data1
 $dat->dump_list(); # print to check if both arrays are loaded and their number of elements
 $dat->unload(name => 'anothername'); # only 'aname' data remains loaded
 $aref = $dat->access(name => 'aname'); # $aref is a reference to a copy of @data1
 $href = $dat->get_hoa(); # get all data
 $dat->dump_vals(name => 'aname', delim => ','); # proof in print it's back 

 # with multiple anonymous arrays:
 $dat->load(\@data1, \@data2); # any number of anonymous arrays
 $dat->add([2], [6]); # pushes a single value apiece onto copies of @data1 and @data2
 $aref = $dat->access(index => 1); # returns reference to copy of @data2, with its new values
 $dat->unload(index => 0); # only @data2 remains loaded, and its index is now 0

=head1 DESCRIPTION

Handles data for some other statistics modules, as in loading, updating and retrieving data for analysis. Performs no actual statistical analysis itself.

Rationale is not wanting to write the same or similar load, add, etc. methods for every statistics module, not to provide an omnibus API for Perl stat modules. It, however, encompasses much of the variety of how Perl stats modules do the basic handling their data. Used for L<Statistics::Sequences|Statistics::Sequences> (and its sub-tests). 

=head1 SUBROUTINES/METHODS

Manages caches of one or more lists of data for use by some other statistics modules. The lists are ordered arrays comprised of literal scalars (numbers, strings). They can be loaded, added to (updated), accessed or unloaded by referring to the index (order) in which they have been loaded (or previously added to), or by a particular name. The lists are cached within the class object's '_DATA' aref as an aref itself, optionally associated with a 'name'. The particular structures supported here to load, update, retrieve, unload data are specified under L<load|Statistics::Data/load>. Any module that uses this one as its base can still use its own rules to select the appropriate list, or provide the appropriate list within the call to itself.

=head2 Constructors

=head3 new

 $dat = Statistics::Data->new();

Returns a new Statistics::Data object.

=cut

sub new {
    my $class = shift;
    my $self = bless {}, ref($class) ? ref($class) : $class;
    $self->{_DATA} = [];
    return $self;
}

=head3 clone

 $new_self = $dat->clone();

I<Alias>: B<clone>

Returns a copy of the class object with its data loaded (if any). This is not a copy of any particular data but the whole blessed hash; nothing modified in this new object affects the original.

=cut

sub clone {
    my $self = shift;
    require Clone;
    return Clone::clone($self);
}
*copy = \*clone;

=head2 Setting data

Methods to cache and uncache data into the data-object.

=head3 load

 $dat->load(ARRAY);             # CASE 1 - can be updated/retrieved anonymously, or as index => i (load order)
 $dat->load(AREF);            # CASE 2 - same, as aref
 $dat->load(STRING => AREF);    # CASE 3 - updated/retrieved as name => 'data' (arbitrary name); or by index (order)
 $dat->load({ STRING => AREF }) # CASE 4 - same as CASE 4, as hashref
 $dat->load(STRING => AREF, STRING => AREF);      # CASE 5 - same as CASE 3 but with multiple named loads
 $dat->load({ STRING => AREF, STRING => AREF });  # CASE 6 - same as CASE 5 bu as hashref
 $dat->load(AREF, AREF);  # CASE 7 - same as CASE 2 but with multiple aref loads

 # Not supported:
 #$dat->load(STRING => ARRAY); # not OK - use CASE 3 instead
 #$dat->load([AREF, AREF]); # not OK - use CASE 7 instead
 #$dat->load([ [STRING => AREF], [STRING => AREF] ]); # not OK - use CASE 5 or CASE 6 instead
 #$dat->load(STRING => AREF, STRING => [AREF, AREF]); # not OK - too mixed to make sense

I<Alias>: B<load_data>

Cache a list of data as an array-reference. Each call removes previous loads, as does sending nothing. If data need to be cached without unloading previous loads, use the L<add|Statistics::Data/add> method instead. Arguments with the following structures are acceptable as data, and will be L<access|Statistics::Data/access>ible by either index or name as expected:

=over 4

=item load ARRAY

Load an anonymous array that has no named values. For example:

 $dat->load(1, 4, 7);
 $dat->load(@ari);

This is loaded as a single flat list, with an undefined name, and indexed as 0. Note that trying to load a named dataset with an unreferenced array is wrong - the name will be "folded" into the array itself.

=item load AREF

Load a reference to a single anonymous array that has no named values, e.g.: 

 $dat->load([1, 4, 7]);
 $dat->load(\@ari);

This is loaded as a single flat list, with an undefined name, and indexed as 0.

=item load ARRAY of AREF(s)

Same as above, but note that more than one unnamed array-reference can also be loaded at once, e.g.:

 $dat->load([1, 4, 7], [2, 5, 9]);
 $dat->load(\@ari1, \@ari2);

Each array can be accessed, using L<access|Statistics::Data/access>, by specifying B<index> => index, the latter value representing the order in which these arrays were loaded.

=item load HASH of AREF(s)

Load one or more named references to arrays, e.g.:

 $dat->load('dist1' => [1, 4, 7]);
 $dat->load('dist1' => [1, 4, 7], 'dist2' => [2, 5, 9]);

This loads the array(s) with a name attribute, so that when calling L<access|Statistics::Data/access>, they can be retrieved by name, e.g., passing B<name> => 'dist1'. The load method involves a check that there is an even number of arguments, and that, if this really is a hash, all the keys are defined and not empty, and all the values are in fact array-references.

=item load HASHREF of AREF(s)

As above, but where the hash is referenced, e.g.:

 $dat->load({'dist1' => [1, 4, 7], 'dist2' => [2, 5, 9]});

=back

This means that using the following forms--including a referenced array of referenced arrays--will produce unexpected results, if they do not actually croak, and so should not be used:

 $dat->load(data => @data); # no croak but wrong - puts "data" in @data - use \@data
 $dat->load([\@blue_data, \@red_data]); # use unreferenced ARRAY of AREFs instead
 $dat->load([ [blues => \@blue_data], [reds => \@red_data] ]); # treated as single AREF; use HASH of AREFs instead
 $dat->load(blues => \@blue_data, reds => [\@red_data1, \@red_data2]); # mixed structures not supported

A warning is I<not> thrown if any of the given arrays actually contain no data; could cause too many warnings if multiple analyses on different datasets are run.

=cut

sub load
{ # load single aref: cannot load more than one array; keeps a direct reference to the data: any edits creep back.
    my ( $self, @args ) = @_;
    $self->unload();
    $self->add(@args);
    return 1;
}
*load_data = \&load;

=head3 add

I<Alias>: B<add_data>, B<append_data>, B<update>

Same usage as above for L<load|Statistics::Data/load>. Just push any value(s) or so along, or loads an entirely named list, without clobbering what's already in there (as L<load|Statistics::Data/load> would). If data have not been loaded with a name, then appending data to them happens according to the order of array-refs set here; e.g., $dat->add([], \new_data) adds nothing to the first loaded list, and initialises a second array, if none already, or appends the new data to it.

=cut

sub add {
    my ( $self, @args ) = @_;
    my $href = _init_data( $self, @args );    # href of array(s) keyed by index
    while ( my ( $i, $val ) = each %{$href} ) {
        if ( defined $val->{'name'} ) {       # new named data
            $self->{_DATA}->[$i] =
              { aref => $val->{'aref'}, name => $val->{'name'} };
        }
        else {    # new data, anonymous, indexed only
            push @{ $self->{_DATA}->[$i]->{'aref'} }, @{ $val->{'aref'} };
        }
    }
    return;
}
*add_data = \&add;
*update   = \&add;

=head3 unload

 $dat->unload(); # deletes all cached data, named or not
 $dat->unload(index => POSINT); # deletes the aref named 'data' whatever
 $dat->unload(name => STRING); # deletes the aref named 'data' whatever

Empty, clear, clobber what's in there. Does nothing if given index or name that does not refer to any loaded data. This should be used whenever any already loaded or added data are no longer required ahead of another L<add|Statistics::Data/add>, including via L<copy|Statistics::Data/copy> or L<share|Statistics::Data/share>.

=cut

sub unload {
    my ( $self, @args ) = @_;
    if ( !$args[0] ) {
        $self->{_DATA} = [];
    }
    else {
        my $i = _get_aref_index_by_args( $self, @args );
        if ( defined $i ) {
            splice @{ $self->{_DATA} }, $i, 1;
        }
    }
    return;
}

=head3 share

 $dat_new->share($dat_old);

Adds all the data from one Statistics::Data object to another. Changes in the new copies do not affect the originals.

=cut

sub share {
    my ( $self, $other ) = @_;
    _add_from_object_aref( $self, $other->{_DATA} );
    return 1;
}

=head2 Getting data

=head3 get_aref

  $aref = $dat->get_aref(name => STRING);
  $aref = $dat->get_aref();

Returns a reference to a single, previously loaded hashref of arrayed of data, as specified in the named argument B<name>. The array is empty if no data have been loaded, or if there is none with the given B<name>. If B<name> is not defined, and there is only one loaded array, a reference to that array is returned; otherwise croaks.

=cut

sub get_aref {
    my ( $self, %args ) = @_;
    my $name_aref = _get_argument_name_or_names( \%args );
    my $data_aref = [];
    if ( nocontent($name_aref)) {
        if ($self->ndata() == 1 ) {
            $data_aref = $self->{_DATA}->[0]->{'aref'};
        }
        else {
            croak 'Data to get need to be named';
        }
    }
    else {
        my $i = _get_aref_index_by_name( $self, $name_aref->[0] );

# is name loaded with data? ($i only defined if the name matched data already loaded)
        if ( defined $i ) {
            $data_aref = $self->{_DATA}->[$i]->{'aref'};
        }
    }
    return $data_aref;
}
*get_aref_by_lab = \&get_aref;

=head3 get_aoa

 $aref_of_arefs = $dat->get_aoa(name => AREF);
 $aref_of_arefs = $dat->get_aoa(); # all loaded data

Returns a reference to an array where each value is itself an array of data, as separately loaded under a different name or anonymously, in the order that they were loaded. If no B<name> value is defined, all the loaded data are returned as a list of arefs.

=cut

sub get_aoa {
    my ( $self, %args ) = @_;
    my $name_aref = _get_argument_name_or_names( \%args );
    my @data      = ();
    if ( !ref $name_aref ) {    # get all data
        for my $i ( 0 .. $self->ndata() - 1 ) {
            $data[$i] = $self->{_DATA}->[$i]->{'aref'};
        }
    }
    else {                      # get named data
        for my $i ( 0 .. scalar @{$name_aref} - 1 ) {    # assume ref eq 'ARRAY'
            my $j = _get_aref_index_by_name( $self, $name_aref->[$i] )
              ;    # is name loaded with data?
            if ( defined $j ) {
                $data[$i] = $self->{_DATA}->[$j]->{'aref'};
            }      # else ignore the given name
        }
    }
    return wantarray ? @data : \@data;  # unreferenced for chance legacy for now
}
*get_aoa_by_lab = \&get_aoa;

=head3 get_hoa

  $href = $data->get_hoa(name => AREF); # 1 or more named data
  $href = $data->get_hoa(); # all named data
  %hash = $data->get_hoa(); # same but unreferenced

Returns a hash or hashref of arefs, where the keys are the names of the loaded data, and the values are arefs of their associated data. 

By default, all of the loaded data are returned in the (reference to a) hash. The optional argument B<name> is used to return one or more specific data-arrays in the hashref, given a referenced array of their names. Names that have never been used are ignored, and an empty hash (ref) is returned if all names are unknown, or there are no loaded data.

=cut

sub get_hoa {
    my ( $self, %args ) = @_;
    my $name_aref = _get_argument_name_or_names( \%args );
    my %data      = ();
    if ( !ref $name_aref ) {    # get all data
        for my $i ( 0 .. $self->ndata() - 1 ) {
            if ( hascontent( $self->{_DATA}->[$i]->{'name'} ) ) {
                $data{ $self->{_DATA}->[$i]->{'name'} } =
                  $self->{_DATA}->[$i]->{'aref'};
            }
        }
    }
    else {                      # get named data
        for my $i ( 0 .. scalar @{$name_aref} - 1 ) {    # assume ref eq 'ARRAY'
            my $j = _get_aref_index_by_name( $self, $name_aref->[$i] )
              ;    # is name loaded with data?
            if ( defined $j ) {
                $data{ $name_aref->[$i] } = $self->{_DATA}->[$j]->{'aref'};
            }      # else ignore the given name
        }
    }
    return wantarray ? %data : \%data;
}
*get_hoa_by_lab = \&get_hoa;

=head3 get_hoa_numonly_indep

 $hoa = $dat->get_hoa_numonly_indep(name => AREF);
 $hoa = $dat->get_hoa_numonly_indep();

Same as L<get_hoa|get_hoa> but each array is culled of any empty or non-numeric values as independent variables, with culls in one array not creating a cull on any other.

=cut

sub get_hoa_numonly_indep {
    my ( $self, %args ) = @_;
    return _cull_hoa_indep( scalar $self->get_hoa(%args), \$self->{'purged'} );
}
*get_hoa_by_lab_numonly_indep = \&get_hoa_numonly_indep;

=head3 get_hoa_numonly_across

 $hoa = $dat->get_hoa_numonly_across(); # same as get_hoa but each list culled of NaNs at same i across lists

Returns hashref of previously loaded variable data (as arefs) culled of an empty or non-numerical values whereby a valid value in one list is culled if it is at an index that is invalid in another list. This is the type of data useful for a dependent ANOVA.

=cut

sub get_hoa_numonly_across {
    my ( $self, %args ) = @_;
    return _cull_hoa_across( scalar $self->get_hoa(%args), \$self->{'purged'} );
}
*get_hoa_by_lab_numonly_across = \&get_hoa_numonly_across;

=head3 access

 $aref = $dat->access(); #returns the first and/or only array loaded, if any
 $aref = $dat->access(index => INT); #returns the ith array loaded
 $aref = $dat->access(name => STRING); # returns a particular named cache of data

Returns an aref given its B<index> for order of being "L<add|Statistics::Data/add>ed" to the loaded data, or by explicit B<name> (as by L<get_aref|Statistics::Data/get_aref>). Default returned is the first loaded data, which is reliable if there is only one loaded array.

=cut

sub access {
    my ( $self, @args ) = @_;
    return $self->{_DATA}->[_get_aref_index_by_args( $self, @args )]->{'aref'};
}
*read = \&access;    # legacy only

=head3 ndata

 $n = $dat->ndata();

Returns the number of loaded arrays.

=cut

sub ndata {
    my $self = shift;
    return scalar( @{ $self->{'_DATA'} } );
}

=head3 names

 $aref = $dat->names();

Returns a reference to an array of all the datanames, if any.

=cut

sub names {
    my $self  = shift;
    my @names = ();
    for ( 0 .. scalar @{ $self->{'_DATA'} } - 1 ) {
        if ( hascontent( $self->{'_DATA'}->[$_]->{'name'} ) ) {
            push @names, $self->{'_DATA'}->[$_]->{'name'};
        }
    }
    return \@names;
}
*labels = \&names;

=head2 Checking data

=head3 all_full

 $bool = $dat->all_full(AREF); # test data are valid before loading them
 $bool = $dat->all_full(name => STRING); # checking after loading/adding the data (or key in 'index')

Checks not only if the data array, as named or indexed, exists, but if it is non-empty: has no empty elements, with any elements that might exist in there being checked with L<hascontent|String::Util/hascontent>.

=cut

sub all_full {
    my ( $self, @args ) = @_;
    my $data = ref $args[0] ? shift @args : $self->access(@args);
    my ( $bool, @vals ) = ();
    for ( @{$data} ) {
        $bool = nocontent($_) ? 0 : 1;
        if (wantarray) {
            if ($bool) {
                push @vals, $_;
            }
        }
        else {
            last if $bool == 0;
        }
    }
    return wantarray ? ( \@vals, $bool ) : $bool;
}

=head3 all_numeric

 $bool = $dat->all_numeric(); # test data first-loaded, if any
 $bool = $dat->all_numeric(AREF); # test these data are valid before loading them
 $bool = $dat->all_numeric(name => STRING); # check specific data after loading/adding them by a 'name' or by their 'index' order
 ($aref, $bool) = $dat->all_numeric([3, '', 4.7, undef, 'b']); # returns ([3, 4.7], 0); - same for any loaded data

Given an aref of data, or reference to data previously loaded (see L<access|Statistics::Data/access>), tests numeracy of each element, and return, if called in scalar context, a boolean scalar indicating if all data in this aref are defined and not empty (using C<nocontent> in L<String::Util|String::Util/nocontent>), and, if they have content, if these are all numerical, using C<looks_like_number> in L<Scalar::Util|Scalar::Util/looks_like_number>. Alternatively, if called in list context, returns the data (as an aref) less any values that failed this test, followed by the boolean. If the requested data do not exist, returns undef.

=cut

sub all_numeric {
    my ( $self, @args ) = @_;
    my ( $data, $bool, @vals ) = ();
    if ( ref $args[0] eq 'ARRAY' ) {
        $data = shift @args;
    }
    else {
        my $i = _get_aref_index_by_args( $self, @args );
        if ( defined $i ) {
            $data = $self->{_DATA}->[$i]->{'aref'};
        }
    }
    if ( ref $data ) {
        for ( @{$data} ) {
            $bool = _nan($_) ? 0 : 1;
            if (wantarray) {
                if ($bool) {
                    push @vals, $_;
                }
            }
            else {
                last if $bool == 0;
            }
            $data = \@vals;
        }
        return ( wantarray and $data )
          ? ( $data, $bool )
          : $bool
          ; # just bool even if wantarray when there is no array to return (so bool is null)
    }
    else {
        return;
    }

}
*all_numerical = \&all_numeric;

=head3 all_proportions

 $bool = $dat->all_proportions(AREF); # test data are valid before loading them
 $bool = $dat->all_proportions(name => STRING); # checking after loading/adding the data  (or key in 'index')

Ensure data are all proportions. Sometimes, the data a module needs are all proportions, ranging from 0 to 1 inclusive. A dataset might have to be cleaned 

=cut

sub all_proportions {
    my ( $self, @args ) = @_;
    my $data = ref $args[0] ? shift @args : $self->access(@args);
    my ( $bool, @vals ) = ();
    for ( @{$data} ) {
        if ( nocontent($_) ) {
            $bool = 0;
        }
        elsif ( looks_like_number($_) ) {
            $bool = ( $_ < 0 || $_ > 1 ) ? 0 : 1;
        }
        if (wantarray) {
            if ($bool) {
                push @vals, $_;
            }
        }
        else {
            last if $bool == 0;
        }
    }
    return wantarray ? ( \@vals, $bool ) : $bool;
}

=head3 all_counts

 $bool = $dat->all_counts(AREF); # test data are valid before loading them
 $bool = $dat->all_counts(name => STRING); # checking after loading/adding the data  (or key in 'index')
 ($aref, $bool) = $dat->all_counts(AREF);

Returns true if all values in given data are real positive integers or zero, as well as satisfying "hascontent" and "looks_like_number" methods; false otherwise. Called in list context, returns aref of data culled of any values that are false on this basis, and then the boolean. For example, [2.2, 3, 4] and [-1, 3, 4] both fail, but [1, 3, 4] is true. Integer test is simply if $v == int($v).

=cut

sub all_counts {
    my ( $self, @args ) = @_;
    my $data = ref $args[0] ? shift @args : $self->access(@args);
    my ( $bool, @vals ) = ();
    for ( @{$data} ) {
        if ( nocontent($_) ) {
            $bool = 0;
        }
        elsif ( looks_like_number($_) ) {
            $bool = $_ >= 0 && $_ == int $_ ? 1 : 0;
        }
        else {
            $bool = 0;
        }
        if (wantarray) {
            if ($bool) {
                push @vals, $_;
            }
        }
        else {
            last if $bool == 0;
        }
    }
    return wantarray ? ( \@vals, $bool ) : $bool;
}

=head3 all_pos

 $bool = $dat->all_pos(AREF); # test data are valid before loading them
 $bool = $dat->all_pos(name => STRING); # checking after loading/adding the data  (or key in 'index')
 ($aref, $bool) = $dat->all_pos(AREF);

Returns true if all values in given data are greater than zero, as well as "hascontent" and "looks_like_number"; false otherwise. Called in list context, returns aref of data culled of any values that are false on this basis, and then the boolean. 

=cut

sub all_pos {
    my ( $self, @args ) = @_;
    my $data = ref $args[0] ? shift @args : $self->access(@args);
    my ( $bool, @vals ) = ();
    for ( @{$data} ) {
        if ( nocontent($_) ) {
            $bool = 0;
        }
        elsif ( looks_like_number($_) ) {
            $bool = $_ > 0 ? 1 : 0;
        }
        if (wantarray) {
            if ($bool) {
                push @vals, $_;
            }
        }
        else {
            last if $bool == 0;
        }
    }
    return wantarray ? ( \@vals, $bool ) : $bool;
}

=head3 equal_n

 $num = $dat->equal_n(); # number of vals in each loaded data if equal; else 0
 $num = $dat->equal_n(name => AREF); # names of loaded data to check

If the named loaded data all have the same number of elements, then that number is returned; otherwise 0.

=cut

sub equal_n {
    my ( $self, %args ) = @_;

    # supports specific "data" as a name for legacy - to be culled
    my $data =
      $args{'data'} ? delete $args{'data'} : $self->get_hoa(%args);
    my @data = values %{$data};
    my $n    = scalar @{ $data[0] };
    for ( 1 .. scalar @data - 1 ) {
        my $count = scalar @{ $data[$_] };
        if ( $count != $n ) {
            $n = 0;
            last;
        }
        else {
            $n = $count;
        }
    }
    return $n;
}

=head2 Dumping data

=head3 dump_vals

 $dat->dump_vals(delim => ", "); # assumes the first (only?) loaded array should be dumped
 $dat->dump_vals(index => INT, delim => ", "); # dump the i'th loaded array
 $dat->dump_vals(name => STRING, delim => ", "); # dump the array loaded/added with the given "name"

Prints to STDOUT a space-separated line (ending with "\n") of a loaded/added data's elements. Optionally, give a value for B<delim> to specify how the elements in each array should be separated; default is a single space.

=cut

sub dump_vals {
    my ( $self, @args ) = @_;
    my $args = ref $args[0] ? $args[0] : {@args};
    my $delim = $args->{'delim'} || q{ };
    print {*STDOUT} join( $delim, @{ $self->access($args) } ), "\n"
      or croak 'Could not print line to STDOUT';
    return 1;
}

=head3 dump_list

Dumps a list (using L<Text::SimpleTable|Text::SimpleTable>) of the data currently loaded, without showing their actual elements. List is firstly by index, then by name (if any), then gives the number of elements in the associated array.

=cut

sub dump_list {
    my $self = shift;
    my ( $lim, $name, $N, $len_name, $len_n, $tbl, @rows, @maxlens ) = ();
    $lim = $self->ndata();
    my $default = 5;
    @maxlens = ( ( $lim > $default ? $lim : $default ), $default, 1 );
    for my $i ( 0 .. $lim - 1 ) {
        $name =
          defined $self->{_DATA}->[$i]->{'name'}
          ? $self->{_DATA}->[$i]->{'name'}
          : q{-};
        $N        = scalar @{ $self->{_DATA}->[$i]->{'aref'} };
        $len_name = length $name;
        $len_n    = length $N;
        if ( $len_name > $maxlens[1] ) {
            $maxlens[1] = $len_name;
        }
        if ( $len_n > $maxlens[2] ) {
            $maxlens[2] = $len_n;
        }
        $rows[$i] = [ $i, $name, $N ];
    }
    require Text::SimpleTable;
    $tbl = Text::SimpleTable->new(
        [ $maxlens[0], 'index' ],
        [ $maxlens[1], 'name' ],
        [ $maxlens[2], 'N' ]
    );
    for (@rows) {
        $tbl->row( @{$_} );
    }
    print {*STDOUT} $tbl->draw or croak 'Could not print list of loaded data';
    return 1;
}

# PRIVATE METHODS:

sub _cull_hoa_indep {
    my ( $hoa,    $purged_n )    = @_;
    my ( $purged, %purged_data ) = 0;
    for my $name ( keys %{$hoa} ) {
        my @clean = ();
        for my $i ( 0 .. scalar( @{ $hoa->{$name} } ) - 1 ) {
            if ( _nan( $hoa->{$name}->[$i] ) ) {
                $purged++;
            }
            else {
                push @clean, $hoa->{$name}->[$i];
            }
        }
        $purged_data{$name} = [@clean];
    }
    ${$purged_n} = $purged;
    return wantarray ? %purged_data : \%purged_data;
}

sub _cull_hoa_across {
    my ( $hoa, $purged_n ) = @_;

    # List all indices in all lists with invalid values;
    # and copy each group of data for cleaning:
    my $invalid_i_by_name = _href_of_idx_with_nans_per_name($hoa);
    my ( %clean, %invalid_idx ) = ();
    for my $name ( keys %{$hoa} ) {
        $clean{$name} = $hoa->{$name};
        while ( my ( $idx, $val ) = each %{ $invalid_i_by_name->{$name} } ) {
            $invalid_idx{$idx} += $val;
        }
    }

    ${$purged_n} = ( scalar keys %invalid_idx ) || 0;

    # Purge by index (from highest to lowest):
    for my $idx ( reverse sort { $a <=> $b } keys %invalid_idx ) {
        for my $name ( keys %clean ) {
            if ( $idx < scalar @{ $clean{$name} } ) {
                splice @{ $clean{$name} }, $idx, 1;
            }
        }
    }
    return wantarray ? %clean : \%clean;
}

sub _init_data {
    my ( $self, @args ) = @_;

    my $data = {};
    if ( _isa_hashref_of_arefs( $args[0] ) ) {    # cases 4 & 6
        $data = _init_named_data( $self, $args[0] );
    }
    elsif ( _isa_hash_of_arefs(@args) ) {         # cases 3 & 5
        $data = _init_named_data( $self, {@args} );
    }
    elsif ( _isa_array_of_arefs(@args) ) {        # cases 2 & 7
        $data = _init_unnamed_data(@args);
    }
    else {    # assume @args is just a list of strings - case 1
        if ( ref $args[0] ) {
            croak
'Don\'t know how to load/add the given data: Need to be in the structure of HOA (referenced or not), or an unreferenced AOA';
        }
        else {
            $data->{0} = { aref => [@args], name => undef };
        }
    }
    return $data;
}

sub _isa_hashref_of_arefs {
    my $arg = shift;
    if ( not ref $arg or ref $arg ne 'HASH' ) {
        return 0;
    }
    else {
        return _isa_hash_of_arefs( %{$arg} );
    }
}

sub _isa_hash_of_arefs {

    # determines that:
    # - scalar @args passes Number::Misc is_even, then that:
    # - every odd indexed value 'hascontent' via String::Util
    # - every even indexed value is aref
    my @args = @_;
    my $bool = 0;
    if ( is_even( scalar @args ) )
    {    # Number::Misc method - not odd number in assignment
        my %args = @args;    # so assume is hash
      HASH_CHECK:
        while ( my ( $name, $val ) = each %args ) {
            if ( hascontent($name) && ref $val eq 'ARRAY' ) {
                $bool = 1;
            }
            else {
                $bool = 0;
            }
            last HASH_CHECK if $bool == 0;
        }
    }
    else {
        $bool = 0;
    }
    return $bool;
}

sub _isa_array_of_arefs {
    my @args = @_;
    if ( all { ref $_ eq 'ARRAY' } @args ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub _init_named_data {
    my ( $self, $href ) = @_;
    my ( $i,    %data ) = ( scalar @{ $self->{_DATA} } );
    while ( my ( $name, $aref ) = each %{$href} ) {
        my $j = _get_aref_index_by_name( $self, $name );
        if ( defined $j )
        { # already a name for these data, so don't need to define it for this init
            $data{$j} = { aref => [ @{$aref} ], name => undef };
        }
        else {    # no aref named $name yet: define for aref and name
            $data{ $i++ } = { aref => [ @{$aref} ], name => $name };
        }
    }
    return \%data;
}

sub _init_unnamed_data {
    my @args = @_;
    my %data = ();
    for my $i ( 0 .. scalar @args - 1 ) {
        $data{$i} = { aref => [ @{ $args[$i] } ], name => undef };
    }
    return \%data;
}

sub _get_aref_index_by_args {
    my ( $self, @args ) = @_;
    my $i = 0; # get first by default
        my $args = ref $args[0] ? $args[0] : {@args};
        if ( looks_like_number( $args->{'index'} ) and ref $self->{_DATA}->[$args->{'index'}] ) {
            $i = $args->{'index'};
        }
        else {
            my $name = _name_or_label($args);
            if ( hascontent($name) ) {
                $i = _get_aref_index_by_name( $self, $name );
            }
        }
    return $i;
}

sub _get_aref_index_by_name {
    my ( $self, $name ) = @_;
    my ( $i, $found ) = ( 0, 0 );
    for ( ; $i < scalar @{ $self->{_DATA} } ; $i++ ) {
        if (    $self->{_DATA}->[$i]->{'name'}
            and $self->{_DATA}->[$i]->{'name'} eq $name )
        {
            $found = 1;
            last;
        }
    }
    return $found ? $i : undef;
}

sub _add_from_object_aref {
    my ( $self, $aref ) = @_;
    for my $dat ( @{$aref} ) {
        if ( hascontent( $dat->{'name'} ) ) {
            $self->add( $dat->{'name'} => $dat->{'aref'} );
        }
        else {
            $self->add( $dat->{'aref'} );
        }
    }
    return 1;
}

sub _href_of_idx_with_nans_per_name {
    my $hoa               = shift;
    my %invalid_i_by_name = ();
    for my $name ( keys %{$hoa} ) {
        for my $i ( 0 .. scalar( @{ $hoa->{$name} } ) - 1 ) {
            if ( _nan( $hoa->{$name}->[$i] ) ) {
                $invalid_i_by_name{$name}->{$i} = 1;
            }
        }
    }
    return \%invalid_i_by_name;
}

# Return AREF of names given as an aref or single string as value to optional argument:
sub _get_argument_name_or_names {
    my $href = shift;
    my $var  = _name_or_label($href);
    return hascontent($var) ? ref $var ? $var : [$var] : q{};
}

sub _name_or_label {
    my $href = shift;
    my $str = first { $href->{$_} } qw/lab label name/;
    return $str ? $href->{$str} : q{};
}

sub _nan {
    return !looks_like_number(shift) ? 1 : 0;
}

## Deprecated/obsolete methods:
sub load_from_file {
    croak __PACKAGE__
      . ': load_from_file() method is obsolete from v.11; read-in and save data by your own methods';
}

sub save_to_file {
    croak __PACKAGE__
      . ': load_from_file() method is obsolete from v.11; read-in and save data by your own methods';
}

=head1 DIAGNOSTICS

=over 4

=item Don't know how to load/add the given data

Croaked when attempting to load or add data with an unsupported data structure where the first argument is a reference. See the examples under L<load|Statistics::Data/load> for valid (and invalid) ways of sending data to them.

=item Data for accessing need to be loaded

Croaked when calling L<access|Statistics::Data/access>, or any methods that use it internally -- viz., L<dump_vals|Statistics::Data/dump_vals> and the validity checks L<all_numeric|Statistics::Data/all_numeric> -- when it is called with a name for data that have not been loaded, or did not load successfully.

=item Data for unloading need to be loaded

Croaked when calling L<unload|Statistics::Data/unload> with an index or a name attribute and the data these refer to have not been loaded, or did not load successfully.

=item Data to get need to be named

Croaked when calling L<get_aref|Statistics::Data/get_aref> and no name is specified for the aref to get, and there is more than one loaded aref to choose from.

=back

=head1 DEPENDENCIES

L<List::AllUtils|List::AllUtils> - used for its C<all> method when testing loads

L<Number::Misc|Number::Misc> - used for its C<is_even> method when testing loads

L<String::Util|String::Util> - used for its C<hascontent> and C<nocontent> methods

L<Scalar::Util|Scalar::Util> - required for L<all_numeric|Statistics::Data/all_numeric>

L<Text::SimpleTable|Text::SimpleTable> - required for L<dump_list|Statistics::Data/dump_list>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-statistics-data-0.01 at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-Data-0.01>. This will notify the author, and then you'll automatically be notified of progress on your bug as any changes are made.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::Data

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-Data-0.11>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-Data-0.11>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-Data-0.11>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-Data-0.11/>

=back

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2009-2017 Roderick Garton

This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License. See L<perl.org|http://dev.perl.org/licenses/> for more information.

=cut

1;    # End of Statistics::Data
