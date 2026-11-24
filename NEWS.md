# bareun 1.4.0

* 긴 글 대응. 서버가 5,000자를 넘는 요청을 거절하지 않고
  앞 5,000자 안팎만 처리하면, `bareun_truncated_warning` 경고를 올립니다. 지금 기준은 5,000자이며 서비스 운영 상황에 따라 바뀔 수
  있으니 숫자를 코드에 박지 말고 응답의 `truncation` 필드로 판단하세요.
* 새 함수 `truncation()`(처리한 글자 수·버린 글자 수·안내 문구)과
  `is_truncated()`. 기존 함수의 반환값은 바뀌지 않습니다.
* 교정 세션. `open_session()`·`close_session()`, `correct_grammar(session = )`,
  `session_revision()`·`session_events()`.
  긴 글은 세션(`OpenSession`, `CloseSession`)을 열고 문단 단위로 나눠 보내세요. 세션 안의 요청들은 따로 부르는 `CorrectError` 가 아니라 한 문서로 이어진 것으로 처리되어, 사용자 사전과 옵션이 문단마다 같게 적용되고 앞 문단에서 두 번 이상 나온 사전에 없는 낱말을 뒤 문단에서 오타로 보지 않습니다. 짧은 문단 요청은 서버가 한 번에 쓰는 메모리와 시간이 작아 긴 한 요청보다 안정되게 처리되며, 이는 서버 처리 부담에 관한 설명이고 요금이 달라진다는 뜻은 아닙니다. 5,000자 기준은 세션 안의 각 요청에도 똑같이 걸립니다.
  세션 오류는  `bareun_session_error`(`e$reason`).
