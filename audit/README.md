# audit/

모델 정확도 검증 결과가 쌓이는 자리입니다 — 예:

- `../scripts/batch_eval_10.py` / `batch_eval_50.sh`로 돌린 표면 필드(pMean,
  wallShearStressMean) R²/MAE/RMSE 결과 CSV
- 40-case 모델 vs 500-case 모델 비교 결과
- STL-vs-CFD 법선/해상도 버그를 발견/검증했던 과정의 중간 산출물

**이 저장소에는 포함하지 않았습니다** — 실행할 때마다 다시 생성되는 결과물이고(용량도
수 GB), 검증에 쓰인 스크립트 자체(`../scripts/batch_eval_*`)가 핵심이라 그쪽을 올렸습니다.
