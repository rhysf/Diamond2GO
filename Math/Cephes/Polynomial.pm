package Math::Cephes::Polynomial;
use strict;
use warnings;
use vars qw(@EXPORT_OK $VERSION $MAXPOL $FMAXPOL $flag $fflag);
eval {require Math::Complex; import Math::Complex qw(Re Im)};
eval {local $^W=0; require Math::Fraction;};
$MAXPOL = 256;
$flag = 0;
$FMAXPOL = 256;
$fflag = 0;

require Exporter;
*import = \&Exporter::import;
@EXPORT_OK = qw(poly);
$VERSION = '0.5305';

require Math::Cephes;
require Math::Cephes::Fraction;
require Math::Cephes::Complex;

sub new {
    my ($caller, $arr) = @_;
    my $refer = ref($caller);
    my $class = $refer || $caller;
    die "Must supply data for the polynomial"
      unless ($refer or $arr);
    my ($type, $ref, $data, $n);
    if ($refer) {
      ($type, $ref, $n) =
	($caller->{type}, $caller->{ref}, $caller->{n});
      my $cdata = $caller->{data};
      if (ref($cdata) eq 'ARRAY') {
	$data = [ @$cdata ];
      }
      else {
	my ($f, $s) = ($type eq 'fract') ? ('n', 'd') : ('r', 'i');
	$data = {$f => [ @{$cdata->{$f}} ],
		 $s => [ @{$cdata->{$s}} ],
		};
      }
    }
    else {
      ($type, $ref, $data, $n) = get_data($arr);
    }
    bless { type => $type,
	    ref => $ref,
	    data => $data,
	    n => $n,
	}, $class;
}

sub poly {
  return Math::Cephes::Polynomial->new(shift);
}

sub coef {
    return $_[0]->{data};
}

sub get_data {
    my ($arr, $ref_in) = @_;
    die "Must supply an array reference" unless ref($arr) eq 'ARRAY';
    my $n = scalar @$arr - 1;
    my $ref = ref($arr->[0]);
    die "array data must be of type '$ref_in'"
	if (defined $ref_in and $ref_in ne $ref);
    my ($type, $data);
  SWITCH: {
      not $ref and do {
	  $type = 'scalar';
	  foreach (@$arr) {
	      die 'Found conflicting types in array data'
		  if ref($_);
	  }
	  $data = $arr;
	  set_max() unless $flag;
	  last SWITCH;
      };
      $ref eq 'Math::Cephes::Complex' and do {
	  $type = 'cmplx';
	  foreach (@$arr) {
	      die 'Found conflicting types in array data'
		  unless ref($_) eq $ref;
	      die "array data must be of type '$ref_in'"
		  if (defined $ref_in and $ref_in ne $ref);
	      push @{$data->{r}}, $_->r;
	      push @{$data->{i}}, $_->i;
	  }
	  set_max() unless $flag;
	  last SWITCH;
      };
      $ref eq 'Math::Complex' and do {
	  $type = 'cmplx';
	  foreach (@$arr) {
	      die 'Found conflicting types in array data'
		  unless ref($_) eq $ref;
	      die "array data must be of type '$ref_in'"
		  if (defined $ref_in and $ref_in ne $ref);
	      push @{$data->{r}}, Re($_);
	      push @{$data->{i}}, Im($_);
	  }
	  set_max() unless $flag;
	  last SWITCH;
      };
      $ref eq 'Math::Cephes::Fraction' and do {
	  $type = 'fract';
	  foreach (@$arr) {
	      die 'Found conflicting types in array data'
		  unless ref($_) eq $ref;
	      die "array data must be of type '$ref_in'"
		  if (defined $ref_in and $ref_in ne $ref);
	      my ($gcd, $n, $d) = Math::Cephes::euclid($_->n, $_->d);
	      push @{$data->{n}}, $n;
	      push @{$data->{d}}, $d;
	  }
	  set_fmax() unless $fflag;
	  last SWITCH;
      };
       $ref eq 'Math::Fraction' and do {
	  $type = 'fract';
	  foreach (@$arr) {
	      die 'Found conflicting types in array data'
		  unless ref($_) eq $ref;
	      die "array data must be of type '$ref_in'"
		  if (defined $ref_in and $ref_in ne $ref);
	      push @{$data->{n}}, $_->{frac}->[0];
	      push @{$data->{d}}, $_->{frac}->[1];
	  }
	  set_fmax() unless $fflag;
	  last SWITCH;
      };
      die "Unknown type '$ref' in array data";
  }
    return ($type, $ref, $data, $n);
}

sub as_string {
  my $self = shift;
  my ($type, $data, $n) =
    ($self->{type}, $self->{data}, $self->{n});
  my $d = shift || $n;
  $d = $n if $d > $n;
  my $string;
    for (my $j=0; $j<=$d; $j++) {
      my $coef;
    SWITCH: {
	$type eq 'fract' and do {
	      my $n = $data->{n}->[$j];
	      my $d = $data->{d}->[$j];
	      my $sgn = $n < 0 ? ' -' : ' +';
	      $coef = $sgn . ($j == 0? '(' : ' (') .
		abs($n) . '/' . abs($d) . ')';
	      last SWITCH;
	  };
	$type eq 'cmplx' and do {
	      my $re = $data->{r}->[$j];
	      my $im = $data->{i}->[$j];
	      my $sgn = $j == 0 ? ' ' :  ' + ';
	      $coef = $sgn . '(' . $re .
		( (int( $im / abs($im) ) == -1) ? '-' : '+' ) .
		  ( ($im < 0) ? abs($im) : $im) . 'I)';
	      last SWITCH;
	    };
	my $f = $data->[$j];
	my $sgn = $f < 0 ? ' -' : ' +';
	$coef = $j == 0 ? ' ' . $f :
	  $sgn . ' ' . abs($f);
      }
	$string .=  $coef . ($j > 0 ? "x^$j" : '');
    }
  return $string . "\n";
}

sub add {
    my ($self, $b) = @_;
    my ($atype, $aref, $adata, $na) =
	($self->{type}, $self->{ref}, $self->{data}, $self->{n});
    my ($btype, $bref, $bdata, $nb) =
	ref($b) eq 'Math::Cephes::Polynomial' ?
	    ($b->{type}, $b->{ref}, $b->{data}, $b->{n}) :
		get_data($b, $aref);
    my $c = [];
    my $nc;
  SWITCH: {
      $atype eq 'fract' and do {
	  $nc = $na > $nb ? $na: $nb;
	  my $cn = [split //, 0 x ($nc+1)];
	  my $cd = [split //, 0 x ($nc+1)];
	Math::Cephes::fpoladd_wrap($adata->{n}, $adata->{d}, $na,
				   $bdata->{n}, $bdata->{d}, $nb,
				   $cn, $cd, $nc);
	  for (my $i=0; $i<=$nc; $i++) {
	      my ($gcd, $n, $d) = Math::Cephes::euclid($cn->[$i], $cd->[$i]);
	      push @$c, ($aref eq 'Math::Fraction' ?
			 Math::Fraction->new($n, $d) :
		       Math::Cephes::Fraction->new($n, $d) );
	  }
	  last SWITCH;
      };
      $atype eq 'cmplx' and do {
	  $nc = $na > $nb ? $na: $nb;
	  my $cr = [split //, 0 x ($nc+1)];
	  my $ci = [split //, 0 x ($nc+1)];
	Math::Cephes::poladd($adata->{r}, $na,
			     $bdata->{r}, $nb, $cr);
	Math::Cephes::poladd($adata->{i}, $na,
			     $bdata->{i}, $nb, $ci);
	  for (my $i=0; $i<=$nc; $i++) {
	      push @$c, ($aref eq 'Math::Complex' ?
		       Math::Complex->make($cr->[$i], $ci->[$i]) :
		       Math::Cephes::Complex->new($cr->[$i], $ci->[$i]) );
	  }
	  last SWITCH;
      };
      $nc = $na > $nb ? $na + 1 : $nb + 1;
      $c = [split //, 0 x $nc];
    Math::Cephes::poladd($adata, $na, $bdata, $nb, $c);
  }
    return wantarray ? (Math::Cephes::Polynomial->new($c), $nc) :
      Math::Cephes::Polynomial->new($c);

}

sub sub {
    my ($self, $b) = @_;
    my ($atype, $aref, $adata, $na) =
	($self->{type}, $self->{ref}, $self->{data}, $self->{n});
    my ($btype, $bref, $bdata, $nb) =
	ref($b) eq 'Math::Cephes::Polynomial' ?
	    ($b->{type}, $b->{ref}, $b->{data}, $b->{n}) :
		get_data($b, $aref);
    my $c = [];
    my $nc;
  SWITCH: {
      $atype eq 'fract' and do {
	  $nc = $na > $nb ? $na: $nb;
	  my $cn = [split //, 0 x ($nc+1)];
	  my $cd = [split //, 0 x ($nc+1)];
	Math::Cephes::fpolsub_wrap($bdata->{n}, $bdata->{d}, $nb,
				   $adata->{n}, $adata->{d}, $na,
				   $cn, $cd, $nc);
	  for (my $i=0; $i<=$nc; $i++) {
	      my ($gcd, $n, $d) = Math::Cephes::euclid($cn->[$i], $cd->[$i]);
	      push @$c, ($aref eq 'Math::Fraction' ?
			 Math::Fraction->new($n, $d) :
		       Math::Cephes::Fraction->new($n, $d) );
	  }
	  last SWITCH;
      };
      $atype eq 'cmplx' and do {
	  $nc = $na > $nb ? $na: $nb;
	  my $cr = [split //, 0 x ($nc+1)];
	  my $ci = [split //, 0 x ($nc+1)];
	Math::Cephes::polsub($bdata->{r}, $nb,
			     $adata->{r}, $na, $cr);
	Math::Cephes::polsub($bdata->{i}, $nb,
			     $adata->{i}, $na, $ci);
	  for (my $i=0; $i<=$nc; $i++) {
	      push @$c, ($aref eq 'Math::Complex' ?
		       Math::Complex->make($cr->[$i], $ci->[$i]) :
		       Math::Cephes::Complex->new($cr->[$i], $ci->[$i]) );
	  }
	  last SWITCH;
      };
      $nc = $na > $nb ? $na + 1 : $nb + 1;
      $c = [split //, 0 x $nc];
    Math::Cephes::polsub($bdata, $nb, $adata, $na, $c);
  }
    return wantarray ? (Math::Cephes::Polynomial->new($c), $nc) :
      Math::Cephes::Polynomial->new($c);

}

sub mul {
    my ($self, $b) = @_;
    my ($atype, $aref, $adata, $na) =
	($self->{type}, $self->{ref}, $self->{data}, $self->{n});
    my ($btype, $bref, $bdata, $nb) =
	ref($b) eq 'Math::Cephes::Polynomial' ?
	    ($b->{type}, $b->{ref}, $b->{data}, $b->{n}) :
		get_data($b, $aref);
    my $c = [];
    my $nc;
  SWITCH: {
      $atype eq 'fract' and do {
	  $nc = $na + $nb;
	  my $cn = [split //, 0 x ($nc+1)];
	  my $cd = [split //, 1 x ($nc+1)];
	Math::Cephes::fpolmul_wrap($adata->{n}, $adata->{d}, $na,
				   $bdata->{n}, $bdata->{d}, $nb,
				   $cn, $cd, $nc);
	  for (my $i=0; $i<=$nc; $i++) {
	      my ($gcd, $n, $d) = Math::Cephes::euclid($cn->[$i], $cd->[$i]);
	      push @$c, ($aref eq 'Math::Fraction' ?
			 Math::Fraction->new($n, $d) :
		       Math::Cephes::Fraction->new($n, $d) );
	  }
	  last SWITCH;
      };
      $atype eq 'cmplx' and do {
	  my $dc = $na + $nb + 3;
	  my $cr = [split //, 0 x $dc];
	  my $ci = [split //, 0 x $dc];
	  $nc = Math::Cephes::cpmul_wrap($adata->{r}, $adata->{i}, $na+1,
					 $bdata->{r}, $bdata->{i}, $nb+1,
					 $cr, $ci, $dc);
	  $cr = [ @{$cr}[0..$nc] ];
	  $ci = [ @{$ci}[0..$nc] ];
	  for (my $i=0; $i<=$nc; $i++) {
	      push @$c, ($aref eq 'Math::Complex' ?
		       Math::Complex->make($cr->[$i], $ci->[$i]) :
		       Math::Cephes::Complex->new($cr->[$i], $ci->[$i]) );
	  }
	  last SWITCH;
      };
      $nc = $na + $nb + 1;
      $c = [split //, 0 x $nc];
    Math::Cephes::polmul($adata, $na, $bdata, $nb, $c);
  }
    return wantarray ? (Math::Cephes::Polynomial->new($c), $nc) :
      Math::Cephes::Polynomial->new($c);
}

sub div {
    my ($self, $b) = @_;
    my ($atype, $aref, $adata, $na) =
	($self->{type}, $self->{ref}, $self->{data}, $self->{n});
    my ($btype, $bref, $bdata, $nb) =
	ref($b) eq 'Math::Cephes::Polynomial' ?
	    ($b->{type}, $b->{ref}, $b->{data}, $b->{n}) :
		get_data($b, $aref);
    my $c = [];
    my $nc;
  SWITCH: {
      $atype eq 'fract' and do {
	  $nc = $MAXPOL;
	  my $cn = [split //, 0 x ($nc+1)];
	  my $cd = [split //, 0 x ($nc+1)];
	Math::Cephes::fpoldiv_wrap($adata->{n}, $adata->{d}, $na,
				   $bdata->{n}, $bdata->{d}, $nb,
				   $cn, $cd, $nc);
	  for (my $i=0; $i<=$nc; $i++) {
	      my ($gcd, $n, $d) = Math::Cephes::euclid($cn->[$i], $cd->[$i]);
	      push @$c, ($aref eq 'Math::Fraction' ?
			 Math::Fraction->new($n, $d) :
		       Math::Cephes::Fraction->new($n, $d) );
	  }
	  last SWITCH;
      };
      $atype eq 'cmplx' and do {
	  die "Cannot do complex division";
	  last SWITCH;
      };
      $nc = $MAXPOL;
      $c = [split //, 0 x ($nc+1)];
    Math::Cephes::poldiv($adata, $na, $bdata, $nb, $c);
  }
    return wantarray ? (Math::Cephes::Polynomial->new($c), $nc) :
      Math::Cephes::Polynomial->new($c);
}

sub clr {
  my $self = shift;
  my ($atype, $aref, $adata, $na) =
	($self->{type}, $self->{ref}, $self->{data}, $self->{n});
  set_max() unless $flag;
  my $n = shift || $na;
  $n = $na if $n > $na;
 SWITCH: {
      $atype eq 'fract' and do {
	  for (my $i=0; $i<=$n; $i++) {
	    $self->{data}->{n}->[$i] = 0;
	    $self->{data}->{d}->[$i] = 1;
	  }
	  last SWITCH;
      };
      $atype eq 'cmplx' and do {
	  for (my $i=0; $i<=$n; $i++) {
	    $self->{data}->{r}->[$i] = 0;
	    $self->{data}->{i}->[$i] = 0;
	  }
	  last SWITCH;
      };
      for (my $i=0; $i<=$n; $i++) {
	$self->{data}->[$i] = 0;
      }
   }
}

sub sbt {
  my ($self, $b) = @_;
  my ($atype, $aref, $adata, $na) =
    ($self->{type}, $self->{ref}, $self->{data}, $self->{n});
  my ($btype, $bref, $bdata, $nb) =
    ref($b) eq 'Math::Cephes::Polynomial' ?
      ($b->{type}, $b->{ref}, $b->{data}, $b->{n}) :
	get_data($b, $aref);
  set_max() unless $flag;
  my $c = [];
  my $nc;
 SWITCH: {
    $atype eq 'fract' and do {
      $nc = ($na+1)*($nb+1);
      my $cn = [split //, 0 x ($nc+1)];
      my $cd = [split //, 0 x ($nc+1)];
      Math::Cephes::fpolsbt_wrap($bdata->{n}, $bdata->{d}, $nb,
				 $adata->{n}, $adata->{d}, $na,
				 $cn, $cd, $nc);
      $nc = $na * $nb;
      for (my $i=0; $i<=$nc; $i++) {
	my ($gcd, $n, $d) = Math::Cephes::euclid($cn->[$i], $cd->[$i]);
	push @$c, ($aref eq 'Math::Fraction' ?
		   Math::Fraction->new($n, $d) :
		   Math::Cephes::Fraction->new($n, $d) );
      }
      last SWITCH;
    };
    $atype eq 'cmplx' and do {
      die "Cannot do complex substitution";
      last SWITCH;
    };
    $nc = ($na+1)*($nb+1);
    $c = [split //, 0 x $nc];
    Math::Cephes::polsbt($bdata, $nb, $adata, $na, $c);
    $nc = $na*$nb;
    $c = [@$c[0..$nc]];
  }
  return wantarray ? (Math::Cephes::Polynomial->new($c), $nc) :
    Math::Cephes::Polynomial->new($c);
}

sub set_max {
  Math::Cephes::polini($MAXPOL);
    $flag = 1;
}

sub set_fmax {
  Math::Cephes::fpolini($FMAXPOL);
    $fflag = 1;
}

sub eval {
  my $self = shift;
  my $x = 0 || shift;
  my ($atype, $aref, $adata, $na) =
    ($self->{type}, $self->{ref}, $self->{data}, $self->{n});
  my $y;
 SWITCH: {
    $atype eq 'fract' and do {
      my $xref = ref($x);
      $y = Math::Cephes::Fraction->new(0, 1);
    FRACT: {
	not $xref and do {
	  $x = Math::Cephes::Fraction->new($x, 1);
	  last FRACT;
	};
	$xref eq 'Math::Cephes::Fraction' and do {
	  last FRACT;
	};
	$xref eq 'Math::Fraction' and do {
	  $x = Math::Cephes::Fraction->new($x->{frac}->[0], $x->{frac}->[1]);
	  last FRACT;
	};
	die "Unknown data type '$xref' for x";
      }
      Math::Cephes::fpoleva_wrap($adata->{n}, $adata->{d}, $na, $x, $y);
      $y = Math::Fraction->new($y->n, $y->d) if $aref eq 'Math::Fraction';
      last SWITCH;
    };
    $atype eq 'cmplx' and do {
      my $r = Math::Cephes::poleva($adata->{r}, $na, $x);
      my $i = Math::Cephes::poleva($adata->{i}, $na, $x);
      $y = $aref eq 'Math::Complex' ?
	Math::Complex->make($r, $i) :
	    Math::Cephes::Complex->new($r, $i);
      last SWITCH;
    };
    $y = Math::Cephes::poleva($adata, $na, $x);
  }
  return $y;
}

sub fract_to_real {
    my $in = shift;
    my $a = [];
    my $n = scalar @{$in->{n}} - 1;
    for (my $i=0; $i<=$n; $i++) {
	push @$a, $in->{n}->[$i] / $in->{d}->[$i];
    }
    return $a;
}

sub atn {
    my ($self, $bin) = @_;
    my $type = $self->{type};
    die "Cannot take the atan of a complex polynomial"
	if $type eq 'cmplx';
    my ($a, $b);
    my ($atype, $aref, $adata, $na) =
	($self->{type}, $self->{ref}, $self->{data}, $self->{n});
    die "Cannot take the atan of a complex polynomial"
	if $atype eq 'cmplx';
    $a = $atype eq 'fract' ? fract_to_real($adata) : $adata;

    my ($btype, $bref, $bdata, $nb) =
	ref($bin) eq 'Math::Cephes::Polynomial' ?
	    ($bin->{type}, $bin->{ref}, $bin->{data}, $bin->{n}) :
		get_data($bin);

    die "Cannot take the atan of a complex polynomial"
	if $btype eq 'cmplx';
    $b = $btype eq 'fract' ? fract_to_real($bdata) : $bdata;

    my $c = [split //, 0 x ($MAXPOL+1)];
  Math::Cephes::polatn($a, $b, $c, 16);
    return Math::Cephes::Polynomial->new($c);
}

sub sqt {
  my $self = shift;
  my $type = $self->{type};
  die "Cannot take the sqrt of a complex polynomial"
    if $type eq 'cmplx';
  my $a = $type eq 'fract' ? fract_to_real($self->{data}) : $self->coef;
  my $b = [split //, 0 x ($MAXPOL+1)];
  Math::Cephes::polsqt($a, $b, 16);
  return Math::Cephes::Polynomial->new($b);
}

sub sin {
  my $self = shift;
  my $type = $self->{type};
  die "Cannot take the sin of a complex polynomial"
    if $type eq 'cmplx';
  my $a = $type eq 'fract' ? fract_to_real($self->{data}) : $self->coef;
  my $b = [split //, 0 x ($MAXPOL+1)];
  Math::Cephes::polsin($a, $b, 16);
  return Math::Cephes::Polynomial->new($b);
}

sub cos {
  my $self = shift;
  my $type = $self->{type};
  die "Cannot take the cos of a complex polynomial"
    if $type eq 'cmplx';
  my $a = $type eq 'fract' ? fract_to_real($self->{data}) : $self->coef;
  my $b = [split //, 0 x ($MAXPOL+1)];
  Math::Cephes::polcos($a, $b, 16);
  return Math::Cephes::Polynomial->new($b);
}

sub rts {
  my $self = shift;
  my ($atype, $aref, $adata, $na) =
    ($self->{type}, $self->{ref}, $self->{data}, $self->{n});
  my ($a, $b, $ret);
  my $cof = [split //, 0 x ($na+1)];
  my $r = [split //, 0 x ($na+1)];
  my $i = [split //, 0 x ($na+1)];
 SWITCH: {
    $atype eq 'fract' and do {
      $adata = fract_to_real($adata);
      $ret = Math::Cephes::polrt_wrap($adata, $cof, $na, $r, $i);
      for (my $j=0; $j<$na; $j++) {
	push @$b,
	  Math::Cephes::Complex->new($r->[$j], $i->[$j]);
      }
      last SWITCH;
    };
    $atype eq 'cmplx' and do {
      die "Cannot do complex root finding";
      last SWITCH;
    };
    $ret = Math::Cephes::polrt_wrap($adata, $cof, $na, $r, $i);
    for (my $j=0; $j<$na; $j++) {
      push @$b,
	Math::Cephes::Complex->new($r->[$j], $i->[$j]);
    }
  }
  return wantarray ? ($ret, $b) : $b;
}

1;

__END__

=head1 NAME

Math::Cephes::Polynomial - Perl interface to the cephes math polynomial routines

=head1 SYNOPSIS

  use Math::Cephes::Polynomial qw(poly);
  # 'poly' is a shortcut for Math::Cephes::Polynomial->new

  require Math::Cephes::Fraction; # if coefficients are fractions
  require Math::Cephes::Complex;  # if coefficients are complex

  my $a = poly([1, 2, 3]);           # a(x) = 1 + 2x + 3x^2
  my $b = poly([4, 5, 6, 7];         # b(x) = 4 + 5x + 6x^2 + 7x^3
  my $c = $a->add($b);               # c(x) = 5 + 7x + 9x^2 + 7x^3
  my $cc = $c->coef;
  for (my $i=0; $i<4; $i++) {
     print "term $i: $cc->[$i]\n";
  }
  my $x = 2;
  my $r = $c->eval($x);
  print "At x=$x, c(x) is $r\n";

  my $u1 = Math::Cephes::Complex->new(2,1);
  my $u2 = Math::Cephes::Complex->new(1,-3);
  my $v1 = Math::Cephes::Complex->new(1,3);
  my $v2 = Math::Cephes::Complex->new(2,4);
  my $z1 = Math::Cephes::Polynomial->new([$u1, $u2]);
  my $z2 = Math::Cephes::Polynomial->new([$v1, $v2]);
  my $z3 = $z1->add($z2);
  my $z3c = $z3->coef;
  for (my $i=0; $i<2; $i++) {
     print "term $i: real=$z3c->{r}->[$i], imag=$z3c->{i}->[$i]\n";
  }
  $r = $z3->eval($x);
  print "At x=$x, z3(x) has real=", $r->r, " and imag=", $r->i, "\n";

  my $a1 = Math::Cephes::Fraction->new(1,2);
  my $a2 = Math::Cephes::Fraction->new(2,1);
  my $b1 = Math::Cephes::Fraction->new(1,2);
  my $b2 = Math::Cephes::Fraction->new(2,2);
  my $f1 = Math::Cephes::Polynomial->new([$a1, $a2]);
  my $f2 = Math::Cephes::Polynomial->new([$b1, $b2]);
  my $f3 = $f1->add($f2);
  my $f3c = $f3->coef;
  for (my $i=0; $i<2; $i++) {
     print "term $i: num=$f3c->{n}->[$i], den=$f3c->{d}->[$i]\n";
  }
  $r = $f3->eval($x);
  print "At x=$x, f3(x) has num=", $r->n, " and den=", $r->d, "\n";
  $r = $f3->eval($a1);
  print "At x=", $a1->n, "/", $a1->d,
      ", f3(x) has num=", $r->n, " and den=", $r->d, "\n";

=head1 DESCRIPTION

This module is a layer on top of the basic routines in the
cephes math library to handle polynomials. In the following,
a Math::Cephes::Polynomial object is created as

  my $p = Math::Cephes::Polynomial->new($arr_ref);

where C<$arr_ref> is a reference to an array which can
consist of one of

=over

=item * floating point numbers, for polynomials with floating
point coefficients,

=item * I<Math::Cephes::Fraction> or I<Math::Fraction> objects,
for polynomials with fractional coefficients,

=item * I<Math::Cephes::Complex> or I<Math::Complex> objects,
for polynomials with complex coefficients,

=back

The maximum degree of the polynomials handled is set by default
to 256 - this can be changed by setting I<$Math::Cephes::Polynomial::MAXPOL>.

A copy of a I<Math::Cephes::Polynomial> object may be done as

  my $p_copy = $p->new();

and a string representation of the polynomial may be gotten through

  print $p->as_string;

=head2 Methods

The following methods are available.

=over 4

=item I<coef>: get coefficients of the polynomial

 SYNOPSIS:

 my $c = $p->coef;

 DESCRIPTION:

This returns an array reference containing the coefficients of
the polynomial.

=item I<clr>: set a polynomial identically equal to zero

 SYNOPSIS:

 $p->clr($n);

 DESCRIPTION:

This sets the coefficients of the polynomial identically to 0,
up to $p->[$n]. If $n is omitted, all elements are set to 0.

=item I<add>: add two polynomials

 SYNOPSIS:

 $c = $a->add($b);

 DESCRIPTION:

This sets $c equal to $a + $b.

=item I<sub>: subtract two polynomials

 SYNOPSIS:

 $c = $a->sub($b);

 DESCRIPTION:

This sets $c equal to $a - $b.

=item I<mul>: multiply two polynomials

 SYNOPSIS:

 $c = $a->mul($b);

 DESCRIPTION:

This sets $c equal to $a * $b.

=item I<div>: divide two polynomials

 SYNOPSIS:

 $c = $a->div($b);

 DESCRIPTION:

This sets $c equal to $a / $b, expanded by a Taylor series. Accuracy
is approximately equal to the degree of the polynomial, with an
internal limit of about 16.

=item I<sbt>: change of variables

 SYNOPSIS:

 $c = $a->sbt($b);

 DESCRIPTION:

If a(x) and b(x) are polynomials, then

     c(x) = a(b(x))

is a polynomial found by substituting b(x) for x in a(x). This method is
not available for polynomials with complex coefficients.

=item I<eval>: evaluate a polynomial

 SYNOPSIS:

 $s = $a->eval($x);

 DESCRIPTION:

This evaluates the polynomial at the value $x. The returned value
is of the same type as that used to represent the coefficients of
the polynomial.

=item I<sqt>: square root of a polynomial

 SYNOPSIS:

 $b = $a->sqt();

 DESCRIPTION:

This finds the square root of a polynomial, evaluated by a
Taylor expansion. Accuracy is approximately equal to the
degree of the polynomial, with an internal limit of about 16.
This method is not available for polynomials with complex coefficients.

=item I<sin>: sine of a polynomial

 SYNOPSIS:

 $b = $a->sin();

 DESCRIPTION:

This finds the sine of a polynomial, evaluated by a
Taylor expansion. Accuracy is approximately equal to the
degree of the polynomial, with an internal limit of about 16.
This method is not available for polynomials with complex coefficients.

=item I<cos>: cosine of a polynomial

 SYNOPSIS:

 $b = $a->cos();

 DESCRIPTION:

This finds the cosine of a polynomial, evaluated by a
Taylor expansion. Accuracy is approximately equal to the
degree of the polynomial, with an internal limit of about 16.
This method is not available for polynomials with complex coefficients.

=item I<atn>: arctangent of the ratio of two polynomials

 SYNOPSIS:

 $c = $a->atn($b);

 DESCRIPTION:

This finds the arctangent of the ratio $a / $b of two polynomial,
evaluated by a Taylor expansion. Accuracy is approximately equal to the
degree of the polynomial, with an internal limit of about 16.
This method is not available for polynomials with complex coefficients.

=item I<rts>: roots of a polynomial

 SYNOPSIS:

  my $w = Math::Cephes::Polynomial->new([-2, 0, -1, 0, 1]);
  my ($flag, $r) = $w->rts();
  for (my $i=0; $i<4; $i++) {
    print "Root $i has real=", $r->[$i]->r, " and imag=", $r->[$i]->i, "\n";
  }

 DESCRIPTION:

This finds the roots of a polynomial. I<$flag>, if non-zero, indicates
a failure of some kind. I<$roots> in an array reference of
I<Math::Cephes::Complex> objects holding the
real and complex values of the roots found.
This method is not available for polynomials with complex coefficients.

 ACCURACY:

Termination depends on evaluation of the polynomial at
the trial values of the roots.  The values of multiple roots
or of roots that are nearly equal may have poor relative
accuracy after the first root in the neighborhood has been
found.

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
