#!/usr/bin/perl -w
use strict;
#use FindBin qw($Bin);
#use lib "$Bin/perl_modules";
#use MutationTools::read_FASTA;

### r.farrer@exeter.ac.uk

# usage
my $usage = "perl $0 <iprscan.tsv.tsv> > gene_to_go.tab\n";
die $usage unless (@ARGV eq 1);
my ($iprscan_file) = @ARGV;

# Save sequences
#my $fasta = fastafile::fasta_to_struct($pep_file);

# save
my $gene_to_go = &save_gene_to_go($iprscan_file);

# print
foreach my $gene(sort keys %{$gene_to_go}) {
	foreach my $go(sort keys %{$$gene_to_go{$gene}{'go'}}) {
		my $name = $$gene_to_go{$gene}{'name'};
		print "$gene\t$name\t$go\n";
	}
}

sub save_gene_to_go {
	my $file = $_[0];
	warn "save_gene_to_go  : $file\n";
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
		next if(!defined $bits[13]);
		my ($gene, $name, $go) = ($bits[0], $bits[5], $bits[13]);
		next if($gene =~ m/Reactome/);
		next if($go !~ m/^GO:/);

		my @go_split = split /\|/, $go;
		foreach my $go_ind(@go_split) {
			$gene_to_GO_terms{$gene}{'go'}{$go_ind} = 1;
			$gene_to_GO_terms{$gene}{'name'} = $name;
		}

		$go_count++;
	}
	my $genes_count = scalar(keys(%gene_to_GO_terms));
	warn "save_gene_to_go : $genes_count total genes with $go_count total go terms\n";
	return \%gene_to_GO_terms;
} 