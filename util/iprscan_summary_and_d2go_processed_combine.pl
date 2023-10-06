#!/usr/bin/perl -w
use strict;
#use FindBin qw($Bin);
#use lib "$Bin/perl_modules";
#use MutationTools::read_FASTA;

### r.farrer@exeter.ac.uk

# usage
my $usage = "perl $0 <iprscan_all_results.parsed (output from cat of iprscan_tsv_to_GO_summary.pl> <.processed> > .processed2\n";
die $usage unless (@ARGV eq 2);
my ($iprscan_parsed, $d2go_processed) = @ARGV;

# save
my $interpro_gene_to_go = &save_interpro_gene_to_go_summary($iprscan_parsed);
my ($d2go, $d2go_lines) = &save_d2go($d2go_processed);

# print
print "#gene_id\tgene_name\tspecies\te-value\tGO-term\tevidence_code\tqualifier\tcategory\n";

# d2go hits
GENE: foreach my $gene(sort keys %{$d2go}) {

	# print d2go entries
	print "$$d2go_lines{$gene}";

	# Go through all d2go entries for this gene
	next if(!defined $$interpro_gene_to_go{$gene});

	# Only add go-terms not already assigned
	foreach my $interpro_go_term(sort keys %{$$interpro_gene_to_go{$gene}{'go'}}) {
		next if(defined $$d2go{$gene}{$interpro_go_term});

		my $name = $$interpro_gene_to_go{$gene}{'name'};
		print "$gene\t$name\tInterpro-NA\tInterpro-NA\t$interpro_go_term\tInterpro-NA\tInterpro-NA\tInterpro-NA\n";
		#warn "Adding $interpro_go_term\n";
	}
	print "\n";
}

# interpro hits that have no d2go genes
foreach my $gene(sort keys %{$interpro_gene_to_go}) {
	next if(defined $$d2go{$gene});

	# $gene_to_GO_terms{$gene}{'go'}{$go_ind} = 1;
	# $gene_to_GO_terms{$gene}{'name'} = $name;

	foreach my $go(sort keys %{$$interpro_gene_to_go{$gene}{'go'}}) {
		my $name = $$interpro_gene_to_go{$gene}{'name'};
		print "$gene\t$name\tInterpro-NA\tInterpro-NA\t$go\tInterpro-NA\tInterpro-NA\tInterpro-NA\n";
	}
	print "\n";
}

#gene_id	gene_name	species	e-value	GO-term	evidence_code	qualifier	category
sub save_d2go {
	my $file = $_[0];
	warn "save_d2go  : $file\n";
	my %gene_to_GO_terms;

	my %gene_details;

	my $go_count = 0;
	open my $fh, '<', $file or die "Error: Cannot open $file : $!";
	while(my $line=<$fh>) {
		chomp $line;
		# ignore headers and blank lines
		next if($line =~ m/^\#/);
		next if($line =~ m/^\n/);
		next if($line eq "\n");
		next if($line eq '');

		# save
		my @bits = split /\t/, $line;
		die "unrecognised line: $line" if(!defined $bits[7]);
		my ($gene_id, $gene_name, $species, $evalue, $go_term, $evidence_code, $qualifier, $category) = @bits;

		# ignore most parental and uninformative terms
		next if($go_term eq 'GO:0008150' or $go_term eq 'GO:0005575' or $go_term eq 'GO:0003674');

		# to match with b2go, remove colon and transcript id
		#$go_term =~ s/\://;
		#$gene_id =~ s/T0$//;

		# save
		if(defined $gene_to_GO_terms{$gene_id}{$go_term}) { warn "redundant go term on $gene_id: $go_term\n"; }
		$gene_to_GO_terms{$gene_id}{$go_term} = 1;
		$go_count++;

		# extra:
		$gene_details{$gene_id} .= "$line\n";
	}
	my $genes_count = scalar(keys(%gene_to_GO_terms));
	#foreach my $gene(keys %gene_to_GO_terms) {
	#	print "$gene\n";
	#}
	warn "save_d2go : $genes_count total genes with $go_count total go terms\n";
	return (\%gene_to_GO_terms, \%gene_details);
} 

sub save_interpro_gene_to_go_summary {
	my $file = $_[0];
	warn "save_interpro_gene_to_go_summary : $file\n";
	my %gene_to_GO_terms;
	my $go_count = 0;
	open my $fh, '<', $file or die "Error: Cannot open $file : $!";
	while(my $line=<$fh>) {
		chomp $line;
		# ignore headers and blank lines
		next if($line =~ m/^\#/);
		next if($line =~ m/^\n/);
		next if($line eq "\n");
		next if($line eq '');

		# save

		my @bits = split /\t/, $line;
		my ($gene, $name, $go) = @bits;

		# ignore most parental and uninformative terms
		next if($go eq 'GO:0008150' or $go eq 'GO:0005575' or $go eq 'GO:0003674');
		
		$gene_to_GO_terms{$gene}{'go'}{$go} = 1;
		$gene_to_GO_terms{$gene}{'name'} = $name;

		$go_count++;
	}
	my $genes_count = scalar(keys(%gene_to_GO_terms));
	warn "save_interpro_gene_to_go_summary : $genes_count total genes with $go_count total go terms\n";
	return \%gene_to_GO_terms;
} 