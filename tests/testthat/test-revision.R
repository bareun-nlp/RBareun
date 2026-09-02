# 응답을 다루는 부분은 서버 없이 확인할 수 있다.

test_that("빈 입력은 서버를 부르기 전에 막는다", {
  expect_error(correct_grammar(""), class = "bareun_argument_error")
  expect_error(correct_grammar(character(0)), class = "bareun_argument_error")
})

test_that("교정문을 꺼낸다", {
  r <- list(text = "아버지가방에들어가신다",
            result = list(revised = "아버지가 방에 들어가신다"))
  expect_equal(revised_text(r), "아버지가 방에 들어가신다")
})

test_that("고칠 것이 없어 revised 가 비면 원문을 돌려준다", {
  # 서버는 기본값인 필드를 JSON 에서 빼고 보낸다. 그때 원문이 답이다.
  r <- list(text = "정상 문장입니다.", result = list())
  expect_equal(revised_text(r), "정상 문장입니다.")
})

test_that("교정 내역이 없으면 빈 표를 돌려준다", {
  r <- list(result = list(revised_blocks = list()))
  out <- revisions(r)
  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 0)
  expect_equal(names(out), c("origin", "revised", "category", "help"))
})

test_that("교정 내역을 표로 만든다", {
  r <- list(result = list(revised_blocks = list(
    list(origin = list(content = "아버지가방에"),
         revised = "아버지가 방에",
         revisions = list(list(category = "SPACING", help_id = "spacing-1"))),
    list(origin = list(content = "들어가신다"),
         revised = "들어가신다")
  )))
  out <- revisions(r)
  expect_equal(nrow(out), 2)
  expect_equal(out$origin[1], "아버지가방에")
  expect_equal(out$revised[1], "아버지가 방에")
  expect_equal(out$category[1], "SPACING")
  # 후보가 없는 블럭은 빈 문자열로 채워 표가 깨지지 않아야 한다.
  expect_equal(out$category[2], "")
})

test_that("없는 값은 빈 문자열이 된다", {
  expect_equal(bareun:::.or_empty(NULL), "")
  expect_equal(bareun:::.or_empty(list()), "")
  expect_equal(bareun:::.or_empty("가"), "가")
})
