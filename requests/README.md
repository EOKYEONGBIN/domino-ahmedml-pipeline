# requests/

Kit-CAE 확장(`domino_predict`)이 "Request Prediction"을 누를 때마다, SSH로 받은 STL과
그 결과(VTP/VTI)를 주고받기 위해 **요청 하나당 하나씩** 만들어지는 임시 작업 폴더입니다
(`requests/<request_id>/input/`, `requests/<request_id>/output/`).

`../scripts/run_prediction.sh`가 끝날 때 보통 바로 정리되는, **순수 런타임 전용** 폴더라
장기 보존 가치가 없습니다. 이 저장소에는 빈 폴더 자리만 남겨뒀습니다.
