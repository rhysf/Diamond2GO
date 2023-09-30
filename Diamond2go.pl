#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use Getopt::Std;
use LWP::UserAgent;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);

### r.farrer@exeter.ac.uk

# usage
my $usage = "perl $0 -q <query.fasta>\n
Optional: -d\tDatabase [$Bin/resources/nr_clean_d2go.dmnd]
          -s\tSteps (1=Diamond, 2=summarise GO terms) [12]
          -e\tE-value cutoff [1e-10]
          -n\tSensitivity (default, mid-sensitive, sensitive, more-sensitive, very-sensitive, ultra-sensitive)
          -t\tQuery Type (protein/dna) [protein]
          -m\tMax target sequences [1]\n
Notes: 1) Diamond needs to be in PATH
       2) Database needs to be made with diamond (E.g. diamond makedb --in <nr.faa> -d nr)\n";
our($opt_d, $opt_e, $opt_m, $opt_n, $opt_q, $opt_s, $opt_t);
getopt('demnqst');
die $usage unless ($opt_q);
if(!defined $opt_d) { $opt_d = "$Bin/resources/nr_clean_d2go.dmnd"; }
if(!defined $opt_m) { $opt_m = 1; }
if(!defined $opt_n) { $opt_n = "default"; }
if(!defined $opt_s) { $opt_s = '12'; }
if(!defined $opt_t) { $opt_t = 'protein'; }
if(!defined $opt_e) { $opt_e = '1e-10'; }
die "Cannot open $opt_q : $!" unless (-e $opt_q);
die "Cannot open $opt_d : $!" unless (-e $opt_d);
die "Error: -e not numeric : $opt_e\n" if(! looks_like_number($opt_e));
die "Error -t not protein or dna: $opt_t\n" if($opt_t !~ m/(dna)|(protein)/);

# program
my $program = 'blastp';
if($opt_t ne 'protein') { $program = 'blastx'; }

# sensitivity
my $sensitivity_flag ='';
if(($opt_n eq 'mid-sensitive') || ($opt_n eq 'sensitive') || ($opt_n eq 'more-sensitive') || ($opt_n eq 'very-sensitive') || ($opt_n eq 'ultra-sensitive')) {
       $sensitivity_flag = "--$opt_n";
}

# run diamond (this could be scatter gathered)
my $out_diamond = "$opt_q-diamond.out";
if($opt_s =~ m/1/) {

       #my $blast_cmd = "blastp -query $opt_q -db nr -remote -out $out_blast";
       #my $diamond_cmd = "diamond blastp -d $opt_d -q $opt_q -o $out_diamond -f 6";

       # Query Seq ID, Subject Seq ID, Subject Title/Desc, E-value 
       my $diamond_cmd = "diamond $program -d $opt_d -q $opt_q -o $out_diamond $sensitivity_flag --max-target-seqs $opt_m -f 6 qseqid sseqid stitle evalue";
       warn "cmd: $diamond_cmd\n";
       my $run_blast = `$diamond_cmd`;
}

if($opt_s =~ m/2/) {

       # save all diamond hits
       my $out_diamond_processed = "$opt_q-diamond.out.processed";
       my $gene_to_go_to_evalue_to_info = &save_all_diamond_hits_from_file($out_diamond, $opt_e);

       # print best e-value score go-terms
       &print_non_redundant_and_best_scoring_go_terms($gene_to_go_to_evalue_to_info, $out_diamond_processed);
}

sub print_non_redundant_and_best_scoring_go_terms {
       my ($data, $outfile) = @_;

       # outfile
       open my $ofh, '>', $outfile or die "Cannot open $outfile : $!";
       print $ofh "#gene_id\tgene_name\tspecies\te-value\tGO-term\tevidence_code\tqualifier\tcategory\n";

       foreach my $gene(sort keys %{$data}) {
              GOTERMS: foreach my $GO_term(keys %{$$data{$gene}}) {
                     foreach my $evalue(sort { $a <=> $b } keys %{$$data{$gene}{$GO_term}}) {
                            my $info = $$data{$gene}{$GO_term}{$evalue};

                            print $ofh "$info\n";

                            # only interested in the lowest scoring evalue per GO-term
                            next GOTERMS;
                     }
              }
              print $ofh "\n";
       }
       close $ofh;

       return 1;
}

sub save_all_diamond_hits_from_file {
       my ($file, $evalue_cutoff) = @_;
       warn "$0: save_diamond_hits_from_file: $file\n";

       
       my %hits;

       open my $fh, '<', $file or die "Cannot open $file : $!";
       while(my $line=<$fh>) {
              chomp $line;
              my @bits = split /\t/, $line;
              # Query Seq ID, Subject Seq ID, Subject Title/Desc, E-value
              my ($gene_id, $subject_ID, $desc, $evalue) = @bits;

              # e-value cutoff
              next if($evalue > $evalue_cutoff);

              # save
              # desc e.g. 
              # XP_016864433.1 E3 ubiquitin-protein ligase MARCHF6 isoform X8 [Homo sapiens] [[GO:0000835 (IC part_of C),
              #GO:0004842 (IDA enables F),GO:0004842 (IMP enables F),GO:0005515 (IPI enables F),GO:0005783 (IDA located_in C),GO:0005789 
              #(IDA located_in C),GO:0005789 (TAS located_in C),GO:0008270 (IEA enables F),GO:0010498 (IDA involved_in P),GO:0016020 (HDA located_in C),GO:0016020 (IDA located_in C),GO:0016567 (IDA involved_in P),
              # GO:0019899 (IPI enables F),GO:0030433 (IBA involved_in P),GO:0031624 (IPI enables F),GO:0036503 (TAS involved_in P),GO:0043161 (IDA involved_in P),GO:0044322 (IEA located_in C),GO:0061630 (IDA enables F),
              # GO:0061630 (TAS enables F),GO:0070936 (IDA involved_in P),GO:1904380 (TAS involved_in P),GO:1990381 (IPI enables F),]]
              my @desc_parts = split /\[\[|\]\]/, $desc;
              #my $gene_name_and_species = $desc_parts[0];
              my $go_terms_string = $desc_parts[scalar(@desc_parts) - 1]; # end bit

              # everything before the GO terms
              my $gene_name_and_species;
              for(my $i=0; $i < (scalar(@desc_parts) - 1); $i++) {
                     $gene_name_and_species .= "$desc_parts[$i] ";
              }

              $go_terms_string =~ s/\,$//;

              my @gene_name_and_species_parts = split /\[|\]/, $gene_name_and_species;

              # sometime matches multiple entries, and may have gene names with [] - and in this case, even [[ or ]], e.g., 
              # NP_571700.1 [Pyruvate dehydrogenase [acetyl-transferring]]-phosphatase 2, mitochondrial [Danio rerio]AAI09400.1 Putative pyruvate dehydrogenase phosphatase isoenzyme 2 [Danio rerio] 
              my $gene_name = $gene_name_and_species_parts[0];
              my $species = $gene_name_and_species_parts[1];

              # individual go terms
              my @go_terms = split /\,/, $go_terms_string;
              GOTERMS: foreach my $go_term_and_info(@go_terms) {
                     my @term_and_info = split /\(|\)/, $go_term_and_info;
                     my $go_term = $term_and_info[0];
                     $go_term =~ s/ $//;


                     # go term info
                     if(!defined $term_and_info[1]) {
                            warn "so far ive got:\ngene name = $gene_name\nspecies = $species\n";
                            die "what is up with this: $line\n$go_term_and_info\n";
                     }
                     my $info = $term_and_info[1];
                     my @info_parts = split / /, $info;
                     my $evidence_code = $info_parts[0];

                     # not interested in these kinds of entries: (IDA NOT located_in C)
                     next GOTERMS if($info_parts[1] eq 'NOT');

                     my $qualifier = $info_parts[1];
                     my $category = $info_parts[2];

                     # save (gene_to_go_to_evalue_to_info)
                     my $all_info = "$gene_id\t$gene_name\t$species\t$evalue\t$go_term\t$evidence_code\t$qualifier\t$category";
                     $hits{$gene_id}{$go_term}{$evalue} = $all_info;
              }
       }
       close $fh;

       return (\%hits);
}
