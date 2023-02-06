# package bareun: Bareun grpc client

library(curl)
library(RProtoBuf)

tag_labels <- c("EC", "EF", "EP", "ETM", "ETN", "IC",
                "JC", "JKB", "JKC", "JKG", "JKO", "JKQ", "JKS", "JKV", "JX",
                "MAG", "MAJ", "MMA", "MMD", "MMN",
                "NA", "NF", "NNB", "NNG", "NNP", "NP", "NR", "NV",
                "SE", "SF", "SH", "SL", "SN", "SO", "SP", "SS", "SW",
                "VA", "VCN", "VCP", "VV", "VX",
                "XPN", "XR", "XSA", "XSN", "XSV", "_SP_", "PAD")


.get_client <- function(host, proto) {
  grpc_client(read_services(proto), host)
}

.get_metadata <- function(apikey) {
  c("api-key", apikey)
}

.analyze_text <- function(text, host, proto, domain, apikey, bareun) {
  client <- .get_client(host, proto)
  if (bareun) {
    doc <- new(P("bareun.Document", file = proto))
  } else {
    doc <- new(P("baikal.language.Document", file = proto))
  }
  doc$content <- text
  doc$language <- "ko_KR"
  example <- client$AnalyzeSyntax$build(document = doc,
    encoding_type = 1, auto_split_sentence = 0, custom_domain = domain)
  metadata <- .get_metadata(apikey)
  client$AnalyzeSyntax$call(example, metadata)
}

#' grpc cllient
#'
#' @export
get_grpc_client <- function(host, proto) {
  .get_client(host, proto)
}

#' Call Bareun server to read postag result message for the sentences
#'
#' - Bareun grpc 서버를 호출하여 입력 문장(들)의 분석 결과를 가져 온다
#'
#' @param text string - subject sentences splitted by newlines(\\n)
#' @param apikey string - Bareun user's API KEY
#' @param server string - Bareun grpc server address
#' @param port number - Bareun grpc server port
#' @param domain string - custom domain (custom dictionary)
#' @param local bool - use local protobuf files, if TRUE
#' @return returns tagged object
#' @examples
#' tagged <- tagger("결과를 문자열로 바꾼다.")
#' @importFrom RProtoBuf P
#' @importFrom curl nslookup
#' @export
tagger <- function(text = "",
    apikey = "",
    server = "nlp.bareun.ai", port = 5656,
    domain = "", local = FALSE, bareun = TRUE) {
  host <- paste(nslookup(server), ":", as.character(port), sep = "")
  if (local) {
    if (bareun) {
      lang_proto <- "protos/language_service.proto"
      dict_proto <- "protos/custom_dict.proto"
    } else {
      lang_proto <- "protos/baikal/language_service.proto"
      dict_proto <- "protos/baikal/custom_dict.proto"
    }
  } else {
    if (bareun) {
      lang_proto <- system.file("protos/language_service.proto",
        package = "bareun")
      dict_proto <- system.file("protos/custom_dict.proto",
        package = "bareun")
    } else {
      lang_proto <- system.file("protos/baikal/language_service.proto",
        package = "bareun")
      dict_proto <- system.file("protos/baikal/custom_dict.proto",
        package = "bareun")
    }
  }
  custom_domain <- domain
  response <- NULL
  dict <- NULL
  if (text != "") {
    response <- .analyze_text(text, host, lang_proto, custom_domain,
      apikey, bareun)
  }
  tagged <- list(text = text,
    result = response,
    domain = custom_domain,
    custom_dict = dict,
    host = host,
    apikey = apikey,
    lang_proto = lang_proto,
    dict_proto = dict_proto,
    bareun = bareun)
  class(tagged) <- "tagged"
  tagged
}

#' Return JSON string for response message
#'
#' - 결과를 JSON 문자열로 출력
#'
#' @param tagged Bareun tagger result
#' @return returns JSON string
#' @export
as_json_string <- function(tagged) {
  if (is.null(tagged$result)) {
    "No result"
  } else {
    toJSON(tagged$result)
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
  if (is.null(tagged$result)) {
    "No result"
  } else {
    cat(as_json_string(tagged))
  }
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
        sen <- c(sen, c(ts$content, tag_labels[mol$tag]))
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
    t <- tagged
    # 문자열이 주어지지 않으면 이전 결과를 파싱
    if (text == "") {
      res <- tagged$result
    } else {
      # 새로운 문자열이면 실행 결과를 저장
      res <- .analyze_text(text, tagged$host, tagged$lang_proto,
        tagged$domain, tagged$apikey, tagged$bareun)
      t <- tagged
      t$text <- text
      t$result <- res
      eval.parent(substitute(tagged <- t))
    }
  }
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

.get_dic_list <- function(host, proto, apikey) {
    cli <- .get_client(host, proto)
    ops <- cli$GetCustomDictionaryList$build()
    metadata <- .get_metadata(apikey)
    cli$GetCustomDictionaryList$call(ops, metadata)
}

#' Get List of Custom Dictionaries
#'
#' - 사용자 사전의 목록 출력
#'
#' @param tagged Bareun tagger result
#' @return returns dict
#' @export
dict_list <- function(tagged) {
  dl <- .get_dic_list(tagged$host, tagged$dict_proto, tagged$apikey)
  out <- c()
  for (d in as.list(dl)$domain_dicts) {
    out <- c(out, as.list(d)$domain_name)
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
  cli <- .get_client(tagged$host, tagged$dict_proto)
  ops <- cli$GetCustomDictionary$build(domain_name = name)
  metadata <- .get_metadata(tagged$apikey)
  dict <- cli$GetCustomDictionary$call(ops, metadata)
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
  if (tagged$bareun) {
    ds <- new(P("bareun.DictSet", file = tagged$dict_proto))
  } else {
    ds <- new(P("baikal.language.DictSet", file = tagged$dict_proto))
  }
  ds$name <- paste(domain, "-", name, sep = "")
  ds$type <- 1 # common.DictType.WORD_LIST
  if (tagged$bareun) {
    dsentry <- P("bareun.DictSet.ItemsEntry", file = tagged$dict_proto)
  } else {
    dsentry <- P("baikal.language.DictSet.ItemsEntry", file = tagged$dict_proto)
  }
  for (v in dict_set) {
    de <- new(dsentry)
    de$key <- v
    de$value <- 1
    ds$items <- c(ds$items, de)
  }
  ds
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
#' @export
make_custom_dict <- function(tagged, domain, nps, cps, carets, vvs, vas) {
  if (tagged$bareun) {
    dict <- new(P("bareun.CustomDictionary",
      file = tagged$dict_proto))
  } else {
    dict <- new(P("baikal.language.CustomDictionary",
      file = tagged$dict_proto))
  }
  dict$domain_name <- domain
  dict$np_set <- build_dict_set(tagged, domain, "np-set", nps)
  dict$cp_set <- build_dict_set(tagged, domain, "cp-set", cps)
  dict$cp_caret_set <- build_dict_set(tagged, domain, "cp-caret-set", carets)
  dict$vv_set <- build_dict_set(tagged, domain, "vv-set", vvs)
  dict$va_set <- build_dict_set(tagged, domain, "va-set", vas)
  cli <- .get_client(tagged$host, tagged$dict_proto)
  ops <- cli$UpdateCustomDictionary$build(domain_name = domain, dict = dict)
  metadata <- .get_metadata(tagged$apikey)
  res <- cli$UpdateCustomDictionary$call(ops, metadata)
  if (res$updated_domain_name == domain) {
    print(paste(domain, ": 업데이트 성공"))
  }
}

#' Remove Custom Dictionary
#'
#' - 사용자 사전(들)을 삭제
#'
#' @param tagged Bareun tagger result
#' @param name name of custom dictionary
#' @return print results
#' @export
remove_custom_dict <- function(tagged, names) {
  cli <- .get_client(tagged$host, tagged$dict_proto)
  ops <- cli$RemoveCustomDictionaries$build(domain_names = names)
  metadata <- .get_metadata(tagged$apikey)
  res <- cli$RemoveCustomDictionaries$call(ops, metadata)
  for (r in as.list(res)$deleted_domain_names) {
    print(c(r$key, r$value))
  }
}
