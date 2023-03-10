# package bareun: Bareun grpc client

library(curl)
library(RProtoBuf)
library(httr)
library(jsonlite)
library(grpc)

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
set_server <- function(host = "localhost:5757", api = "grpc") {
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
    svr$api <- "grpc"
  }
  svr
}

#' save api config
#'
#' @param apikey string - bareun user's api key
#' @param host string - bareun api server (addr:port)
#' @param api string - api type (grpc or rest)
#' @export
set_api <- function(apikey, host = "localhost:5757", api = "grpc") {
  set_key(apikey)
  set_server(host, api)
}

#' @importFrom grpc grpc_client read_services
.get_client <- function(host, proto) {
  grpc_client(read_services(proto), host)
}

.meta <- function(apikey) {
  c("api-key", apikey)
}

#' @importFrom RProtoBuf P
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
  client$AnalyzeSyntax$call(example, metadata = .meta(apikey))
}

#' @importFrom httr POST add_headers content
.rest_analyze_text <- function(text, host, custom_domain, apikey) {
  url <- paste("http://", host, "/bareun/api/v1/analyze", sep = "")
  doc <- list(content = text, language = "ko_KR")
  body <- list(document = doc, encoding_type = "UTF8",
    custom_domain = custom_domain)
  r <- POST(url, config = add_headers("api-key" = apikey),
    body = body, encode = "json")
  content(r)
}

#' grpc cllient
#'
#' @export
get_grpc_client <- function(host, proto) {
  .get_client(host, proto)
}

#' Call Bareun server to read postag result message for the sentences
#'
#' - Bareun grpc ????????? ???????????? ?????? ??????(???)??? ?????? ????????? ?????? ??????
#'
#' @param text string - subject sentences splitted by newlines(\\n)
#' @param apikey string - Bareun user's API KEY
#' @param server string - Bareun grpc server address
#' @param port number - Bareun grpc server port
#' @param domain string - custom domain (custom dictionary)
#' @param local bool - use local protobuf files, if TRUE
#' @return returns tagged object
#' @examples
#' tagged <- tagger("????????? ???????????? ?????????.")
#' @importFrom curl nslookup
#' @export
tagger <- function(text = "",
    apikey = "",
    server = "", port = 5656,
    domain = "", local = FALSE, bareun = TRUE,
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
  if (text != "") {
    # grpc
    if (api == "grpc") {
      response <- .analyze_text(text, host, lang_proto, custom_domain,
        apikey, bareun)
    } else {
      # rest
      response <- .rest_analyze_text(text, host, custom_domain, apikey)
    }
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
    bareun = bareun)
  class(tagged) <- "tagged"
  tagged
}

#' Return JSON string for response message
#'
#' - ????????? JSON ???????????? ??????
#'
#' @param tagged Bareun tagger result
#' @return returns JSON string
#' @importFrom RProtoBuf toJSON
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
#' - ????????? ?????? ??? ?????? JSON ???????????? ?????? ??????
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
  # tagged??? ???????????? ????????? tagger??? ??????
  if (is.null(tagged)) {
    t <- tagger(text)
    res <- t$result
  } else {
    t <- tagged
    # ???????????? ???????????? ????????? ?????? ????????? ??????
    if (text == "") {
      res <- tagged$result
    } else {
      # ????????? ??????????????? ?????? ????????? ??????
      if (tagged$api == "grpc") {
        res <- .analyze_text(text, tagged$host, tagged$lang_proto,
          tagged$domain, tagged$apikey, tagged$bareun)
      } else {
        res <- .rest_analyze_text(text, tagged$host, tagged$domain,
          tagged$apikey)
      }
      t <- tagged
      t$text <- text
      t$result <- res
      eval.parent(substitute(tagged <- t))
    }
  }
  res
}

#' @export
analyze_text <- function(tagged, text) {
  res <- .rest_analyze_text(text, tagged$host, tagged$domain,
          tagged$apikey)
  res
}

#' Return array of (morpheme, postag) pairs
#'
#' - ??????/????????? (??????, ???????????????) ???????????? ???????????? ??????
#' - ????????? ????????? ???????????? ????????? ????????????, ????????? ???????????? ????????? ?????? ????????? ?????? ??????
#'
#' @param tagged Bareun tagger result
#' @param text input text
#' @param matrix if TRUE, result output to matrix not list (default = FALSE)
#' @return returns array of lists for (morpheme, tag)
#' @examples
#' > postag(, "????????? ???????????? ?????????.", TRUE)
#' [[1]]
#'      [,1]     [,2]
#' [1,] "??????"   "NNG"
#' [2,] "???"     "JKO"
#' [3,] "?????????" "NNG"
#' [4,] "???"     "JKB"
#' [5,] "??????"   "VV"
#' [6,] "??????"   "EF"
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
#' - ??????/????????? '??????/??????' ????????? ???????????? ??????
#' - ????????? ????????? ???????????? ????????? ????????????, ????????? ???????????? ????????? ?????? ????????? ?????? ??????
#'
#' @param tagged Bareun tagger result
#' @param text input text
#' @return returns array of words 'morpheme/tag'
#' @examples
#' > pos(, "????????? ???????????? ?????????.")
#' [[1]]
#' [1] "??????/NNG"   "???/JKO"     "?????????/NNG" "???/JKB"     "??????/VV"    "??????/EF"    "./SF"
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
#' - ??????/????????? ?????? ???????????? ??????
#' - ????????? ????????? ???????????? ????????? ????????????, ????????? ???????????? ????????? ?????? ????????? ?????? ??????
#'
#' @param tagged Bareun tagger result
#' @param text input text
#' @return returns array of list for morphemes
#' @examples
#' > morphs(, "????????? ???????????? ?????????.")
#' [[1]]
#' [1] "??????"   "???"     "?????????" "???"     "??????"   "??????"   "."
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
#' - ??????/????????? ?????? ???????????? ??????
#' - ????????? ????????? ???????????? ????????? ????????????, ????????? ???????????? ????????? ?????? ????????? ?????? ??????
#'
#' @param tagged Bareun tagger result
#' @param text input text
#' @return returns array of list for nouns
#' @examples
#' > nouns(, "????????? ???????????? ?????????.")
#' [[1]]
#' [1] "??????"   "?????????"
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
#' - ??????/????????? ?????? ???????????? ??????
#' - ????????? ????????? ???????????? ????????? ????????????, ????????? ???????????? ????????? ?????? ????????? ?????? ??????
#'
#' @param tagged Bareun tagger result
#' @param text input text
#' @return returns array of list for verbs
#' @examples
#' > verbs(, "????????? ???????????? ?????????.")
#' [[1]]
#' [1] "??????"
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
    cli$GetCustomDictionaryList$call(ops, metadata = .meta(apikey))
}

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
#' - ????????? ????????? ?????? ??????
#'
#' @param tagged Bareun tagger result
#' @return returns dict
#' @export
dict_list <- function(tagged) {
  if (tagged$api == "grpc") {
    dl <- .get_dic_list(tagged$host, tagged$dict_proto, tagged$apikey)
  } else {
    dl <- .rest_get_dic(tagged$host, tagged$apikey)
  }
  out <- c()
  for (d in as.list(dl)$domain) {
    out <- c(out, as.list(d)$domain)
  }
  out
}

#' Get Custom Dictionary
#'
#' - ????????? ????????? ?????? ????????????
#'
#' @param tagged Bareun tagger result
#' @param name name of custom dictionary
#' @return returns dict
#' @export
get_dict <- function(tagged, name) {
  if (tagged$api == "grpc") {
    cli <- .get_client(tagged$host, tagged$dict_proto)
    ops <- cli$GetCustomDictionary$build(domain_name = name)
    dict <- cli$GetCustomDictionary$call(ops, metadata = .meta(tagged$apikey))
  } else {
    dict <- .rest_get_dic(tagged$host, tagged$apikey, name)
  }
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
#' - ????????? ?????? ????????? ?????? ??????
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
#' - ????????? ?????? ?????? ?????? ??????
#'
#' @param tagged Bareun tagger result
#' @return prints all contents of all sets
#' @export
print_dict_all <- function(tagged) {
  print("-> ???????????? ??????")
  print(get_set(tagged, "np"))
  print("-> ???????????? ??????")
  print(get_set(tagged, "cp"))
  print("-> ?????? ??????")
  print(get_set(tagged, "caret"))
  print("-> ?????? ??????")
  print(get_set(tagged, "vv"))
  print("-> ????????? ??????")
  print(get_set(tagged, "va"))
}

#' Build A Dictionary
#'
#' - ????????? ?????? ??? ?????? ?????????
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

#' @export
build_custom_dict <- function(tagged, domain, nps, cps, carets, vvs, vas) {
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
  dict
}

#' Update Custom Dictionary
#'
#' - ????????? ?????? ????????? ?????????(??????)
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
#' @importFrom RProtoBuf toJSON
#' @importFrom jsonlite fromJSON
#' @export
make_custom_dict <- function(tagged, domain, nps, cps, carets, vvs, vas) {
  dict <- build_custom_dict(tagged, domain, nps, cps, carets, vvs, vas)
  if (tagged$api == "grpc") {
    cli <- .get_client(tagged$host, tagged$dict_proto)
    ops <- cli$UpdateCustomDictionary$build(domain_name = domain, dict = dict)
    res <- cli$UpdateCustomDictionary$call(ops, metadata = .meta(tagged$apikey))
  } else {
    url <- paste("http://", tagged$host,
        "/bareun/api/v1/customdict/", domain, sep = "")
    body <- list(domain_name = domain,
        dict = fromJSON(dict$toJSON(preserve_proto_field_names = TRUE)))
    r <- POST(url, config = add_headers("api-key" = get_key()),
        body = body, encode = "json")
    res <- content(r, preserve_proto_field_names = TRUE)
  }
  if (res$updated == domain) {
    print(paste(domain, ": ???????????? ??????"))
  }
}

#' Remove Custom Dictionary
#'
#' - ????????? ??????(???)??? ??????
#'
#' @param tagged Bareun tagger result
#' @param name name of custom dictionary
#' @return print results
#' @importFrom httr POST add_headers content
#' @export
remove_custom_dict <- function(tagged, names) {
  if (tagged$api == "grpc") {
    cli <- .get_client(tagged$host, tagged$dict_proto)
    ops <- cli$RemoveCustomDictionaries$build(domain_names = names)
    res <- cli$RemoveCustomDictionaries$call(ops,
        metadata = .meta(tagged$apikey))
  } else {
    url <- paste("http://", tagged$host,
        "/bareun/api/v1/customdict/delete", sep = "")
    body <- list(domain_names = names)
    r <- POST(url, config = add_headers("api-key" = get_key()),
        body = body, encode = "json")
    res <- content(r)
  }
  for (d in as.list(res)$deleted) {
    print(d)
  }
}
