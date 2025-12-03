#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use lib "$Bin/modules";
use read_Tab;
use Getopt::Std;
use Statistics::Multtest qw(BH qvalue);
use Statistics::WilsonInterval;
use Statistics::RightFisher;
use Statistics::TwoFisher;
use Data::Dumper;

### r.farrer@exeter.ac.uk

# Opening commands
my $usage = "Usage: perl $0 -a <gene tab GO_term1,GO_term2,etc> -b <subset.list>\n
Optional: -c\tColumn of gene in file a [1]
          -d\tColumn of GO terms separated by comma [2]
          -o\tgo-basic.obo [$Bin/../resources/go-basic.obo]
          -p\tOutput file [opt_b.enrichments]
          -q\tOutput file parsed for significant GO terms without significant child GO terms [opt_b.enrichments.parsed]
          -r\tConduct a right-tailed Fisher test instead of two-tailed (y/n) [n]
	  -z\tInclude gene entries in output (y/n) [n]\n";
our($opt_a, $opt_b, $opt_c, $opt_d, $opt_f, $opt_o, $opt_p, $opt_q, $opt_r, $opt_z);
getopt('abcdfopqrz');
die $usage unless ($opt_a && $opt_b);
if(!defined $opt_c) { $opt_c = 1; }
if(!defined $opt_d) { $opt_d = 2; }
if(!defined $opt_o) { $opt_o = "$Bin/../resources/go-basic.obo"; }
if(!defined $opt_p) { $opt_p = "$opt_b.enrichments"; }
if(!defined $opt_q) { $opt_q = "$opt_b.enrichments.parsed"; }
if(!defined $opt_r) { $opt_r = 'n'; }
if(!defined $opt_z) { $opt_z = 'n'; }
foreach my $file($opt_a, $opt_b, $opt_o) { die "Error: file $file cannot be opened : $!" if(! -e $file); }

# Save genes of interest and GO terms
my $genes_of_interest = tabfile::save_columns_to_one_hash($opt_b, 0);
my $all_GO_terms = tabfile::save_columns_to_column_hash($opt_a, $opt_c, $opt_d);

# Save obo file
my ($go_desc, $has_parents) = &save_obo_file($opt_o);

# Print GO-terms for subset.list
my $file1_test = "$opt_b-GO";
&print_GO_terms_for_subset_list_from_own_file($all_GO_terms, $genes_of_interest, $file1_test);

# Print GO terms for all (D2GO-out)
my $file2_compare = "$opt_a-GO";
&print_GO_terms_for_all_D2GO_from_own_file($all_GO_terms, $file2_compare);

# read in b2g files
my %go_terms1;
my $term_col = 1;
my ($go_counts1, $go_terms2, $gene2go_1, $sp1_gc, $go_to_gene1) = &save_b2g_file($file1_test, $term_col, \%go_terms1, $has_parents);
my ($go_counts2, $go_terms, $gene2go_2, $sp2_gc, $go_to_gene2) = &save_b2g_file($file2_compare, $term_col, $go_terms2, $has_parents);

# Save zero values for those found in one file but not the other
my @go_term_list = sort (keys %{$go_terms});
my @diff_go_terms;
foreach my $go_term(@go_term_list) {
	
	#warn "go_term = $go_term . has parents = $$has_parents{$go_term} count1 = $$go_counts1{$go_term} and count2 = $$go_counts2{$go_term}\n";
	if ($$go_counts1{$go_term}) { } 
	else { $$go_counts1{$go_term} = 0; }

	if ($$go_counts2{$go_term}) { } 
	else { $$go_counts2{$go_term} = 0; }

	if ($go_term eq 'GO:0008150' or $go_term eq 'GO:0005575' or $go_term eq 'GO:0003674') { } 
	elsif ($$has_parents{$go_term}) {
		if (($$go_counts1{$go_term} + $$go_counts2{$go_term}) > 1) {
			push @diff_go_terms, $go_term;
		}
	}
}

# Calculate Statistics
my %fisher_ps;
foreach my $go_term (@diff_go_terms) {
	my $npp = $sp1_gc + $sp2_gc;
	my $np1 = $sp1_gc;
	my $n11 = $$go_counts1{$go_term};
	my $n1p = $$go_counts1{$go_term} + $$go_counts2{$go_term};
	my $fisher_p;
	if ($opt_r ne 'n') {
		$fisher_p = Stats::RightFisher::getRightFisher($n11,$n1p,$np1,$npp);
	} else {
		$fisher_p = Stats::TwoFisher::getTwoFisher($n11,$n1p,$np1,$npp);
	}
	if($fisher_p > 1) {
		$fisher_p = 1;
	}
	if($fisher_p < 0) {
		$fisher_p = 0;
	}

	#print "$go_term -> $fisher_p\n";
	$fisher_ps{$go_term} = $fisher_p;
}

#print Dumper(\%fisher_ps);
my $ps = \%fisher_ps;
warn "Calculating q-values (takes a while)...\n";
my $res = eval 'qvalue($ps)';
if($@) {
    warn $@;
}
my %qs = %$res;

# Print Results
open my $ofh, '>', $opt_p or die "Error: cannot open $opt_p : $!";
if($opt_z eq 'y') { print $ofh "GO term\tsp1 count\tsp2 count\tfisher p\tq value\trel prop\tsig\tGO desc\tgenes1\tgenes2\n"; }
else { print $ofh "GO term\tsp1 count\tsp2 count\tfisher p\tq value\trel prop\tsig\tGO desc\n"; }
foreach my $go_term (@diff_go_terms) {
	my $genes1 = '';
	my $genes2 = '';
	if(defined $$go_to_gene1{$go_term}) { $genes1 = $$go_to_gene1{$go_term}; }
	if(defined $$go_to_gene2{$go_term}) { $genes2 = $$go_to_gene2{$go_term}; }

	# calculate and print
	my $rel_prop = sprintf("%.2f", ($$go_counts1{$go_term} / ($$go_counts2{$go_term}+0.00001))*($sp2_gc/$sp1_gc)); # relative proportion
	print $ofh "$go_term\t$$go_counts1{$go_term}\t$$go_counts2{$go_term}\t$fisher_ps{$go_term}\t$qs{$go_term}\t$rel_prop\t";
	#print "$npp,$np1,$n11,$n1p\t";
	if ($qs{$go_term} < 0.05) { print $ofh "*"; }
	print $ofh "\t$$go_desc{$go_term}";
	if($opt_z eq 'y') { print $ofh "\t$genes1\t$genes2\n"; }
	else { print "\n"; }
}
close $ofh;

# Parse

# Save b2g files
my ($sig_terms, $spec_sig_terms, $term_data, $header) = &save_bfile($opt_p);

# Filter significant GO terms without significant child GO terms 
foreach my $sig_term (@{$sig_terms}) {
    my $current_go = $sig_term;
    ### print "$current_go"; ###
    my @current_parents;
    my @family;
    ##### working area
    if ($$has_parents{$current_go}) {  					
        @current_parents = @{$$has_parents{$current_go}};
    } 
    elsif ($current_go eq 'GO:0008150' or $current_go eq 'GO:0005575' or $current_go eq 'GO:0003674') {
    } 
    else {
        #warn "Warning: No parents found for $current_go. Term may be obsolete or have an alternate id.\n"
    }

	while (@current_parents) {
		$current_go = shift @current_parents;
		push @family, $current_go;
		### print " $current_go"; ###

		if ($$has_parents{$current_go}) {
			my @new_parents = @{$$has_parents{$current_go}};
			foreach my $new_parent (@new_parents) {
				push @current_parents, $new_parent;
			}
		}
	}

	if (@family) {
		foreach my $family (@family) {
			$$spec_sig_terms{$family} = 0;
		}
	}  
}

# print
open my $ofh2, '>', $opt_q or die "Error: cannot open $opt_q : $!";
print $ofh2 "$header\n";
foreach my $sig_term (@{$sig_terms}) {
	if($$spec_sig_terms{$sig_term} == 1) {
		print $ofh2 "$$term_data{$sig_term}\n";
	}
}
close $ofh2;

sub save_bfile {
    my $file = $_[0];

    my @sig_terms;
    my %spec_sig_terms;
    my %term_data;
    my $header = '';

    open my $fh, '<', $file or die "Error: cannot open $file : $!";
    while(my $line=<$fh>) {
        chomp $line;
        # header
        if($line =~ /^GO term/) {
            #print "$line";
            $header = $line;
        }
        # sig
        elsif($line =~ /\t\*\t/) {
            my @bits = split (/\t/, $line);
            push @sig_terms, $bits[0];
            $spec_sig_terms{$bits[0]} = 1;
            $term_data{$bits[0]} = $line;
        } 
    }
    close $fh;
    return (\@sig_terms, \%spec_sig_terms, \%term_data, $header);
}

sub save_b2g_file {
	my ($file, $term_col, $go_terms_hash, $has_parents) = @_;

	my %go_counts;
	my %RF_new_GO_to_genes;
	my %gene2go_1;
	my $sp1_gc = 0; 

	warn "save_b2g_file: $file (term_col = $term_col)\n";

	# Go through GO-terms file, saving counts and finding parents
	open my $fh, '<', $file or die "Cannot open $file : $!\n";
	while(my $line=<$fh>) {
		chomp $line;
		next if($line =~ m/^#/);
		my @bits = split /\t/, $line;
		my $gene_id = $bits[0];
		my $go_terms = $bits[$term_col];
		next if($go_terms eq '.');
		++$sp1_gc;

		# For each GO term saved for this gene
		my @y = split /;/, $go_terms;
		foreach my $current_go(@y) {

			# Save parents
			my @current_parents;
			my @family;
			push @family, $current_go;
			if ($$has_parents{$current_go}) { @current_parents = @{$$has_parents{$current_go}}; }
			# don't do anything with these - uninformative top terms
			elsif ($current_go eq 'GO:0008150' or $current_go eq 'GO:0005575' or $current_go eq 'GO:0003674') { }
			#else { warn "Warning: No parents found for $current_go. Term may be obsolete or have an alternate id.\n" }

			while (@current_parents) {
				$current_go = shift @current_parents;
				push @family, $current_go;
				### print " $current_go"; ###
 
				if ($$has_parents{$current_go}) {
					my @new_parents = @{$$has_parents{$current_go}};
					foreach my $new_parent (@new_parents) {
						push @current_parents, $new_parent;
					}
				}
			}

			# Make new family
			my @sorted_family = sort @family;
			my $last_member = '';
			my @new_family;
			foreach my $sorted_family (@sorted_family) {
				if ($sorted_family eq $last_member or exists ($gene2go_1{$bits[0]}{$sorted_family})) { } 
				else {
					push @new_family, $sorted_family;   
					$gene2go_1{$bits[0]}{$sorted_family} = 1;
				}
				$last_member = $sorted_family;
			}
			foreach my $new_family (@new_family) {
				if ($go_counts{$new_family}) { 
					++$go_counts{$new_family}; 
					$RF_new_GO_to_genes{$new_family} .= ",$gene_id";
				} 
				else { 
					$go_counts{$new_family} = 1; 
					$RF_new_GO_to_genes{$new_family} .= "$gene_id";
				}
				$$go_terms_hash{$new_family} = 1;
			}
		}
	}
	close $fh;
	return (\%go_counts, $go_terms_hash, $gene2go_1, $sp1_gc, \%RF_new_GO_to_genes);
}

sub save_obo_file {
	my $file = $_[0];

	my (%go_desc, %has_parents);
	my $current_go;

	warn "save_obo_file: $file\n";
	open my $fh, '<', $file or die "Cannot open $file : $!\n";
	while(my $line=<$fh>) {
		chomp $line;
		# not downloaded
		if($line =~ m/version https:\/\/git-lfs/) {
			die "save_obo_file: error: obo not downloaded from LFS. Either redownload, or obtain from elsewhere\n";
		}

		if ($line =~ /^id: (GO:\d+)/) {
			$current_go = $1;
		} elsif ($line =~ /^name: ([\S ]+)/) {
			$go_desc{$current_go} = $1;
		} elsif ($line =~ /^is_a: (GO:\d+)/) {
			push (@{$has_parents{$current_go}}, $1);
		} elsif ($line =~ /^relationship: part_of (GO:\d+)/) {
			push (@{$has_parents{$current_go}}, $1);
		}
	}
	close $fh;
	#print Dumper(%has_parents);
	return (\%go_desc, \%has_parents);
}

sub print_GO_terms_for_all_D2GO_from_own_file {
	my ($genes_to_go_separated_by_comma, $outfile) = @_;

	warn "print_GO_terms_for_all_D2GO: $outfile\n";
	open my $ofh, '>', $outfile or die "Error: cannot open $outfile : $!";
	my $gene_count = 0;
	foreach my $gene(sort keys %{$genes_to_go_separated_by_comma}) {
		next if($$genes_to_go_separated_by_comma{$gene} eq 'NA');
		next if($$genes_to_go_separated_by_comma{$gene} eq '');
		
		$gene_count++;
		my $go_terms_new = $$genes_to_go_separated_by_comma{$gene};
		$go_terms_new =~ s/,/;/g;
		print $ofh "entry$gene_count\t$go_terms_new\n";
		
		#my @go_terms = split /,/, $$genes_to_go_separated_by_comma{$gene};
		#foreach my $go_term(@go_terms) {
		#	print $ofh "entry$gene_count\t$go_term\n";
		#}
	}
	close $ofh;
	return;
}

sub print_GO_terms_for_subset_list_from_own_file {
	my ($genes_to_go_separated_by_comma, $genes_of_interest, $outfile) = @_;
	
	warn "print_GO_terms_for_subset_list: $outfile\n";
	open my $ofh, '>', $outfile or die "Error: cannot open $outfile : $!";
	my $gene_count = 0;
	foreach my $gene(sort keys %{$genes_of_interest}) {
		next if(!defined $$genes_to_go_separated_by_comma{$gene});
		next if($$genes_to_go_separated_by_comma{$gene} eq '');
		next if($$genes_to_go_separated_by_comma{$gene} eq 'NA');

		$gene_count++;
		my $go_terms_new = $$genes_to_go_separated_by_comma{$gene};
		$go_terms_new =~ s/,/;/g;
		print $ofh "entry$gene_count\t$go_terms_new\n";
		
		#my @go_terms = split /,/, $$genes_to_go_separated_by_comma{$gene};
		#foreach my $go_term(@go_terms) {
		#	print $ofh "entry$gene_count\t$go_term\n";
		#}
	}
	close $ofh;
	return;
}
