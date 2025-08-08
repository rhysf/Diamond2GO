#!/bin/bash

# r.farrer@exeter.ac.uk
# Automated script to generate a new DIAMOND2GO database with date-stamped output

set -e  # exit on error

DATE=$(date +%Y%m%d)
RESOURCES_DIR="./resources"
DB_BASENAME="nr_clean_d2go_${DATE}"

mkdir -p "$RESOURCES_DIR"

echo "[1/8] Downloading NCBI nr.gz..."
rsync -av --progress rsync://ftp.ncbi.nlm.nih.gov/blast/db/nr* .

#echo "[2/8] Decompressing nr.gz..."
#gunzip -f "${RESOURCES_DIR}/nr.gz"

#echo "[3/8] Cleaning ASCII characters in nr..."
#tr -cd '\11\12\15\40-\176' < "${RESOURCES_DIR}/nr" > "${RESOURCES_DIR}/nr_clean.faa"

#echo "[4/8] Downloading gene2go.gz..."
#wget --continue https://ftp.ncbi.nih.gov/gene/DATA/gene2go.gz -O "${RESOURCES_DIR}/gene2go_${DATE}.gz"

#echo "[5/8] Downloading gene2accession.gz..."
#wget --continue https://ftp.ncbi.nih.gov/gene/DATA/gene2accession.gz -O "${RESOURCES_DIR}/gene2accession_${DATE}.gz"

#echo "[6/8] Decompressing gene2go and gene2accession..."
#gunzip -f "${RESOURCES_DIR}/gene2go_${DATE}.gz"
#gunzip -f "${RESOURCES_DIR}/gene2accession_${DATE}.gz"

#echo "[7/8] Merging gene2go and gene2accession..."
#perl util/ncbi_gene2go_merge.pl \
#  -a "${RESOURCES_DIR}/gene2go_${DATE}" \
#  -b "${RESOURCES_DIR}/gene2accession_${DATE}" \
#  > "${RESOURCES_DIR}/gene2go_and_accessions_merged_${DATE}.tab"

#echo "[8/8] Annotating nr and building DIAMOND database..."
#perl util/blast_database_to_new_description.pl \
#  -d "${RESOURCES_DIR}/nr_clean.faa" \
#  -a "${RESOURCES_DIR}/gene2go_and_accessions_merged_${DATE}.tab" \
#  > "${RESOURCES_DIR}/${DB_BASENAME}.faa"

#diamond makedb --in "${RESOURCES_DIR}/${DB_BASENAME}.faa" -d "${RESOURCES_DIR}/${DB_BASENAME}.faa.dmnd"

#echo "Database build complete: ${RESOURCES_DIR}/${DB_BASENAME}.faa.dmnd"
