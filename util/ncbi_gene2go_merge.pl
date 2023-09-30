#!/usr/bin/perl -w
use strict;
use Getopt::Std;

### r.farrer@exeter.ac.uk

# usage
my $usage = "perl $0 -a <gene2go> -b <gene2accession> > gene2info\n";
our($opt_a, $opt_b);
getopt('ab');
die $usage unless ($opt_a && $opt_b);
foreach my $file($opt_a, $opt_b) { die "Cannot open $file : $!" unless (-e $file); }

# save gene2go to memory
my $taxID_and_gene_to_lines = &save_gene2go($opt_a);

my $taxID_and_gene_to_lines2 = &find_overlap_between_gene2go_and_gene2accession($opt_b, $taxID_and_gene_to_lines);

# print summary
print "TaxID\tGeneID1\tGeneIDs_alt\tGO_terms\n";
foreach my $taxID_and_gene(sort keys %{$taxID_and_gene_to_lines2}) {
       my $gene2go_lines = $$taxID_and_gene_to_lines{$taxID_and_gene};
       my $gene2accession_lines = $$taxID_and_gene_to_lines2{$taxID_and_gene};

       my @gene2go = split /\n/, $gene2go_lines;
       my @gene2accession = split /\n/, $gene2accession_lines;

       my $GO_terms;
       foreach(@gene2go) {
              $GO_terms .= "$_,";
       }
       $GO_terms =~ s/\,$//;

       my $gene_accessions;
       foreach(@gene2accession) {
              $gene_accessions .= "$_,";
       }
       $gene_accessions =~ s/\,$//;

       print "$taxID_and_gene\t$gene_accessions\t$GO_terms\n";
}

sub find_overlap_between_gene2go_and_gene2accession {
       my ($file, $gene2go_hash) = @_;

       warn "find_overlap_between_gene2go_and_gene2accession: $file\n";

       my %info;
       my $count = 0;
       my $count_overlap = 0;

       # read file
       open my $fh, '<', $file or die "Cannot open $file : $!";
       while(my $line=<$fh>) {
              chomp $line;

              # ignore header 
              next if($line =~ m/^\#/);

              my @bits = split /\t/, $line;
              my ($tax_id, $GeneID, $status, $RNA_nucleotide_accession_version, $RNA_nucleotide_gi, $protein_accession_version, $protein_gi, $genomic_nucleotide_accession_version, $genomic_nucleotide_gi, $start_position_on_the_genomic_accession, $end_position_on_the_genomic_accession, $orientation, $assembly, $mature_peptide_accession_version, $mature_peptide_gi, $Symbol) = @bits;
              $count++;
              if($count % 1000000 == 0) {
                     warn "find_overlap_between_gene2go_and_gene2accession: processed $count lines ($count_overlap overlaps found)\n";
              }

              # next if nothing saved for in gene2go
              my $entry = "$tax_id\t$GeneID";
              next if(!defined $$gene2go_hash{$entry});
              my $gene2go_info_lines = $$gene2go_hash{$entry};
              $count_overlap++;

              # gene2accession info (don't know which of these id's might be in the nr database?)
              my $ids_found = '';
              foreach my $accession_ids($RNA_nucleotide_accession_version, $RNA_nucleotide_gi, $protein_accession_version, $protein_gi, $genomic_nucleotide_accession_version, $genomic_nucleotide_gi) {
                     if($accession_ids ne '-') { $ids_found .= "$accession_ids,"; }
              }

              # save
              #warn "$entry\n";
              $info{$entry} .= "$ids_found\n";
       }
       close $fh;
       warn "find_overlap_between_gene2go_and_gene2accession: went through $count entries\n";
       warn "find_overlap_between_gene2go_and_gene2accession: found $count_overlap overlapping entries\n";

       return (\%info);

}

sub save_gene2go {
       my $file = $_[0];

       warn "save_gene2go: $file\n";

       my %info;
       my $count = 0;

       # read file
       open my $fh, '<', $file or die "Cannot open $file : $!";
       while(my $line=<$fh>) {
              chomp $line;

              # ignore header 
              next if($line =~ m/^\#/);

              my @bits = split /\t/, $line;
              my ($tax_id, $GeneID, $GO_ID, $Evidence, $Qualifier, $GO_term, $PubMed, $Category) = @bits;
              $count++;

              my $entry = "$tax_id\t$GeneID";

              # Category
              if($Category eq 'Component') { $Category = 'C'; }
              if($Category eq 'Process') { $Category = 'P'; }
              if($Category eq 'Function') { $Category = 'F'; }

              my $info = "$GO_ID ($Evidence $Qualifier $Category)";

              # save
              $info{$entry} .= "$info\n";
       }
       close $fh;
       warn "save_gene2go: saved $count entries\n";

       return (\%info);
}