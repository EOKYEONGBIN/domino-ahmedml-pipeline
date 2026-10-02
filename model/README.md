# model/

학습이 끝난 뒤 배포하는 최종 산출물입니다:

- `DoMINO.0.220.mdlus` — 500-case combined 모델의 best checkpoint (epoch 220, best val loss 0.00171)
- `scaling_factors.pkl` — 학습 때 계산한 정규화 통계 (추론 시 반드시 이 파일을 그대로 재사용해야 함)

## 라이선스 — 코드와 다릅니다

이 모델은 코드가 아니라 **AhmedML 데이터셋으로 학습한 결과물**입니다. AhmedML은
[CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/) 라이선스라, 이 체크포인트도
저장소 전체의 Apache 2.0이 아니라 **CC BY-SA 4.0**을 따릅니다:

- **저작자 표시**: AhmedML 데이터셋 — N. Ashton, D. C. Maddix, S. Gundry, P. M. Shabestari,
  "AhmedML: High-Fidelity Computational Fluid Dynamics Dataset for Incompressible,
  Low-Speed Bluff Body Aerodynamics," arXiv:2407.20801, 2024.
  ([caemldatasets.org/ahmedml](https://caemldatasets.org/ahmedml/))
- **동일 라이선스 유지(ShareAlike)**: 이 체크포인트를 가져다 쓰거나 재배포할 때도 CC BY-SA 4.0을
  유지해야 합니다.

## 쓰는 법

`../../domino-cfd-pipeline-guide`의 `predict_on_stl.py`와, 이 저장소의
`../configs/real_train_500.yaml`을 함께 써야 합니다 — 모델 구조가 그 config와 정확히
일치해야 체크포인트가 로드됩니다.
