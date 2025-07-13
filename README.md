![D2GO](https://github.com/rhysf/Diamond2GO/blob/main/resources/logo.png?raw=true)

# Diamond2GO

## Introduction

Diamond2GO is a set of tools that can rapidly assign gene ontology and perform enrichment for functional genomics. The key features are:

- Obtain GO-terms for >100,000 protein or nucleotide sequences in FASTA format in ~15 minutes on a desktop computer.
- Use a ready-built database comprising the subset of the NCBI nr database that have GO-terms pre-assigned to them.
- The scripts and pipeline to re-make the database or make a new reference database.
- A pipeline for GO-term enrichment using two-tailed Fisher’s exact test with Storey-Tibshirani multiple correction.

## Documentation

All documentation for Diamond2GO can be found at https://github.com/rhysf/Diamond2GO

## Support

For issues, questions, comments or feature requests, please check or post to the issues tab on github: https://github.com/rhysf/Diamond2GO/issues

---

## Running with Docker (Recommended)

To simplify setup and ensure compatibility, we provide a Docker environment.

### Build the image

```bash
docker buildx build --platform linux/amd64 -t diamond2go .

docker run --rm -v $(pwd):/data -w /data diamond2go -d ./resources/nr_clean_d2go.dmnd -q ./data/query.fasta -t protein

docker-compose run --rm diamond2go -d ./resources/nr_clean_d2go.dmnd -q ./data/query.fasta -t protein

```

## Prerequisites (if not using Docker)

If running locally outside of Docker, the following must be pre-installed:

* Git Large File Storage (LFS) – [https://git-lfs.com](https://git-lfs.com)
* Perl and BioPerl
* CPAN modules: `Getopt::Std`, `Scalar::Util`, and others listed below
* Diamond aligner (available in your system `$PATH`)

## InterPro (optional)

If using InterPro mode:

    CPAN modules: List::AllUtils, LWP, LWP::Protocol::https, Mozilla::CA, Time::HiRes, XML::Simple


## Getting started / examples

* Assign GO terms to protein fasta

``docker run --rm -v $(pwd):/data -w /data diamond2go -d ./resources/nr_clean_d2go.dmnd -q ./data/query.fasta -t protein``

or:

``perl Diamond2go.pl -d nr_clean_d2go.dmnd -q query.fasta -t protein``

* Assign GO terms to gene fasta 

``perl Diamond2go.pl -d nr_clean_d2go.dmnd -q query.fasta -t dna``

* Adjust e-cutoff to more stringent

``perl Diamond2go.pl -d nr_clean_d2go.dmnd -q query.fasta -e 1e-20``

* Adjust sensitivity

``perl Diamond2go.pl -d nr_clean_d2go.dmnd -q query.fasta -n sensitive``

* Adjust to use InterPro

``perl Diamond2go.pl -d nr_clean_d2go.dmnd -q query.fasta -s 1234 -i h -z my.email@email.com``

## Default Database Description

D2GO comes with a default database that was prepared on <strong>14th May 2023</strong>strong>. If this is sufficiently dated, or a new database is required for any reason, these steps should be sufficient to recreate or update the default database. There is also a new wrapper script that attempts to run all commands: make_new_database.sh. To recreate the default reference database:

``
wget --continue https://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz
tr -cd '\11\12\15\40-\176' < nr.faa > nr_clean.faa
perl ncbi_gene2go_merge.pl -a gene2go -b gene2accession > gene2go_and_accessions_merged.tab
perl blast_database_to_new_description.pl -d nr_clean.faa -a gene2go_and_accessions_merged.tab > nr_clean_d2go.faa
diamond makedb --in nr_clean_d2go.faa -d nr_clean_d2go.faa.dmnd
``

## Utility scripts


* blast_database_to_new_description.pl — add GO terms to FASTA headers

* iprscan5_RF.pl — run InterProScan jobs

* iprscan_tsv_to_GO_summary.pl — parse InterProScan TSV

* iprscan_summary_and_d2go_processed_combine.pl — combine InterPro and GO annotations

* ncbi_gene2go_merge.pl — merge NCBI gene2go and gene2accession

* test_enrichment.pl — perform GO enrichment tests

## Updates

* 8th July 2025. Uploaed a new wrapper script that attempts to run all commands to make a new d2go database file from scratch: make_new_database.sh
