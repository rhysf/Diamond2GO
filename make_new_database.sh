#!/bin/bash

# r.farrer@exeter.ac.uk
# Automated script to generate a new DIAMOND2GO database with date-stamped output

set -e  # exit on error

DATE=$(date +%Y%m%d)
RESOURCES_DIR="./resources"
DB_BASENAME="nr_clean_d2go_${DATE}"

mkdir -p "$RESOURCES_DIR"

echo "[1/6] Downloading NCBI nr.gz..."
wget --continue https://ftp.ncbi.nlm.nih.gov/blast/db/FASTA/nr.gz -O "${RESOURCES_DIR}/nr.gz"

echo "[2/6] Decompressing..."
gunzip -f "${RESOURCES_DIR}/nr.gz"

echo "[3/6] Cleaning ASCII..."
tr -cd '\11\12\15\40-\176' < "${RESOURCES_DIR}/nr" > "${RESOURCES_DIR}/nr_clean.faa"

echo "[4/6] Merging NCBI gene2go and gene2accession..."
perl util/ncbi_gene2go_merge.pl -a gene2go -b gene2accession > "${RESOURCES_DIR}/gene2go_and_accessions_merged.tab"

echo "[5/6] Annotating nr with GO terms..."
perl util/blast_database_to_new_description.pl \
  -d "${RESOURCES_DIR}/nr_clean.faa" \
  -a "${RESOURCES_DIR}/gene2go_and_accessions_merged.tab" \
  > "${RESOURCES_DIR}/${DB_BASENAME}.faa"

echo "[6/6] Building DIAMOND database..."
diamond makedb --in "${RESOURCES_DIR}/${DB_BASENAME}.faa" -d "${RESOURCES_DIR}/${DB_BASENAME}.faa.dmnd"

echo "Database build complete: ${RESOURCES_DIR}/${DB_BASENAME}.faa.dmnd"