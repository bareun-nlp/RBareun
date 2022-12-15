# RBareun

* R package for BareunNLP
* About BareunNLP: https://license.baikal.ai/

## Install

library(devtools)  
devtools::install_github("bareun/RBareun")  

➡️ [INSTALL](https://github.com/bareun/RBareun/blob/main/INSTALL.md) 파일 내용 참고 

## Usage

library(RProtoBuf)  
library(bareun)

## Functions

- tagger: BareunNLP 서버를 호출하여 문장(들)을 분석
- postag: 분석한 문장의 음절, 태그 배열 보기
- morphs: 분석한 문장의 음절 배열 보기
- nouns: 분석한 문장의 명사 배열 보기
- verbs: 분석한 문장의 동사 배열 보기
- as_json_string: 분석 결과를 JSON 문자열 반환
- print_as_json: 분석 결과를 JSON 으로 표시
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
> t <- tagger("문장을 입력합니다.\n여러 문장을 넣습니다.")
```
- 형태소 분석을 매트릭스로 출력
```
> postag(t, , TRUE)
[[1]]
     [,1]     [,2]
[1,] "문장"   "NNG"
[2,] "을"     "JKO"
[3,] "입력"   "NNG"
[4,] "하"     "XSV"
[5,] "ㅂ니다" "EF"
[6,] "."      "SF"

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
> postag(t)[[1]][[5]]
$morpheme
[1] "ㅂ니다"

$tag
[1] "EF"
```
- 어절, 명사, 동사 출력(해당 없는 경우 빈 문자열 배열 반환)
```
> morphs(t)
[[1]]
[1] "문장"   "을"     "입력"   "하"     "ㅂ니다" "."

[[2]]
[1] "여러"   "문장"   "을"     "넣"     "습니다" "."

> nouns(t)
[[1]]
[1] "문장" "입력"

[[2]]
[1] "문장"

> verbs(t)
[[1]]
[1] ""

[[2]]
[1] "넣"
```
- 문장만 입력할 수도 있습니다.
```
> morphs(, "문장만 입력하기")
[[1]]
[1] "문장" "만"   "입력" "하"   "기"
```

## Examples / 사용자 사전

- 호출: 처음에는 사전이 없습니다.
```
> t <- tagger()
> dict_list(t)
NULL
```
- 만들기: 5세트를 모두 입력해야 합니다.
```
> np <- c("고유명사1", "고유명사2")
> cp <- c("복합명사1", "복합명사2")
> caret <- c("분리^사전1", "분리^사전2")
> vv <- c("동사1", "동사2")
> va <- c("형용사1", "형용사2")
> make_custom_dict(t, "사용자", np, cp, caret, vv, va)
[1] "사용자 : 업데이트 성공"
```
- 확인: 새 사전이 생겼습니다.
```
> dict_list(t)
[1] "사용자"
> get_dict(t, "사용자")
message of type 'baikal.language.GetCustomDictionaryResponse' with 2 fields set
> print_dict_all(t)
[1] "-> 고유명사 사전"
[1] "고유명사1" "고유명사2"
[1] "-> 복합명사 사전"
[1] "복합명사1" "복합명사2"
[1] "-> 분리 사전"
[1] "분리^사전1" "분리^사전2"
[1] "-> 동사 사전"
[1] "동사1" "동사2"
[1] "-> 형용사 사전"
[1] "형용사1" "형용사2"
```
- 삭제: 지웁니다.
```
> remove_custom_dict(t, "사용자")
[1] "사용자" "TRUE"
> dict_list(t)
NULL
```

---

by [baikal.ai](https://baikal.ai)
