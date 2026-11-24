# bareun 1.4.0

* 긴 글 대응. 서버가 5,000자를 넘는 요청을 거절하지 않고
  앞 5,000자 안팎만 처리하면, `bareun_truncated_warning` 경고를 올립니다.
* 새 함수 `truncation()`(처리한 글자 수·버린 글자 수·안내 문구)과
  `is_truncated()`. 기존 함수의 반환값은 바뀌지 않습니다.
* 교정 세션. `open_session()`·`close_session()`, `correct_grammar(session = )`,
  `session_revision()`·`session_events()`. 긴 문서를 나눠 교정할 때 앞 호출에서 본
  미등록 단어를 뒤 호출에 쓴다. 세션 오류는 `bareun_session_error`(`e$reason`).
