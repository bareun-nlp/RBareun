# 접속 정보 결정과 오류 조건은 서버 없이 확인할 수 있다.

test_that("API 키가 없으면 부르기 전에 막는다", {
  old <- get_key()
  on.exit(set_key(old), add = TRUE)
  set_key("")
  expect_error(bareun:::.resolve_conn(), class = "bareun_auth_error")
})

test_that("tagged 객체의 접속 정보를 쓴다", {
  tagged <- list(host = "example:5656", apikey = "koba-TEST")
  conn <- bareun:::.resolve_conn(tagged)
  expect_equal(conn$host, "example:5656")
  expect_equal(conn$apikey, "koba-TEST")
})

test_that("직접 준 인자가 tagged 보다 우선한다", {
  tagged <- list(host = "example:5656", apikey = "koba-TEST")
  conn <- bareun:::.resolve_conn(tagged, apikey = "koba-OTHER")
  expect_equal(conn$apikey, "koba-OTHER")
})

test_that("전역 설정으로 넘어간다", {
  old_key <- get_key()
  on.exit(set_key(old_key), add = TRUE)
  set_key("koba-GLOBAL")
  set_server("global:5656", "rest")
  conn <- bareun:::.resolve_conn()
  expect_equal(conn$host, "global:5656")
  expect_equal(conn$apikey, "koba-GLOBAL")
})

test_that("접속 실패는 connection 오류로 구분된다", {
  # 아무것도 듣고 있지 않은 포트로 보내 접속 단계에서 실패시킨다.
  expect_error(
    bareun:::.rest_post("127.0.0.1:1", "LanguageService", "AnalyzeSyntax",
                        list(), "koba-TEST"),
    class = "bareun_connection_error"
  )
})

test_that("응답 필드를 camelCase 로도 snake_case 로도 읽는다", {
  expect_equal(bareun:::.field(list(revisedBlocks = 1), "revised_blocks"), 1)
  expect_equal(bareun:::.field(list(revised_blocks = 2), "revised_blocks"), 2)
  expect_equal(bareun:::.field(list(revised = 3), "revised"), 3)
  expect_null(bareun:::.field(list(), "revised_blocks"))
  expect_null(bareun:::.field(NULL, "revised"))
})
