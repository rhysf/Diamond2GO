
# description: is the scalar a number
sub is_numberic {
    my $value = $_[0];
    if($value =~/^-?\d+\.?\d*$/) {
        return 1;
    } else {
        return 0;
    }
}

# description: is the scalar a array reference
sub is_array_ref {
    if($_[0] and ref($_[0])
             and ref($_[0]) eq "ARRAY") {
        return 1;
    }
    else {
        return 0;
    }
}

# description: is the scalar a hash reference
sub is_hash_ref {
    if($_[0] and ref($_[0])
             and ref($_[0]) eq "HASH") {
        return 1;
    }
    else {
        return 0;
    }
}

# description: is the scalar a scalar reference
sub is_scalar_ref {
    if($_[0] and ref($_[0])
             and ref($_[0]) eq "SCALAR") {
        return 1;
    }
    else {
        return 0;
    }
}

# description: is the scalar a subroutiine reference
sub is_code_ref {
    if($_[0] and ref($_[0])
             and ref($_[0]) eq "CODE") {
        return 1;
    }
    else {
        return 0;
    }
}

# description: is the scalar a typeglob reference
sub is_glob_ref {
    if($_[0] and ref($_[0])
             and ref($_[0]) eq "GLOB") {
        return 1;
    }
    else {
        return 0;
    }
}

# description: is the scalar a reference reference
sub is_ref_ref {
    if($_[0] and ref($_[0])
             and ref($_[0]) eq "REF") {
        return 1;
    }
    else {
        return 0;
    }
}

# description: the type of a scalar
sub type_of {

	if(ref($_[0])) {
		return ref($_[0])."_REF";
	}
	elsif(ref(\$_[0]) eq "GLOB") {
		return "GLOB";
	}
	else {
		return "SCALAR";
	}
}

1;
