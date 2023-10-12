
# ============================= IO subroutine ==============================================
# usage: print_ref( [TYPEGLOB], [SCALAR] )
# description: print the data structure of a reference
sub print_ref {
	
	check_prototype(@_, '*?($|\$|\@|\%|\&)+');
	
	local $handle = *STDOUT;
	if(is_glob_ref(\$_[0])) {
		$handle = shift(@_);
	}
	my $ref = shift;
    
    if(is_array_ref($ref)) {
        print $handle "Reference of ARRAY.\n";
		for (0..$#$ref) {
			print $handle "[$_] $ref->[$_]\n";
		}
        print $handle "\n";
    } elsif(is_hash_ref($ref)) {
        print $handle "Reference of HASH.\n";
        foreach (keys %$ref) {
            print $handle "$_\t$ref->{$_}\n";
        }
        print $handle "\n";
    } elsif(is_scalar_ref($ref)) {
        print $handle "Reference of SCALAR.\n";
        print $handle $$ref;
        print $handle "\n";
    } elsif(is_ref_ref($ref)) {
        print $handle "Reference of REF.\n";
        print $handle $$ref;
        print $handle "\n";
    } elsif(is_code_ref($ref)) {
        print $handle "Reference of CODE.\n";
    } else {
        print $handle "@_\n";
    }
    return $ref;
}

# usage: print_matrix( [TYPEGLOB], [SCALAR] )
# description: print the matrix
sub print_matrix {
	
	check_prototype(@_, '*?\@');
	
	local $handle = *STDOUT;
	if(is_glob_ref(\$_[0])) {
		$handle = shift(@_);
	}
	my $mat = $_[0];
	my $sep = "\t";
	
	my ($nrow, $ncol) = dim($mat);
	print "$nrow x $ncol matrix:\n\n";
	
	for(my $i = 0; $i < len($mat); $i ++) {
		print $handle join $sep, @{$mat->[$i]};
		print $handle "\n";
	}
	print "\n";
}

# usage: read_table( [SCALAR], %setup )
sub read_table {
	
	check_prototype(@_, '$($|\@){0,}');
	
	my $file = shift;
	
	my %setup = @_;
	my $quote = $setup{"quote"} || "";
	my $sep = $setup{"sep"} || "\t";
	my $whether_rownames = $setup{"row.names"} || 0;       # if set true, first item will be key
	my $whether_colnames = $setup{"col.names"} || 0;       # if set true, first item will be key
	
	open F, $file or croak "ERROR: cannot open $file.\n";
	my $data;
	my $rownames;
	my $colnames;
	my $i_line = 0;
	my $i_array = 0;
	my $flag = 0;
	while( my $line = <F>) {
		$i_line ++;
		
		# read the column names
		if($flag == 0 and $whether_colnames) {
			chomp $line;
			$line =~s/^$quote|$quote$//g;
			@$colnames = split "$quote$sep$quote", $line; 
			if($whether_rownames) {
				shift(@$colnames);
			}
			$flag = 1;
			$i_line --;
			next;
		}
		
		$i_array ++;
		
		chomp $line;
		$line =~s/^$quote|$quote$//g;
		my @tmp = split "$quote$sep$quote", $line; 
		
		# read rownames
		if($whether_rownames) {
			push(@$rownames, shift(@tmp));
		}
		
		push(@{$data->[$i_array - 1]}, @tmp);
		
	}
	close F;

	wantarray ? ($data, $colnames, $rownames) : $data;
}

# usage: write_table( [MATRIX], %setup )
sub write_table {
	
	check_prototype(@_, '\@($|\@){2,}');
	
	my $matrix = shift;
	
	my %setup = @_;
	my $quote = $setup{"quote"} || "";
	my $sep = $setup{"sep"} || "\t";
	my $colnames = $setup{"col.names"};   # column names
	my $rownames = $setup{"row.names"};   # row names
	my $file = $setup{"file"};
	
	my ($nrow, $ncol) = dim($matrix);
	if($rownames and $nrow != len($rownames)) {
		croak "ERROR: Length of rownames should be equal to the length of rows in matrix\n";
	}
	if($colnames and $ncol != len($colnames)) {
		croak "ERROR: Length of colnames should be equal to the length of columns in matrix\n";
	}
	
	open OUT, ">$file" or croak "ERROR: Cannot create file:$file\n";
	if($rownames) {
		if($colnames) {
			# print colnames
			print OUT "$quote$quote$sep";
			print OUT join $sep, @{sapply($colnames, sub{"$quote$_$quote"})};
			print OUT "\n";
		}
		for(my $i = 0; $i < len($matrix); $i ++) {
			print OUT "$quote$rownames->[$i]$quote$sep";
			print OUT join $sep, @{sapply($matrix->[$i], sub{"$quote$_$quote"})};
			print OUT "\n";
		}
	}
	else {
		if($colnames) {
			print OUT join $sep, @{sapply($colnames, sub{"$quote$_$quote"})};
			print OUT "\n";
		}
		for(my $i = 0; $i < len($matrix); $i ++) {
			print OUT join $sep, @{sapply($matrix->[$i], sub{"$quote$_$quote"})};
			print OUT "\n";
		}
	}
	close OUT;
}



1;
