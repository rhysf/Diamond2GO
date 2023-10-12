package Math::Cephes::Matrix;
use strict;
use warnings;
use vars qw(@EXPORT_OK $VERSION);

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(mat);

$VERSION = '0.5305';

require Math::Cephes;

sub new {
  my ($caller, $arr) = @_;
  my $refer = ref($caller);
  my $class = $refer || $caller;
  die "Must supply data for the matrix"
    unless ($refer or $arr);
  unless ($refer) {
    die "Please supply an array of arrays for the matrix data"
      unless (ref($arr) eq 'ARRAY' and ref($arr->[0]) eq 'ARRAY');
    my $n = scalar @$arr;
    my $m = scalar @{$arr->[0]};
    die "Matrices must be square" unless $m == $n;
  }
  my ($coef, $n);
  if ($refer) {
    $n = $caller->{n};
    my $cdata = $caller->{coef};
    foreach (@$cdata) {
      push @$coef, [ @$_];
    }
  }
  else {
    ($coef, $n) = ($arr, scalar @$arr);
  }
  bless { coef => $coef,
	  n => $n,
	}, $class;
}

sub mat {
  return Math::Cephes::Matrix->new(shift);
}

sub mat_to_vec {
  my $self = shift;
  my ($M, $n) = ($self->{coef}, $self->{n});
  my $A = [];
  for (my $i=0; $i<$n; $i++) {
    for (my $j=0; $j<$n; $j++) {
      my $index = $i*$n+$j;
      $A->[$index] = $M->[$i]->[$j];
    }
  }
  return $A;
}

sub vec_to_mat {
  my ($self, $X) = @_;
  my $n = $self->{n};
  my $I = [];
  for (my $i=0; $i<$n; $i++) {
    for (my $j=0; $j<$n; $j++) {
      my $index = $i*$n+$j;
      $I->[$i]->[$j] = $X->[$index];
    }
  }
  return $I;
}

sub check {
  my ($self, $B) = @_;
  my $na = $self->{n};
  my $ref = ref($B);
  if ($ref eq 'Math::Cephes::Matrix') {
    die "Matrices must be of the same size"
      unless $B->{n} == $na;
    return $B->coef;
  }
  elsif ($ref eq 'ARRAY') {
    my $nb = scalar @$B;
    my $ref0 = ref($B->[0]);
    if ($ref0 eq 'ARRAY') {
      my $m = scalar @{$B->[0]};
      die "Can only use square matrices" unless $m == $nb;
      die "Can only use matrices of the same size"
	unless $na == $nb;
      return $B;
    }
    elsif (not $ref0) {
      die "Can only use vectors of the same size" unless $nb == $na;
      return $B;
    }
    else {
      die "Unknown reference '$ref0' for data";
    }
  }
  else {
    die "Unknown reference '$ref' for data";
  }
}

sub coef {
  return $_[0]->{coef};
}

sub clr {
  my $self = shift;
  my $what = shift || 0;
  my $n = $self->{n};
  my $B = [];
  for (my $i=0; $i<$n; $i++) {
    for (my $j=0; $j<$n; $j++) {
      $B->[$i]->[$j] = $what;
    }
  }
  $self->{coef} = $B;
}

sub simq {
  my ($self, $B) = @_;
  $B = $self->check($B);
  my ($M, $n) = ($self->{coef}, $self->{n});
  die "Must supply an array reference for B" unless ref($B) eq 'ARRAY';
  my $A = $self->mat_to_vec();
  my $X = [split //, 0 x $n];
  my $IPS = [split //, 0 x $n];
  my $flag = 0;
  my $ret = Math::Cephes::simq($A, $B, $X, $n, $flag, $IPS);
  return $ret ? undef : $X;
}


sub inv {
  my $self = shift;
  my ($M, $n) = ($self->{coef}, $self->{n});
  my $A = $self->mat_to_vec();
  my $X = [split //, 0 x ($n*$n)];
  my $B = [split //, 0 x $n];
  my $IPS = [split //, 0 x $n];
  my $flag = 0;
  my $ret = Math::Cephes::minv($A, $X, $n, $B, $IPS);
  return undef if $ret;
  my $I = $self->vec_to_mat($X);
  return Math::Cephes::Matrix->new($I);
}

sub transp {
  my $self = shift;
  my ($M, $n) = ($self->{coef}, $self->{n});
  my $A = $self->mat_to_vec();
  my $T = [split //, 0 x ($n*$n)];
  Math::Cephes::mtransp($n, $A, $T);
  my $R = $self->vec_to_mat($T);
  return Math::Cephes::Matrix->new($R);
}

sub add {
  my ($self, $B) = @_;
  $B = $self->check($B);
  my ($A, $n) = ($self->{coef}, $self->{n});
  my $C = [];
  for (my $i=0; $i<$n; $i++) {
    for (my $j=0; $j<$n; $j++) {
      $C->[$i]->[$j] = $A->[$i]->[$j] + $B->[$i]->[$j];
    }
  }
  return Math::Cephes::Matrix->new($C);
}

sub sub {
  my ($self, $B) = @_;
  $B = $self->check($B);
  my ($A, $n) = ($self->{coef}, $self->{n});
  my $C = [];
  for (my $i=0; $i<$n; $i++) {
    for (my $j=0; $j<$n; $j++) {
      $C->[$i]->[$j] = $A->[$i]->[$j] - $B->[$i]->[$j];
    }
  }
  return Math::Cephes::Matrix->new($C);
}

sub mul {
  my ($self, $B) = @_;
  $B = $self->check($B);
  my ($A, $n) = ($self->{coef}, $self->{n});
  my $C = [];
  if (ref($B->[0]) eq 'ARRAY') {
    for (my $i=0; $i<$n; $i++) {
      for (my $j=0; $j<$n; $j++) {
	for (my $m=0; $m<$n; $m++) {
	  $C->[$i]->[$j] += $A->[$i]->[$m] * $B->[$m]->[$j];
	}
      }
    }
    return Math::Cephes::Matrix->new($C);
  }
  else {
    for (my $i=0; $i<$n; $i++) {
      for (my $m=0; $m<$n; $m++) {
	$C->[$i] += $A->[$i]->[$m] * $B->[$m];
      }
    }
    return $C;
  }
}

sub div {
  my ($self, $B) = @_;
  $B = $self->check($B);
  my $C = Math::Cephes::Matrix->new($B)->inv();
  my $D = $self->mul($C);
  return $D;
}

sub eigens {
  my $self = shift;
  my ($M, $n) = ($self->{coef}, $self->{n});
  my $A = [];
  for (my $i=0; $i<$n; $i++) {
    for (my $j=0; $j<$n; $j++) {
      my $index = ($i*$i+$i)/2 + $j;
      $A->[$index] = $M->[$i]->[$j];
    }
  }
  my $EV1 = [split //, 0 x ($n*$n)];
  my $E = [split //, 0 x $n];
  my $IPS = [split //, 0 x $n];
  Math::Cephes::eigens($A, $EV1, $E, $n);
  my $EV = $self->vec_to_mat($EV1);
  return ($E, Math::Cephes::Matrix->new($EV));
}

1;

__END__

=head1 NAME

Math::Cephes::Matrix - Perl interface to the cephes matrix routines

=head1 SYNOPSIS

  use Math::Cephes::Matrix qw(mat);
  # 'mat' is a shortcut for Math::Cephes::Matrix->new
  my $M = mat([ [1, 2, -1], [2, -3, 1], [1, 0, 3]]);
  my $C = mat([ [1, 2, 4], [2, 9, 2], [6, 2, 7]]);
  my $D = $M->add($C);          # D = M + C
  my $Dc = $D->coef;
  for (my $i=0; $i<3; $i++) {
    print "row $i:\n";
    for (my $j=0; $j<3; $j++) {
        print "\tcolumn $j: $Dc->[$i]->[$j]\n";
    }
  }

=head1 DESCRIPTION

This module is a layer on top of the basic routines in the
cephes math library for operations on square matrices. In
the following, a Math::Cephes::Matrix object is created as

  my $M = Math::Cephes::Matrix->new($arr_ref);

where C<$arr_ref> is a reference to an array of arrays, as
in the following example:

  $arr_ref = [ [1, 2, -1], [2, -3, 1], [1, 0, 3] ]

which represents

     / 1   2  -1  \
     | 2  -3   1  |
     \ 1   0   3  /

A copy of a I<Math::Cephes::Matrix> object may be done as

  my $M_copy = $M->new();

=head2 Methods

=over 4

=item I<coef>: get coefficients of the matrix

 SYNOPSIS:

 my $c = $M->coef;

 DESCRIPTION:

This returns an reference to an array of arrays
containing the coefficients of the matrix.

=item I<clr>: set all coefficients equal to a value.

 SYNOPSIS:

 $M->clr($n);

 DESCRIPTION:

This sets all the coefficients of the matrix identically to I<$n>.
If I<$n> is not given, a default of 0 is used.

=item I<add>: add two matrices

 SYNOPSIS:

 $P = $M->add($N);

 DESCRIPTION:

This sets $P equal to $M + $N.

=item I<sub>: subtract two matrices

 SYNOPSIS:

 $P = $M->sub($N);

 DESCRIPTION:

This sets $P equal to $M - $N.

=item I<mul>: multiply two matrices or a matrix and a vector

 SYNOPSIS:

 $P = $M->mul($N);

 DESCRIPTION:

This sets $P equal to $M * $N. This method can handle
matrix multiplication, when $N is a matrix, as well
as matrix-vector multiplication, where $N is an
array reference representing a column vector.

=item I<div>: divide two matrices

 SYNOPSIS:

 $P = $M->div($N);

 DESCRIPTION:

This sets $P equal to $M * ($N)^(-1).

=item I<inv>: invert a matrix

 SYNOPSIS:

 $I = $M->inv();

 DESCRIPTION:

This sets $I equal to ($M)^(-1).

=item I<transp>: transpose a matrix

 SYNOPSIS:

 $T = $M->transp();

 DESCRIPTION:

This sets $T equal to the transpose of $M.

=item I<simq>: solve simultaneous equations

 SYNOPSIS:

 my $M = Math::Cephes::Matrix->new([ [1, 2, -1], [2, -3, 1], [1, 0, 3]]);
 my $B = [2, -1, 10];
 my $X = $M->simq($B);
 for (my $i=0; $i<3; $i++) {
    print "X[$i] is $X->[$i]\n";
  }

where $M is a I<Math::Cephes::Matrix> object, $B
is an input array reference, and $X is an output
array reference.

 DESCRIPTION:

A set of N simultaneous equations may be represented
in matrix form as

  M X = B

where M is an N x N square matrix and X and B are column
vectors of length N.

=item I<eigens>: eigenvalues and eigenvectors of a real symmetric matrix

 SYNOPSIS:

 my $S = Math::Cephes::Matrix->new([ [1, 2, 3], [2, 2, 3], [3, 3, 4]]);
 my ($E, $EV1) = $S->eigens();
 my $EV = $EV1->coef;
 for (my $i=0; $i<3; $i++) {
   print "For i=$i, with eigenvalue $E->[$i]\n";
   my $v = [];
   for (my $j=0; $j<3; $j++) {
     $v->[$j] = $EV->[$i]->[$j];
   }
   print "The eigenvector is @$v\n";
 }

where $M is a I<Math::Cephes::Matrix> object representing
a real symmetric matrix. $E is an array reference containing
the eigenvalues of $M, and $EV is a I<Math::Cephes::Matrix> object
representing the eigenvalues, the I<ith> row corresponding
to the I<ith> eigenvalue.

 DESCRIPTION:

If M is an N x N real symmetric matrix, and X is an N component
column vector, the eigenvalue problem

  M X = lambda X

will in general have N solutions, with X the eigenvectors
and lambda the eigenvalues.

=back

=head1 BUGS

Please report any to Randy Kobes <randy@theoryx5.uwinnipeg.ca>

=head1 COPYRIGHT

The C code for the Cephes Math Library is
Copyright 1984, 1987, 1989, 2002 by Stephen L. Moshier,
and is available at http://www.netlib.org/cephes/.
Direct inquiries to 30 Frost Street, Cambridge, MA 02140.

The perl interface is copyright 2000, 2002 by Randy Kobes.
This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

