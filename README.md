# domino-ahmedml-pipeline

DoMINO/AhmedML CFD 예측 파이프라인의 **설정 + 운영/자동화 스크립트**입니다. 모델 코드 자체
(`train.py`, `predict_on_stl.py` 등 수정된 PhysicsNeMo 예제)는
[`domino-cfd-pipeline-guide`](https://github.com/EOKYEONGBIN/domino-cfd-pipeline-guide)
저장소에 있고, 이 저장소는 그 코드를 **실제로 어떤 설정/데이터로, 어떤 자동화 스크립트로
돌렸는지**를 보여줍니다.

**이 저장소엔 실제 모델이나 데이터셋이 들어있지 않습니다** — `data/`, `model/`, `audit/`,
`requests/`는 실제 운영 서버의 폴더 구조를 보여주기 위한 **빈 자리(각 폴더 안 README만
있음)**이고, 진짜 내용물은 "재현에 쓰는 configs/manifests/scripts"뿐입니다.

실제 운영 서버(`~/domino-ahmedml/`)는 전처리된 데이터만 500GB가 넘어서, 전체를 그대로
올리는 대신 **재현에 필요한 작은 파일만 실제로 담고, 용량이 큰 폴더는 빈 자리 + 설명**으로
남겨뒀습니다.

> **참고**: 실제 프로젝트는 40-case → 200-case → 500-case로 세 번에 걸쳐 점진적으로
> 확장됐지만(그래서 매니페스트가 원래 `train.txt`+`new_train.txt`+`new2_train.txt`처럼
> 세 파일로 나뉘어 있었습니다), 이 저장소는 **교육 목적상 "처음부터 500개를 대상으로 진행했다"고
> 가정**하고 그 세 파일을 `train_400.txt` 하나로 합쳐 정리했습니다. 케이스 ID 자체는 실제
> 사용된 것과 동일합니다 — 파일 구성만 단순화했습니다.

## 폴더 구조

| 폴더 | 내용 | 상태 |
|---|---|---|
| `configs/` | 학습 설정 yaml 6종 (`smoke_test` → `real_train_single_case` → `real_train_200*` → `real_train_500`, 프로젝트가 커진 순서 그대로) | ✅ 실제 파일 포함 |
| `manifests/` | train/val/test에 어떤 케이스 ID가 들어가는지 정의한 목록 — `train_400.txt`(399개), `val_50.txt`(49개), `test_50.txt`(50개) | ✅ 실제 파일 포함 |
| `scripts/` | 전처리(`process_data.py`), 다운로드+전처리+학습 자동화(`pipeline_500.sh`), 정확도 검증(`batch_eval_*`) | ✅ 실제 파일 포함 |
| `data/` | AhmedML raw + 전처리된(.npy) 데이터 | 📁 빈 폴더 (527GB, 미포함 — `data/README.md` 참고) |
| `model/` | 500-case combined 모델의 최종 체크포인트(`DoMINO.0.220.mdlus`) + 정규화 통계(`scaling_factors.pkl`) | ✅ 실제 파일 포함 (단, CC BY-SA 4.0 — `model/README.md` 참고) |
| `audit/` | R²/MAE 등 정확도 검증 결과물 | 📁 빈 폴더 (실행 시 재생성됨 — `audit/README.md` 참고) |
| `requests/` | Kit-CAE 추론 요청용 임시 작업 폴더 | 📁 빈 폴더 (순수 런타임 전용 — `requests/README.md` 참고) |

각 빈 폴더 안의 `README.md`에 "원래 뭐가 들어가는지"와 "왜 여기엔 없는지/어떻게 다시
만드는지"를 적어뒀습니다.

## 데이터셋

[AhmedML](https://caemldatasets.org/ahmedml/) (Ashton et al., 2024,
[arXiv:2407.20801](https://arxiv.org/abs/2407.20801)) — HuggingFace에서 공개 다운로드 가능:
[`huggingface.co/datasets/neashton/ahmedml`](https://huggingface.co/datasets/neashton/ahmedml)

## 관련 저장소

- [`domino-cfd-pipeline-guide`](https://github.com/EOKYEONGBIN/domino-cfd-pipeline-guide) — 수정된 모델 코드(`predict_on_stl.py`, `train.py`), 원격 추론 실행 스크립트(`scripts/run_prediction.sh`), 11단계 빌드 가이드

## 라이선스

- 코드(`scripts/`, `configs/`, `manifests/`): Apache License 2.0. `scripts/process_data.py`,
  `scripts/openfoam_datapipe.py`는 NVIDIA PhysicsNeMo 예제(`domino_nim_finetuning`)를
  변형한 파일이며, 변경 내역은 [`NOTICE`](./NOTICE)에 명시돼 있습니다.
- **모델(`model/`): CC BY-SA 4.0** — AhmedML 데이터셋 자체의 라이선스를 따릅니다. 자세한
  저작자 표시는 [`model/README.md`](./model/README.md) 참고.
