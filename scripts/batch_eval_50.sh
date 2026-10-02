#!/bin/bash
# Batch A-3 style evaluation across all 50 AhmedML test cases, comparing the
# 40-case model vs the 500-case combined model, using the fully-fixed
# predict_on_stl.py (normal sign fix + subdivision area fix, 2026-09-29).
set -u

DOMINO_AHMEDML=~/domino-ahmedml
SRC=~/physicsnemo/examples/cfd/external_aerodynamics/domino/src
BATCH_DIR="$DOMINO_AHMEDML/audit/batch50"
IDS_FILE=/tmp/all_test_ids2.txt
LOG="$DOMINO_AHMEDML/audit/batch50.log"
RESULTS="$DOMINO_AHMEDML/audit/batch50_results.csv"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

echo "case,model,mae,rmse,r2,rel_l2" > "$RESULTS"

source ~/venvs/domino/bin/activate
cd "$SRC"

while read -r id; do
    [ -z "$id" ] && continue
    CASE_DIR="$BATCH_DIR/run_$id"
    mkdir -p "$CASE_DIR/input/case"
    ln -sfn "$DOMINO_AHMEDML/data/CAE_Examples_AhmedML/run_$id/ahmed_$id.stl" "$CASE_DIR/input/case/ahmed_$id.stl"
    GT="$DOMINO_AHMEDML/data/CAE_Examples_AhmedML/run_$id/boundary_$id.vtp"

    for MODEL in full500 full40; do
        if [ "$MODEL" = "full500" ]; then
            CFG=real_train_500
            RESUME="$DOMINO_AHMEDML/audit/full500_model"
        else
            CFG=real_train
            RESUME="$DOMINO_AHMEDML/model_backup_full50"
        fi
        OUT_DIR="$CASE_DIR/output_$MODEL"
        rm -rf "$OUT_DIR" "$CASE_DIR/hydra_$MODEL"
        log "run_$id / $MODEL: predicting..."
        python predict_on_stl.py \
            --config-path "$DOMINO_AHMEDML/configs" --config-name "$CFG" \
            eval.test_path="$CASE_DIR/input" \
            eval.save_path="$OUT_DIR" \
            resume_dir="$RESUME" \
            data.scaling_factors="$RESUME/scaling_factors.pkl" \
            eval.scaling_param_path="$RESUME" \
            hydra.run.dir="$CASE_DIR/hydra_$MODEL" \
            >> "$LOG" 2>&1
        if [ ! -f "$OUT_DIR/prediction_0.vtp" ]; then
            log "run_$id / $MODEL: FAILED (no output), skipping metrics"
            continue
        fi
        python3 -c "
import pyvista as pv, numpy as np
from scipy.spatial import cKDTree
pred = pv.read('$OUT_DIR/prediction_0.vtp')
gt = pv.read('$GT')
tree = cKDTree(gt.cell_centers().points)
_, idx = tree.query(pred.cell_centers().points, k=1)
pp = np.asarray(pred.cell_data['pMean']).reshape(-1)
gp = np.asarray(gt.cell_data['pMean']).reshape(-1)[idx]
mae = np.mean(np.abs(pp-gp)); rmse = np.sqrt(np.mean((pp-gp)**2))
r2 = 1 - np.sum((pp-gp)**2)/np.sum((gp-gp.mean())**2)
rel_l2 = np.linalg.norm(pp-gp)/np.linalg.norm(gp)
with open('$RESULTS', 'a') as f:
    f.write(f'$id,$MODEL,{mae:.6f},{rmse:.6f},{r2:.6f},{rel_l2:.6f}\n')
print(f'run_$id $MODEL: R2={r2:.4f}')
" >> "$LOG" 2>&1
    done
done < "$IDS_FILE"

log "=== Batch evaluation complete ==="
