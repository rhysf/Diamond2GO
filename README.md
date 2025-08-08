![D2GO](https://github.com/rhysf/Diamond2GO/blob/main/resources/logo.png?raw=true)

# Diamond2GO

## Introduction

Diamond2GO is a set of tools that can rapidly assign Gene Ontology (GO) terms and perform functional enrichment for large-scale functional genomics datasets. It combines the speed of DIAMOND with curated annotation databases and optional InterProScan enrichment.

As of August 2025, the tool no longer relies on git-lfs to download large database files. Instead, pre-split validated files are now hosted on Zenodo and assembled locally on first use. In addition, performance options and default behaviour have been streamlined and documented to support broad usability.

Zenodo record: https://zenodo.org/records/16753349

## key features

- **High-throughput GO-term annotation**: Originally capable of annotating >100,000 protein or nucleotide sequences in FASTA format in ~15 minutes on a desktop machine (using the original smaller database).
- **Built-in reference database**: Includes a pre-built database comprising the subset of the NCBI `nr` database with GO-terms pre-assigned.
- **Custom database generation**: Scripts and pipelines to re-create or build new GO-annotated reference databases.
- **Enrichment analysis**: Implements GO-term enrichment using a two-tailed Fisher’s exact test with Storey-Tibshirani multiple testing correction.


## Documentation

All documentation for Diamond2GO can be found at https://github.com/rhysf/Diamond2GO

## Support

For issues, questions, comments or feature requests, please check or post to the issues tab on github: https://github.com/rhysf/Diamond2GO/issues

---

## Running with Docker (Recommended)

```bash
docker buildx build --platform linux/amd64 -t diamond2go .

docker run --rm -v $(pwd):/data -w /data diamond2go -d ./resources/nr_clean_d2go_20250728.faa.dmnd -q ./data/query.fasta -t protein

docker-compose run --rm diamond2go -d ./resources/nr_clean_d2go_20250728.faa.dmnd -q ./data/query.fasta -t protein

```

## Prerequisites (if not using Docker)

If running locally outside of Docker, the following must be pre-installed:

* Perl and BioPerl
* CPAN module `Getopt::Std`, and others listed below
* Diamond aligner (available in your system `$PATH`)

## InterPro (optional)

If using InterPro mode:

    CPAN modules: List::AllUtils, LWP, LWP::Protocol::https, Mozilla::CA, Time::HiRes, XML::Simple


## Installation and usage

```bash
git clone https://github.com/YOUR_ORG/Diamond2GO.git
cd Diamond2GO
perl Diamond2go.pl -q query.pep
```

## Optional parameters

DIAMOND Options

    -d   : DIAMOND database path [resources/nr_clean_d2go_20250728.faa.dmnd]
    -n   : Sensitivity mode (fast, mid-sensitive, sensitive, more-sensitive, very-sensitive, ultra-sensitive) [sensitive]
    -e   : E-value cutoff [1e-10]
    -t   : Query type (protein or dna) [protein]
    -m   : Max target sequences per query [1]
    -g   : Block size in GB (maps to --block-size) [Optional]
    -k   : Index chunk count (maps to --index-chunks) [Optional]
    -r   : Number of threads [Optional]
    -v   : Suppress DIAMOND logs (--verbose 0) [Off by default]

InterProScan Integration

    -i   : Run InterProScan on genes with no D2GO hits (h) or all genes (a) [h]
    -z   : Valid email address (required by InterProScan)

Pipeline Control

    -s   : Steps to run (1 = DIAMOND, 2 = GO term summarisation, 3 = InterProScan prep, 4 = InterProScan run and merge) [12]

Output Control

    -a   : DIAMOND raw output file [<query>.diamond.tab]
    -b   : Processed DIAMOND output [<query>.diamond.processed.tab]
    -c   : Final output with InterProScan [<query>.diamond.processed_with_interpro.tab]

## Default Database Description

Diamond2GO now uses a modular download-and-verify system. If using the default database (resources/nr_clean_d2go_20250728.faa.dmnd), the script will:

* Check for the presence of the assembled database and its .md5 file.
* If missing, download part files from Zenodo.
* Validate each part using MD5 checksums.
* Concatenate into the final database.
* Optionally validate final MD5 (disabled by default for performance).

Zenodo Record:
https://zenodo.org/records/16753349

* If a newer or custom database is required, the script `make_new_database.sh` contains all the steps needed to re-create or update the default database. Note that this process may take **several days** to complete due to the size of the NCBI `nr` dataset.
* Interrupted downloads during the setup can be safely resumed by re-running the script.
* For users who wish to reproduce the results from the original publication, the previous database version from **14th May 2023** is still available as part of the [v1.0.0 release]

## Performance & Speed

As of 8 August 2025:

* Runtime: < 7 minutes on the example query peptide in /data
* Default: --sensitive mode with --max-target-seqs 1
* For faster runs, use -n faster, and optomise for -g (DIAMOND block size in GB), -k (Index chunk count) and -r (Threads to use)

## Utility scripts

* blast_database_to_new_description.pl — add GO terms to FASTA headers

* iprscan5_RF.pl — run InterProScan jobs

* iprscan_tsv_to_GO_summary.pl — parse InterProScan TSV

* iprscan_summary_and_d2go_processed_combine.pl — combine InterPro and GO annotations

* ncbi_gene2go_merge.pl — merge NCBI gene2go and gene2accession

* test_enrichment.pl — perform GO enrichment tests

* make_new_database.sh — make new D2GO database

## Disclosure

This tool may log anonymized usage data (timestamp, IP address, user-agent) for the purpose of improving the software, and future funding.

## Updates

**8th August 2025**. Pipeline enhancements and performance improvements

- Removed dependency on Git LFS for large database downloads.
- Introduced automated logic to download `.dmnd_part_*` files from [Zenodo](https://zenodo.org/records/16753349), validate them using `.md5`, and reconstruct the full database file.
- Added runtime tuning options: `--block-size`, `--index-chunks`, `--threads`.
- Better handling of DIAMOND sensitivity modes (e.g. `fast`).
- Cleaned up usage instructions and removed bundled database from repo in favour of published releases.

**5th August 2025**: Database upgrade to improve annotation quality 

- **Previous** (v1.0.0, 2023-07-20): 699,409 sequences, 419M letters 
- **New** (2025-07-28): 34,093,871 sequences, 22.9B letters  
- Greatly increases functional coverage and sensitivity, particularly for novel proteins.  
- Users replicating the original manuscript should continue using the [v1.0.0 release].

**13th July 2025**: Docker support added

- Enables easier deployment and reproducibility of the pipeline.

**8th July 2025**: New helper script `make_new_database.sh`

- Automates construction of a Diamond2GO-compatible database from scratch.

## Citation

If you use this tool, please cite:

* Golden C, Studholme DJ, Farrer RA. DIAMOND2GO: Rapid Gene Ontology assignment and enrichment detection for functional genomics. Front. Bioinform. 5 (2025) doi: 10.3389/fbinf.2025.1634042
* https://www.frontiersin.org/journals/bioinformatics/articles/10.3389/fbinf.2025.1634042/abstract
