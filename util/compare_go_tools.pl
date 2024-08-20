#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use lib "$Bin/../modules";
use read_FASTA;

### rf

# usage
my $usage = "perl $0 <eggnog.annotations> <B2GO.annotation.GO> <D2GO.diamond.out.processed> <all.pep>\n";
die $usage unless(@ARGV eq 4);
my ($file_eggnog, $file_B2GO, $file_D2GO, $all_pep) = @ARGV;

# save files (gene -> go_terms = 1)
my $eggnog = &save_eggnog_file($file_eggnog);
my $d2go = &save_d2go_file($file_D2GO);
my $b2go = &save_b2go_file($file_B2GO);

# save fasta file for all proteins
my $fasta = fastafile::fasta_to_struct($all_pep);

# calculate overlap (description -> gene -> go = 1)
my $genes_overlap = &calculate_overlap($eggnog, $d2go, $b2go, $fasta);

# print summary
foreach my $desc(sort keys %{$genes_overlap}) {
	my $gene_count = scalar(keys(%{$$genes_overlap{$desc}}));
	warn "$desc gene count = $gene_count\n";

	my $GO_term_count = 0;
	foreach my $gene(sort keys %{$$genes_overlap{$desc}}) {
		my $go_count = scalar(keys(%{$$genes_overlap{$desc}{$gene}}));
		$GO_term_count += $go_count;
	}
	warn "$desc GO count = $GO_term_count\n";
}

sub calculate_overlap {
	my ($eggnog, $d2go, $b2go, $fasta) = @_;

	warn "calculate_overlap...\n";

	my %genes_overlap;
	IDS: foreach my $ids(sort keys %{$$fasta{'seq'}}) {

		if((!defined $$eggnog{$ids}) && (!defined $$d2go{$ids}) && (!defined $$b2go{$ids})) {
			$genes_overlap{'found_in_none'}{$ids}{'na'} = 1;
			next IDS;
		}

		# eggnog
		foreach my $go_in_eggnog(sort keys %{$$eggnog{$ids}}) {
			# found in all
			if((defined $$d2go{$ids}{$go_in_eggnog}) && (defined $$b2go{$ids}{$go_in_eggnog})) {
				$genes_overlap{'found_in_all'}{$ids}{$go_in_eggnog} = 1;
			}
			elsif((defined $$d2go{$ids}{$go_in_eggnog}) && (!defined $$b2go{$ids}{$go_in_eggnog})) {
				$genes_overlap{'found_in_eggnog_and_d2go'}{$ids}{$go_in_eggnog} = 1;
			}
			elsif((!defined $$d2go{$ids}{$go_in_eggnog}) && (defined $$b2go{$ids}{$go_in_eggnog})) {
				$genes_overlap{'found_in_eggnog_and_b2go'}{$ids}{$go_in_eggnog} = 1;
			}
			elsif((!defined $$d2go{$ids}{$go_in_eggnog}) && (!defined $$b2go{$ids}{$go_in_eggnog})) {
				$genes_overlap{'found_in_eggnog_only'}{$ids}{$go_in_eggnog} = 1;
			}
			else { die "Not accounted for: $ids and $go_in_eggnog\n"; }
		}

		# d2go
		foreach my $go_in_d2go(sort keys %{$$d2go{$ids}}) {
			# found in all
			if((defined $$eggnog{$ids}{$go_in_d2go}) && (defined $$b2go{$ids}{$go_in_d2go})) {
				# this if is redundant - but it will only save over itself, and keeps code easily readable
				$genes_overlap{'found_in_all'}{$ids}{$go_in_d2go} = 1;
			}
			elsif((defined $$eggnog{$ids}{$go_in_d2go}) && (!defined $$b2go{$ids}{$go_in_d2go})) {
				# this if is redundant - but it will only save over itself, and keeps code easily readable
				$genes_overlap{'found_in_eggnog_and_d2go'}{$ids}{$go_in_d2go} = 1;
			}
			elsif((!defined $$eggnog{$ids}{$go_in_d2go}) && (defined $$b2go{$ids}{$go_in_d2go})) {
				$genes_overlap{'found_in_d2go_and_b2go'}{$ids}{$go_in_d2go} = 1;
			}
			elsif((!defined $$eggnog{$ids}{$go_in_d2go}) && (!defined $$b2go{$ids}{$go_in_d2go})) {
				$genes_overlap{'found_in_d2go_only'}{$ids}{$go_in_d2go} = 1;
			}
			else { die "Not accounted for: $ids and $go_in_d2go\n"; }
		}

		# b2go
		foreach my $go_in_b2go(sort keys %{$$b2go{$ids}}) {



			# found in all
			if((defined $$eggnog{$ids}{$go_in_b2go}) && (defined $$d2go{$ids}{$go_in_b2go})) {
				# this if is redundant - but it will only save over itself, and keeps code easily readable
				$genes_overlap{'found_in_all'}{$ids}{$go_in_b2go} = 1;
			}
			elsif((defined $$eggnog{$ids}{$go_in_b2go}) && (!defined $$d2go{$ids}{$go_in_b2go})) {
				# this if is redundant - but it will only save over itself, and keeps code easily readable
				$genes_overlap{'found_in_eggnog_and_b2go'}{$ids}{$go_in_b2go} = 1;
			}
			elsif((!defined $$eggnog{$ids}{$go_in_b2go}) && (defined $$d2go{$ids}{$go_in_b2go})) {
				$genes_overlap{'found_in_d2go_and_b2go'}{$ids}{$go_in_b2go} = 1;
			}
			elsif((!defined $$eggnog{$ids}{$go_in_b2go}) && (!defined $$d2go{$ids}{$go_in_b2go})) {
				$genes_overlap{'found_in_b2go_only'}{$ids}{$go_in_b2go} = 1;
			}
			else { die "Not accounted for: $ids and $go_in_b2go\n"; }
		}
	}
	return \%genes_overlap;
}

sub save_eggnog_file {
	my $file = $_[0];
	my %info;
	my $count = 0;
	warn "save_eggnog_file: $file\n";
	open my $fh, '<', $file or die "Error: cannot open $file : $!";
	while(my $line=<$fh>) {
		chomp $line;
		next if($line =~ m/^#/);
		my @bits = split /\t/, $line;
		my ($query, $seed_ortholog, $evalue, $score, $eggNOG_OGs, $max_annot_lvl, $COG_category, $Description, $Preferred_name, $GOs, $EC, $KEGG_ko, $KEGG_Pathway, $KEGG_Module, $KEGG_Reaction, $KEGG_rclass, $BRITE, $KEGG_TC, $CAZy, $BiGG_Reaction, $PFAMs) = @bits;

		next if($GOs eq '-');
		my @GO_t = split /\,/, $GOs;
		foreach my $GO(@GO_t) {
			$count++;
			$info{$query}{$GO} = 1;
		}
	}
	my $num_genes_with_go_terms = scalar(keys(%info));
	warn "save_eggnog_file: $count GO terms found in total\n";
	warn "save_eggnog_file: $num_genes_with_go_terms genes with GO terms\n";
	return \%info;
}

sub save_d2go_file {
	my $file = $_[0];
	my %info;
	my $count = 0;
	warn "save_d2go_file: $file\n";
	open my $fh, '<', $file or die "Error: cannot open $file : $!";
	while(my $line=<$fh>) {
		chomp $line;
		next if($line =~ m/^#/);
		next if($line =~ m/^\n/);
		next if($line eq '');
		my @bits = split /\t/, $line;
		my ($gene_id, $gene_name, $species, $e_value, $GOterm, $evidence_code, $qualifier, $category) = @bits;
		$count++;
		$info{$gene_id}{$GOterm} = 1;
	}
	my $num_genes_with_go_terms = scalar(keys(%info));
	warn "save_d2go_file: $count GO terms found in total\n";
	warn "save_d2go_file: $num_genes_with_go_terms genes with GO terms\n";
	return \%info;
}

sub save_b2go_file {
	my $file = $_[0];
	my %info;
	my $count = 0;
	warn "save_b2go_file: $file\n";
	open my $fh, '<', $file or die "Error: cannot open $file : $!";
	while(my $line=<$fh>) {
		chomp $line;
		next if($line =~ m/^#/);
		# header
		next if($line =~ m/TRUE\tTags\tSeqName/);
		my @bits = split /\t/, $line;
		my ($TRUE, $Tags, $SeqName, $Description, $Length, $Hits, $eValue, $sim_mean, $num_GO, $GO_IDs, $GO_Names, $Enzyme_Codes, $Enzyme_Names, $InterPro_IDs, $InterPro_GO_IDs, $InterPro_GO_Names) = @bits;

		next if($GO_IDs eq '');
		$SeqName .= 'T0'; # make compatable with other tools

		# GO0006355; GO0006357; GO0000978;
		#warn "go string = $GO_IDs\n";
		my @GO_t = split /\; /, $GO_IDs;
		foreach my $GO(@GO_t) {
			$GO =~ s/GO/GO:/;
			#die "go = $GO\n";
			if(!defined $info{$SeqName}{$GO}) { $count++; }
			$info{$SeqName}{$GO} = 1;
		}
	}
	my $num_genes_with_go_terms = scalar(keys(%info));
	warn "save_b2go_file: $count GO terms found in total\n";
	warn "save_b2go_file: $num_genes_with_go_terms genes with GO terms\n";
	return \%info;
}