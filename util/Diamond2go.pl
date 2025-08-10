#!/usr/bin/env perl -w
use strict;
use FindBin qw($Bin);
use lib "$Bin/modules";
use read_FASTA;
use Getopt::Std;
use LWP::UserAgent;
use Data::Dumper;
use File::Basename;
my $script_name = basename($0);

### r.farrer@exeter.ac.uk

# usage
my $usage = "Usage: $script_name -q <query.fasta>\n

Main Options:
  -q\tInput query file in FASTA format [required]
  -d\tDIAMOND database file [$Bin/resources/nr_clean_d2go_20250728.faa.dmnd]
  -s\tSteps to run:
    \t1 = run DIAMOND
    \t2 = summarise GO terms
    \t3 = prepare InterProScan input
    \t4 = run InterProScan and combine results [default: 12]

Annotation Settings:
  -e\tE-value cutoff [1e-10]
  -n\tSensitivity (default, faster, fast, mid-sensitive, sensitive, more-sensitive, very-sensitive, ultra-sensitive) [fast]
  -t\tQuery type (protein/dna) [protein]
  -m\tMax target sequences per query [1]

InterProScan Integration:
  -i\tUse InterProScan (h = only sequences with no D2GO hit, a = all sequences) [h]
  -z\tValid email address required for InterProScan web service []

PERFORMANCE TUNING:
  -g\tDIAMOND block size in GB (--block-size) [default: 8]
  -k\tIndex chunk count (--index-chunks) [default: 8]
  -r\tThreads to use (--threads) [default: all available]
  -v\tSuppress DIAMOND log output (--verbose 0) [on]\n

Output Files:
  -a\tDIAMOND raw output file [query.fasta-diamond.tab]
  -b\tProcessed DIAMOND results [query.fasta-diamond.processed.tab]
  -c\tProcessed DIAMOND results with InterPro annotations [query.fasta-diamond.processed_with_interpro.tab]

Notes:
  1) DIAMOND must be installed and in your PATH
  2) Database must be created with 'diamond makedb' (e.g., diamond makedb --in <nr.faa> -d <db>)\n";

our($opt_a, $opt_b, $opt_c, $opt_d, $opt_e, $opt_g, $opt_i, $opt_k, $opt_m, $opt_n, $opt_q, $opt_r, $opt_s, $opt_t, $opt_v, $opt_z);
getopts('a:b:c:d:e:g:i:k:m:n:q:r:s:t:vz');
die $usage unless ($opt_q);
my $default_db = "$Bin/resources/nr_clean_d2go_20250728.faa.dmnd";
if(!defined $opt_a) { $opt_a = "$opt_q-diamond.tab"; }
if(!defined $opt_b) { $opt_b = "$opt_q-diamond.processed.tab"; }
if(!defined $opt_c) { $opt_c = "$opt_q-diamond.processed_with_interpro.tab"; }
if(!defined $opt_d) { $opt_d = $default_db; }
if(!defined $opt_i) { $opt_i = 'h'; }
if(!defined $opt_m) { $opt_m = 1; }
if(!defined $opt_n) { $opt_n = "fast"; }
if(!defined $opt_s) { $opt_s = '12'; }
if(!defined $opt_t) { $opt_t = 'protein'; }
if(!defined $opt_e) { $opt_e = '1e-10'; }
die "Error: Missing required query file (-q)\n$usage" unless $opt_q;
die "Error: Cannot open query file: '$opt_q' ($!)" unless -e $opt_q;
die "Error: -e not numeric or scientific notation: '$opt_e'\n" unless ($opt_e =~ /^(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?$/);
die "Error: -t must be 'protein' or 'dna', got '$opt_t'\n" unless $opt_t =~ /^(dna|protein)$/;
die "Error: -i must be 'h' or 'a', got '$opt_i'\n" unless $opt_i =~ /^[ha]$/;

# DIAMOND runtime tuning
my $block_flag  = defined $opt_g ? "--block-size $opt_g" : "--block-size 8";
my $chunk_flag  = defined $opt_k ? "--index-chunks $opt_k" : "--index-chunks 8";
my $thread_flag = defined $opt_r ? "--threads $opt_r" : "--threads 10";  # `nproc` or a system call could be used to detect actual CPUs
my $verbose_flag = $opt_v ? "--verbose" : "";

# program
my $program = 'blastp';
if($opt_t ne 'protein') { $program = 'blastx'; }

# sensitivity
my $sensitivity_flag = '';
my @valid_sensitivity_modes = qw(faster fast mid-sensitive sensitive more-sensitive very-sensitive ultra-sensitive);
if (grep { $_ eq $opt_n } @valid_sensitivity_modes) { $sensitivity_flag = "--$opt_n"; } 
else { warn "Warning: Unrecognized sensitivity level '$opt_n'. Proceeding without a sensitivity flag.\n"; }

# Only run database validation/downloading if using the default database
if ($opt_d eq $default_db) {
       &check_or_download_db($default_db);  # verifies and reassembles the split files
} else {
       warn "D2GO: Using custom database path: '$opt_d'. Skipping automatic integrity checks.\n";
}

# run diamond (this could be scatter gathered)
&usage_count();
if($opt_s =~ m/1/) {

       warn "D2GO step 1...\n";

       # Query Seq ID, Subject Seq ID, Subject Title/Desc, E-value
       my $diamond_cmd = "diamond $program -d $opt_d -q $opt_q -o $opt_a $sensitivity_flag --masking 0 --max-target-seqs $opt_m $block_flag $chunk_flag $thread_flag $verbose_flag -f 6 qseqid sseqid stitle evalue";
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

sub check_or_download_db {
       my $final_file = $_[0];
       warn "check_or_download_db: $final_file\n";

       my $final_md5_file = "$final_file.md5";
       my $parts_list_file = "$final_file.parts.txt";  # your manifest
       foreach($final_md5_file, $parts_list_file) {
              die "check_or_download_db: Error: missing $_. Reclone or obtain this file from the repo : $!" if(! -e $_);
       }
       my $base_url = "https://zenodo.org/record/16753349/files";

       # Step 1: Check full file and validate MD5
       if (-e $final_file && -e $final_md5_file) {
              my $md5_expected = `cut -d ' ' -f1 $final_md5_file`; chomp $md5_expected;
              warn "check_or_download_db: Final database file exists. Skipping validation.\n";
              warn "To manually validate: md5 -q \"$final_file\"  # expected: $md5_expected\n";
              return;
       } else {
              warn "check_or_download_db: Final database file or its .md5 is missing. Will build from parts.\n";
       }

       # Step 2: Read expected part filenames from manifest
       die "check_or_download_db: Missing parts manifest file: $parts_list_file\n" unless(-e $parts_list_file);
       open my $fh, '<', $parts_list_file or die "Cannot open $parts_list_file: $!";
       chomp(my @part_filenames = <$fh>);
       close $fh;

       # Step 3: Download and validate each part
       foreach my $part_filename (@part_filenames) {
              my $part_path = "$Bin/resources/$part_filename";
              my $md5_path = "$part_path.md5";
              
              unless (-e $part_path && -e $md5_path) {
                     warn "check_or_download_db: Downloading missing part or .md5: $part_filename...\n";
                     system("wget --continue '$base_url/$part_filename?download=1' -O $part_path");
                     system("wget --continue '$base_url/$part_filename.md5?download=1' -O $md5_path");
              }

              # Check MD5
              my $md5_actual = `md5 -q $part_path`; chomp $md5_actual;
              my $md5_expected = `cut -d ' ' -f1 $md5_path`; chomp $md5_expected;

              if ($md5_actual ne $md5_expected) {
                     warn "check_or_download_db: Part $part_filename failed MD5 check. Redownloading...\n";
                     system("wget --continue '$base_url/$part_filename?download=1' -O $part_path");
              } else {
                     warn "check_or_download_db: Part $part_filename passed MD5.\n";
              }
       }

       # Step 4: Concatenate parts into final file
       warn "check_or_download_db: Reconstructing full database file...\n";
       my @part_paths = map { "$Bin/resources/$_" } @part_filenames;
       my $cat_cmd = "cat " . join(' ', @part_paths) . " > $final_file";
       system($cat_cmd) == 0 or die "check_or_download_db: Failed to concatenate parts: $!";

       # Step 5: Final full MD5 check
       my $md5_final_actual = `md5 -q $final_file`; chomp $md5_final_actual;
       my $md5_final_expected = `cut -d ' ' -f1 $final_md5_file`; chomp $md5_final_expected;

       if($md5_final_actual ne $md5_final_expected) {
              die "check_or_download_db: Error. Final database file failed MD5 check after reassembly. Aborting.\n" ;
       }
       warn "check_or_download_db: Reconstructed database file is valid.\n";
       return;
}

sub usage_count {
	my $url  = "https://rhysfarrer.com/code_track/log.php";
	if (command_exists("curl")) {
		system("curl -s \"$url\" > /dev/null");
	} elsif (command_exists("wget")) {
		system("wget -q \"$url\" -O /dev/null");
	} else { }
}

sub process_cmd {
       my ($cmd) = @_;
       warn "CMD: $cmd\n";
       my $ret = system($cmd);
       die "Error, cmd $cmd died with return $ret\n" if($ret);
       return 1;
}

# Function to check if a command exists
sub command_exists {
    my ($cmd) = @_;
    return system("command -v $cmd > /dev/null 2>&1") == 0;
}