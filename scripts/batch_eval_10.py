"""
Surface-field accuracy check for the deployed (500-case combined) model:
runs inference on N held-out test cases, compares predicted pMean /
wallShearStressMean against the real CFD boundary_N.vtp via nearest-cell
matching (predicted output lives on the original, coarser STL faces; the
ground-truth CFD mesh is finer), and reports MAE/RMSE/R2 per case + a
summary across all of them. Results are appended to a CSV per case so a
partial run is still a usable report.
"""
import csv
import os
import subprocess
import sys

import numpy as np
import pyvista as pv
from scipy.spatial import cKDTree

HOME = os.path.expanduser("~")
DATA_DIR = f"{HOME}/domino-ahmedml/data/CAE_Examples_AhmedML"
REQUESTS_DIR = f"{HOME}/domino-ahmedml/requests"
RUN_SCRIPT = f"{HOME}/domino-ahmedml/scripts/run_prediction.sh"
OUT_CSV = f"{HOME}/domino-ahmedml/audit/eval10_results.csv"

N_CASES = int(sys.argv[1]) if len(sys.argv) > 1 else 10


def field_r2(pred, gt):
    pred = pred.reshape(-1)
    gt = gt.reshape(-1)
    mae = float(np.mean(np.abs(pred - gt)))
    rmse = float(np.sqrt(np.mean((pred - gt) ** 2)))
    r2 = float(1 - np.sum((pred - gt) ** 2) / np.sum((gt - gt.mean()) ** 2))
    return mae, rmse, r2


def main():
    with open("/tmp/all_test_cases.txt") as f:
        case_names = [line.strip() for line in f if line.strip()]

    available = []
    for case_name in case_names:
        case_id = case_name.removeprefix("run_")
        d = f"{DATA_DIR}/run_{case_id}"
        if os.path.isfile(f"{d}/ahmed_{case_id}.stl") and os.path.isfile(f"{d}/boundary_{case_id}.vtp"):
            available.append(case_id)
    cases = available[:N_CASES]
    print(f"Evaluating {len(cases)} cases: {cases}", flush=True)

    os.makedirs(os.path.dirname(OUT_CSV), exist_ok=True)
    with open(OUT_CSV, "w", newline="") as out_f:
        writer = csv.writer(out_f)
        writer.writerow(["case_id", "p_mae", "p_rmse", "p_r2", "wss_mae", "wss_rmse", "wss_r2"])

        p_r2s, wss_r2s = [], []
        for case_id in cases:
            case_dir = f"{DATA_DIR}/run_{case_id}"
            stl_path = f"{case_dir}/ahmed_{case_id}.stl"
            gt_path = f"{case_dir}/boundary_{case_id}.vtp"

            req = f"eval10_{case_id}"
            req_dir = f"{REQUESTS_DIR}/{req}"
            subprocess.run(["rm", "-rf", req_dir], check=True)
            os.makedirs(f"{req_dir}/input/case", exist_ok=True)
            subprocess.run(["cp", stl_path, f"{req_dir}/input/case/"], check=True)

            print(f"[{case_id}] running inference...", flush=True)
            result = subprocess.run([RUN_SCRIPT, req, "true", "false"], capture_output=True, text=True)
            pred_path = f"{req_dir}/output/prediction_0.vtp"
            if result.returncode != 0 or not os.path.isfile(pred_path):
                print(f"[{case_id}] FAILED: {result.stderr[-500:]}", flush=True)
                subprocess.run(["rm", "-rf", req_dir], check=True)
                continue

            pred = pv.read(pred_path)
            gt = pv.read(gt_path)
            tree = cKDTree(gt.cell_centers().points)
            _, idx = tree.query(pred.cell_centers().points, k=1)

            pp = np.asarray(pred.cell_data["pMean"])
            gp = np.asarray(gt.cell_data["pMean"])[idx]
            p_mae, p_rmse, p_r2 = field_r2(pp, gp)

            pw = np.asarray(pred.cell_data["wallShearStressMean"])
            gw = np.asarray(gt.cell_data["wallShearStressMean"])[idx]
            wss_mae, wss_rmse, wss_r2 = field_r2(pw, gw)

            writer.writerow([case_id, p_mae, p_rmse, p_r2, wss_mae, wss_rmse, wss_r2])
            out_f.flush()
            p_r2s.append(p_r2)
            wss_r2s.append(wss_r2)
            print(f"[{case_id}] pMean R2={p_r2:.4f}  wallShearStressMean R2={wss_r2:.4f}", flush=True)

            subprocess.run(["rm", "-rf", req_dir], check=True)

        if p_r2s:
            print(f"=== MEAN over {len(p_r2s)} cases: pMean R2={np.mean(p_r2s):.4f}  wallShearStressMean R2={np.mean(wss_r2s):.4f} ===", flush=True)
    print("ALL DONE", flush=True)


if __name__ == "__main__":
    main()
