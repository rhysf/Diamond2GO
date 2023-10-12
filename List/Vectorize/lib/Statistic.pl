
#===== statistic functions ==================

sub abs {
	
	check_prototype(@_, '$');
	
	$_[0] < 0 ? -$_[0] : $_[0];
}

# usage: sign( [SCALAR] )
# return: SCALAR
sub sign {
	
	check_prototype(@_, '$');
	
	$_[0] > 0 ? 1 : $_[0] < 0 ? -1 : 0;
}

# usage: sum( [ARRAY REF] )
# return: SCALAR
# description: ÇóºÍ
sub sum {
	
	check_prototype(@_, '\@');
	
    my $array = shift;
    
    my $sum = 0;
    for(my $i = 0; $i < len($array); $i ++) {
        $sum += $array->[$i];
    }
	
    return $sum;
}

# usage: mean( [ARRAY REF] )
# return: SCALAR
sub mean {
	
	check_prototype(@_, '\@');
	
    return sum($_[0]) / len($_[0]);
}

# usage: geometric_mean( [ARRAY REF] )
# return: SCALAR
sub geometric_mean {
	
	check_prototype(@_, '\@');
	
    return exp(sum(sapply($_[0], sub{log($_[0])})) / len($_[0]));
}

# usage: sd( [ARRAY REF] )
# return: SCALAR
sub sd {
	
	check_prototype(@_, '\@$?');
	
    return sqrt(var(@_));
}

# usage: var( [ARRAY REF], [SCALAR] )
# return: SCALAR
sub var {
	
	check_prototype(@_, '\@$?');
	
    my $array = shift;
    my $mean = shift;
	
	if(len($array) < 2) {
		croak "ERROR: Length of the vector should be larger than 1.";
	}
    
	# if the second argument was not specified
    if(!defined($mean) or $mean eq "") {
        $mean = mean($array);
    }
    return sum(sapply($array, sub {($_[0]-$mean)**2})) / $#$array;
}

# usage: cov( [ARRAY REF], [ARRAY REF] )
# return: SCALAR
sub cov{
	
	check_prototype(@_, '\@\@');
	
    my $array1 = shift;
    my $array2 = shift;
	
	if(len($array1) != len($array2)) {
		croak "ERROR: Length of the two vectors should be same";
	}
	
    my $mean1 = mean($array1);
    my $mean2 = mean($array2);

   return sum(mapply($array1, $array2, sub {($_[0]-$mean1)*($_[1]-$mean2)})) / $#$array1;
}

# usage: cor( [ARRAY REF], [ARRAY REF] )
# return: SCALAR
sub cor {
	
	check_prototype(@_, '\@\@$?');
	
    my $array1 = shift;
    my $array2 = shift;
	my $method = shift || "pearson";
    
	if($method eq "spearman") {
		return cor(rank($array1), rank($array2));
	}
	else {
		return cov($array1, $array2)/sd($array1)/sd($array2);
	}
}

# usage: dist( [ARRAY REF], [ARRAY REF], [SCALAR] )
# return: SCALAR
sub dist {
	
	check_prototype(@_, '\@\@$?');
	
	my $vector1 = shift;
	my $vector2 = shift;
	my $method = shift || "euclidean";
	
	if(len($vector1) != len($vector2)) {
		croak "ERROR: Length of the two vectors should be same";
	}
	
	$method = lc($method);
	if($method eq "euclidean") {
		return sqrt(sum(mapply($vector1, $vector2, sub{($_[0]+$_[1])**2})));
	}
	elsif($method eq "pearson") {
		return 1 - cor($vector1, $vector2);
	}
	elsif($method eq "spearman") {
		return 1 - cor($vector1, $vector2, "spearman");
	}
	elsif($method eq "logical") {
		return 1/(1+sum(mapply($vector1, $vector2, sub{($_[0] && $_[1])})));
	}
	
}

# usage: freq( [ARRAY REF], [ARRAY REF], ... )
# return: HASH REF
sub freq {
	
	check_prototype(@_, '(\@)+');
	
    my @category = @_;
    
    my $f = {};
	my $category = paste(@category, "|");
    foreach (@$category) {
		$f->{$_} ++;
	}
    return $f;
}

# same as frequency
sub table {
	
	check_prototype(@_, '(\@)+');
	
	return freq(@_);
}

# usage: scale( [ARRAY REF], "zvalue|percentage|sphere")
# return: HASH REF
sub scale {
	
	check_prototype(@_, '\@$?');
	
    my $array = shift;
	my $type = shift || "zvalue";
	$type = lc($type);
				 
	if($type eq "percentage") {
		my $max = max($array);
		my $min = min($array);
		
		return sapply($array, sub { ($_[0] - $min)/($max - $min) });
	}
	elsif($type eq "sphere") {    # all the points are on the surface of the unit super sphere
		my $s = sqrt(sum(sapply($array, sub{$_[0]**2})));
		
		return sapply($array, sub { $_[0]/$s });
	}
	else {
		my $mean = mean($array);
		my $sd = sd($array, $mean);
		
		return sapply($array, sub { ($_[0] - $mean)/$sd });
	}
}

# usage: sample( [ARRAY REF], [SCALAR], "p" => [ARRAY REF], "replace" => 0|1 )
# return: ARRAY REF
sub sample {
	
	check_prototype(@_, '\@($|\@|\%)+');
	
    my $array = shift;
    my $size = shift;
	
    my $setup = {"p" => repeat(1, len($array)),
	             "replace" => 0,
	             @_ };
	my $sum_p = sum($setup->{"p"});
    my $p = sapply($setup->{"p"}, sub {$_[0]/$sum_p}); #0-1
    my $replace = $setup->{"replace"};
    
	if(!$replace and len($array) < $size) {
        croak "ERROR: Size($size) should not be bigger than the sample size with no replacement.\n";
    }
	
	if(len($array) != len($p)) {
		croak "ERROR: Length of the vector should be same as the length of the probability.\n";
	}
	
    my $sample = [];
    my $ecdf = _ecdf($p);  
    
    if($replace) { 
        for(my $i = 0; $i < $size; $i ++) {
            my $ind = _get_index_from_p(rand(), $ecdf);
            push(@$sample, $array->[$ind]);
        }
    }
    else {
        my $array_copy;
        push(@$array_copy, @$array);
        my $p_copy;
        push(@$p_copy, @$p);
        
		my $p_sum = sum($p_copy);
        for(my $i = 0; $i < $size; $i ++) {
            my $ind = _get_index_from_p(rand(), $ecdf);
            push(@$sample, $array_copy->[$ind]);
            $p_sum -= $p_copy->[$ind];
			
			$array_copy = del_array_item($array_copy, $ind);
			$p_copy = del_array_item($p_copy, $ind);

            $p_copy = sapply($p_copy, sub{$_[0]/$p_sum});
            $ecdf = _ecdf($p_copy);
        }
    }
    return $sample;
}

# usage: ecdf( [ARRAY REF])
# return: ARRAY REF
sub _ecdf {
    my $p = shift;
    my $ecdf = cumf($p, \&sum);
    return $ecdf;
}

# usage: _get_index_from_p( [SCALAR], [ARRAY REF])
# return: SCALAR
# [, )
sub _get_index_from_p {
    my $r = shift;
    my $p = shift;
	# the first
	if($r < $p->[0]) {
	  return 0;
	}
    for(my $k = 0; $k < len($p)-1; $k ++) {
        if($r >= $p->[$k] and $r < $p->[$k+1]) {
            return $k+1;
        }
    }
    return len($p)-1;
}


# usage: rnorm( [SCALAR], [SCALAR], [SCALAR])
# return: ARRAY REF
sub rnorm {
	
	check_prototype(@_, '${1,3}');
	
    my $size = shift;
    my $mean = shift;
    my $sd = shift;
    
    $mean = (defined($mean) and $mean ne "") ? $mean : 0;
    $sd = (defined($sd) and $sd ne "") ? $sd : 1;
    
    my $r = [];
    for(my $i = 0; $i < $size; $i ++) {
        my $yita1 = rand(1);
        my $yita2 = rand(1);
        while($yita1 == 0) {
            $yita1 = rand(1);
        }
        while($yita2 == 0) {
            $yita2 = rand(1);
        }
        my $x = sqrt(-2*log($yita1)/log(exp(1)))*sin(2*3.1415926*$yita2);
        $x = $mean + $sd*$x;
        push(@$r, $x);
    }
    
    return $r;
}

# usage: rbinom( [SCALAR], [SCALAR])
# return: ARRAY REF
sub rbinom {
	
	check_prototype(@_, '$+');
	
	my $size = shift;
	my $p = shift;
	
	$p = (defined($p) and $p ne "") ? $p : 0.5;
	
	my $d = initial_array($size);
	$d = sapply($d, sub { rand() < $p ? 1 : 0});
	return $d;
}

# usage: max( [ARRAY REF] )
# return: SCALAR
sub max {
	
	check_prototype(@_, '\@');
	
    my $array = shift;
    my $max = $array->[0];
    for (@$array) {
        $max = $max > $_ ? $max : $_;
    }
    return $max;
}

# usage: min( [ARRAY REF] )
# return: SCALAR
sub min {
	
	check_prototype(@_, '\@');
	
    my $array = shift;
    my $min = $array->[0];
    for (@$array) {
        $min = $min < $_ ? $min : $_;
    }
    return $min;
}

# usage: which_max( [ARRAY REF] )
# return: SCALAR
sub which_max {
	
	check_prototype(@_, '\@');
	
    my $array = shift;
    my $max = $array->[0];
	my $which_max = 0;
    for (1..$#$array) {
		if($array->[$_] > $max) {
			$which_max = $_;
		}
	}
	return $which_max;
}

# usage: which_min( [ARRAY REF] )
# return: SCALAR
sub which_min {
	
	check_prototype(@_, '\@');
	
    my $array = shift;
    my $min = $array->[0];
	my $which_min = 0;
    for (1..$#$array) {
		if($array->[$_] < $min) {
			$which_min = $_;
		}
	}
	return $which_min;
}

# usage: median( [ARRAY REF] )
# return: SCALAR
sub median {
	
	check_prototype(@_, '\@');
	
    my $array = shift;
    
    my $sort = sort_array($array);
    
    my $median_index;
    if(len($sort) % 2 == 1) {
        $median_index = int(scalar(@$sort) / 2);
        return $sort->[$median_index];
    }
    else {
        return ($sort->[int(scalar(@$sort) / 2)] + $sort->[int(scalar(@$sort) / 2) - 1])/2;
    }
}

# usage: quantile( [ARRAY REF], [SCALAR | ARRAY REF] )
# return: SCALAR | ARRAY REF
sub quantile {
	
	check_prototype(@_, '\@($|\@)?');
	
    my $array = shift;
	my $p = shift;
	$p = defined($p) ? $p : [0, 0.25, 0.5, 0.75, 1];
	my $q;
	
    if(is_array_ref($p)) {
        return sapply($p, sub{ quantile($array, $_[0]) });
    }
    else {
		if($p > 1 or $p < 0) {
			croak "P value should in 0~1";
		}
		$array = sort_array($array);
		if($p == 1) {
			return $array->[$#$array];
		}
		if($p == 0) {
			return $array->[0];
		}
		
		my $n = len($array);
		
		if(&abs(int($p*($n-1)) - $p*($n-1)) < EPS) {
			return $array->[int($p*($n-1))];
		}
		else {
			my $floor = $array->[int($p*($n-1)+EPS)];
			my $ceiling = $array->[int($p*($n-1)+EPS) + 1];
			return ($p*($n-1)-int($p*($n-1)+EPS))*($ceiling - $floor) + $floor;
		}
    }
}


# usage: iqr( [ARRAY REF])
# return: SCALAR
sub iqr {
	
	check_prototype(@_, '\@');
	
	my $array = shift;
	
	my $q = quantile($array, [.25, .75]);
	return $q->[1] - $q->[0];
}

sub cumf {
	
	check_prototype(@_, '\@(\&)?');
	
	my $array = shift;
	my $function = shift || sub {my $x = $_[0]; $x->[$#$x];};
	
	my $cum = [];
	my $carray = [];
	for(my $i = 0; $i < len($array); $i ++) {
		push(@$carray, $array->[$i]);
		$cum->[$i] = $function->($carray);
	}
	return $cum;
}


1;


