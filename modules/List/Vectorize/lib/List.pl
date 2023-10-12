

sub initial_array {

	check_prototype(@_, '$(\&|$|\@)?');
	
	my $size = shift;
	my $value = shift || undef;
	if(is_code_ref($value)) {
		return sapply([1..$size], $value);
	}
	else {
		return repeat($value, $size);
	}
}


sub initial_matrix {

	check_prototype(@_, '$$(\&|$)?');
	
	my $n_row = shift;
	my $n_col = shift;
	my $value = shift || undef;
	
	my $mat = initial_array($n_row);
	if(is_code_ref($value)) {
		return sapply($mat, sub {sapply([1..$n_col], $value)});
	}
	else {
		return sapply($mat, sub {repeat($value, $n_col)});
	}
}


sub order {

	check_prototype(@_, '\@(\&)?');
	
    my $array = shift;
    my $function = shift || sub {$_[0] <=> $_[1]}; 

    my $order = [];
	@$order = sort { $function->($array->[$a], $array->[$b]) } 0..$#$array;
    return $order;
}

sub rank {
	
	check_prototype(@_, '\@(\&)?');
	
	my $order = order(@_);
	my $array = shift(@_);
	my $rank = [];
	my $same = [];
	my $index = [];
	for($i = 0; $i < len($order); $i ++) {
		
		if($i != 0 and ($array->[$order->[$i]] != $array->[$order->[$i - 1]])) {
			foreach (@$index) {
				$rank->[$_] = mean($same);
			}
			$same = [];
			$index = [];
		}
		
		push(@$same, $i+1);
		push(@$index, $order->[$i]);
		
	}
	
	foreach (@$index) {
		$rank->[$_] = mean($same);
	}
	return $rank;
}


sub sort_array {
	
	check_prototype(@_, '\@(\&)?');
	
	my $array = shift;
    my $function = shift || sub {$_[0] <=> $_[1]}; 
    
	return [sort {$function->($a, $b)} @$array];
}


sub reverse_array {
	
	check_prototype(@_, '\@');
	
    my $array = shift;
    
	return [reverse(@$array)];
}


sub repeat {
	
	check_prototype(@_, '($|\$|\@|\%)$$?');
	
    my $value = shift;
    my $size = shift;
	my $need_copy = shift;
	$need_copy = defined($need_copy) ? $need_copy : 1;
    
    my $array = [];
	if(is_ref_ref(\$value)) {
		for(my $i = 0; $i < $size; $i ++) {
			if($need_copy) {
				push(@$array, copy($value));
			}
			else {
				push(@$array, $value);
			}
		}
	}
	else {
		for(my $i = 0; $i < $size; $i ++) {
			push(@$array, $value);
		}
	}
    return $array;
}

sub rep {

	check_prototype(@_, '($|\$|\@|\%)$$?');
	
	return repeat(@_);
}


sub copy {
	
	check_prototype(@_, '(\$|\@|\%)');
	
	my $value = shift;
	my $copy;
	if(is_ref_ref(\$value)) { 
		my $s = Dumper($value);
		$s =~s/^\$\w+/\$copy/ms;
		eval($s);
		if($@) {
			croak "ERROR: $@\n";
		}
	}
	else {
		croak "ERROR: must copy a reference\n";
	}
	return $copy;
}


sub paste {

	check_prototype(@_, '(\@|$)+');
	
	my $sep;
	if(is_scalar_ref(\$_[$#_])) {
		$sep = pop; 
	}
	else {
		$sep = "|";
	}
    my @args = @_;
	
    return mapply(@args, sub{join $sep, @_});
}


sub seq {

	check_prototype(@_, '$$$?');
	
    my $from = shift;
    my $to = shift;
    my $by = shift || 1;
    
    my $seq = [];
    if($from < $to) {
		for(my $i = $from; $i <= $to; $i += $by) {
            push(@$seq, $i);
        }
    }
    else {
		for(my $i = $from; $i >= $to; $i -= $by) {
            push(@$seq, $i);
        }
    }
    return $seq;
}


sub c {
    
	check_prototype(@_, '(\@|$|\$)+');
	
	my @array_refs = @_;
    my $c = [];
    foreach (@array_refs) {
		if(is_array_ref($_)) {
			push(@$c, @$_);
		}
		else {
			push(@$c, $_);
		}
    }
    return $c;
}


sub test {
	
	check_prototype(@_, '\@\&');
	
    my $array = shift;
    my $function = shift;

    return sapply($array, sub {$function->($_[0]) ? 1: 0});
}


sub unique {
	
	check_prototype(@_, '\@');
	
    my $array = shift;
    my $hash = {};
    return [grep {not $hash->{$_} ++} @$array];
}


sub subset {
	
	check_prototype(@_, '\@(\@|\&)');
	
    my $array = shift;
    my $index = shift;
    
    if(is_code_ref($index)) {
        my $function = $index;
        return subset($array, which(test($array, $function)));
    }
    else {
        my $subset = [];
		
		my $max_index = max($index);
		my $min_index = min($index);
		if($max_index * $min_index < 0) {
			croak "ERROR: index should be in the same sign\n";
		}
		if($min_index >= 0) {
			for(my $i = 0; $i < len($index); $i ++) {
				push(@$subset, $array->[$index->[$i]]);
			}
		}
		elsif($max_index < 0) {
			return subset($array, setdiff(seq(0, $#$array), sapply($index, sub {-$_[0]-1})));
		}
        return $subset;
    }
}


sub subset_value {

	check_prototype(@_, '\@(\@|\&)(\@|$)');
		
    my $array = shift;
    my $index = shift;
	my $value = shift;
    
    if(is_code_ref($index)) {
        my $function = $index;
        return subset_value($array, which(test($array, $function)), $value);
    }
    else {
		if(is_scalar_ref(\$value)) {
			$value = repeat($value, len($index));
		}
		if(len($value) != len($index)) {
			croak "ERROR: length of values must be equal to that of subset!\n";
		}
		
		my $max_index = max($index);
		my $min_index = min($index);
		if($max_index * $min_index < 0) {
			croak "ERROR: index should be in the same sign\n";
		}
		if($min_index >= 0) {
			for(my $i = 0; $i < len($index); $i ++) {
				$array->[$index->[$i]] = $value->[$i];
			}
			return $array;
		}
		elsif($max_index < 0) {
			return subset($array, complement(sapply($index, sub {-$_[0]-1}), seq(0, $#$index)), $value);
		}
    }
}


# usage: del_array_item( [ARRAY REF])
# return: ARRAY REF
sub del_array_item {

	check_prototype(@_, '\@($|\@)');
	
	my $array = shift;
	my $del_i = shift;
	
	if(is_array_ref($del_i)) {
		my $remain = setdiff([0..$#$array], $del_i);
		@$array = @$array[@$remain];
	}
	else {
		@$array = (@$array[0..($del_i-1)], @$array[($del_i+1)..$#$array]);
	}
	return $array;
}


sub which {
	
	check_prototype(@_, '\@');
	
    my $logical = shift;
    
    my $which = [];
	@$which = grep {$logical->[$_]} 0..$#$logical;
    return $which;
}

sub all {
    
    check_prototype(@_, '\@');
    
    my $l = shift;
    if(len($l)) {
        return sum(test($l, sub {$_[0]})) == len($l) ? 1 : 0;
    } else {
        return 0;
    }
}

sub any {

    check_prototype(@_, '\@');
    
    my $l = shift;
    return sum(test($l, sub {$_[0]})) ? 1 : 0;
}


sub dim {
	
	check_prototype(@_, '\@');
	
	my $mat = shift;
	if(all(sapply($mat, sub {is_array_ref($_[0])}))) {
		
		my $nc = len($mat->[0]);
		if(all(sapply($mat, sub {len($_[0]) == $nc}))) {
			return (len($mat), $nc);
		}
	}
	
	return undef;

}


sub t {
	
	check_prototype(@_, '\@');
	
    my $matrix = shift;
    
    my ($n_row, $n_col) = dim($matrix);

    my $t = [[]];
    for(my $i = 0; $i < $n_row; $i ++) {
        for(my $j = 0; $j < $n_col; $j ++) {
            $t->[$j]->[$i] = $matrix->[$i]->[$j];
        }
    }
    return $t;
}

sub matrix_prod {
	
	check_prototype(@_, '(\@)+');
	
	if(scalar(@_) > 2) {
		my $first = shift(@_);
		my $second = shift(@_);
		return matrix_prod(matrix_prod($first, $second), @_);
	}
	
	my $mat1 = shift;
	my $mat2 = shift;
	
	my ($I, $J1) = dim($mat1);
	my ($J2, $K) = dim($mat2);
	
	if($J1 == $J2) {
		my $J = $J1;
		my $product;
		for(my $i = 0; $i < $I; $i ++) {
			for(my $k = 0; $k < $K; $k ++) {
				my $sum = 0;
				for(my $j = 0; $j < $J; $j ++) {
					$sum += $mat1->[$i]->[$j]*$mat2->[$j]->[$k];
				}
				$product->[$i]->[$k] = $sum;
			}
		}
		return $product;
	}
	else {
		croak "ERROR: columns in the first matrix must be equal to the rows in the second matrix";
	}
}


sub is_array_identical {
	
	check_prototype(@_, '\@\@');
	
	my $array1 = shift;
	my $array2 = shift;
	
	if(len($array1) != len($array2)) {
		return 0;
	}
	else {
		if(sum(mapply($array1, $array2, sub{abs($_[0]-$_[1]) < EPS})) == len($array1)) {
			return 1;
		}
		else {
			return 0;
		}
	}
}


sub is_matrix_identical {

	check_prototype(@_, '\@\@');
	
	my $matrix1 = shift;
	my $matrix2 = shift;
	
	my ($d1, $d2) = dim($matrix1);
	my ($d3, $d4) = dim($matrix2);
	
	if(!defined($d1) or !defined($d2) or !defined($d3) or !defined($d4)) {
		return 0;
	}
	
	unless($d1 == $d3 and $d2 == $d4) {
		return 0;
	}
	
	my $v = mapply($matrix1, $matrix2, sub {is_array_identical($_[0], $_[1])});
	if(sum($v) == len($matrix1)) {
		return 1;
	}
	else {
		return 0;
	}
}


sub outer {
	
	check_prototype(@_, '\@\@(\&)?');
	
	my $vector1 = shift;
	my $vector2 = shift;
	my $function = shift || sub {$_[0]*$_[1]};
	
	my $outer = [];
	for(my $i = 0; $i < len($vector1); $i ++) {
		for(my $j = 0; $j < len($vector2); $j ++) {
			$outer->[$i]->[$j] = $function->($vector1->[$i], $vector2->[$j]);
		}
	}
	
	return $outer;
}

sub inner {
	
	check_prototype(@_, '\@\@(\&)?');
	
	my $vector1 = shift;
	my $vector2 = shift;
	my $function = shift || sub {$_[0]*$_[1]};
	
	my $inner = [];
	$inner = sum(mapply($vector1, $vector2, $function));
	
	return $inner;
}


sub len {
	
	my $array = shift;
	if(is_array_ref($array)) {
		return scalar(@$array);
	}
	elsif(is_hash_ref($array)) {
		return scalar(keys %$array);
	}
	elsif(!defined($array)) {
		return 0;
	}
	else {
		return 1;
	}
}

sub match {
	
	check_prototype(@_, '\@\@');
	
	my $array1 = shift;
	my $array2 = shift;
	
	my $h = {};
	foreach (@$array2) {
		$h->{$_} = 1;
	}
	
	my $index = [];
	for(my $i = 0; $i < len($array1); $i ++) {
		push(@$index, $i) if($h->{$array1->[$i]});
	}
	return $index;
}

sub is_empty {
	!len($_[0]) + 0;
}

sub plus {
	
	check_prototype(@_, '(\@|$)+');
	
	croak "ERROR: at least two array lists is required" if scalar(@_) < 2;
	
	my $array1 = shift;
	my $array2 = shift;
	my @arrays = @_;
	
	my $res = mapply($array1, $array2, sub {$_[0] + $_[1]});
	if(scalar(@arrays) == 0) {
		return $res;
	}
	else {
		return plus($res, @arrays);
	}
}

sub minus {
	
	check_prototype(@_, '(\@|$)+');
	
	croak "ERROR: at least two array lists is required" if scalar(@_) < 2;
	
	my $array1 = shift;
	my $array2 = shift;
	my @arrays = @_;
	
	my $res = mapply($array1, $array2, sub {$_[0] - $_[1]});
	if(scalar(@arrays) == 0) {
		return $res;
	}
	else {
		return minus($res, @arrays);
	}
}

sub divide {
	
	check_prototype(@_, '(\@|$)+');
	
	croak "ERROR: at least two array lists is required" if scalar(@_) < 2;
	
	my $array1 = shift;
	my $array2 = shift;
	my @arrays = @_;
	
	my $res = mapply($array1, $array2, sub {$_[0] / $_[1]});
	if(scalar(@arrays) == 0) {
		return $res;
	}
	else {
		return divide($res, @arrays);
	}
}

sub multiply {
	
	check_prototype(@_, '(\@|$)+');
	
	croak "ERROR: at least two array lists is required" if scalar(@_) < 2;
	
	my $array1 = shift;
	my $array2 = shift;
	my @arrays = @_;
	
	my $res = mapply($array1, $array2, sub {$_[0] * $_[1]});
	if(scalar(@arrays) == 0) {
		return $res;
	}
	else {
		return multiply($res, @arrays);
	}
}



1;
