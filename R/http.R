# 서버 호출을 한 곳으로 모은 헬퍼.
#
# 바른 서버는 connect-go 로 gRPC·Connect·HTTP+JSON 을 한 포트에서 받는다.
# 이 패키지는 그중 HTTP+JSON 경로를 쓴다. 경로 규약은
# `POST http://<host>/bareun.<Service>/<Method>` 이고 인증은 `api-key` 헤더다.
#
# 예전에는 엔드포인트마다 POST 를 직접 부르고 `content(r)` 를 그대로 돌려줬다.
# 그래서 접속 실패·인증 실패·서버 오류가 모두 같은 모양으로 떨어져 호출한 쪽에서
# 구분할 수 없었다. 여기서 상태 코드를 보고 조건(condition) 클래스를 붙인다.

#' 바른 서버에 Connect HTTP+JSON 요청을 보낸다.
#'
#' @param host string - "주소:포트" 형태의 서버
#' @param service string - 서비스 이름 (예: "LanguageService")
#' @param method string - 메서드 이름 (예: "AnalyzeSyntax")
#' @param body list - 요청 본문. JSON 으로 직렬화된다.
#' @param apikey string - API 키
#' @return 파싱된 응답 본문(list)
#' @keywords internal
#' @importFrom httr POST add_headers content status_code
.rest_post <- function(host, service, method, body, apikey) {
  url <- paste("http://", host, "/bareun.", service, "/", method, sep = "")

  # 접속 자체가 안 되는 경우(주소 오타·서버 미기동·방화벽)를 먼저 가른다.
  # httr 은 이때 curl 오류를 그대로 던지므로 붙잡아 다시 던진다.
  r <- tryCatch(
    POST(url,
      config = add_headers("api-key" = apikey, "Content-Type" = "application/json"),
      body = body, encode = "json"),
    error = function(e) {
      .bareun_stop(
        c("bareun_connection_error", "bareun_error"),
        paste0("바른 서버에 접속하지 못했습니다 (", host, "): ", conditionMessage(e))
      )
    }
  )

  code <- status_code(r)
  if (code >= 200 && code < 300) {
    return(content(r))
  }

  # Connect 는 오류도 JSON 본문으로 돌려준다. 읽을 수 있으면 그 메시지를 쓴다.
  detail <- tryCatch({
    b <- content(r)
    if (is.list(b) && !is.null(b$message)) b$message else ""
  }, error = function(e) "")

  cls <- if (code == 401 || code == 403) {
    c("bareun_auth_error", "bareun_http_error", "bareun_error")
  } else if (code == 501) {
    # rev 빌드가 아닌 서버에 교정·사전 검색을 요청하면 여기로 온다.
    c("bareun_unimplemented_error", "bareun_http_error", "bareun_error")
  } else if (code >= 500) {
    c("bareun_server_error", "bareun_http_error", "bareun_error")
  } else {
    c("bareun_request_error", "bareun_http_error", "bareun_error")
  }

  msg <- if (code == 401 || code == 403) {
    "API 키가 유효하지 않거나 라이선스가 만료되었습니다."
  } else if (code == 501) {
    paste0("이 서버는 bareun.", service, " 를 제공하지 않습니다. ",
           "교정·사전 검색은 맞춤법 교정(rev) 빌드에서만 동작합니다.")
  } else {
    paste0("바른 서버가 오류를 돌려주었습니다 (HTTP ", code, ")")
  }
  if (nzchar(detail)) msg <- paste0(msg, ": ", detail)

  .bareun_stop(cls, msg, status = code, service = service, method = method)
}

#' 조건 클래스를 붙여 오류를 던진다.
#'
#' @param class character - 조건 클래스들. 좁은 것부터 넓은 것 순으로 준다.
#' @param message string - 사람이 읽는 오류 메시지
#' @param ... 조건 객체에 함께 실을 값들
#' @keywords internal
.bareun_stop <- function(class, message, ...) {
  stop(structure(
    class = c(class, "error", "condition"),
    list(message = message, call = NULL, ...)
  ))
}

#' 호출에 쓸 서버·API 키를 정한다.
#'
#' tagger() 로 만든 tagged 객체가 있으면 거기 담긴 값을 쓰고, 없으면 전역 설정
#' (set_api·set_server·set_key)을 쓴다. 두 방식이 섞여도 되게 한 곳에서 정리한다.
#'
#' @param tagged tagger() 결과 또는 NULL
#' @param apikey string - 비어 있으면 tagged 또는 전역 설정에서 가져온다
#' @param server string - 비어 있으면 tagged 또는 전역 설정에서 가져온다
#' @param port number - server 를 직접 준 경우에만 쓰인다
#' @return list(host=, apikey=)
#' @keywords internal
#' @importFrom curl nslookup
.resolve_conn <- function(tagged = NULL, apikey = "", server = "", port = 5656) {
  if (server != "") {
    host <- paste(nslookup(server), ":", as.character(port), sep = "")
  } else if (!is.null(tagged) && !is.null(tagged$host) && nzchar(tagged$host)) {
    host <- tagged$host
  } else {
    host <- get_server()$host
  }

  if (apikey == "") {
    if (!is.null(tagged) && !is.null(tagged$apikey) && nzchar(tagged$apikey)) {
      apikey <- tagged$apikey
    } else {
      apikey <- get_key()
    }
  }
  if (is.null(apikey) || !nzchar(apikey)) {
    .bareun_stop(c("bareun_auth_error", "bareun_error"),
      "API 키가 없습니다. set_key() 또는 set_api() 로 먼저 지정하세요.")
  }

  list(host = host, apikey = apikey)
}

#' 응답 필드를 이름 표기와 무관하게 읽는다.
#'
#' 서버는 Connect 의 protojson 으로 응답을 만들고, 그 기본 표기는 camelCase 다
#' (`revised_blocks` 가 아니라 `revisedBlocks`). 반면 요청은 두 표기를 모두 받는다.
#' 응답을 snake_case 로 읽으면 오류가 아니라 **조용히 NULL** 이 되어 교정 내역이
#' 통째로 비어 보이므로, 두 표기를 다 시도한다.
#'
#' @param x list - 파싱된 응답 조각
#' @param name string - proto 필드 이름(snake_case)
#' @return 필드 값 또는 NULL
#' @keywords internal
.field <- function(x, name) {
  if (is.null(x)) return(NULL)
  if (!is.null(x[[name]])) return(x[[name]])
  parts <- strsplit(name, "_", fixed = TRUE)[[1]]
  if (length(parts) > 1) {
    camel <- paste0(parts[1],
      paste0(toupper(substring(parts[-1], 1, 1)), substring(parts[-1], 2), collapse = ""))
    return(x[[camel]])
  }
  NULL
}
