# package bareun: Bareun R client

library(curl)
library(httr)
library(jsonlite)

tag_labels <- c("EC", "EF", "EP", "ETM", "ETN", "IC",
                "JC", "JKB", "JKC", "JKG", "JKO", "JKQ", "JKS", "JKV", "JX",
                "MAG", "MAJ", "MMA", "MMD", "MMN",
                "NA", "NF", "NNB", "NNG", "NNP", "NP", "NR", "NV",
                "SE", "SF", "SH", "SL", "SN", "SO", "SP", "SS", "SW",
                "VA", "VCN", "VCP", "VV", "VX",
                "XPN", "XR", "XSA", "XSN", "XSV", "_SP_", "PAD")

barenv <- new.env()

#' save api key
#'
#' @param apikey string - bareun user's api key
#' @export
set_key <- function(apikey) {
  barenv$apikey <- apikey
}

#' get api key
#'
#' @export
get_key <- function() {
  barenv$apikey
}

#' save server config
#'
#' @param host string - bareun api server (addr:port)
#' @param api string - api type (grpc or rest)
#' @export
set_server <- function(host = "localhost:5757", api = "rest") {
  barenv$host <- host
  barenv$api <- api
}

#' print server config
#'
#' @return list of server config
#' @export
get_server <- function() {
  svr <- list(host = barenv$host, api = barenv$api)
  if (svr$host == "") {
    svr$host <- "localhost:5757"
  }
  if (svr$api == "") {
    svr$api <- "rest"
  }
  svr
}

#' save api config
#'
#' @param apikey string - bareun user's api key
#' @param server string - bareun api server name or ip
#' @param port number - bareun api server port (default: 5757)
#' @param api string - api type (rest or grpc)
#' @export
set_api <- function(apikey, server = "localhost", port = 5757, api = "rest") {
  set_key(apikey)
  host <- paste(server, ":", as.character(port), sep = "")
  set_server(host, api)
}

.meta <- function(apikey) {
  c("api-key", apikey)
}

#' @importFrom httr POST add_headers content
.rest_analyze_text <- function(text, host, custom_domain,
    auto_spacing, auto_jointing, apikey) {
  url <- paste("http://", host, "/bareun/api/v1/analyze", sep = "")
  doc <- list(content = text, language = "ko_KR")
  body <- list(document = doc, encoding_type = "UTF8",
    auto_spacing = auto_spacing, auto_jointing = auto_jointing,
    custom_domain = custom_domain)
  r <- POST(url, config = add_headers("api-key" = apikey),
    body = body, encode = "json")
  content(r)
}

#' Call Bareun server to read postag result message for the sentences
#'
#' - Bareun 서버를 호출하여 입력 문장(들)의 분석 결과를 가져 온다
#'
#' @param text string - subject sentences splitted by newlines(\\n)
#' @param apikey string - Bareun user's API KEY
#' @param server string - Bareun server address
#' @param port number - Bareun server port
#' @param domain string - custom domain (custom dictionary)
#' @param local bool - use local protobuf files, if TRUE
#' @return returns tagged object
#' @examples
#' tagged <- tagger("결과를 문자열로 바꾼다.")
#' @importFrom curl nslookup
#' @export
tagger <- function(text = "",
    apikey = "",
    server = "",
    port = 5757,
    domain = "",
    local = FALSE,
    bareun = TRUE,
    auto_spacing = TRUE,
    auto_jointing = TRUE,
    api = "") {
  # host
  if (server == "") {
    host <- get_server()$host
  } else {
    host <- paste(nslookup(server), ":", as.character(port), sep = "")
  }
  # api type
  if (api == "") {
    api <- get_server()$api
  }
  # api-key
  if (apikey == "") {
    apikey <- barenv$apikey
  }
  custom_domain <- domain
  response <- NULL
  dict <- NULL
  lang_proto <- ""
  dict_proto <- ""
  auto_spacing <- auto_spacing
  auto_jointing <- auto_jointing
  if (text != "") {
    response <- .rest_analyze_text(text, host, custom_domain,
      auto_spacing, auto_jointing, apikey)
  }
  tagged <- list(text = text,
    result = response,
    domain = custom_domain,
    custom_dict = dict,
    host = host,
    apikey = apikey,
    api = api,
    lang_proto = lang_proto,
    dict_proto = dict_proto,
    auto_spacing = auto_spacing,
    auto_jointing = auto_jointing,
    bareun = bareun
  )
  class(tagged) <- "tagged"
  tagged
}

#' Return JSON string for response message
#'
#' - 결과를 JSON 문자열로 출력
#'
#' @param tagged Bareun tagger result
#' @return returns JSON string
#' @importFrom jsonlite toJSON
#' @export
as_json_string <- function(tagged, pretty = FALSE) {
  if (is.null(tagged$result)) {
    "No result\n"
  } else {
    toJSON(tagged$result, pretty = pretty)
  }
}

#' Print JSON string for response message
#'
#' - 결과를 읽을 수 있는 JSON 문자열로 화면 출력
#'
#' @param tagged Bareun tagger result
#' @return prints JSON string
#' @export
print_as_json <- function(tagged) {
  cat(as_json_string(tagged, pretty = TRUE), sep = "\n")
}

.tagging <- function(m) {
  tags <- c()
  ms <- m$sentences
  for (s in ms) {
    tx <- as.list(s)
    sen <- c()
    tokens <- as.list(tx$tokens)
    for (t in tokens) {
      tk <- as.list(t)
      for (m in tk$morphemes) {
        mol <- as.list(m)
        ts <- as.list(mol$text)
        if (typeof(mol$tag) == "integer") {
          sen <- c(sen, c(ts$content, tag_labels[mol$tag]))
        } else {
          sen <- c(sen, c(ts$content, mol$tag))
        }
      }
    }
    t <- list()
    t$tag <- sen
    tags <- c(tags, t)
  }
  tags
}

.analyze_tag <- function(tagged = NULL, text = "") {
  # tagged가 주어지지 않으면 tagger로 생성
  if (is.null(tagged)) {
    t <- tagger(text)
    res <- t$result
  } else {
    # 문자열이 주어지지 않으면 이전 결과를 파싱
    if (text == "") {
      res <- tagged$result
    } else {
      # 새로운 문자열이면 실행, 저장
      res <- .rest_analyze_text(text, tagged$host, tagged$domain,
          tagged$auto_spacing, tagged$auto_jointing, tagged$apikey)
      t <- tagged
      t$text <- text
      t$result <- res
      eval.parent(substitute(tagged <- t))
    }
  }
  res
}

#' analyze_text
#'
#' @param tagged Bareun tagger result
#' @param text string - input text
#' @return raw result
#' @export
analyze_text <- function(tagged, text) {
  res <- .rest_analyze_text(text, tagged$host, tagged$domain,
      tagged$auto_spacing, tagged$auto_jointing, tagged$apikey)
  res
}

#' Return array of (morpheme, postag) pairs
#'
#' - 결과/문장을 (음절, 형태소태그) 리스트의 리스트로 출력
#' - 새로운 문장이 주어지면 결과를 변경하고, 문장이 주어지지 않으면 이전 결과를 다시 사용
#'
#' @param tagged Bareun tagger result
#' @param text input text
#' @param matrix if TRUE, result output to matrix not list (default = FALSE)
#' @return returns array of lists for (morpheme, tag)
#' @examples
#' > postag(, "결과를 문자열로 바꾼다.", TRUE)
#' [[1]]
#'      [,1]     [,2]
#' [1,] "결과"   "NNG"
#' [2,] "를"     "JKO"
#' [3,] "문자열" "NNG"
#' [4,] "로"     "JKB"
#' [5,] "바꾸"   "VV"
#' [6,] "ㄴ다"   "EF"
#' [7,] "."      "SF"
#' @export
postag <- function(tagged = NULL, text = "", matrix = FALSE) {
  dup <- tagged
  res <- .analyze_tag(dup, text)
  if (!is.null(dup) && text != "") {
    t <- dup
    eval.parent(substitute(tagged <- t))
  }
  tags <- .tagging(res)
  pos_list <- c(list(), seq_along(tags))
  pos_mat <- pos_list
  tag_i <- 0
  for (t in tags) {
    tag_i <- tag_i + 1
    pos_mat[[tag_i]] <- matrix(t, ncol = 2, byrow = TRUE)
    tag_a <- 1 : (length(t) / 2)
    tag_list <- c(list(), tag_a)
    a_i <- 0
    for (i in tag_a) {
      a_i <- a_i + 1
      tag_list[[a_i]] <- list(morpheme = t[i * 2 - 1], tag = t[i * 2])
    }
    pos_list[[tag_i]] <- tag_list
  }
  if (matrix) {
    pos_mat
  } else {
    pos_list
  }
}

#' Return array of morpheme/postag words
#'
#' - 결과/문장을 '음절/태그' 문자열 리스트로 출력
#' - 새로운 문장이 주어지면 결과를 변경하고, 문장이 주어지지 않으면 이전 결과를 다시 사용
#'
#' @param tagged Bareun tagger result
#' @param text input text
#' @return returns array of words 'morpheme/tag'
#' @examples
#' > pos(, "결과를 문자열로 바꾼다.")
#' [[1]]
#' [1] "결과/NNG"   "를/JKO"     "문자열/NNG" "로/JKB"     "바꾸/VV"    "ㄴ다/EF"    "./SF"
#' @export
pos <- function(tagged = NULL, text = "") {
  l <- postag(tagged, text, FALSE)
  pol <- c(list(), seq_along(l))
  pol_i <- 0
  for (s in l) {
    pol_i <- pol_i + 1
    out <- c()
    for (m in s) {
      out <- c(out, paste(m$morpheme, "/", m$tag, sep = ""))
    }
    pol[[pol_i]] <- out
  }
  pol
}

#' Return array of Morphemes
#'
#' - 결과/문장의 음절 리스트만 출력
#' - 새로운 문장이 주어지면 결과를 변경하고, 문장이 주어지지 않으면 이전 결과를 다시 사용
#'
#' @param tagged Bareun tagger result
#' @param text input text
#' @return returns array of list for morphemes
#' @examples
#' > morphs(, "결과를 문자열로 바꾼다.")
#' [[1]]
#' [1] "결과"   "를"     "문자열" "로"     "바꾸"   "ㄴ다"   "."
#' @export
morphs <- function(tagged = NULL, text = "") {
  dup <- tagged
  res <- .analyze_tag(dup, text)
  if (!is.null(dup) && text != "") {
    t <- dup
    eval.parent(substitute(tagged <- t))
  }
  tags <- .tagging(res)
  morp <- c(list(), seq_along(tags))
  tag_i <- 0
  for (t in tags) {
    tag_i <- tag_i + 1
    morp[[tag_i]] <- t[seq(1, length(t), by = 2)]
  }
  morp
}

.findtag <- function(t, c) {
  out <- c()
  num <- length(t) / 2
  for (i in 1:num) {
    if (!is.na(match(t[i * 2], c))) {
      out <- c(out, t[i * 2 - 1])
    }
  }
  if (length(out) == 0) {
    out <- c("")
  }
  out
}

#' Return array of Nouns
#'
#' - 결과/문장의 명사 리스트만 출력
#' - 새로운 문장이 주어지면 결과를 변경하고, 문장이 주어지지 않으면 이전 결과를 다시 사용
#'
#' @param tagged Bareun tagger result
#' @param text input text
#' @return returns array of list for nouns
#' @examples
#' > nouns(, "결과를 문자열로 바꾼다.")
#' [[1]]
#' [1] "결과"   "문자열"
#' @export
nouns <- function(tagged = NULL, text = "") {
  dup <- tagged
  res <- .analyze_tag(dup, text)
  if (!is.null(dup) && text != "") {
    t <- dup
    eval.parent(substitute(tagged <- t))
  }
  tags <- .tagging(res)
  nns <- c(list(), seq_along(tags))
  tag_i <- 0
  for (t in tags) {
    tag_i <- tag_i + 1
    nns[[tag_i]] <- .findtag(t, c("NNP", "NNG", "NP", "NNB"))
  }
  nns
}

#' Return array of Verbs
#'
#' - 결과/문장의 동사 리스트만 출력
#' - 새로운 문장이 주어지면 결과를 변경하고, 문장이 주어지지 않으면 이전 결과를 다시 사용
#'
#' @param tagged Bareun tagger result
#' @param text input text
#' @return returns array of list for verbs
#' @examples
#' > verbs(, "결과를 문자열로 바꾼다.")
#' [[1]]
#' [1] "바꾸"
#' @export
verbs <- function(tagged = NULL, text = "") {
  dup <- tagged
  res <- .analyze_tag(dup, text)
  if (!is.null(dup) && text != "") {
    t <- dup
    eval.parent(substitute(tagged <- t))
  }
  tags <- .tagging(res)
  vbs <- c(list(), seq_along(tags))
  tag_i <- 0
  for (t in tags) {
    tag_i <- tag_i + 1
    vbs[[tag_i]] <- .findtag(t, c("VV"))
  }
  vbs
}

# For Custom dicts

#' @importFrom httr GET add_headers content
.rest_get_dic <- function(host, apikey, name = "") {
  if (name == "") {
    url <- paste("http://", host, "/bareun/api/v1/customdict", sep = "")
  } else {
    url <- paste("http://", host, "/bareun/api/v1/customdict/", name, sep = "")
  }
  r <- GET(url, config = add_headers("api-key" = apikey), encode = "json")
  content(r)
}

#' Get List of Custom Dictionaries
#'
#' - 사용자 사전의 목록 출력
#'
#' @param tagged Bareun tagger result
#' @return returns dict
#' @export
dict_list <- function(tagged) {
  dl <- .rest_get_dic(tagged$host, tagged$apikey)
  out <- c()
  for (d in as.list(dl)$domain) {
    out <- c(out, as.list(d)$domain)
  }
  out
}

#' Get Custom Dictionary
#'
#' - 지정된 사용자 사전 읽어오기
#'
#' @param tagged Bareun tagger result
#' @param name name of custom dictionary
#' @return returns dict
#' @export
get_dict <- function(tagged, name) {
  dict <- .rest_get_dic(tagged$host, tagged$apikey, name)
  t <- tagged
  t$custom_dict <- dict
  t$domain <- name
  eval.parent(substitute(tagged <- t))
  dict
}

.get_dict_set <- function(t, set_name) {
  d <- t$custom_dict
  switch(set_name,
    np = as.list(as.list(d)$dict)$np_set,
    cp = as.list(as.list(d)$dict)$cp_set,
    caret = as.list(as.list(d)$dict)$cp_caret_set,
    vv = as.list(as.list(d)$dict)$vv_set,
    va = as.list(as.list(d)$dict)$va_set,
    NULL)
}

#' Get Contents of Set
#'
#' - 사용자 사전 세트별 내용 출력
#'
#' @param tagged Bareun tagger result
#' @param set_name name of set (np, cp, caret)
#' @return returns list of words
#' @export
get_set <- function(tagged, set_name) {
  ds <- .get_dict_set(tagged, set_name)
  out <- c()
  for (i in ds$items) {
    out <- c(out, i$key)
  }
  out
}

#' Print All Contents of Custom Dictionary
#'
#' - 사용자 사전 내용 모두 출력
#'
#' @param tagged Bareun tagger result
#' @return prints all contents of all sets
#' @export
print_dict_all <- function(tagged) {
  print("-> 고유명사 사전")
  print(get_set(tagged, "np"))
  print("-> 복합명사 사전")
  print(get_set(tagged, "cp"))
  print("-> 분리 사전")
  print(get_set(tagged, "caret"))
  print("-> 동사 사전")
  print(get_set(tagged, "vv"))
  print("-> 형용사 사전")
  print(get_set(tagged, "va"))
}

#' Build A Dictionary
#'
#' - 사용자 사전 한 세트 만들기
#'
#' @param tagged Bareun tagger result
#' @param domain domain name of custom dictionary
#' @param name name of dictionary set
#' @param dict_set set of dictionary contents(values)
#' @return returns DictSet
#' @export
build_dict_set <- function(tagged, domain, name, dict_set) {
  ds <- list()
  ds$name <- paste(domain, "-", name, sep = "")
  ds$type <- 1 # common.DictType.WORD_LIST
  for (v in dict_set) {
    l <- list()
    l[[v]] <- 1
    ds$items <- c(ds$items, l)
  }
  ds
}

#' Build Custom Dictionary
#'
#' - 사용자 사전 데이터 구조 만들기
#'
#' @param tagged Bareun tagger result
#' @param domain domain name of custom dictionary
#' @param nps set of np-set dictinary
#' @param cps set of cp-set dictinary
#' @param carets set of cp-caret-set dictinary
#' @param vvs set of vv-set dictinary
#' @param vas set of va-set dictinary
#' @return dict
#' @export
build_custom_dict <- function(tagged, domain, nps, cps, carets, vvs, vas) {
  dict <- list()
  dict$domain_name <- domain
  dict$np_set <- build_dict_set(tagged, domain, "np-set", nps)
  dict$cp_set <- build_dict_set(tagged, domain, "cp-set", cps)
  dict$cp_caret_set <- build_dict_set(tagged, domain, "cp-caret-set", carets)
  dict$vv_set <- build_dict_set(tagged, domain, "vv-set", vvs)
  dict$va_set <- build_dict_set(tagged, domain, "va-set", vas)
  dict
}

#' Update Custom Dictionary
#'
#' - 사용자 사전 만들고 업로드(저장)
#'
#' @param tagged Bareun tagger result
#' @param domain domain name of custom dictionary
#' @param nps set of np-set dictinary
#' @param cps set of cp-set dictinary
#' @param carets set of cp-caret-set dictinary
#' @param vvs set of vv-set dictinary
#' @param vas set of va-set dictinary
#' @return print result
#' @importFrom httr POST add_headers content
#' @importFrom jsonlite toJSON fromJSON
#' @export
make_custom_dict <- function(tagged, domain, nps, cps, carets, vvs, vas) {
  dict <- build_custom_dict(tagged, domain, nps, cps, carets, vvs, vas)
  url <- paste("http://", tagged$host,
      "/bareun/api/v1/customdict/", domain, sep = "")
  body <- list(domain_name = domain, dict = dict)
  r <- POST(url, config = add_headers("api-key" = get_key(),
      "Content-Type" = "application/json"),
      body = body, encode = "json")
  res <- content(r, preserve_proto_field_names = TRUE, encoding = "UTF-8")
  if (r$status_code == 200) {
    if (res$updated == domain) {
      print(paste(domain, ": 업데이트 성공"))
    }
  } else {
    print(res)
  }
}

#' Remove Custom Dictionary
#'
#' - 사용자 사전(들)을 삭제
#'
#' @param tagged Bareun tagger result
#' @param name name of custom dictionary
#' @return print results
#' @importFrom httr POST add_headers content
#' @export
remove_custom_dict <- function(tagged, names) {
  url <- paste("http://", tagged$host,
      "/bareun/api/v1/customdict/delete", sep = "")
  body <- list(domain_names = names)
  r <- POST(url, config = add_headers("api-key" = get_key()),
      body = body, encode = "json")
  res <- content(r)
  for (d in as.list(res)$deleted) {
    print(d)
  }
}
