#!/usr/bin/env bash
set -euo pipefail

# r.farrer@exeter.ac.uk
# Automated script to generate a new DIAMOND2GO database with date-stamped output

# === Defaults ===
: "${RESOURCES_DIR:=../resources}" # Default to ../resources unless RESOURCES_DIR is set in environment
: "${STEPS_TO_RUN:="all"}"  # could be "all" or a comma-separated list e.g., "1,2,5"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -g, --go              Run the pipeline (required, else script exits)
  -r, --resources DIR   Path to resources directory (default: $RESOURCES_DIR)
  -s, --steps STEPS     Steps to run: "all" or comma-separated list (default: $STEPS_TO_RUN)
  -t, --tag TAG         Stable run tag to use for all outputs (e.g. 20250812)
      --new-tag         Force a fresh tag even if one is recorded
  -f, --force           Force re-run even if step outputs exist
  -h, --help            Show this help message

Examples:
  Run all steps with defaults:
    $(basename "$0") -g

  Run only steps 1, 3, and 5:
    $(basename "$0") -g -s 1,3,5

EOF
}

# Parse arguments
FORCE=0
GO_FLAG=0
USER_TAG=""
NEW_TAG=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--go)       GO_FLAG=1; shift;;
    -r|--resources) RESOURCES_DIR="$2"; shift 2;;
    -s|--steps)     STEPS_TO_RUN="$2"; shift 2;;
    -t|--tag)       USER_TAG="$2"; shift 2;;
    --new-tag)      NEW_TAG=1; shift;;
    -f|--force)     FORCE=1; shift;;
    -h|--help)      usage; exit 0;;
    *) echo "Unknown option: $1"; usage; exit 1;;
  esac
done

if [[ $GO_FLAG -ne 1 ]]; then
  echo "ERROR: You must pass -g or --go to actually run the script."
  usage
  exit 1
fi

should_run_step() {
  local step="$1"
  [[ "$STEPS_TO_RUN" == "all" ]] || [[ ",$STEPS_TO_RUN," == *",$step,"* ]]
}

# Default variables
DATE=$(date +%Y%m%d)
FORCE="${FORCE:-0}"            # FORCE=1 to redo all steps (or use FORCE_STEPS)
FORCE_STEPS="${FORCE_STEPS:-}" # comma-separated list, e.g. "2,6,9"
VERBOSE="${VERBOSE:-1}"

# Stamp dir (generic, not yet tag-scoped)
STAMP_DIR="${STAMP_DIR:-${RESOURCES_DIR}/.stamps}"
mkdir -p "$STAMP_DIR"

# Determine RUN_TAG
RUN_TAG_FILE="${STAMP_DIR}/run_tag"
if [[ -n "$USER_TAG" ]]; then
  RUN_TAG="$USER_TAG"
elif [[ -s "$RUN_TAG_FILE" && $NEW_TAG -eq 0 ]]; then
  RUN_TAG="$(cat "$RUN_TAG_FILE")"
else
  # New default tag (UTC): YYYYMMDD (you can use YYYYMMDDThhmmssZ if you prefer)
  RUN_TAG="$(date -u +%Y%m%d)"
fi

# Persist tag for resumes
echo "$RUN_TAG" > "$RUN_TAG_FILE"

# Now configure tag-scoped stamps and basenames
STAMP_DIR_TAGGED="${STAMP_DIR}/${RUN_TAG}"
mkdir -p "$STAMP_DIR_TAGGED"
DB_BASENAME="nr_clean_d2go_${RUN_TAG}"

# Dependencies
need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: Missing $1"; exit 1; }; }
need blastdbcmd
need diamond
# mmseqs and cd-hit are optional due to fallback logic; you can warn instead:
command -v mmseqs >/dev/null 2>&1 || echo "Note: mmseqs not found; Step 10 will try CD-HIT."

# helper: is step forced?
is_forced() {
  [ "$FORCE" = "1" ] && return 0
  IFS=',' read -r -a _fs <<<"$FORCE_STEPS"
  for s in "${_fs[@]:-}"; do
    [ "$s" = "$1" ] && return 0
  done
  return 1
}

# run_step <step_no> "<title>" "<outputs...>" -- <command...>
run_step() {
  local step="$1"; shift
  local title="$1"; shift
  local stamp="$1"; shift
  [ "$1" = "--" ] && shift || { echo "BUG: run_step missing --"; exit 1; }

  local fn="$1"; shift
  # Any remaining "$@" after this are extra args to send to the function.

  # Skip if stamp exists, unless globally forced or this step is forced
  if [ -s "$stamp" ] && [ "${FORCE:-0}" != "1" ] && ! is_forced "$step"; then
    echo "[$step] $title ... already done."
    return 0
  fi

  echo "[$step] $title ..."
  mkdir -p "$(dirname "$stamp")"

  # Call the function with stamp and RESOURCES_DIR first (only once)
  if "$fn" "$stamp" "$RESOURCES_DIR" "$@"; then
    date -u +"%Y-%m-%dT%H:%M:%SZ" > "$stamp"
    echo "[$step] OK."
  else
    echo "[$step] FAILED."
    return 1
  fi
}

# run_step_auto <step_no> "<title>" -- <function> [args...]
run_step_auto() {
  local step="$1"; shift
  local title="$1"; shift
  [ "$1" = "--" ] && shift || { echo "BUG: run_step_auto missing --"; exit 1; }
  local stamp="${STAMP_DIR_TAGGED}/step_${step}.done"
  run_step "$step" "$title" "$stamp" -- "$@"
}

step1_download_NCBI_nr() {
  local stamp="$1"; shift
  local resources_dir="$1"; shift

  echo "[1/11] step1_download_NCBI_nr()"
  mkdir -p "$resources_dir"
  rsync -av --progress \
    --include='nr.*.tar.gz' --exclude='*' \
    rsync://ftp.ncbi.nlm.nih.gov/blast/db/ "$resources_dir"/
}

step2_decompress_nr() {
  local stamp="$1"; shift
  local resources_dir="$1"; shift

  # Tunables (can override via environment)
  local MIN_FREE_GIB="${MIN_FREE_GIB:-50}"        # guardrail: must keep at least this much free
  local SAFETY_BUFFER_GIB="${SAFETY_BUFFER_GIB:-10}"
  local EXPANSION_FACTOR="${EXPANSION_FACTOR:-2}" # rough guess: uncompressed ≈ 2x compressed

  # hr() helper local to this function
  hr() { command -v numfmt >/dev/null 2>&1 && numfmt --to=iec "$1" || awk -v b="$1" 'BEGIN{printf "%.1f MiB", b/1048576}'; }

  echo "[2/11] Decompressing NR archives sequentially in: ${resources_dir}"

  # Sanity
  if [ ! -d "$resources_dir" ]; then
    echo "ERROR: RESOURCES_DIR does not exist: $resources_dir" >&2
    return 1
  fi

  shopt -s nullglob

  # Pick a version-aware sort if available
  local SORT=sort
  if command -v gsort >/dev/null 2>&1; then
    SORT=gsort
  fi

  # Natural sort so nr.010 follows nr.009
  mapfile -t parts < <(printf '%s\n' "$resources_dir"/nr.*.tar.gz | "$SORT" -V)
  if [ ${#parts[@]} -eq 0 ]; then
    echo "No nr.*.tar.gz archives found in $resources_dir"
    return 0
  fi

  # Coarse pre-check: sum(compressed) * EXPANSION_FACTOR + SAFETY_BUFFER
  local COMPRESSED_BYTES=0
  for f in "${parts[@]}"; do
    # stat -f%z (BSD/macOS), fall back to stat -c%s (GNU)
    local sz
    sz=$(stat -f%z "$f" 2>/dev/null || stat -c%s "$f")
    COMPRESSED_BYTES=$((COMPRESSED_BYTES + sz))
  done
  local SAFETY_BUFFER_BYTES=$((SAFETY_BUFFER_GIB * 1024 * 1024 * 1024))
  local EST_REQUIRED_BYTES=$((COMPRESSED_BYTES * EXPANSION_FACTOR + SAFETY_BUFFER_BYTES))
  local AVAIL_K AVAIL_BYTES
  AVAIL_K=$(df -Pk "$resources_dir" | awk 'NR==2 {print $4}')
  AVAIL_BYTES=$((AVAIL_K * 1024))

  echo "Compressed total:     $(hr $COMPRESSED_BYTES)"
  echo "Expansion factor:     ${EXPANSION_FACTOR}x"
  echo "Safety buffer:        ${SAFETY_BUFFER_GIB} GiB ($(hr $SAFETY_BUFFER_BYTES))"
  echo "Estimated required:   $(hr $EST_REQUIRED_BYTES)"
  echo "Available now:        $(hr $AVAIL_BYTES)"

  if [ "$AVAIL_BYTES" -lt "$EST_REQUIRED_BYTES" ]; then
    echo "WARNING: Available space is below conservative estimate."
    echo "         You may still proceed (sequential extraction frees space as we go),"
    echo "         but consider moving RESOURCES_DIR to a larger volume."
  fi

  # Per-part guardrail
  local MIN_FREE_BYTES=$((MIN_FREE_GIB * 1024 * 1024 * 1024))
  echo "Per-part guardrail: require at least ${MIN_FREE_GIB} GiB free before each extract."

  # Extract sequentially; delete tarball after success to reclaim space
  for f in "${parts[@]}"; do
    AVAIL_K=$(df -Pk "$resources_dir" | awk 'NR==2 {print $4}')
    AVAIL_BYTES=$((AVAIL_K * 1024))
    if [ "$AVAIL_BYTES" -lt "$MIN_FREE_BYTES" ]; then
      echo "ERROR: Free space below ${MIN_FREE_GIB} GiB before extracting:"
      echo "       $(hr $AVAIL_BYTES) available. Aborting to avoid ENOSPC."
      return 1
    fi

    echo "Extracting: $f  (free: $(hr $AVAIL_BYTES))"
    if tar -xzf "$f" -C "$resources_dir"; then
      rm -f "$f"
    else
      echo "ERROR: Extraction failed for $f" >&2
      return 1
    fi
  done

  echo "[2/11] Extraction complete."
}

step3_blastdbcmd_NCBI_nr() {
  local stamp="$1"; shift
  local resources_dir="$1"; shift

  echo "[3/11] step3_blastdbcmd_NCBI_nr()"

  # Single‑accession header: >ACCESSION TITLE
  # looks better, but reduce size without: -line_length 80 \
  # more info [taxid=], but can reduce size by omitting: -outfmt $'>%a %t [taxid=%T]\n%s' \
  ulimit -n 4096
  blastdbcmd -db "${resources_dir}/nr" -dbtype prot \
    -outfmt $'>%a %t\n%s' \
    -entry all \
    -out "${resources_dir}"/nr.faa
}

step4_cleanup_blast_db_files() {
  local stamp="$1"; shift
  local resources_dir="$1"; shift

    echo "[4/11] step4_cleanup_blast_db_files()"

    # Safety check
    if [ ! -d "$resources_dir" ]; then
        echo "ERROR: RESOURCES_DIR does not exist: $resources_dir" >&2
        return 1
    fi

    # Remove BLAST DB core and volume files
    rm -f "$resources_dir"/nr.p*
    rm -f "$resources_dir"/nr.*.p*

    # Remove taxonomy files
    rm -f "$resources_dir"/taxdb.*
    rm -f "$resources_dir"/taxonomy4blast.sqlite3

    echo "[4/11] Cleanup complete. Remaining files in $resources_dir:"
    ls -lh "$resources_dir"
}

step5_ascii_clean() {
  local stamp="$1"; shift
  local resources_dir="$1"; shift
  LC_ALL=C tr -cd '\11\12\15\40-\176' \
    < "${resources_dir}/nr.faa" \
    > "${resources_dir}/nr_clean.faa"
}

step6_download_gene2go() {
  local stamp="$1"; shift
  local resources_dir="$1"; shift
  local TAG="$1"; shift
  wget --continue "https://ftp.ncbi.nih.gov/gene/DATA/gene2go.gz" \
    -O "${resources_dir}/gene2go_${TAG}.gz"
  gunzip -f "${resources_dir}/gene2go_${TAG}.gz"
}

step7_download_gene2accession() {
  local stamp="$1"; shift
  local resources_dir="$1"; shift
  local TAG="$1"; shift
  wget --continue "https://ftp.ncbi.nih.gov/gene/DATA/gene2accession.gz" \
    -O "${resources_dir}/gene2accession_${TAG}.gz"
  gunzip -f "${resources_dir}/gene2accession_${TAG}.gz"
}

step8_merge_gene_tables() {
  local stamp="$1"; shift
  local resources_dir="$1"; shift
  local TAG="$1"; shift
  perl util/ncbi_gene2go_merge.pl \
    -a "${resources_dir}/gene2go_${TAG}" \
    -b "${resources_dir}/gene2accession_${TAG}" \
    > "${resources_dir}/gene2go_and_accessions_merged_${TAG}.tab"
}

step9_annotate_and_subset_nr() {
  local stamp="$1"; shift
  local resources_dir="$1"; shift
  local DB_BASENAME="$1"; shift
  local TAG="$1"; shift
  perl util/blast_database_to_new_description.pl \
    -d "${resources_dir}/nr_clean.faa" \
    -a "${resources_dir}/gene2go_and_accessions_merged_${TAG}.tab" \
    > "${resources_dir}/${DB_BASENAME}.faa"
}

# Step 10: clustering (prefer MMseqs2 Linclust, fallback to CD-HIT)
# Controls (local defaults; override via env if needed):
#   CLUSTER_IDENTITY (0.90|0.95|0.99), CLUSTER_COVERAGE (0.8), CLUSTER_THREADS, CLUSTER_TMP
step10_cluster_reps() {
  local stamp="$1"; shift
  local resources_dir="$1"; shift
  local DB_BASENAME="$1"; shift

  local IDENTITY="${CLUSTER_IDENTITY:-0.95}"
  local COVERAGE="${CLUSTER_COVERAGE:-0.80}"
  local THREADS="${CLUSTER_THREADS:-$(command -v nproc >/dev/null 2>&1 && nproc || sysctl -n hw.ncpu 2>/dev/null || echo 8)}"
  local TMPDIR_MM="${CLUSTER_TMP:-${resources_dir}/mmseqs_tmp}"

  local in_faa="${resources_dir}/${DB_BASENAME}.faa"
  if [ ! -s "$in_faa" ]; then
    echo "ERROR: Step 10 cannot find input FASTA: $in_faa" >&2
    return 1
  fi

  # derive cXX suffix from IDENTITY (e.g., 0.95 -> 95)
  local id_pct; id_pct=$(awk -v x="$IDENTITY" 'BEGIN{printf "%.0f", x*100}')
  local out_faa="${resources_dir}/${DB_BASENAME}_c${id_pct}.faa"
  local symlink_out="${resources_dir}/nr_clean_clustered.faa"  # generic symlink

  mkdir -p "$TMPDIR_MM"

  if command -v mmseqs >/dev/null 2>&1; then
    echo "[10/11] Using MMseqs2 Linclust (min-seq-id=${IDENTITY}, cov=${COVERAGE}, threads=${THREADS})"

    # MMseqs outputs:
    #   ${prefix}_rep_seq.fasta  (representatives)
    #   ${prefix}_cluster.tsv    (mapping)
    local prefix="${resources_dir}/nr_lc${id_pct}"
    local reps="${prefix}_rep_seq.fasta"

    # Only run if reps missing
    if [ ! -s "$reps" ]; then
      mmseqs easy-linclust "$in_faa" "$prefix" "$TMPDIR_MM" \
        --min-seq-id "$IDENTITY" \
        -c "$COVERAGE" --cov-mode 1 \
        --threads "$THREADS"
    else
      echo "[10/11] Skipping Linclust (exists): $(basename "$reps")"
    fi

    cp -f "$reps" "$out_faa"
    ln -sf "$(basename "$out_faa")" "$symlink_out"

    echo "[10/11] Clustered FASTA: $(basename "$out_faa")  (symlink: $(basename "$symlink_out"))"
    return 0
  fi

  # ---- Fallback: CD-HIT two-pass ----
  echo "[10/11] mmseqs not found; falling back to CD-HIT (this is slower)."

  local CDHIT_BIN="${CDHIT_BIN:-cd-hit}"
  local c100="${resources_dir}/${DB_BASENAME}_c100.faa"

  # Quick OpenMP check (so -T actually works)
  if "$CDHIT_BIN" -T 2 -h 2>&1 | grep -q "OpenMP is NOT enabled"; then
    echo "ERROR: cd-hit binary lacks OpenMP; -T will be ignored. Install cd-hit with OpenMP (bioconda/homebrew) and re-run." >&2
    return 1
  fi

  # Pass 1: exact duplicates
  if [ ! -s "$c100" ]; then
    "$CDHIT_BIN" -i "$in_faa" -o "$c100" \
      -c 1.0 -n 5 -g 0 -d 0 \
      -T "$THREADS" -M 0
  else
    echo "[10/11] Skipping CD-HIT pass1 (exists): $(basename "$c100")"
  fi

  # Pass 2: target identity with coverage constraint
  if [ ! -s "$out_faa" ]; then
    "$CDHIT_BIN" -i "$c100" -o "$out_faa" \
      -c "$IDENTITY" -n 5 -aS "$COVERAGE" \
      -g 0 -d 0 -T "$THREADS" -M 0
  else
    echo "[10/11] Skipping CD-HIT pass2 (exists): $(basename "$out_faa")"
  fi

  ln -sf "$(basename "$out_faa")" "$symlink_out"
  echo "[10/11] Clustered FASTA: $(basename "$out_faa")  (symlink: $(basename "$symlink_out"))"
}

step11_make_diamond_db() {
  local stamp="$1"; shift
  local resources_dir="$1"; shift
  local DB_BASENAME="$1"; shift

  # if symlink from step 10 exists, use it; else fall back to unclustered
  local fasta_in="${resources_dir}/nr_clean_clustered.faa"

  if [ ! -s "$fasta_in" ]; then
    fasta_in="${resources_dir}/${DB_BASENAME}.faa"
    echo "[11/11] Note: clustered FASTA not found; using unclustered ${fasta_in}"
  fi

  local db_prefix="${resources_dir}/${DB_BASENAME}.faa"
  echo "[11/11] Building DIAMOND DB from: $(basename "$fasta_in")"
  diamond makedb --in "$fasta_in" -d "$db_prefix"
}

# Run steps

if should_run_step 1; then
  echo "[1/11] Downloading NCBI nr.gz into $RESOURCES_DIR..."
  run_step_auto 1 "Download NCBI NR parts" -- step1_download_NCBI_nr
fi

if should_run_step 2; then
  echo "[2/11] Decompressing nr.gz..."
  run_step_auto 2 "Decompress NR archives" -- step2_decompress_nr
fi

if should_run_step 3; then
  echo "[3/11] Run blastdbcmd to gather all sequences in fasta..."
  run_step_auto 3 "Dump NR to FASTA (blastdbcmd)" -- step3_blastdbcmd_NCBI_nr
fi

if should_run_step 4; then
  echo "[4/11] Remove all the BLAST database volume files and index files after extraction..."
  run_step_auto 4 "Cleanup BLAST DB volumes" -- step4_cleanup_blast_db_files
fi

if should_run_step 5; then
  echo "[5/11] Cleaning ASCII characters in nr..."
  run_step_auto 5 "ASCII clean FASTA" -- step5_ascii_clean
fi

if should_run_step 6; then
  echo "[6/11] Downloading gene2go.gz..."
  run_step_auto 6 "Download gene2go" -- step6_download_gene2go "$RUN_TAG"
fi

if should_run_step 7; then
  echo "[7/11] Downloading gene2accession.gz..."
  run_step_auto 7 "Download gene2accession" -- step7_download_gene2accession "$RUN_TAG"
fi

if should_run_step 8; then
  echo "[8/11] Merging gene2go and gene2accession..."
  run_step_auto 8 "Merge gene2go + gene2accession" -- step8_merge_gene_tables "$RUN_TAG"
fi

if should_run_step 9; then
  echo "[9/11] Annotating and subsetting nr..."
  run_step_auto 9 "Annotate & subset NR" -- step9_annotate_and_subset_nr "$DB_BASENAME" "$RUN_TAG"
fi

if should_run_step 10; then
  echo "[10/11] Clustering representatives (MMseqs2/CD-HIT)..."
  run_step_auto 10 "Cluster representatives (MMseqs2/CD-HIT)" -- step10_cluster_reps "$DB_BASENAME"
fi

if should_run_step 11; then
  echo "[11/11] Making diamond database..."
  run_step_auto 11 "Build DIAMOND database" -- step11_make_diamond_db "$DB_BASENAME"
fi

echo "Database build complete: ${RESOURCES_DIR}/${DB_BASENAME}.faa.dmnd"
