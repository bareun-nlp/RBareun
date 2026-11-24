# bareun 1.4.0

* 긴 글 대응. 서버가 기준(바른 클라우드 API 는 9,000자)을 넘는 요청을 거절하지 않고
  앞부분만 처리하면, `bareun_truncated_warning` 경고를 올립니다.
* 새 함수 `truncation()`(처리한 글자 수·버린 글자 수·안내 문구)과
  `is_truncated()`. 기존 함수의 반환값은 바뀌지 않습니다.
