#!/usr/bin/env python3
r"""R/messages.R 을 다시 만든다.

CRAN 은 R 코드에 ASCII 만 허용하므로 한국어 메시지를 \uXXXX 로 이스케이프한다.
아래 목록만 고치고 이 스크립트를 돌리면 R/messages.R 이 갱신된다.

    python3 tools/make-messages.py
"""
MESSAGES = [
    ("need_text",     "text 는 비어 있지 않은 문자열 하나여야 합니다."),
    ("need_pattern",  "pattern 은 비어 있지 않은 문자열 하나여야 합니다."),
    ("bad_anchor",    "anchor 는 word·prefix·suffix·contains 중 하나여야 합니다: %s"),
    ("conn_failed",   "바른 서버에 접속하지 못했습니다 (%s): %s"),
    ("auth_invalid",  "API 키가 유효하지 않거나 라이선스가 만료되었습니다."),
    ("unimplemented", "이 서버는 bareun.%s 를 제공하지 않습니다. "
                      "교정·사전 검색은 맞춤법 교정(rev) 빌드에서만 동작합니다."),
    ("http_error",    "바른 서버가 오류를 돌려주었습니다 (HTTP %s)"),
    ("no_key",        "API 키가 없습니다. set_key() 또는 set_api() 로 먼저 지정하세요."),
    ("dict_np",       "-> 고유명사 사전"),
    ("dict_cp",       "-> 복합명사 사전"),
    ("dict_caret",    "-> 분리 사전"),
    ("dict_vv",       "-> 동사 사전"),
    ("dict_va",       "-> 형용사 사전"),
    ("dict_updated",  "%s : 업데이트 성공"),
]

HEADER = r'''# 사용자에게 보이는 한국어 문자열 모음.
#
# CRAN 은 R 코드에 ASCII 만 허용한다(주석은 예외다 - 실측으로 확인했다).
# 그래서 한국어 메시지는 \uXXXX 로 이스케이프해 두고, 사람이 읽을 수 있도록
# 원문을 바로 위 주석에 남긴다.
#
# 이 파일은 tools/make-messages.py 가 만든다. 직접 고치지 말고
# 그 스크립트의 MESSAGES 목록을 고친 뒤 다시 돌린다.

.messages <- list('''

FOOTER = r'''
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
}'''


def escape(s: str) -> str:
    """비ASCII 문자를 \\uXXXX 로 바꾼다."""
    return ''.join(c if ord(c) < 128 else '\\u%04X' % ord(c) for c in s)


def main() -> None:
    out = [HEADER]
    for i, (key, text) in enumerate(MESSAGES):
        out.append('  # "%s"' % text)
        comma = ',' if i < len(MESSAGES) - 1 else ''
        out.append('  %s = "%s"%s' % (key, escape(text), comma))
    out.append(')')
    out.append(FOOTER)
    with open('R/messages.R', 'w', encoding='utf-8') as f:
        f.write('\n'.join(out) + '\n')
    print('R/messages.R (%d messages)' % len(MESSAGES))


if __name__ == '__main__':
    main()
