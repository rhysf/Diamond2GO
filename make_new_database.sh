#!/bin/bash

# r.farrer@exeter.ac.uk

CMD1="wget --continue https://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz -O ./resources/nr.gz"
CMD2="gunzip ./resources/nr.gz"
CMD3="tr -cd '\11\12\15\40-\176' < ./resources/nr.faa > ./resources/nr_clean.faa"
CMD4="perl util/ncbi_gene2go_merge.pl -a gene2go -b gene2accession > gene2go_and_accessions_merged.tab"
CMD5="perl util/blast_database_to_new_description.pl -d nr_clean.faa -a gene2go_and_accessions_merged.tab > nr_clean_d2go.faa"
CMD6="diamond makedb --in nr_clean_d2go.faa -d nr_clean_d2go.faa.dmnd"

echo "CMD1: $CMD1"
eval $CMD1

echo "CMD2: $CMD2"
eval $CMD2

echo "CMD3: $CMD3"
eval $CMD3

echo "CMD4: $CMD4"
eval $CMD4

echo "CMD5: $CMD5"
eval $CMD5

echo "CMD6: $CMD6"
eval $CMD6
