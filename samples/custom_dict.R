# 사용자 사전 사용 예제

library(RProtoBuf)
library(bareun)

example <- "sample"
api_key <- "YOUR_API_KEY"

make_dict <- function(apikey = api_key, domain = example) {
    t <- tagger(apikey = apikey)
    np <- c("청하", "트와이스", "티키타카", "TIKITAKA", "오마이걸")
    cp <- c("자유여행", "방역당국", "코로나19", "주술부", "완전주의")
    caret <- c("주어^역할", "주어^술어^구조", "하급^공무원")
    vv <- c("카톡하다", "인스타하다")
    va <- c("혜자스럽다", "창렬하다")
    make_custom_dict(t, domain, np, cp, caret, vv, va)
    print_dict()
}

print_dict <- function(apikey = api_key, domain = example) {
    t <- tagger(apikey = apikey)
    get_dict(t, domain)
    print_dict_all(t)
    t
}

t <- tagger(apikey = api_key, domain = example)
morphs(t, "효정이는 오마이걸의 리덥니다.")
