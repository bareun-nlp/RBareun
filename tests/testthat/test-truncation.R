# 잘림 응답은 서버 없이 확인할 수 있다.
# 응답은 Connect 의 protojson 이라 camelCase 로 오고, 값이 0 이면 필드가 빠진다.

cut_response <- function() {
  list(
    origin = "a",
    truncation = list(
      originalChars = 5001L, processedChars = 4991L, droppedChars = 10L,
      droppedBeginOffset = 12287L,
      message = "request too long", cutMidWord = TRUE
    )
  )
}

test_that("잘린 응답에서 값을 꺼낸다", {
  tr <- truncation(cut_response())
  expect_true(tr$truncated)
  expect_equal(tr$original_chars, 5001L)
  expect_equal(tr$processed_chars, 4991L)
  expect_equal(tr$dropped_chars, 10L)
  expect_equal(tr$dropped_begin_offset, 12287L)
  expect_equal(tr$message, "request too long")
  expect_true(tr$cut_mid_word)
})

test_that("snake_case 표기와 객체(result)도 읽는다", {
  r <- list(result = list(truncation = list(
    original_chars = 10L, processed_chars = 6L, dropped_chars = 4L)))
  tr <- truncation(r)
  expect_true(tr$truncated)
  expect_equal(tr$dropped_chars, 4L)
  expect_true(is_truncated(r))
})

test_that("빠진 값(0)은 0 이고 cutMidWord 가 없으면 FALSE 다", {
  tr <- truncation(list(truncation = list(originalChars = 5L)))
  expect_true(tr$truncated)
  expect_equal(tr$dropped_begin_offset, 0L)
  expect_equal(tr$message, "")
  expect_false(tr$cut_mid_word)
})

test_that("자르지 않았으면 truncated 가 FALSE 이고 같은 모양을 돌려준다", {
  for (x in list(list(), list(result = list(origin = "a")), NULL)) {
    tr <- truncation(x)
    expect_false(tr$truncated)
    expect_true(is.na(tr$dropped_chars))
    expect_equal(tr$message, "")
    expect_false(is_truncated(x))
  }
  # truncation 이 객체가 아닌 값이어도 자르지 않은 것으로 본다.
  expect_false(is_truncated(list(truncation = "x")))
})

test_that("잘린 응답은 경고 조건으로 알린다", {
  w <- expect_warning(bareun:::.warn_if_truncated(cut_response()),
    class = "bareun_truncated_warning")
  expect_equal(conditionMessage(w), "request too long")
  expect_equal(w$truncation$dropped_chars, 10L)
})

test_that("서버 문구가 없으면 패키지 문구를 쓴다", {
  r <- list(truncation = list(originalChars = 5731L, processedChars = 5000L,
    droppedChars = 731L))
  w <- expect_warning(bareun:::.warn_if_truncated(r),
    class = "bareun_truncated_warning")
  expect_match(conditionMessage(w), "5000")
  expect_match(conditionMessage(w), "731")
  expect_match(conditionMessage(w), "5731")
})

test_that("자르지 않은 응답은 경고 없이 그대로 돌려준다", {
  r <- list(origin = "a")
  expect_no_warning(out <- bareun:::.warn_if_truncated(r))
  expect_identical(out, r)
})

test_that("교정·분석 호출 경로에서 경고가 올라온다", {
  # .rest_post 의 성공 경로를 가짜 서버 응답으로 시험한다.
  local_mocked_bindings(
    POST = function(...) structure(list(), class = "fake"),
    status_code = function(r) 200L,
    content = function(r) cut_response(),
    .package = "bareun"
  )
  expect_warning(
    out <- bareun:::.rest_post("h:1", "RevisionService", "CorrectError",
      list(), "k"),
    class = "bareun_truncated_warning")
  expect_equal(out$origin, "a")
})
