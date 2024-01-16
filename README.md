
![D2GO](https://github.com/rhysf/Diamond2GO/blob/main/resources/logo.png?raw=true)

## Introduction

Diamond2GO is a set of tools that can rapidly assign gene ontology and perform
enrichment for functional genomics. The key features are:

* Obtain GO-terms for >100,000 protein or nucleotide sequences in FASTA format in ~15 minutes on a desktop computer.
* Use a ready built database comprising the subset of the NCBI nrdatabase that have GO-terms pre-assigned to them.
* The scripts and pipeline to re-make the database or make a new reference database.
* A pipeline for GO-term enrichment using two-tailed Fisher’s exact test with Storey-Tibshirani multiple correction.

## Documentation

All documentation for Diamond2GO can be found at https://github.com/rhysf/Diamond2GO

## Support

For issues, questions, comments or geature requests, please check or post to the issues tab on github: https://github.com/rhysf/Diamond2GO/issues


## Prerequisites

* Git Large File Storage (LFS) (LFS is used to store the default database. Ensure this is pre-installed from https://git-lfs.com/)
* Perl
* BioPerl
* CPAN modules Getopt::Std and Scalar::Util
* Diamond (in $PATH)

## InterPro prerequisites

The following CPAN modules are required for InterPro (if used):

* LWP
* XML::Simple
* Time::HiRes
* List::AllUtils

## Getting started / examples

* Assign GO terms to protein fasta

``perl Diamond2go.pl -d nr_clean_d2go.dmnd -q query.fasta -t protein``

* Assign GO terms to gene fasta 

``perl Diamond2go.pl -d nr_clean_d2go.dmnd -q query.fasta -t dna``

* Adjust e-cutoff to more stringent

``perl Diamond2go.pl -d nr_clean_d2go.dmnd -q query.fasta -e 1e-20``

* Adjust sensitivity

``perl Diamond2go.pl -d nr_clean_d2go.dmnd -q query.fasta -n sensitive``

* Adjust to use InterPro

``perl Diamond2go.pl -d nr_clean_d2go.dmnd -q query.fasta -s 1234 -i h -z my.email@email.com``

## Description of default database and details of how to create a new database

D2GO comes with a default database that was prepared on <strong>14th May 2023</strong>strong>. If this is sufficiently dated, or a new database is required for any reason, these steps should be sufficient to recreate or update the default database

1. NCBI non-redundant database was downloaded on the 14th May 2023 using the command 

``wget --continue https://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz``

2. Non printable ASCII characters were removed using the command 

``tr -cd '\11\12\15\40-\176' < nr.faa > nr_clean.faa``

3. NCBI gene2accession and gene2go were downloaded on the 20th July 2023 from https://ftp.ncbi.nih.gov/gene/DATA/
4. Merge the GO and gene accessions using the command 

``perl ncbi_gene2go_merge.pl -a gene2go -b gene2accession > gene2go_and_accessions_merged.tab``

5. Add GO terms to the NCBI nr database using the command 

``perl blast_database_to_new_description.pl -d nr_clean.faa -a gene2go_and_accessions_merged.tab > nr_clean_d2go.faa``

6. Make diamond database using the command 

``diamond makedb --in nr_clean_d2go.faa -d nr_clean_d2go.faa.dmnd``

## Utility scripts

A brief description of the utility scripts, that can be used to create a new database, are dependencies of other tools or allow enrichment tests.

* blast_database_to_new_description.pl : Used in database construction. Note: nr.faa is a fasta file of the NCBI non-redundant database or other database. gene2go_and_accessions_merged.tab is a tab delimited file output from made from ncbi_gene2go_merge_gene2accession.pl

``perl /util/blast_database_to_new_description.pl -d nr.faa -a gene2go_and_accessions_merged.tab > new_nr.faa``

* iprscan5_RF.pl : Used for InterPro scan

``perl /util/iprscan5_RF.pl --asyncjob --email <your@email.com> [options...] <SeqFile|SeqID(s)>``

* iprscan_summary_and_d2go_processed_combine.pl : Used as part of the InterPro steps. iprscan_all_results.parsed is the output from iprscan_tsv_to_GO_summary.pl

``perl /util/iprscan_summary_and_d2go_processed_combine.pl iprscan_all_results.parsed output.processed > output.processed2``

* iprscan_tsv_to_GO_summary.pl : Used as part of the InterPro steps

``perl /util/iprscan_tsv_to_GO_summary.pl iprscan.tsv.tsv> > gene_to_go.tab``

* ncbi_gene2go_merge.pl : Used in database construction

``perl /util/ncbi_gene2go_merge.pl -a gene2go -b gene2accession > gene2info``

* test_enrichment.pl : Used to calculate functional enrichment. Note: q-value calculation can be slow on large datasets. d2go_out.processed in an outfile of d2go.pl and subset.list is a text file or id's of interest (i.e., a subset of the ids for the sequences in d2go_out.processed). Note: there are other parameters that may be useful when running this script.

``perl /util/test_enrichment.pl -a d2go_out.processed -b subset.list``