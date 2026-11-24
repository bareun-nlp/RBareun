# 잘림(truncation) 응답 처리
#
# 서버는 요청 글이 서버 기준을 넘으면 거절하지 않고 앞부분만 처리한 뒤, 응답의
# `truncation` 에 무엇을 버렸는지 싣는다. 기준 이하의 요청에는 이 필드가 없다.
# 바른 엔진 자체에는 제약이 없고, 클라우드 서비스가 용량 때문에 기준(지금은 5,000자)을 둔다.
# 기준은 운영 상황에 따라 바뀔 수 있고 자체 서버는 자르지 않을 수도 있다. 그래서 코드에 숫자를 박지 않고 이 필드로 판단한다.

#' 잘림 정보를 꺼낸다.
#'
#' 서버가 요청 글을 길다고 보고 앞부분만 처리했을 때 그 내용을 돌려준다.
#' 자르지 않았으면 `truncated = FALSE` 인 같은 모양의 목록을 돌려주므로,
#' 호출한 쪽에서 NULL 을 따로 살필 필요가 없다.
#'
#' @param x tagger()·correct_grammar() 가 돌려준 객체, 또는 서버 응답 목록
#' @return 다음 값을 가진 list.
#'   `truncated`(잘렸는지), `original_chars`(보낸 글자 수),
#'   `processed_chars`(처리한 글자 수), `dropped_chars`(버린 글자 수),
#'   `dropped_begin_offset`(버린 구간이 시작하는 위치. 요청 글의 처음 기준,
#'   단위는 UTF8 바이트), `message`(서버의 안내 문구),
#'   `cut_mid_word`(문장·공백 자리를 못 찾아 글자 중간에서 끊었는지).
#'   자르지 않았으면 글자 수는 NA, 문구는 빈 문자열이다.
#' @examples
#' \dontrun{
#' t <- tagger(very_long_text)
#' tr <- truncation(t)
#' if (tr$truncated) cat(tr$dropped_chars, "chars were not processed\n")
#' }
#' @export
truncation <- function(x) {
  res <- if (is.list(x) && !is.null(x$result)) x$result else x
  tr <- .field(res, "truncation")
  if (is.null(tr) || !is.list(tr)) {
    return(list(truncated = FALSE, original_chars = NA_integer_,
      processed_chars = NA_integer_, dropped_chars = NA_integer_,
      dropped_begin_offset = NA_integer_, message = "",
      cut_mid_word = FALSE))
  }
  num <- function(name) {
    v <- .field(tr, name)
    # 0 인 값은 JSON 에서 빠져 오므로 NULL 이면 0 이다.
    if (is.null(v)) 0L else as.integer(v)
  }
  list(
    truncated = TRUE,
    original_chars = num("original_chars"),
    processed_chars = num("processed_chars"),
    dropped_chars = num("dropped_chars"),
    dropped_begin_offset = num("dropped_begin_offset"),
    message = .or_empty(.field(tr, "message")),
    cut_mid_word = isTRUE(.field(tr, "cut_mid_word"))
  )
}

#' 응답이 잘렸는지 본다.
#'
#' @param x tagger()·correct_grammar() 가 돌려준 객체, 또는 서버 응답 목록
#' @return logical
#' @export
is_truncated <- function(x) {
  truncation(x)$truncated
}

#' 잘린 응답이면 경고를 올린다.
#'
#' 조용히 앞부분만 돌려주면 뒷부분이 분석·교정된 줄 알고 넘어가기 쉽다.
#' 경고는 `bareun_truncated_warning` 클래스라 suppressWarnings() 나
#' withCallingHandlers() 로 다룰 수 있다.
#'
#' @param res 서버 응답 목록
#' @return res 를 그대로 돌려준다
#' @keywords internal
.warn_if_truncated <- function(res) {
  tr <- truncation(res)
  if (tr$truncated) {
    msg <- if (nzchar(tr$message)) {
      tr$message
    } else {
      .m("truncated", tr$processed_chars, tr$dropped_chars, tr$original_chars)
    }
    warning(structure(
      class = c("bareun_truncated_warning", "warning", "condition"),
      list(message = msg, call = NULL, truncation = tr)
    ))
  }
  res
}
