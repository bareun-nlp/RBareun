# 교정 세션 (RevisionService.OpenSession / CloseSession / GetSessionEvents)
#
# 책 한 권처럼 긴 글은 세션을 열고 문단 단위로 나눠 보내는 것이 권장 방식이다.
# 세션 안의 요청들은 한 문서로 이어진 것으로 다뤄져, 앞 문단의 미등록어·문맥·사전·옵션이
# 뒤 문단에 이어진다. 사용자 사전과 교정 옵션은 세션을 열 때 한 번 정하고 닫을 때까지
# 바뀌지 않는다. 요청 글자 수 기준(5,000자)은 세션 안 각 요청에도 걸린다.
# 세션은 마지막 호출 뒤 10분(유휴), 열린 지 1시간(최대)이 지나면 서버가 닫는다.

#' Open a correction session
#'
#' - 긴 글을 나눠 교정하기 위한 세션을 연다
#'
#' 세션은 열 때 쓴 API 키로만 쓸 수 있고, 키당·서버당 동시 세션 수에 상한이 있다.
#' 다 쓰면 close_session() 으로 닫아 상한을 바로 돌려받는다.
#'
#' @param apikey string - Bareun user's API KEY. 비우면 set_key() 값을 쓴다.
#' @param server string - Bareun server address. 비우면 set_server() 값을 쓴다.
#' @param port number - Bareun server port
#' @param custom_dict_names character - 사용할 사용자 사전 이름들. 앞에 온 것이 우선한다.
#' @param treat_as_title bool - 입력을 기사 제목처럼 다룬다
#' @param disable_split_sentence bool - 문장 단위 분할을 하지 않는다
#' @param disable_typo_correction bool - 오탈자 교정을 끈다
#' @param disable_confusion bool - 혼동어 판정을 끈다
#' @param enable_sentence_check bool - 문장 단위 점검을 켠다
#' @return `bareun_session` 객체. `$session_id`, `$revision`(열린 직후 0),
#'   `$idle_timeout_seconds`(마지막 호출 뒤 이 시간이 지나면 닫힘),
#'   `$max_lifetime_seconds`(열린 지 이 시간이 지나면 닫힘)를 가진다.
#'   correct_grammar(session = ) 에 넘긴다.
#' @examples
#' \dontrun{
#' set_api("koba-YOUR-KEY", "localhost", 5656)
#' s <- open_session()
#' r1 <- correct_grammar("첫 부분입니다.", session = s)
#' r2 <- correct_grammar("이어지는 부분입니다.", session = s)
#' close_session(s)
#' }
#' @export
open_session <- function(apikey = "",
    server = "",
    port = 5656,
    custom_dict_names = character(0),
    treat_as_title = FALSE,
    disable_split_sentence = FALSE,
    disable_typo_correction = FALSE,
    disable_confusion = FALSE,
    enable_sentence_check = FALSE) {
  conn <- .resolve_conn(NULL, apikey, server, port)
  body <- list(config = .revision_config(treat_as_title, disable_split_sentence,
    disable_typo_correction, disable_confusion, enable_sentence_check))
  if (length(custom_dict_names) > 0) {
    body$custom_dict_names <- as.list(custom_dict_names)
  }
  res <- .rest_post(conn$host, "RevisionService", "OpenSession", body, conn$apikey)

  id <- .field(res, "session_id")
  if (is.null(id) || !nzchar(id)) {
    .bareun_stop(c("bareun_server_error", "bareun_error"), .m("session_no_id"))
  }
  session <- list(
    session_id = id,
    revision = .int64(.field(res, "session_revision")),
    idle_timeout_seconds = .int64(.field(res, "idle_timeout_seconds")),
    max_lifetime_seconds = .int64(.field(res, "max_lifetime_seconds")),
    host = conn$host,
    apikey = conn$apikey
  )
  class(session) <- "bareun_session"
  session
}

#' Close a correction session
#'
#' - 세션을 닫고 서버가 물고 있는 상태를 정리한다
#'
#' 호출하지 않아도 서버가 유휴 10분, 최대 1시간 뒤에 닫지만, 닫으면 동시 세션 수
#' 상한을 바로 돌려받는다.
#'
#' @param session open_session() 이 돌려준 세션
#' @return 닫힌 시점의 세션 개정 번호(보이지 않게 돌려준다)
#' @export
close_session <- function(session) {
  .check_session(session)
  res <- .rest_post(session$host, "RevisionService", "CloseSession",
    list(session_id = session$session_id), session$apikey)
  invisible(.int64(.field(res, "session_revision")))
}

#' Get change events of a session
#'
#' - 세션에서 일어난 변경 사건을 표로 가져온다
#'
#' 앞 호출의 답을 받은 뒤 세션이 새 단어를 확정하면 그 단어가 든 앞 답은 달라졌을
#' 수 있다. correct_grammar() 결과의 session_revision() 이 올랐으면 이 함수로
#' 무엇이 바뀌었는지 가져온다.
#'
#' @param session open_session() 이 돌려준 세션
#' @param since_revision number - 이 번호보다 큰 개정 번호의 사건만 받는다. 0 이면 처음부터.
#' @return data.frame with columns revision, kind, word. 사건이 없으면 0 행.
#' @export
session_events <- function(session, since_revision = 0) {
  .check_session(session)
  res <- .rest_post(session$host, "RevisionService", "GetSessionEvents",
    list(session_id = session$session_id,
      since_revision = as.character(as.numeric(since_revision))),
    session$apikey)
  events <- .field(res, "events")
  if (is.null(events) || length(events) == 0) {
    return(data.frame(revision = numeric(0), kind = character(0),
      word = character(0), stringsAsFactors = FALSE))
  }
  rows <- lapply(events, function(e) {
    data.frame(
      revision = .int64(.field(e, "revision")),
      kind = .or_empty(.field(e, "kind")),
      word = .or_empty(.field(e, "word")),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' Get the session revision of a correction result
#'
#' - 교정 결과를 만든 시점의 세션 개정 번호
#'
#' 세션 호출의 응답에만 있다. 이 번호가 올랐다면 세션이 새 단어를 확정한 것이니
#' session_events() 로 사건을 가져온다.
#'
#' @param revised correct_grammar() 결과
#' @return number. 세션 없이 교정한 결과면 NA.
#' @export
session_revision <- function(revised) {
  v <- .field(revised$result, "session_revision")
  if (is.null(v)) NA_real_ else .int64(v)
}

#' 세션 객체인지 확인한다.
#'
#' @param session 확인할 값
#' @keywords internal
.check_session <- function(session) {
  if (!inherits(session, "bareun_session") || is.null(session$session_id) ||
      !nzchar(session$session_id)) {
    .bareun_stop(c("bareun_argument_error", "bareun_error"), .m("need_session"))
  }
  invisible(session)
}

#' int64 값을 숫자로 읽는다.
#'
#' protojson 은 int64 를 문자열("12")로 보내고, 0 이면 필드를 뺀다.
#'
#' @param x 문자열·숫자·NULL
#' @return numeric. NULL 이면 0.
#' @keywords internal
.int64 <- function(x) {
  if (is.null(x) || length(x) == 0) 0 else as.numeric(x)[1]
}

#' 세션 오류의 이유(reason)를 읽는다.
#'
#' 서버는 ErrorInfo(domain "bareun.ai/session")의 reason 에 SESSION_NOT_FOUND,
#' SESSION_EXPIRED, SESSION_STORE_UNAVAILABLE 를 싣고 메시지 머리에도 같은 이유를
#' 적는다. 상세가 없으면 메시지 머리에서 읽는다.
#'
#' @param body 오류 응답 본문(list)
#' @return reason 문자열. 세션 오류가 아니면 "".
#' @keywords internal
.session_reason <- function(body) {
  if (!is.list(body)) return("")
  for (d in body$details) {
    reason <- d$debug$reason
    if (is.character(reason) && length(reason) == 1 && startsWith(reason, "SESSION_")) {
      return(reason)
    }
  }
  msg <- body$message
  if (is.character(msg) && length(msg) == 1) {
    m <- regmatches(msg, regexpr("SESSION_[A-Z_]+", msg))
    if (length(m) == 1) return(m)
  }
  ""
}
