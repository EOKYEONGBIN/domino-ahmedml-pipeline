#!/bin/bash
# Unattended pipeline: download the remaining 300 AhmedML cases (random,
# excluding the 200 already used), preprocess them alongside the existing
# 160 train / 24 val (combined mode, so volume.vtu IS downloaded/processed
# this time), then automatically launch COMBINED (surface+volume) training
# on the resulting 400 train / 50 val dataset.
#
# Forked from pipeline_200.sh (its download_case/symlink_case/process_split/
# delete_raw_if_processed functions are unchanged, already proven correct)
# with two additions per the user's explicit request before a multi-day
# unattended absence (Chuseok holiday):
#   1. check_disk_space(): a fail-SAFE guard before each major phase (a
#      batch download, compute_statistics, train.py) -- aborts with a clear
#      log message if free space is below a safety floor, instead of
#      plowing ahead and risking a mid-write crash like the original
#      200-case run's disk-full crash (train.py's checkpoint retention is
#      also now patched, which was the actual root cause of that crash, but
#      this is defense in depth for the unattended download phase too).
#   2. A background disk-usage logger (30 min interval) for the training
#      phase, so the log has a paper trail even though nothing should
#      change disk usage much during training anymore.
#
# Designed to survive SSH disconnection (run via nohup+disown) and to be
# safely re-run if interrupted: downloads skip already-present files,
# process_data.py skips already-processed cases (checked via .npy
# existence), so re-running this script after a partial failure just
# resumes where it left off.

set -u

DOMINO_AHMEDML=~/domino-ahmedml
MANIFEST_DIR="$DOMINO_AHMEDML/manifests"
DATA_DIR="$DOMINO_AHMEDML/data/CAE_Examples_AhmedML"
LOG="$DOMINO_AHMEDML/pipeline_500.log"
BATCH_SIZE=60
BASE_URL="https://huggingface.co/datasets/neashton/ahmedml/resolve/main"

# Safety floor: refuse to start a new batch/phase if free space would drop
# below this. Measured peak need for one batch of 60 combined-mode cases
# (raw, incl. volume.vtu, before delete_raw_if_processed reclaims it) is
# ~342GB; current free space is ~623GB, so this floor is a generous margin
# for the unexpected, not something we expect to actually hit.
MIN_FREE_GB=100

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

check_disk_space() {
    local phase="$1"
    local avail_gb
    avail_gb=$(df --output=avail -BG / | tail -1 | tr -dc '0-9')
    log "Disk check before $phase: ${avail_gb}GB free (floor: ${MIN_FREE_GB}GB)"
    if [ "$avail_gb" -lt "$MIN_FREE_GB" ]; then
        log "ABORT: free space ${avail_gb}GB is below the ${MIN_FREE_GB}GB safety floor before $phase. Stopping cleanly -- nothing further will be written. Check disk usage and re-run this script to resume (it skips already-downloaded/processed cases)."
        exit 1
    fi
}

download_case() {
    local run_id="$1"
    local dir="$DATA_DIR/run_$run_id"
    mkdir -p "$dir"
    local files=("ahmed_${run_id}.stl" "boundary_${run_id}.vtp" "volume_${run_id}.vtu" "force_mom_${run_id}.csv" "geo_parameters_${run_id}.csv")
    for f in "${files[@]}"; do
        if [ ! -s "$dir/$f" ]; then
            local ok=0
            for attempt in 1 2 3; do
                if wget -q -O "$dir/$f.part" "$BASE_URL/run_$run_id/$f"; then
                    mv "$dir/$f.part" "$dir/$f"
                    ok=1
                    break
                fi
                log "  retry $attempt failed for run_$run_id/$f"
                rm -f "$dir/$f.part"
                sleep 5
            done
            if [ "$ok" -ne 1 ]; then
                log "FAILED (giving up after 3 attempts): run_$run_id/$f"
                return 1
            fi
        fi
    done
    return 0
}

symlink_case() {
    local run_id="$1"
    local split_dir="$2"  # raw_train / raw_val / raw_test
    mkdir -p "$DOMINO_AHMEDML/data/$split_dir"
    ln -sfn "$DATA_DIR/run_$run_id" "$DOMINO_AHMEDML/data/$split_dir/run_$run_id"
}

process_split() {
    local split="$1"  # train or val
    log "Running process_data.py for split=$split ..."
    (cd "$DOMINO_AHMEDML/scripts" && \
        ~/venvs/domino/bin/python process_data.py --config-name real_train \
            "++data_processor.input_dir=$DOMINO_AHMEDML/data/raw_$split" \
            "++data_processor.output_dir=$DOMINO_AHMEDML/data/processed/$split" \
        >> "$LOG" 2>&1)
    log "process_data.py for split=$split done (exit $?)."
}

delete_raw_if_processed() {
    local run_id="$1"
    local split="$2"
    if [ -f "$DOMINO_AHMEDML/data/processed/$split/run_$run_id.npy" ]; then
        rm -rf "$DATA_DIR/run_$run_id"
        rm -f "$DOMINO_AHMEDML/data/raw_$split/run_$run_id"
        log "  freed raw data for run_$run_id (processed .npy confirmed present)"
    else
        log "  WARNING: run_$run_id has no processed .npy yet -- keeping raw data, NOT deleting"
    fi
}

run_batches() {
    local split="$1"
    local ids_file="$2"
    mapfile -t ids < "$ids_file"
    local total=${#ids[@]}
    log "=== $split: $total cases to download+process ==="
    local i=0
    while [ "$i" -lt "$total" ]; do
        check_disk_space "$split batch (cases $i..$((i+BATCH_SIZE)))"
        local batch=("${ids[@]:i:BATCH_SIZE}")
        log "-- $split batch: ${batch[*]}"
        for run_id in "${batch[@]}"; do
            log "Downloading run_$run_id ($split)..."
            if download_case "$run_id"; then
                symlink_case "$run_id" "raw_$split"
            else
                log "  Skipping run_$run_id entirely due to download failure."
            fi
        done
        process_split "$split"
        for run_id in "${batch[@]}"; do
            delete_raw_if_processed "$run_id" "$split"
        done
        i=$((i + BATCH_SIZE))
    done
}

download_test_cases() {
    log "=== Downloading test cases (kept as raw ground truth, no processing) ==="
    while read -r run_id; do
        [ -z "$run_id" ] && continue
        log "Downloading run_$run_id (test)..."
        if download_case "$run_id"; then
            symlink_case "$run_id" "raw_test"
        else
            log "  Skipping run_$run_id (test) due to download failure."
        fi
    done < "$MANIFEST_DIR/new2_test.txt"
    log "=== Test case downloads complete. ==="
}

disk_monitor() {
    while true; do
        sleep 1800
        local avail_gb
        avail_gb=$(df --output=avail -BG / | tail -1 | tr -dc '0-9')
        log "[disk monitor] ${avail_gb}GB free"
    done
}

log "=== Pipeline started (500-case combined expansion) ==="

run_batches train "$MANIFEST_DIR/new2_train.txt"
run_batches val "$MANIFEST_DIR/new2_val.txt"

download_test_cases &

check_disk_space "compute_statistics.py"
log "=== Train/val data ready. Computing scaling factors (compute_statistics.py) ==="
cd ~/physicsnemo/examples/cfd/external_aerodynamics/domino/src
~/venvs/domino/bin/python compute_statistics.py \
    --config-path "$DOMINO_AHMEDML/configs" \
    --config-name real_train_500 \
    >> "$LOG" 2>&1
log "compute_statistics.py done (exit $?). Starting training (real_train_500) immediately -- not waiting on test downloads."

check_disk_space "train.py"
disk_monitor &
MONITOR_PID=$!
trap 'kill $MONITOR_PID 2>/dev/null' EXIT

~/venvs/domino/bin/python train.py \
    --config-path "$DOMINO_AHMEDML/configs" \
    --config-name real_train_500 \
    >> "$LOG" 2>&1

log "=== Training finished (exit $?). Pipeline complete. ==="
