# anchor 변환과 인자 검증은 서버 없이 확인할 수 있다.

test_that("짧은 이름을 proto enum 으로 바꾼다", {
  expect_equal(bareun:::.dict_anchor("word"), "DICT_SEARCH_ANCHOR_WORD")
  expect_equal(bareun:::.dict_anchor("prefix"), "DICT_SEARCH_ANCHOR_PREFIX")
  expect_equal(bareun:::.dict_anchor("suffix"), "DICT_SEARCH_ANCHOR_SUFFIX")
  expect_equal(bareun:::.dict_anchor("contains"), "DICT_SEARCH_ANCHOR_CONTAINS")
})

test_that("대소문자를 가리지 않는다", {
  expect_equal(bareun:::.dict_anchor("SUFFIX"), "DICT_SEARCH_ANCHOR_SUFFIX")
})

test_that("enum 이름을 그대로 줘도 통과한다", {
  expect_equal(bareun:::.dict_anchor("DICT_SEARCH_ANCHOR_CONTAINS"),
               "DICT_SEARCH_ANCHOR_CONTAINS")
})

test_that("모르는 anchor 는 인자 오류로 떨어진다", {
  expect_error(bareun:::.dict_anchor("middle"), class = "bareun_argument_error")
})

test_that("빈 패턴은 서버를 부르기 전에 막는다", {
  expect_error(search_dict(""), class = "bareun_argument_error")
  expect_error(search_dict(character(0)), class = "bareun_argument_error")
  expect_error(search_dict(c("가", "나")), class = "bareun_argument_error")
})

test_that("결과가 비면 빈 문자 벡터를 돌려준다", {
  expect_equal(dict_words(list(entries = list())), character(0))
  expect_equal(dict_words(list()), character(0))
})

test_that("표제어만 뽑아 낸다", {
  result <- list(entries = list(
    list(word = "신다", pos = "동사"),
    list(word = "싣다", pos = "동사")
  ))
  expect_equal(dict_words(result), c("신다", "싣다"))
})
