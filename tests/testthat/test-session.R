# 세션은 서버 없이 가짜 응답으로 확인한다.
# 응답은 protojson 이라 camelCase 이고, int64 는 문자열로 오며, 0 이면 필드가 빠진다.

fake_session <- function() {
  s <- list(session_id = "sid-1", revision = 0, host = "h:1", apikey = "k")
  class(s) <- "bareun_session"
  s
}

test_that("세션을 열면 세션 객체를 돌려준다", {
  captured <- NULL
  local_mocked_bindings(
    .rest_post = function(host, service, method, body, apikey) {
      captured <<- list(host = host, service = service, method = method,
        body = body, apikey = apikey)
      list(sessionId = "sid-1", idleTimeoutSeconds = 600L,
        maxLifetimeSeconds = 3600L)
    }, .package = "bareun")
  s <- open_session(apikey = "k", server = "127.0.0.1", port = 7,
    custom_dict_names = c("a", "b"), disable_confusion = TRUE)
  expect_s3_class(s, "bareun_session")
  expect_equal(s$session_id, "sid-1")
  expect_equal(s$revision, 0)  # 0 이라 필드가 빠져 온다
  expect_equal(s$idle_timeout_seconds, 600)
  expect_equal(s$max_lifetime_seconds, 3600)
  expect_equal(captured$method, "OpenSession")
  expect_equal(captured$service, "RevisionService")
  expect_equal(captured$body$custom_dict_names, list("a", "b"))
  expect_true(captured$body$config$disable_confusion)
})

test_that("사전 이름이 없으면 요청에 싣지 않는다", {
  captured <- NULL
  local_mocked_bindings(
    .rest_post = function(host, service, method, body, apikey) {
      captured <<- body
      list(sessionId = "sid-1")
    }, .package = "bareun")
  open_session(apikey = "k")
  expect_null(captured$custom_dict_names)
})

test_that("서버가 세션 ID 를 안 주면 오류다", {
  local_mocked_bindings(.rest_post = function(...) list(), .package = "bareun")
  expect_error(open_session(apikey = "k"), class = "bareun_server_error")
})

test_that("세션으로 교정하면 session_id 만 싣고 옵션은 싣지 않는다", {
  captured <- NULL
  local_mocked_bindings(
    .rest_post = function(host, service, method, body, apikey) {
      captured <<- list(host = host, body = body, apikey = apikey)
      list(revised = "교정문", sessionRevision = "3")
    }, .package = "bareun")
  s <- fake_session()
  r <- correct_grammar("문장", session = s, custom_dict_names = "x")
  expect_equal(captured$body$session_id, "sid-1")
  expect_null(captured$body$config)
  expect_null(captured$body$custom_dict_names)
  expect_equal(captured$host, "h:1")
  expect_equal(captured$apikey, "k")
  expect_equal(revised_text(r), "교정문")
  expect_equal(session_revision(r), 3)
  expect_identical(r$session, s)
})

test_that("세션 없이 교정한 결과의 개정 번호는 NA 다", {
  r <- list(result = list(revised = "x"))
  expect_true(is.na(session_revision(r)))
})

test_that("세션이 아닌 값은 서버를 부르기 전에 막는다", {
  expect_error(correct_grammar("문장", session = "sid"),
    class = "bareun_argument_error")
  expect_error(close_session(list()), class = "bareun_argument_error")
  expect_error(session_events(NULL), class = "bareun_argument_error")
  bad <- structure(list(session_id = ""), class = "bareun_session")
  expect_error(close_session(bad), class = "bareun_argument_error")
})

test_that("세션을 닫으면 개정 번호를 보이지 않게 돌려준다", {
  captured <- NULL
  local_mocked_bindings(
    .rest_post = function(host, service, method, body, apikey) {
      captured <<- list(method = method, body = body)
      list(sessionRevision = "2")
    }, .package = "bareun")
  expect_invisible(out <- close_session(fake_session()))
  expect_equal(out, 2)
  expect_equal(captured$method, "CloseSession")
  expect_equal(captured$body$session_id, "sid-1")
})

test_that("세션 사건을 표로 만든다", {
  captured <- NULL
  local_mocked_bindings(
    .rest_post = function(host, service, method, body, apikey) {
      captured <<- list(method = method, body = body)
      list(sessionRevision = "2", events = list(
        list(revision = "1", kind = "SESSION_EVENT_KIND_WORD_CONFIRMED",
          word = "가나다"),
        list(revision = "2", word = "라마바")))
    }, .package = "bareun")
  out <- session_events(fake_session(), since_revision = 0)
  expect_equal(nrow(out), 2)
  expect_equal(names(out), c("revision", "kind", "word"))
  expect_equal(out$revision, c(1, 2))
  expect_equal(out$word, c("가나다", "라마바"))
  expect_equal(out$kind[2], "")
  expect_equal(captured$method, "GetSessionEvents")
  expect_equal(captured$body$since_revision, "0")
})

test_that("사건이 없으면 빈 표를 돌려준다", {
  local_mocked_bindings(.rest_post = function(...) list(), .package = "bareun")
  out <- session_events(fake_session())
  expect_equal(nrow(out), 0)
  expect_equal(names(out), c("revision", "kind", "word"))
})

test_that("세션 오류는 reason 이 붙은 조건으로 올라온다", {
  err_body <- list(code = "not_found", message = "SESSION_EXPIRED: 세션 수명이 다했습니다",
    details = list(list(type = "google.rpc.ErrorInfo",
      debug = list(reason = "SESSION_EXPIRED", domain = "bareun.ai/session"))))
  local_mocked_bindings(
    POST = function(...) structure(list(), class = "fake"),
    status_code = function(r) 404L,
    content = function(r) err_body,
    .package = "bareun")
  e <- expect_error(
    bareun:::.rest_post("h:1", "RevisionService", "CorrectError", list(), "k"),
    class = "bareun_session_error")
  expect_equal(e$reason, "SESSION_EXPIRED")
  expect_s3_class(e, "bareun_http_error")
  expect_equal(e$status, 404L)
  expect_match(conditionMessage(e), "SESSION_EXPIRED")
})

test_that("세션 오류인데 메시지가 없어도 reason 은 남는다", {
  local_mocked_bindings(
    POST = function(...) structure(list(), class = "fake"),
    status_code = function(r) 503L,
    content = function(r) list(details = list(list(
      debug = list(reason = "SESSION_STORE_UNAVAILABLE")))),
    .package = "bareun")
  e <- expect_error(
    bareun:::.rest_post("h:1", "RevisionService", "CorrectError", list(), "k"),
    class = "bareun_session_error")
  expect_equal(e$reason, "SESSION_STORE_UNAVAILABLE")
})

test_that("상세가 없으면 메시지 머리에서 reason 을 읽는다", {
  f <- bareun:::.session_reason
  expect_equal(f(list(message = "SESSION_NOT_FOUND: 모르는 세션")), "SESSION_NOT_FOUND")
  expect_equal(f(list(message = "다른 오류")), "")
  expect_equal(f(list(details = list(list(debug = list(reason = "OTHER"))),
    message = "x")), "")
  expect_equal(f(NULL), "")
  expect_equal(f("문자열"), "")
})

test_that("int64 는 숫자로 읽고 없으면 0 이다", {
  expect_equal(bareun:::.int64("12"), 12)
  expect_equal(bareun:::.int64(NULL), 0)
  expect_equal(bareun:::.int64(list()), 0)
})

test_that("세션 없이 교정하면 옵션과 사전을 싣고 session_id 는 싣지 않는다", {
  captured <- NULL
  local_mocked_bindings(
    .rest_post = function(host, service, method, body, apikey) {
      captured <<- body
      list(revised = "x")
    }, .package = "bareun")
  r <- correct_grammar("문장", apikey = "k", server = "127.0.0.1",
    custom_dict_names = c("a", "b"), treat_as_title = TRUE)
  expect_null(captured$session_id)
  expect_true(captured$config$treat_as_title)
  expect_equal(captured$custom_dict_names, list("a", "b"))
  expect_null(r$session)

  correct_grammar("문장", apikey = "k", server = "127.0.0.1")
  expect_null(captured$custom_dict_names)
})
