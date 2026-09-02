# 응답을 표로 바꾸는 부분은 서버 없이 확인할 수 있다.

test_that("결과가 없으면 빈 표를 돌려준다", {
  out <- senses(list(result = list()))
  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 0)
  expect_equal(names(out),
    c("sentence", "morph", "tag", "sense_no", "meaning", "probability"))
})

test_that("sense 가 붙은 형태소만 표에 넣는다", {
  # 서버 응답은 camelCase 로 온다. 그 표기를 그대로 넣어 확인한다.
  tagged <- list(result = list(sentences = list(
    list(tokens = list(
      list(morphemes = list(
        list(text = list(content = "나"), tag = "NP"),
        list(text = list(content = "밤"), tag = "NNG",
             sense = list(senseNo = 2, meaning = "밤나무의 열매.", probability = 0.55))
      ))
    ))
  )))
  out <- senses(tagged)
  expect_equal(nrow(out), 1)
  expect_equal(out$morph, "밤")
  expect_equal(out$tag, "NNG")
  expect_equal(out$sense_no, 2L)
  expect_equal(out$probability, 0.55)
})

test_that("snake_case 응답도 읽는다", {
  tagged <- list(result = list(sentences = list(
    list(tokens = list(
      list(morphemes = list(
        list(text = list(content = "먹"), tag = "VV",
             sense = list(sense_no = 2, meaning = "음식을 먹다."))
      ))
    ))
  )))
  out <- senses(tagged)
  expect_equal(out$sense_no, 2L)
  # probability 가 빠져 있어도 표가 깨지지 않아야 한다.
  expect_equal(out$probability, 0)
})
