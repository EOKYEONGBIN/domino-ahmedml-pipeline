# domino-ahmedml-project

DoMINO/AhmedML CFD 예측 파이프라인의 **프로젝트 운영 폴더 구조**입니다. 모델 코드 자체
(`train.py`, `predict_on_stl.py` 등 수정된 PhysicsNeMo 예제)는
[`domino-cfd-pipeline-guide`](https://github.com/EOKYEONGBIN/domino-cfd-pipeline-guide)
저장소에 있고, 이 저장소는 그 코드를 **실제로 어떤 설정/데이터/스크립트로 돌렸는지** 보여줍니다.

실제 운영 서버(`~/domino-ahmedml/`)는 전처리된 데이터만 500GB가 넘어서, 전체를 그대로
올리는 대신 **재현에 필요한 작은 파일만 실제로 담고, 용량이 큰 폴더는 빈 자리 + 설명**으로
남겨뒀습니다.

## 폴더 구조

| 폴더 | 내용 | 상태 |
|---|---|---|
| `configs/` | 학습 설정 yaml 6종 (`smoke_test` → `real_train_single_case` → `real_train_200*` → `real_train_500`, 프로젝트가 커진 순서 그대로) | ✅ 실제 파일 포함 |
| `manifests/` | train/val/test에 어떤 케이스 ID가 들어가는지 정의한 목록 (40-case → 200-case → 500-case로 확장된 이력이 `new_*`/`new2_*` 파일명에 남아있음) | ✅ 실제 파일 포함 |
| `scripts/` | 전처리(`process_data.py`), 다운로드+전처리+학습 자동화(`pipeline_500.sh`), 원격 추론(`run_prediction.sh`), 정확도 검증(`batch_eval_*`) | ✅ 실제 파일 포함 |
| `data/` | AhmedML raw + 전처리된(.npy) 데이터 | 📁 빈 폴더 (527GB, 미포함 — `data/README.md` 참고) |
| `model/` | 학습된 체크포인트(`.mdlus`) + 정규화 통계(`scaling_factors.pkl`) | 📁 빈 폴더 (재현 가능, 미포함 — `model/README.md` 참고) |
| `audit/` | R²/MAE 등 정확도 검증 결과물 | 📁 빈 폴더 (실행 시 재생성됨 — `audit/README.md` 참고) |
| `requests/` | Kit-CAE 추론 요청용 임시 작업 폴더 | 📁 빈 폴더 (순수 런타임 전용 — `requests/README.md` 참고) |

각 빈 폴더 안의 `README.md`에 "원래 뭐가 들어가는지"와 "왜 여기엔 없는지/어떻게 다시
만드는지"를 적어뒀습니다.

## 데이터셋

[AhmedML](https://caemldatasets.org/ahmedml/) (Ashton et al., 2024,
[arXiv:2407.20801](https://arxiv.org/abs/2407.20801)) — HuggingFace에서 공개 다운로드 가능:
[`huggingface.co/datasets/neashton/ahmedml`](https://huggingface.co/datasets/neashton/ahmedml)

## 관련 저장소

- [`domino-cfd-pipeline-guide`](https://github.com/EOKYEONGBIN/domino-cfd-pipeline-guide) — 수정된 모델 코드(`predict_on_stl.py`, `train.py`)와 11단계 빌드 가이드

## 라이선스

Apache License 2.0. `scripts/process_data.py`, `scripts/openfoam_datapipe.py`는 NVIDIA
PhysicsNeMo 예제(`domino_nim_finetuning`)를 변형한 파일이며, 변경 내역은
[`NOTICE`](./NOTICE)에 명시돼 있습니다. 나머지 파일은 이 프로젝트에서 직접 작성했습니다.
