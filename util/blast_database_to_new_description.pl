#!/usr/bin/perl -w
use strict;
use Getopt::Std;
use FindBin qw($Bin);
use lib "$Bin/../modules";
use read_Tab;
use Bio::SeqIO;

### r.farrer@exeter.ac.uk

# usage
my $usage = "perl $0 -d <nr.faa> -a <gene2go_and_accessions_merged.tab made from ncbi_gene2go_merge_gene2accession.pl> > new_nr.faa\n";
our($opt_a, $opt_d);
getopt('ad');
die $usage unless ($opt_d && $opt_a);
foreach my $file($opt_a, $opt_d) { die "Cannot open $file : $!" unless (-e $file); }

# save go terms info
#TaxID  GeneID1       GeneIDs_alt   GO_terms
#my $GO_info = tabfile::save_columns_to_column_hash($opt_a, 1, 2, 3);
my $GO_info = &save_all_ids_from_GO_info($opt_a);

# Go through nr.faa and look for genes - if found - then make a new description and print
my $run = &find_genes_in_fasta($opt_d, $GO_info);

sub find_genes_in_fasta {
       my ($fasta, $GO_info) = @_;

       my $checked = 0;
       my $found = 0;

       warn "find_genes_in_fasta: saving from $fasta...\n";
       my $inseq = Bio::SeqIO->new('-file' => "<$fasta",'-format' => 'fasta');
       while (my $seq_obj = $inseq->next_seq) { 
              my $id = $seq_obj->id;
              
              # lookup
              if(defined $$GO_info{$id}) {
                     #warn "FOUND OVERLAP $id\n";
                     $found++;

                     my $desc = $seq_obj->description;
                     my $seq = $seq_obj->seq;
                     my $GO_terms = $$GO_info{$id};

                     print ">$id $desc [[$GO_terms]]\n$seq\n";
              }
              
              $checked++;

              if($checked % 1000000 == 0) {
                     warn "checked $checked genes (found $found)\n";
              }
       }
       warn "finished ($found / $checked found)\n";
}

sub save_all_ids_from_GO_info {
        my $file = $_[0];
        warn "save_all_ids_from_GO_info: $file\n";
        my %saved_ids;
        open my $fh, '<', $file or die "Error: Cannot open $file : $!";
        while(my $line=<$fh>) {
              chomp $line;
              next if($line =~ m/^TaxID\t/);

              my @bits = split /\t/, $line;
              my ($taxid, $id1, $ids2, $go_terms) = @bits;
              # id1 is numeric - and i don't think a valid nr.faa id

              my @id2_parts = split /[\,]+/, $ids2;
              foreach my $id2s(@id2_parts) {
                     $saved_ids{$id2s} = $go_terms;
              }
        }
        return \%saved_ids;
}

      