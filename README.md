![D2GO](https://github.com/rhysf/Diamond2GO/blob/main/resources/logo.png?raw=true)

# Diamond2GO

## Introduction

Diamond2GO is a set of tools that can rapidly assign Gene Ontology (GO) terms and perform functional enrichment for large-scale functional genomics datasets. It combines the speed of DIAMOND with curated annotation databases and optional InterProScan enrichment.

As of August 2025, the tool no longer relies on git-lfs to download large database files. Instead, pre-split validated files are now hosted on Zenodo and assembled locally on first use. In addition, performance options and default behaviour have been streamlined and documented to support broad usability.

Zenodo record: https://zenodo.org/records/16753349

## key features

- **High-throughput GO-term annotation**: Originally capable of annotating >100,000 protein or nucleotide sequences in FASTA format in ~15 minutes on a desktop machine (using the original smaller database).
- **Automated database setup from Zenodo**: Automatically downloads, verifies, and reconstructs the latest pre-built reference database from Zenodo, removing the need for Git LFS.
- **Custom database generation**: Includes a pipelines to re-create or build new GO-annotated reference databases.
- **Enrichment analysis**: Implements GO-term enrichment using a two-tailed Fisher’s exact test with Storey-Tibshirani multiple testing correction.

## Documentation

All documentation for Diamond2GO can be found at https://github.com/rhysf/Diamond2GO

## Support

For issues, questions, comments or feature requests, please check or post to the issues tab on github: https://github.com/rhysf/Diamond2GO/issues

---

## Running with Docker (Recommended)

Before using Docker, ensure that the required DIAMOND database has been downloaded and assembled. This happens automatically the first time you run: Diamond2go

```bash
docker buildx build --platform linux/amd64 -t diamond2go .

docker run --rm -v $(pwd):/data -w /data diamond2go -d ./resources/nr_clean_d2go_20250728.faa.dmnd -q ./data/query.fasta -t protein

docker-compose run --rm diamond2go -d ./resources/nr_clean_d2go_20250728.faa.dmnd -q ./data/query.fasta -t protein

```

## Prerequisites (if not using Docker)

If running locally outside of Docker, the following must be pre-installed:

* Perl and BioPerl
* CPAN modules `Getopt::Std`, `File::Basename`, and others listed below for Interpro (optional)
* Diamond aligner (available in your system `$PATH`)

## InterPro (optional)

If using InterPro mode:

    CPAN modules: List::AllUtils, LWP, LWP::Protocol::https, Mozilla::CA, Time::HiRes, XML::Simple


## Installation and usage

```bash
git clone https://github.com/YOUR_ORG/Diamond2GO.git
cd Diamond2GO
./diamond2go -q ./data/query.pep
```

## Optional parameters

DIAMOND Options

    -d   : DIAMOND database path [resources/nr_clean_d2go_20250728.faa.dmnd]
    -n   : Sensitivity mode (fast, mid-sensitive, sensitive, more-sensitive, very-sensitive, ultra-sensitive) [sensitive]
    -e   : E-value cutoff [1e-10]
    -t   : Query type (protein or dna) [protein]
    -m   : Max target sequences per query [1]
    -g   : Block size in GB (maps to --block-size) [8]
    -k   : Index chunk count (maps to --index-chunks) [8]
    -r   : Number of threads [default: all available]
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

Diamond2GO now uses a modular download-and-verify workflow for its default database (resources/nr_clean_d2go_20250812_c95.faa.dmnd). When using the default database, the script will:

* Check for the presence of the assembled database and its .md5 checksum file.
* If missing, download part files from Zenodo.
* Validate each part using MD5 checksum.
* Concatenate parts into the final .dmnd database file.
* Optionally validate final MD5 (disabled by default for performance).
* After downloading and extracting the NCBI nr dataset, redundancy is removed using MMseqs2 Linclust by default (or CD-HIT if MMseqs2 is unavailable).
* The default clustering threshold is 95% sequence identity with 80% coverage, which reduces file size while retaining biological diversity.
* The final database is then built with diamond makedb for high-speed protein sequence alignment.

Zenodo Record:

* https://zenodo.org/records/16818512

Additional notes:

* If you require a new or custom database, see `util/make_new_database.sh` for the full, automated workflow.
* Creating a new database can take multiple days due to the size of nr and the computational demands of clustering.
* Downloads and processing can be safely resumed by re-running the script. Completed steps will be skipped unless forced with --force.
* The previous database version from 28th July 2025 (pre-clustering, ~95% redundancy retained) is archived for reproducibility.

## Performance & Speed

As of 8 August 2025:

- **Example dataset** (`/data/query.pep`): Runtime **3 minutes and 42 seconds**.
- **Full-scale test** (130,184 predicted human protein isoforms):
  - Runtime: **6 hours 53 minutes** 
  - Annotated sequences: **129,509** (>99.4% coverage)
  - GO terms assigned: **1.75 Million**
* Default: --fast mode with --max-target-seqs 1
* For faster runs, try -n faster, and optomise for -g (DIAMOND block size in GB), -k (Index chunk count) and -r (Threads to use)

## Utility scripts

* blast_database_to_new_description.pl — add GO terms to FASTA headers

* iprscan5_RF.pl — run InterProScan jobs

* iprscan_tsv_to_GO_summary.pl — parse InterProScan TSV

* iprscan_summary_and_d2go_processed_combine.pl — combine InterPro and GO annotations

* ncbi_gene2go_merge.pl — merge NCBI gene2go and gene2accession

* test_enrichment.pl — perform GO enrichment tests

* make_new_database.sh — make new D2GO database (dependencies: diamond, and mmseq2 or cd-hit)

## Disclosure

This tool may log anonymized usage data (timestamp, IP address, user-agent) for the purpose of improving the software, and future funding.

## Updates

**12th August 2025**: New Database & Upload Script

- Updated make_new_database.sh to download and process the latest nr files from NCBI.
- New database version includes redundancy reduction using MMseqs2, substantially lowering sequence count while retaining coverage.
- Previous (2025-07-28): 34,093,871 sequences · 22.9 B letters
- New (2025-08-10): 27,500,577 sequences · 19.9 B letters

**10th August 2025**: Repo clean up.

- Repo tidy up and entry point wrapper.

**8th August 2025**: Pipeline enhancements and performance improvements

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
