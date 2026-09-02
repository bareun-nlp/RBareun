# 우리말샘 사전 자소(음소) 검색 (DictSearchService)
#
# 완성형 한글로는 "초성이 ㅅ 이고 종성이 ㄴ 인 음절" 같은 조건을 쓸 수 없다.
# 서버가 슬롯 패턴을 NFD 정규식으로 바꿔 사전을 훑는다.
# 교정(rev) 빌드에서만 제공된다.

#' Search the Urimalsaem dictionary with jamo slot patterns
#'
#' - 자소 패턴으로 우리말샘 표제어를 찾는다
#'
#' 패턴 문법 요약:
#' \itemize{
#'   \item `다` 같은 음절은 그 음절 그대로
#'   \item `{초/중/종}` 은 한 음절의 자소 조건. 비우거나 `.` 이면 아무거나
#'   \item 종성 자리의 `-` 는 받침 없음, `+` 는 받침 있음
#'   \item `*` 는 음절 0개 이상, `?` 는 음절 정확히 1개
#' }
#' 예: `"{ㅅ//ㄴ}다"` 는 신다, `"*{//ㅎ}다"` 는 낳다·넣다·놓다.
#'
#' @param pattern string - 자소 슬롯 패턴
#' @param anchor string - 패턴이 걸리는 위치. "word"(기본)·"prefix"·"suffix"·"contains"
#' @param pos character - 품사 필터. 우리말샘 표기("동사"·"명사") 또는 별칭("용언"·"체언")
#' @param std_only bool - TRUE 면 비표준어·방언·북한어를 뺀다
#' @param limit number - 최대 표제어 수. 0 이면 서버 기본값 100, 상한 1000
#' @param offset number - 건너뛸 표제어 수
#' @param with_definition bool - 뜻풀이·용례까지 받는다. 응답이 크게 늘어난다
#' @param count_only bool - 항목 없이 개수만 센다
#' @param apikey string - Bareun user's API KEY
#' @param server string - Bareun server address
#' @param port number - Bareun server port
#' @return returns list with entries, total_matched, total_senses, regex, elapsed_ms
#' @examples
#' \dontrun{
#' set_api("koba-YOUR-KEY", "localhost", 5656)
#' r <- search_dict("{ㅅ//ㄴ}다", pos = "동사")
#' dict_words(r)
#' }
#' @export
search_dict <- function(pattern,
    anchor = "word",
    pos = character(0),
    std_only = FALSE,
    limit = 0,
    offset = 0,
    with_definition = FALSE,
    count_only = FALSE,
    apikey = "",
    server = "",
    port = 5656) {
  if (!is.character(pattern) || length(pattern) != 1 || !nzchar(pattern)) {
    .bareun_stop(c("bareun_argument_error", "bareun_error"),
      .m("need_pattern"))
  }

  body <- list(
    pattern = pattern,
    anchor = .dict_anchor(anchor),
    std_only = std_only,
    limit = limit,
    offset = offset,
    with_definition = with_definition,
    count_only = count_only
  )
  if (length(pos) > 0) {
    body$pos <- as.list(pos)
  }

  conn <- .resolve_conn(NULL, apikey, server, port)
  .rest_post(conn$host, "DictSearchService", "SearchDict", body, conn$apikey)
}

#' Get matched words as a character vector
#'
#' - 검색 결과에서 표제어만 꺼낸다
#'
#' @param result search_dict() 결과
#' @return returns character vector of words
#' @export
dict_words <- function(result) {
  entries <- .field(result, "entries")
  if (is.null(entries) || length(entries) == 0) {
    return(character(0))
  }
  vapply(entries, function(e) .or_empty(.field(e, "word")), character(1))
}

#' anchor 인자를 proto enum 이름으로 바꾼다.
#'
#' R 쪽에서는 짧은 말("suffix")로 쓰게 하고, 서버가 받는 긴 enum 이름은 여기서 만든다.
#' 사용자가 enum 이름을 그대로 줘도 통과시킨다.
#'
#' @param anchor string
#' @return string - DICT_SEARCH_ANCHOR_* 중 하나
#' @keywords internal
.dict_anchor <- function(anchor) {
  known <- c(word = "DICT_SEARCH_ANCHOR_WORD",
             prefix = "DICT_SEARCH_ANCHOR_PREFIX",
             suffix = "DICT_SEARCH_ANCHOR_SUFFIX",
             contains = "DICT_SEARCH_ANCHOR_CONTAINS")
  key <- tolower(as.character(anchor)[1])
  if (key %in% names(known)) {
    return(unname(known[key]))
  }
  if (as.character(anchor)[1] %in% unname(known)) {
    return(as.character(anchor)[1])
  }
  .bareun_stop(c("bareun_argument_error", "bareun_error"),
    .m("bad_anchor", anchor))
}
