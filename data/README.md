# data/

이 폴더는 실제 운영 환경에서는 AhmedML raw 데이터(`CAE_Examples_AhmedML/run_N/...`)와
`process_data.py`로 전처리된 결과(`processed/train/*.npy`, `processed/val/*.npy`)가
들어가는 자리입니다.

**이 저장소에는 포함하지 않았습니다** — 500개 케이스 전체 기준 raw+전처리 데이터를 합치면
약 **527GB**로, 일반 git 저장소에 올릴 수 있는 범위가 아닙니다.

## 원본 데이터 받는 법

AhmedML 데이터셋은 [HuggingFace](https://huggingface.co/datasets/neashton/ahmedml)에
공개돼 있어 누구나 직접 받을 수 있습니다. `../scripts/pipeline_500.sh`가 실제로 이 폴더
구조(`raw_train/`, `raw_val/`, `raw_test/`, `processed/train/`, `processed/val/`)를
어떻게 채우는지 보여줍니다.
