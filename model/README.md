# model/

학습이 끝난 뒤 배포하는 최종 산출물이 들어가는 자리입니다:

- `DoMINO.0.<epoch>.mdlus` — 가장 좋은 validation loss를 기록한 체크포인트
- `scaling_factors.pkl` — 학습 때 계산한 정규화 통계 (추론 시 반드시 동일한 파일을 재사용해야 함)

**이 저장소에는 포함하지 않았습니다** — 체크포인트 자체는 용량(수십~수백 MB)과 재현성
(학습을 다시 돌리면 또 생성 가능) 문제로 git에 올리는 대신, `../scripts`와 `../configs`의
학습 설정으로 직접 재현하는 걸 전제로 합니다.

실제 배포 모델은 [`domino-cfd-pipeline-guide`](https://github.com/EOKYEONGBIN/domino-cfd-pipeline-guide)
저장소의 `train.py`를 이 폴더의 config로 돌려서 만듭니다.
