############# Class : cmplx ##############
package Math::Cephes::Complex;
use strict;
use warnings;
use vars qw(%OWNER %ITERATORS @ISA
	    @EXPORT_OK %EXPORT_TAGS $VERSION);
require Math::Cephes;

require Exporter;
*import = \&Exporter::import;
@ISA = qw( Math::Cephes );
#my @cmplx = qw(clog cexp csin ccos ctan ccot casin cmplx
#	       cacos catan cadd csub cmul cdiv cmov cneg cabs csqrt
#	       csinh ccosh ctanh cpow casinh cacosh catanh);
@EXPORT_OK = qw(cmplx);
#%EXPORT_TAGS = ('cmplx' => [qw(cmplx)]);

%OWNER = ();
%ITERATORS = ();
$VERSION = '0.5305';

*swig_r_get = *Math::Cephesc::cmplx_r_get;
*swig_r_set = *Math::Cephesc::cmplx_r_set;
*swig_i_get = *Math::Cephesc::cmplx_i_get;
*swig_i_set = *Math::Cephesc::cmplx_i_set;

sub new {
    my $pkg = shift;
    my $self = Math::Cephesc::new_cmplx(@_);
    bless $self, $pkg if defined($self);
}

sub DESTROY {
    return unless $_[0]->isa('HASH');
    my $self = tied(%{$_[0]});
    return unless defined $self;
    delete $ITERATORS{$self};
    if (exists $OWNER{$self}) {
        Math::Cephesc::delete_cmplx($self);
        delete $OWNER{$self};
    }
}

sub DISOWN {
    my $self = shift;
    my $ptr = tied(%$self);
    delete $OWNER{$ptr};
}

sub ACQUIRE {
    my $self = shift;
    my $ptr = tied(%$self);
    $OWNER{$ptr} = 1;
}


sub r {
    my ($self, $value) = @_;
    return $self->{r} unless (defined $value);
    $self->{r} = $value;
    return $value;
}

sub i {
    my ($self, $value) = @_;
    return $self->{i} unless (defined $value);
    $self->{i} = $value;
    return $value;
}

sub cmplx {
  return Math::Cephes::Complex->new(@_);
}

sub as_string {
  my $z = shift;
  my $string;
  my $re = $z->{r};
  my $im = $z->{i};
  if ($im == 0) {
    $string = "$re";
  }
  else {
    $string = sprintf "%f %s %f %s", $re,
      (int( $im / abs($im) ) == -1) ? '-' : '+' ,
	($im < 0) ? abs($im) : $im, 'i';
  }
  return $string;
}


sub cadd {
  my ($z1, $z2) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::cadd($z1, $z2, $z);
  return $z;
}

sub csub {
  my ($z1, $z2) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::csub($z2, $z1, $z);
  return $z;
}

sub cmul {
  my ($z1, $z2) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::cmul($z1, $z2, $z);
  return $z;
}

sub cdiv {
  my ($z1, $z2) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::cdiv($z2, $z1, $z);
  return $z;
}

sub cpow {
  my ($z1, $z2) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::cpow($z1, $z2, $z);
  return $z;
}

sub clog {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::clog($z1, $z);
  return $z;
}
sub cexp {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::cexp($z1, $z);
  return $z;
}
sub csin {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::csin($z1, $z);
  return $z;
}
sub ccos {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::ccos($z1, $z);
  return $z;
}
sub ctan {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::ctan($z1, $z);
  return $z;
}
sub ccot {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::ccot($z1, $z);
  return $z;
}
sub casin {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::casin($z1, $z);
  return $z;
}
sub cacos {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::cacos($z1, $z);
  return $z;
}
sub catan {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::catan($z1, $z);
  return $z;
}
sub cmov {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::cmov($z1, $z);
  return $z;
}
sub cneg {
  my ($z1) = @_;
  Math::Cephes::cneg($z1);
  return $z1;
}
sub csqrt {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::csqrt($z1, $z);
  return $z;
}
sub cabs {
  my ($z1) = @_;
  my $abs = Math::Cephes::cabs($z1);
  return $abs;
}

sub csinh {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::csinh($z1, $z);
  return $z;
}
sub ccosh {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::ccosh($z1, $z);
  return $z;
}
sub ctanh {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::ctanh($z1, $z);
  return $z;
}
sub casinh {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::casinh($z1, $z);
  return $z;
}
sub cacosh {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::cacosh($z1, $z);
  return $z;
}
sub catanh {
  my ($z1) = @_;
  my $z = Math::Cephes::Complex->new();
  Math::Cephes::catanh($z1, $z);
  return $z;
}

1;

__END__

=head1 NAME

  Math::Cephes::Complex - Perl interface to the cephes complex number routines

=head1 SYNOPSIS

  use Math::Cephes::Complex qw(cmplx);
  my $z1 = cmplx(2,3);          # $z1 = 2 + 3 i
  my $z2 = cmplx(3,4);          # $z2 = 3 + 4 i
  my $z3 = $z1->radd($z2);      # $z3 = $z1 + $z2

=head1 DESCRIPTION

This module is a layer on top of the basic routines in the
cephes math library to handle complex numbers. A complex
number is created via any of the following syntaxes:

  my $f = Math::Cephes::Complex->new(3, 2);   # $f = 3 + 2 i
  my $g = new Math::Cephes::Complex(5, 3);    # $g = 5 + 3 i
  my $h = cmplx(7, 5);                        # $h = 7 + 5 i

the last one being available by importing I<cmplx>. If no arguments
are specified, as in

 my $h = cmplx();

then the defaults $z = 0 + 0 i are assumed. The real and imaginary
part of a complex number are represented respectively by

   $f->{r}; $f->{i};

or, as methods,

   $f->r;  $f->i;

and can be set according to

  $f->{r} = 4; $f->{i} = 9;

or, again, as methods,

  $f->r(4);   $f->i(9);

The complex number can be printed out as

  print $f->as_string;

A summary of the usage is as follows.

=over 4

=item I<csin>: Complex circular sine

 SYNOPSIS:

 # void csin();
 # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->csin;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

 DESCRIPTION:

 If
     z = x + iy,

 then

     w = sin x  cosh y  +  i cos x sinh y.

=item I<ccos>: Complex circular cosine

 SYNOPSIS:

 # void ccos();
 # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->ccos;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

 DESCRIPTION:

 If
     z = x + iy,

 then

     w = cos x  cosh y  -  i sin x sinh y.

=item I<ctan>: Complex circular tangent

 SYNOPSIS:

 # void ctan();
 # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->ctan;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

 DESCRIPTION:

 If
     z = x + iy,

 then

           sin 2x  +  i sinh 2y
     w  =  --------------------.
            cos 2x  +  cosh 2y

 On the real axis the denominator is zero at odd multiples
 of PI/2.  The denominator is evaluated by its Taylor
 series near these points.

=item I<ccot>: Complex circular cotangent

 SYNOPSIS:

 # void ccot();
 # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->ccot;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

 DESCRIPTION:

 If
     z = x + iy,

 then

           sin 2x  -  i sinh 2y
     w  =  --------------------.
            cosh 2y  -  cos 2x

 On the real axis, the denominator has zeros at even
 multiples of PI/2.  Near these points it is evaluated
 by a Taylor series.

=item I<casin>: Complex circular arc sine

 SYNOPSIS:

 # void casin();
 # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->casin;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

 DESCRIPTION:

 Inverse complex sine:

                               2
 w = -i clog( iz + csqrt( 1 - z ) ).

=item I<cacos>: Complex circular arc cosine

 SYNOPSIS:

 # void cacos();
 # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->cacos;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

 DESCRIPTION:

 w = arccos z  =  PI/2 - arcsin z.

=item I<catan>: Complex circular arc tangent

 SYNOPSIS:

 # void catan();
 # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->catan;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

 DESCRIPTION:

 If
     z = x + iy,

 then
          1       (    2x     )
 Re w  =  - arctan(-----------)  +  k PI
          2       (     2    2)
                  (1 - x  - y )

               ( 2         2)
          1    (x  +  (y+1) )
 Im w  =  - log(------------)
          4    ( 2         2)
               (x  +  (y-1) )

 Where k is an arbitrary integer.

=item I<csinh>: Complex hyperbolic sine

  SYNOPSIS:

  # void csinh();
  # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->csinh;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)


  DESCRIPTION:

  csinh z = (cexp(z) - cexp(-z))/2
          = sinh x * cos y  +  i cosh x * sin y .

=item I<casinh>: Complex inverse hyperbolic sine

  SYNOPSIS:

  # void casinh();
  # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->casinh;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

  DESCRIPTION:

  casinh z = -i casin iz .

=item I<ccosh>: Complex hyperbolic cosine

  SYNOPSIS:

  # void ccosh();
  # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->ccosh;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

  DESCRIPTION:

  ccosh(z) = cosh x  cos y + i sinh x sin y .

=item I<cacosh>: Complex inverse hyperbolic cosine


  SYNOPSIS:

  # void cacosh();
  # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->cacosh;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

  DESCRIPTION:

  acosh z = i acos z .

=item I<ctanh>: Complex hyperbolic tangent

 SYNOPSIS:

 # void ctanh();
 # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->ctanh;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

 DESCRIPTION:

 tanh z = (sinh 2x  +  i sin 2y) / (cosh 2x + cos 2y) .

=item I<catanh>: Complex inverse hyperbolic tangent

  SYNOPSIS:

  # void catanh();
  # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->catanh;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

  DESCRIPTION:

  Inverse tanh, equal to  -i catan (iz);

=item I<cpow>: Complex power function

  SYNOPSIS:

  # void cpow();
  # cmplx a, z, w;

 $a = cmplx(5, 6);    # $z = 5 + 6 i
 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $a->cpow($z);
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

  DESCRIPTION:

  Raises complex A to the complex Zth power.
  Definition is per AMS55 # 4.2.8,
  analytically equivalent to cpow(a,z) = cexp(z clog(a)).

=item I<cmplx>: Complex number arithmetic

 SYNOPSIS:

 # typedef struct {
 #     double r;     real part
 #     double i;     imaginary part
 #    }cmplx;

 # cmplx *a, *b, *c;

 $a = cmplx(3, 5);   # $a = 3 + 5 i
 $b = cmplx(2, 3);   # $b = 2 + 3 i

 $c = $a->cadd( $b );  #   c = a + b
 $c = $a->csub( $b );  #   c = a - b
 $c = $a->cmul( $b );  #   c = a * b
 $c = $a->cdiv( $b );  #   c = a / b
 $c = $a->cneg;        #   c = -a
 $c = $a->cmov;        #   c = a

 print $c->{r}, '  ', $c->{i};   # prints real and imaginary parts of $c
 print $c->as_string;           # prints $c as Re($c) + i Im($c)


 DESCRIPTION:

 Addition:
    c.r  =  b.r + a.r
    c.i  =  b.i + a.i

 Subtraction:
    c.r  =  b.r - a.r
    c.i  =  b.i - a.i

 Multiplication:
    c.r  =  b.r * a.r  -  b.i * a.i
    c.i  =  b.r * a.i  +  b.i * a.r

 Division:
    d    =  a.r * a.r  +  a.i * a.i
    c.r  = (b.r * a.r  + b.i * a.i)/d
    c.i  = (b.i * a.r  -  b.r * a.i)/d

=item I<cabs>: Complex absolute value

 SYNOPSIS:

 # double a, cabs();
 # cmplx z;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $a = cabs( $z );

 DESCRIPTION:

 If z = x + iy

 then

       a = sqrt( x**2 + y**2 ).

 Overflow and underflow are avoided by testing the magnitudes
 of x and y before squaring.  If either is outside half of
 the floating point full scale range, both are rescaled.

=item I<csqrt>: Complex square root

 SYNOPSIS:

 # void csqrt();
 # cmplx z, w;

 $z = cmplx(2, 3);    # $z = 2 + 3 i
 $w = $z->csqrt;
 print $w->{r}, '  ', $w->{i};  # prints real and imaginary parts of $w
 print $w->as_string;           # prints $w as Re($w) + i Im($w)

 DESCRIPTION:

 If z = x + iy,  r = |z|, then

                       1/2
 Im w  =  [ (r - x)/2 ]   ,

 Re w  =  y / 2 Im w.

 Note that -w is also a square root of z.  The root chosen
 is always in the upper half plane.

 Because of the potential for cancellation error in r - x,
 the result is sharpened by doing a Heron iteration
 (see sqrt.c) in complex arithmetic.

=back

=head1 BUGS

 Please report any to Randy Kobes <randy@theoryx5.uwinnipeg.ca>

=head1 SEE ALSO

For the basic interface to the cephes complex number routines, see
L<Math::Cephes>. See also L<Math::Complex>
for a more extensive interface to complex number routines.

=head1 COPYRIGHT

The C code for the Cephes Math Library is
Copyright 1984, 1987, 1989, 2002 by Stephen L. Moshier,
and is available at http://www.netlib.org/cephes/.
Direct inquiries to 30 Frost Street, Cambridge, MA 02140.

The perl interface is copyright 2000, 2002 by Randy Kobes.
This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
