#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);
use lib "$Bin/modules";
use read_FASTA;
use Getopt::Std;
use LWP::UserAgent;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);

### r.farrer@exeter.ac.uk

# usage
my $usage = "perl $0 -q <query.fasta>\n
Optional: -d\tDatabase [$Bin/resources/nr_clean_d2go.dmnd]
          -s\tSteps (1=Diamond, 2=summarise GO terms, 3=prepare query for interproscan, 4=run interproscan and combine results) [12]
          -e\tE-value cutoff [1e-10]
          -n\tSensitivity (default, mid-sensitive, sensitive, more-sensitive, very-sensitive, ultra-sensitive)
          -t\tQuery Type (protein/dna) [protein]
          -m\tMax target sequences [1]
          -i\tUse interproscan (h=all genes with no d2go hits, a=all) [h]
          -z\tValid email address required for interproscan []\n
Outfile:  -a\tDiamond outfile [query.fasta-diamond.tab]
          -b\tDiamond outfile parsed [query.fasta-diamond.processed.tab]
          -c\tDiamond outfile parsed with interpro [query.fasta-diamond.processed_with_interpro.tab]
Notes: 1) Diamond needs to be in PATH
       2) Database needs to be made with diamond (E.g. diamond makedb --in <nr.faa> -d nr)\n";
our($opt_a, $opt_b, $opt_c, $opt_d, $opt_e, $opt_i, $opt_m, $opt_n, $opt_q, $opt_s, $opt_t, $opt_z);
getopt('abdeimnqstz');
die $usage unless ($opt_q);
if(!defined $opt_a) { $opt_a = "$opt_q-diamond.tab"; }
if(!defined $opt_b) { $opt_b = "$opt_q-diamond.processed.tab"; }
if(!defined $opt_c) { $opt_c = "$opt_q-diamond.processed_with_interpro.tab"; }
if(!defined $opt_d) { $opt_d = "$Bin/resources/nr_clean_d2go.dmnd"; }
if(!defined $opt_i) { $opt_i = 'h'; }
if(!defined $opt_m) { $opt_m = 1; }
if(!defined $opt_n) { $opt_n = "default"; }
if(!defined $opt_s) { $opt_s = '12'; }
if(!defined $opt_t) { $opt_t = 'protein'; }
if(!defined $opt_e) { $opt_e = '1e-10'; }
die "Cannot open $opt_q : $!" unless (-e $opt_q);
die "Cannot open $opt_d : $!" unless (-e $opt_d);
die "Error: -e not numeric : $opt_e\n" if(! looks_like_number($opt_e));
die "Error -t not protein or dna: $opt_t\n" if($opt_t !~ m/(dna)|(protein)/);
die "Error: -a not h or a: $opt_i\n" if($opt_i !~ m/h|n/);

# program
my $program = 'blastp';
if($opt_t ne 'protein') { $program = 'blastx'; }

# sensitivity
my $sensitivity_flag ='';
if(($opt_n eq 'mid-sensitive') || ($opt_n eq 'sensitive') || ($opt_n eq 'more-sensitive') || ($opt_n eq 'very-sensitive') || ($opt_n eq 'ultra-sensitive')) {
       $sensitivity_flag = "--$opt_n";
}

# run diamond (this could be scatter gathered)
if($opt_s =~ m/1/) {

       warn "D2GO step 1...\n";

       #my $blast_cmd = "blastp -query $opt_q -db nr -remote -out $out_blast";
       #my $diamond_cmd = "diamond blastp -d $opt_d -q $opt_q -o $opt_a -f 6";

       # Query Seq ID, Subject Seq ID, Subject Title/Desc, E-value 
       my $diamond_cmd = "diamond $program -d $opt_d -q $opt_q -o $opt_a $sensitivity_flag --max-target-seqs $opt_m -f 6 qseqid sseqid stitle evalue";
       warn "cmd: $diamond_cmd\n";
       my $run_blast = `$diamond_cmd`;
}

# summarise GO terms
if($opt_s =~ m/2/) {

       warn "D2GO step 2...\n";

       # save all diamond hits
       my $gene_to_go_to_evalue_to_info = &save_all_diamond_hits_from_file($opt_a, $opt_e);

       # print best e-value score go-terms
       &print_non_redundant_and_best_scoring_go_terms($gene_to_go_to_evalue_to_info, $opt_b);
}

# prepare query for interproscan
if($opt_s =~ m/3/) {

       warn "D2GO step 3...\n";

       # Save sequences
       my $fasta = fastafile::fasta_to_struct($opt_q);

       # -i\tUse interproscan (h=all genes with no d2go hits, a=all)
       # h=all genes with no d2go hits
       if($opt_i eq 'h') {
              my $d2go = &save_d2go($opt_b);
              my $gene_ids_with_no_hits = &save_d2go_genes_with_no_hits($d2go, $fasta);
              $fasta = fastafile::remove_genes($fasta, $gene_ids_with_no_hits);
       }

       # Remove Stop codons
       $fasta = fastafile::remove_stop_codons($fasta);

       # print - split
       fastafile::fasta_struct_print($fasta, 'fasta', $opt_t, 500);
}

# run interproscan
if($opt_s =~ m/4/) {

       warn "D2GO step 4...\n";

       # Necessary script
       my $interpro_scan = "$Bin/util/iprscan5_RF.pl";
       my $interpro_scan_parse = "$Bin/util/iprscan_tsv_to_GO_summary.pl";
       my $interpro_scan_parse_combine = "$Bin/util/iprscan_summary_and_d2go_processed_combine.pl";
       foreach my $script($interpro_scan, $interpro_scan_parse, $interpro_scan_parse_combine) {
              die "Error: Necessary interproscan script not found: $script\n" if(! -e $script);
       }

       # Necessary email
       die "Error: no valid email gives as option -z\n" if(!defined $opt_z);

       # Stype
       my $stype = 'p';
       if($opt_t ne 'protein') { $stype = 'n'; }

       # find all split gene categories
       my @files = <$opt_q-split-into-500-entries-per-file-pt-*.fasta>;
       die "Error: no split fasta files from input found\n" if(scalar(@files) < 1);
       #warn "files of interest = @files\n";

       # Run interproscan
       foreach my $file(@files) {

              # only run if output not already found, otherwise warn
              if(-e "$file-output.tsv.tsv") {
                     warn "Outfile $file-output.tsv.tsv is already found. Delete if you want it re-run\n";
              } else {
                     # inteproscan
                     my $CMD="perl $interpro_scan --sequence $file --stype $stype --email $opt_z --outfile $file-output --outformat tsv > $file.interpro.out 2> $file.interpro.stderr";
                     &process_cmd($CMD);

                     # parse
                     my $CMD2="perl $interpro_scan_parse $file-output.tsv.tsv > $file-output.tsv.tsv.parsed";
                     &process_cmd($CMD2);
              }
       }

       # concatenate and join
       my $iprscan_results = "$opt_q.all_iprscan_results.parsed";
       die "Error: $iprscan_results already found. Delete if you want this re-generated\n" if(-e $iprscan_results);
       my $CMD3 = "cat $opt_q-split-into-500-entries-per-file-pt-*.fasta-output.tsv.tsv.parsed >> $iprscan_results";
       &process_cmd($CMD3);
       my $CMD4="perl $interpro_scan_parse_combine $iprscan_results $opt_b > $opt_c";
       &process_cmd($CMD4);

       warn "Finished\n";
}

sub save_d2go_genes_with_no_hits {
       my ($d2go, $fasta) = @_;

       my $total_genes = 0;
       my $genes_with_go_terms = 0;
       my $nothing_found_in_diamond2go = 0;
       my %genes_no_hits;

       # for everything
       foreach my $gene(sort keys %{$$fasta{'seq'}}) {
              $total_genes++;

              # found in both
              if(defined $$d2go{$gene}) {
                     $genes_with_go_terms++;
              }
              else {
                     $nothing_found_in_diamond2go++;
                     $genes_no_hits{$gene} = 1;
              }
       }

       warn "save_d2go_genes_with_no_hits: Genes: $total_genes\n";
       warn "save_d2go_genes_with_no_hits: Genes with GO terms: $genes_with_go_terms\n";
       warn "save_d2go_genes_with_no_hits: Genes with no GO terms: $nothing_found_in_diamond2go\n";
       return \%genes_no_hits;
}

#.processed
#gene_id      gene_name     species       e-value       GO-term       evidence_code qualifier     category
sub save_d2go {
       my $file = $_[0];
       warn "save_d2go  : $file\n";
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
              die "unrecognised line: $line" if(!defined $bits[7]);
              my ($gene_id, $gene_name, $species, $evalue, $go_term, $evidence_code, $qualifier, $category) = @bits;

              # ignore most parental and uninformative terms
              next if($go_term eq 'GO:0008150' or $go_term eq 'GO:0005575' or $go_term eq 'GO:0003674');

              # save
              if(defined $gene_to_GO_terms{$gene_id}{$go_term}) { warn "redundant go term on $gene_id: $go_term\n"; }
              $gene_to_GO_terms{$gene_id}{$go_term} = 1;
              $go_count++;
       }
       my $genes_count = scalar(keys(%gene_to_GO_terms));
       warn "save_d2go : $genes_count total genes with $go_count total go terms\n";
       return \%gene_to_GO_terms;
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

sub process_cmd {
       my ($cmd) = @_;
       warn "CMD: $cmd\n";
       my $ret = system($cmd);
       die "Error, cmd $cmd died with return $ret\n" if($ret);
       return 1;
}