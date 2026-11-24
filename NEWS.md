# bareun 1.4.0

* 긴 글 대응. 응답의 `truncation` 필드를 읽는 새 함수 `truncation()`(처리한 글자 수·버린 글자
  수·안내 문구)과 `is_truncated()`를 더하고, 잘린 응답이면 `bareun_truncated_warning` 경고를
  올립니다. 기존 함수의 반환값은 바뀌지 않습니다.
  바른 엔진 자체에는 글자 수 제약이 없지만, 클라우드 서비스(api.bareun.ai)는 용량 때문에 요청 한 번에 처리하는 양을 5,000자로 둡니다. 5,000자를 넘는 글은 앞부분만 처리하고 응답의 `truncation` 필드에 알리므로, 5,000자 이하로 나눠 보내 주세요. 이 기준은 운영 상황에 따라 바뀔 수 있으니 숫자를 코드에 박지 말고 `truncation` 의 `processed_chars`·`dropped_chars` 로 판단하세요.
* 교정 세션. `open_session()`·`close_session()`, `correct_grammar(session = )`,
  `session_revision()`·`session_events()`. 세션 오류는 `bareun_session_error`(`e$reason`).
  바른 엔진 자체에는 글자 수 제약이 없지만, 클라우드 서비스(api.bareun.ai)는 용량 때문에 요청 한 번에 처리하는 양을 5,000자로 둡니다. 5,000자를 넘는 글은 앞부분만 처리하고 응답의 `truncation` 필드에 알리므로, 긴 글은 세션(`OpenSession`, `CloseSession`)을 열고 문단 단위로 5,000자 이하씩 보내 주세요(세션 안의 요청은 한 문서로 이어져 처리되고, 5,000자 기준은 각 요청에 똑같이 걸립니다). 이 기준은 운영 상황에 따라 바뀔 수 있으니 숫자를 코드에 박지 말고 `truncation` 의 `processed_chars`·`dropped_chars` 로 판단하세요.
