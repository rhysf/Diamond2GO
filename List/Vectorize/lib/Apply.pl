

sub sapply {

    check_prototype(@_, '\@\&');

	my $array = shift;
    my $function = shift;
	
    my $sapply = [];
    @$sapply = map { my $scalar = $function->($_);
                     $scalar;
					} @$array;

    return $sapply;
}


sub mapply {
    
	check_prototype(@_, '(\@|$)+\&');

	my $function = pop; # the last argument
    my @array = @_;
	
    for (0..$#array) {
        if(! is_array_ref($array[$_])) {
            $array[$_] = [$array[$_]];
        }
    }

    my $length = sapply(\@array, \&len);
    my $max_length = max($length);
	
	my $check_length = sapply($length, sub {$max_length % $_[0] != 0});
	if(sum($check_length)) {
		croak "ERROR: Longer object length is not a multiple of shorter object length.";
	}
	
    @array = @{ sapply(\@array, sub{_cycle($_[0], $max_length)}) };
	
    my $mapply = [];
    for my $i (0..($max_length-1)) {
        my $param = sapply(\@array, sub {$_[0]->[$i]});
        $mapply->[$i] = do { my $scalar = $function->(@$param);
			                 $scalar; };
    }

    return $mapply;
}


sub _cycle {
    my $array = shift;
    my $size = shift || len($array);
    my $scalar = len($array);

    if($size == $scalar) {
        return $array;
    }
    elsif($size < $scalar) {
        $size --;
        return subset($array, [0..$size]);
    }
    else {
        $size --;
        my $index = sapply([0..$size], sub {$_ % $scalar});
        return subset($array, $index);
    }
}


sub happly {

    check_prototype(@_, '\%\&');

	my $hash = shift;
    my $function = shift;
	
    my $happly = {};
    foreach (keys %$hash) {
        $happly->{$_} = do { my $scalar = $function->($hash->{$_});
			                 $scalar; };
    }
    return $happly;
}


sub tapply {
    
	check_prototype(@_, '\@(\@)+\&');
	
	my $array = shift;
	my $function = pop;
    my @category = @_;
	
	my $length = sapply(\@category, \&len);
	push(@$length, len($array));
	if(max($length) != min($length)) {
		croak "ERROR: Length of the vector must be equal to the length of all categories.\n";
	}
	
	my $category = paste(@category, "|");

    my $label = unique($category);
    my $tapply = {};
    for (0..$#$label) {
        my $current_label = $label->[$_];
        my $index = test($category, sub {$_[0] eq $current_label});
        $index = which($index);
		my @data = @{subset($array, $index)};
        $tapply->{$current_label} = do { my $scalar = $function->(@data);
			                             $scalar; };
    }
    return $tapply;
}

1;
