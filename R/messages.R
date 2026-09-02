# 사용자에게 보이는 한국어 문자열 모음.
#
# CRAN 은 R 코드에 ASCII 만 허용한다(주석은 예외다 - 실측으로 확인했다).
# 그래서 한국어 메시지는 \uXXXX 로 이스케이프해 두고, 사람이 읽을 수 있도록
# 원문을 바로 위 주석에 남긴다.
#
# 이 파일은 tools/make-messages.py 가 만든다. 직접 고치지 말고
# 그 스크립트의 MESSAGES 목록을 고친 뒤 다시 돌린다.

.messages <- list(
  # "text 는 비어 있지 않은 문자열 하나여야 합니다."
  need_text = "text \uB294 \uBE44\uC5B4 \uC788\uC9C0 \uC54A\uC740 \uBB38\uC790\uC5F4 \uD558\uB098\uC5EC\uC57C \uD569\uB2C8\uB2E4.",
  # "pattern 은 비어 있지 않은 문자열 하나여야 합니다."
  need_pattern = "pattern \uC740 \uBE44\uC5B4 \uC788\uC9C0 \uC54A\uC740 \uBB38\uC790\uC5F4 \uD558\uB098\uC5EC\uC57C \uD569\uB2C8\uB2E4.",
  # "anchor 는 word·prefix·suffix·contains 중 하나여야 합니다: %s"
  bad_anchor = "anchor \uB294 word\u00B7prefix\u00B7suffix\u00B7contains \uC911 \uD558\uB098\uC5EC\uC57C \uD569\uB2C8\uB2E4: %s",
  # "바른 서버에 접속하지 못했습니다 (%s): %s"
  conn_failed = "\uBC14\uB978 \uC11C\uBC84\uC5D0 \uC811\uC18D\uD558\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4 (%s): %s",
  # "API 키가 유효하지 않거나 라이선스가 만료되었습니다."
  auth_invalid = "API \uD0A4\uAC00 \uC720\uD6A8\uD558\uC9C0 \uC54A\uAC70\uB098 \uB77C\uC774\uC120\uC2A4\uAC00 \uB9CC\uB8CC\uB418\uC5C8\uC2B5\uB2C8\uB2E4.",
  # "이 서버는 bareun.%s 를 제공하지 않습니다. 교정·사전 검색은 맞춤법 교정(rev) 빌드에서만 동작합니다."
  unimplemented = "\uC774 \uC11C\uBC84\uB294 bareun.%s \uB97C \uC81C\uACF5\uD558\uC9C0 \uC54A\uC2B5\uB2C8\uB2E4. \uAD50\uC815\u00B7\uC0AC\uC804 \uAC80\uC0C9\uC740 \uB9DE\uCDA4\uBC95 \uAD50\uC815(rev) \uBE4C\uB4DC\uC5D0\uC11C\uB9CC \uB3D9\uC791\uD569\uB2C8\uB2E4.",
  # "바른 서버가 오류를 돌려주었습니다 (HTTP %s)"
  http_error = "\uBC14\uB978 \uC11C\uBC84\uAC00 \uC624\uB958\uB97C \uB3CC\uB824\uC8FC\uC5C8\uC2B5\uB2C8\uB2E4 (HTTP %s)",
  # "API 키가 없습니다. set_key() 또는 set_api() 로 먼저 지정하세요."
  no_key = "API \uD0A4\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4. set_key() \uB610\uB294 set_api() \uB85C \uBA3C\uC800 \uC9C0\uC815\uD558\uC138\uC694.",
  # "-> 고유명사 사전"
  dict_np = "-> \uACE0\uC720\uBA85\uC0AC \uC0AC\uC804",
  # "-> 복합명사 사전"
  dict_cp = "-> \uBCF5\uD569\uBA85\uC0AC \uC0AC\uC804",
  # "-> 분리 사전"
  dict_caret = "-> \uBD84\uB9AC \uC0AC\uC804",
  # "-> 동사 사전"
  dict_vv = "-> \uB3D9\uC0AC \uC0AC\uC804",
  # "-> 형용사 사전"
  dict_va = "-> \uD615\uC6A9\uC0AC \uC0AC\uC804",
  # "%s : 업데이트 성공"
  dict_updated = "%s : \uC5C5\uB370\uC774\uD2B8 \uC131\uACF5"
)

#' 메시지를 꺼내 인자를 채운다.
#'
#' @param key string - .messages 의 키
#' @param ... sprintf 로 채울 값들
#' @return 완성된 메시지 문자열
#' @keywords internal
.m <- function(key, ...) {
  s <- .messages[[key]]
  if (is.null(s)) {
    stop("unknown message key: ", key)
  }
  if (length(list(...)) == 0L) s else sprintf(s, ...)
}
