# 동형이의어 의미 구분(WSD) 결과 읽기
#
# tagger(with_sense = TRUE) 로 분석하면 형태소마다 sense 가 붙는다.
# pos()·morphs() 는 표층형과 품사만 다루므로, 어깨번호와 뜻풀이는 여기서 꺼낸다.

#' Get word sense disambiguation results as a data frame
#'
#' - 동형이의어 의미 구분 결과를 표로 만든다
#'
#' `tagger(with_sense = TRUE)` 로 분석한 결과에만 값이 들어 있다. 서버에 WSD 모델이
#' 실려 있지 않거나 `with_sense` 를 켜지 않았으면 빈 표가 나온다.
#'
#' @param tagged tagger() 결과
#' @return returns data.frame with columns sentence, morph, tag, sense_no,
#'   meaning, probability
#' @examples
#' \dontrun{
#' set_api("koba-YOUR-KEY", "localhost", 5656)
#' t <- tagger("나는 밤에 밤을 먹었다.", with_sense = TRUE)
#' senses(t)
#' }
#' @export
senses <- function(tagged) {
  empty <- data.frame(sentence = integer(0), morph = character(0), tag = character(0),
    sense_no = integer(0), meaning = character(0), probability = numeric(0),
    stringsAsFactors = FALSE)

  sentences <- .field(tagged$result, "sentences")
  if (is.null(sentences) || length(sentences) == 0) {
    return(empty)
  }

  rows <- list()
  for (si in seq_along(sentences)) {
    tokens <- .field(sentences[[si]], "tokens")
    if (is.null(tokens)) next
    for (tk in tokens) {
      morphemes <- .field(tk, "morphemes")
      if (is.null(morphemes)) next
      for (m in morphemes) {
        sense <- .field(m, "sense")
        # sense 가 없는 형태소가 대부분이다(중의성이 없거나 모델이 유보한 자리).
        # 표에 빈 줄로 넣으면 실제로 판정된 자리를 찾기 어려워지므로 건너뛴다.
        if (is.null(sense)) next
        rows[[length(rows) + 1]] <- data.frame(
          sentence = si,
          morph = .or_empty(.field(m$text, "content")),
          tag = .or_empty(.field(m, "tag")),
          sense_no = as.integer(.or_zero(.field(sense, "sense_no"))),
          meaning = .or_empty(.field(sense, "meaning")),
          probability = as.numeric(.or_zero(.field(sense, "probability"))),
          stringsAsFactors = FALSE
        )
      }
    }
  }
  if (length(rows) == 0) {
    return(empty)
  }
  do.call(rbind, rows)
}

#' NULL 이면 0 으로 바꾼다.
#'
#' JSON 은 기본값(0)인 숫자 필드를 빼고 오므로 그 자리를 메운다.
#'
#' @param x 값 또는 NULL
#' @return numeric
#' @keywords internal
.or_zero <- function(x) {
  if (is.null(x) || length(x) == 0) 0 else x[1]
}
