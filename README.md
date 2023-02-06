# RBareun

* R package for bareun
* About bareun: https://bareun.ai/

## Install

- 설치에 앞서, gRPC C++ 라이브러리를 직접 컴파일 설치해야 합니다.
➡️ [INSTALL](https://github.com/bareun-nlp/RBareun/blob/main/INSTALL.md) 내용 참고 
- gRPC 설치후 이 패키지 설치
```
library(devtools)  
devtools::install_github("bareun-nlp/RBareun")  
```

## Usage

- 패키지 사용 방법
```
library(RProtoBuf)  
library(bareun)
```

## Functions

- tagger: Bareun 서버를 호출하여 문장(들)을 분석
- postag: 분석한 결과/문장의 음절, 태그 리스트 출력
- pos: 분석한 결과/문장을 음절/태그 문자열 리스트로 출력
- morphs: 분석한 결과/문장의 음절 리스트 출력
- nouns: 분석한 결과/문장의 명사 리스트 출력
- verbs: 분석한 결과/문장의 동사 리스트 출력
- as_json_string: 분석 결과를 JSON 문자열로 출력
- print_as_json: 분석 결과를 읽을 수 있는 JSON 화면 출력
- dict_list: 등록된 사용자 사전 목록
- get_dict: 사용자 사전 가져오기
- print_dict_all: 사용자 사전 내용 보기
- build_dict_set: 새로운 세트 만들기
- make_custom_dict: 사용자 사전 새로 만들고 등록
- remove_custom_dict: 사용자 사전(들) 삭제

## Examples / 형태소 분석

- 로드/호출
```
> library(RProtoBuf)
> library(bareun)
> api_key <- "YOUR_API_KEY"
> t <- tagger(apikey = api_key)
```
- 형태소 분석을 매트릭스로 출력
```
> postag(t, "문장을 입력합니다.\n여러 문장을 넣습니다.", TRUE)
[[1]]
     [,1]     [,2]
[1,] "문장"   "NNG"
[2,] "을"     "JKO"
[3,] "입력하" "VV"
[4,] "ㅂ니다" "EF"
[5,] "."      "SF"

[[2]]
     [,1]     [,2]
[1,] "여러"   "MMN"
[2,] "문장"   "NNG"
[3,] "을"     "JKO"
[4,] "넣"     "VV"
[5,] "습니다" "EF"
[6,] "."      "SF"
```
- 1번째 문장의 5번째 형태소 출력
```
> postag(t)[[1]][[4]]
$morpheme
[1] "ㅂ니다"

$tag
[1] "EF"
```
- 어절, 명사, 동사 출력(해당 없는 경우 빈 문자열 배열 반환)
```
> morphs(t)
[[1]]
[1] "문장"   "을"     "입력하" "ㅂ니다" "."

[[2]]
[1] "여러"   "문장"   "을"     "넣"     "습니다" "."

> nouns(t)
[[1]]
[1] "문장"

[[2]]
[1] "문장"

> verbs(t)
[[1]]
[1] "입력하"

[[2]]
[1] "넣"
```

## Examples / 사용자 사전

- 만들기 & 등록하기
```
> np <- c("청하", "트와이스", "티키타카", "TIKITAKA", "오마이걸")
> cp <- c("자유여행", "방역당국", "코로나19", "주술부", "완전주의")
> caret <- c("주어^역할", "주어^술어^구조", "하급^공무원")
> vv <- c("카톡하다", "인스타하다")
> va <- c("혜자스럽다", "창렬하다")
> make_custom_dict(t, "sample", np, cp, caret, vv, va)
[1] "sample : 업데이트 성공"
```
- 사전 기능 테스트

| 문장 | 사전이 없을때 결과 | 사전이 적용된 결과 | 설명 |
| ------ | ------ | ------ | ------ |
| 효정이는 **오마이걸**의 리덥니다 | [1,] "효정이" "NNP" <br>[2,] "는"     "JX"<br>[3,] "오마이" "NNG"<br>[4,] "걸"     "NNG"<br>[5,] "의"     "JKG"<br>[6,] "리더"   "NNG"<br>[7,] "이"     "VCP"<br>[8,] "ㅂ니다" "EF" | [1,] "효정이"   "NNP"<br>[2,] "는"       "JX"<br>[3,] <b>"오마이걸" "NNP"</b><br>[4,] "의"       "JKG"<br>[5,] "리더"     "NNG"<br>[6,] "이"       "VCP"<br>[7,] "ㅂ니다"   "EF" | '오마이걸'이 고유명사(NNP)로 처리 |
| **자유여행**으로 갈겁니다 | [1,] "자유"   "NNG"<br>[2,] "여행"   "NNG"<br>[3,] "으로"   "JKB"<br>[4,] "가"     "VV"<br>[5,] "ㄹ"     "ETM"<br>[6,] "거"     "NNB"<br>[7,] "이"     "VCP"<br>[8,] "ㅂ니다" "EF" | [1,] <b>"자유여행" "NNG"</b><br>[2,] "으로"     "JKB"<br>[3,] "가"       "VV"<br>[4,] "ㄹ"       "ETM"<br>[5,] "거"       "NNB"<br>[6,] "이"       "VCP"<br>[7,] "ㅂ니다"   "EF"| '자유여행'이 복합명사로 한 단어처럼 처리 |
| 이따가 **카톡해**라 | [1,] "이따가" "MAG"<br>[2,] "카톡"   "NNP"<br>[3,] "하"     "VV"<br>[4,] "아라"   "EF"<br> | [1,] "이따가" "MAG"<br>[2,] <b>"카톡하" "VV"</b><br>[3,] "아라"   "EF"<br> | '카톡하다'가 '카톡(명사)+하'가 아니라 동사로 처리 |



by [Korea Press Foundation](https://bigkinds.or.kr) X [bareun.ai](https://bareun.ai)
