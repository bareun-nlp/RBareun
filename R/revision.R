# 맞춤법·띄어쓰기 교정 (RevisionService)
#
# 서버의 rev 빌드에서만 제공된다. 형태소 분석 전용 빌드에 요청하면
# bareun_unimplemented_error 로 떨어진다.

#' Correct spelling and spacing errors
#'
#' - 문장의 맞춤법·띄어쓰기를 교정한다
#'
#' @param text string - 교정할 문장. 여러 문장이면 줄바꿈으로 나눠 넣는다.
#' @param apikey string - Bareun user's API KEY. 비우면 set_key() 값을 쓴다.
#' @param server string - Bareun server address. 비우면 set_server() 값을 쓴다.
#' @param port number - Bareun server port
#' @param custom_dict_names character - 사용할 사용자 사전 이름들. 앞에 온 것이 우선한다.
#' @param treat_as_title bool - 입력을 기사 제목처럼 다룬다
#' @param disable_split_sentence bool - 문장 단위 분할을 하지 않는다
#' @param disable_typo_correction bool - 오탈자 교정을 끈다
#' @param disable_confusion bool - 혼동어 판정을 끈다
#' @param enable_sentence_check bool - 문장 단위 점검을 켠다
#' @param session open_session() 이 돌려준 세션. 주면 그 세션으로 교정한다.
#'   긴 글을 여러 번에 나눠 교정할 때 앞 호출에서 본 미등록 단어를 뒤 호출에서
#'   알려진 말로 쓰게 한다. 이때 서버와 API 키는 세션에 담긴 값을 쓰고,
#'   custom_dict_names 와 교정 옵션은 **무시**된다(세션을 열 때 정한 값이 쓰인다).
#' @return returns revised object. `$revised` 에 교정문, `$origin` 에 원문,
#'   `$revised_blocks` 에 어떤 자리가 왜 바뀌었는지가 들어 있다.
#' @examples
#' \dontrun{
#' set_api("koba-YOUR-KEY", "localhost", 5656)
#' r <- correct_grammar("아버지가방에들어가신다")
#' revised_text(r)
#' }
#' @export
correct_grammar <- function(text,
    apikey = "",
    server = "",
    port = 5656,
    custom_dict_names = character(0),
    treat_as_title = FALSE,
    disable_split_sentence = FALSE,
    disable_typo_correction = FALSE,
    disable_confusion = FALSE,
    enable_sentence_check = FALSE,
    session = NULL) {
  if (!is.character(text) || length(text) != 1 || !nzchar(text)) {
    .bareun_stop(c("bareun_argument_error", "bareun_error"),
      .m("need_text"))
  }
  if (!is.null(session)) .check_session(session)
  conn <- .resolve_conn(session, apikey, server, port)

  body <- list(
    document = list(content = text, language = "ko_KR"),
    encoding_type = "UTF8"
  )
  if (is.null(session)) {
    body$config <- .revision_config(treat_as_title, disable_split_sentence,
      disable_typo_correction, disable_confusion, enable_sentence_check)
    # 빈 벡터를 그대로 넣으면 JSON 에서 {} 로 나가 서버가 거부한다. 값이 있을 때만 싣는다.
    if (length(custom_dict_names) > 0) {
      body$custom_dict_names <- as.list(custom_dict_names)
    }
  } else {
    # 세션이 있으면 서버는 사전·옵션을 세션에서 정한 값으로 쓰고 요청 값은 무시한다.
    body$session_id <- session$session_id
  }

  response <- .rest_post(conn$host, "RevisionService", "CorrectError", body, conn$apikey)

  revised <- list(
    text = text,
    result = response,
    host = conn$host,
    apikey = conn$apikey,
    session = session
  )
  class(revised) <- "revised"
  revised
}

#' 교정기 옵션을 요청 본문의 config 로 만든다.
#'
#' correct_grammar() 와 open_session() 이 같은 옵션을 쓰므로 한 곳에 둔다.
#'
#' @return list
#' @keywords internal
.revision_config <- function(treat_as_title, disable_split_sentence,
    disable_typo_correction, disable_confusion, enable_sentence_check) {
  list(
    treat_as_title = treat_as_title,
    disable_split_sentence = disable_split_sentence,
    disable_typo_correction = disable_typo_correction,
    disable_confusion = disable_confusion,
    enable_sentence_check = enable_sentence_check
  )
}

#' Get the corrected sentence
#'
#' - 교정된 문장만 꺼낸다
#'
#' @param revised correct_grammar() 결과
#' @return returns corrected text as string
#' @export
revised_text <- function(revised) {
  if (is.null(revised$result) || is.null(.field(revised$result, "revised"))) {
    # 고칠 것이 없으면 서버가 revised 를 비워 보낼 수 있다. 이때는 원문이 답이다.
    return(revised$text)
  }
  .field(revised$result, "revised")
}

#' Get corrections as a data frame
#'
#' - 무엇이 어떻게 바뀌었는지 표로 만든다
#'
#' @param revised correct_grammar() 결과
#' @return returns data.frame with columns origin, revised, category, help
#' @export
revisions <- function(revised) {
  blocks <- .field(revised$result, "revised_blocks")
  if (is.null(blocks) || length(blocks) == 0) {
    return(data.frame(origin = character(0), revised = character(0),
      category = character(0), help = character(0), stringsAsFactors = FALSE))
  }

  rows <- lapply(blocks, function(b) {
    # revisions 는 후보 목록이다. 대표 교정은 block$revised 이므로 그것을 쓰고,
    # 카테고리·도움말은 첫 후보에서 가져온다(대표 교정이 나온 근거).
    revs <- .field(b, "revisions")
    first <- if (!is.null(revs) && length(revs) > 0) revs[[1]] else list()
    data.frame(
      origin = .or_empty(.field(b$origin, "content")),
      revised = .or_empty(.field(b, "revised")),
      category = .or_empty(.field(first, "category")),
      help = .or_empty(.field(first, "help_id")),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

#' NULL 이면 빈 문자열로 바꾼다.
#'
#' JSON 응답은 기본값인 필드를 아예 빼고 오므로, 표를 만들 때 길이가 0 이 되어
#' data.frame 이 깨진다. 그 자리를 메운다.
#'
#' @param x 값 또는 NULL
#' @return string
#' @keywords internal
.or_empty <- function(x) {
  if (is.null(x) || length(x) == 0) "" else as.character(x)[1]
}
