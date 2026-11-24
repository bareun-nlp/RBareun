# bareun 1.4.0

* 긴 글 대응. 서버가 5,000자를 넘는 요청을 거절하지 않고
  앞 5,000자 안팎만 처리하면, `bareun_truncated_warning` 경고를 올립니다. 지금 기준은 5,000자이며 서비스 운영 상황에 따라 바뀔 수 있으니, 숫자를
  코드에 박지 말고 응답의 `truncation` 필드로 판단하세요.
* 새 함수 `truncation()`(처리한 글자 수·버린 글자 수·안내 문구)과
  `is_truncated()`. 기존 함수의 반환값은 바뀌지 않습니다.
* 교정 세션. `open_session()`·`close_session()`, `correct_grammar(session = )`,
  `session_revision()`·`session_events()`. 긴 글은 세션을 열고 문단 단위로 나눠 보내는 것이 권장 방식이다. 세션 안
  요청들은 한 문서로 이어진 것으로 다뤄져 앞 문단의 미등록어·문맥·사전·옵션이 뒤 문단에
  이어진다. 5,000자 기준은 세션 안 각 요청에도 걸린다. 세션 오류는 `bareun_session_error`(`e$reason`).
