GRPC Library installation Guide
---

## 1. Linux (Ubuntu)

- Pre-requisites:
```
sudo apt update && sudo apt -y upgrade
sudo apt install -y build-essential autoconf libtool pkg-config git
sudo apt install -y cmake
sudo apt install -y clang libc++-dev
sudo apt install -y libprotobuf-dev libprotoc-dev
```

- grpc c++ 라이브러리 컴파일 & 설치
```
# install_grpc.sh
# - local install dir
export GRPC_INSTALL_DIR=$HOME/.local
mkdir -p $GRPC_INSTALL_DIR
export PATH="$GRPC_INSTALL_DIR/bin:$PATH"
# - get src
git clone --recurse-submodules -b v1.30.x https://github.com/grpc/grpc grpc_base
# - make main lib
cd grpc_base
mkdir -p cmake/build
pushd cmake/build
cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=$GRPC_INSTALL_DIR \
      ../..
make -j4
sudo make install
popd
# - make sub & others
mkdir -p third_party/abseil-cpp/cmake/build
pushd third_party/abseil-cpp/cmake/build
cmake -DCMAKE_INSTALL_PREFIX=$GRPC_INSTALL_DIR \
      -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE \
      ../..
make -j4
sudo make install
popd
```
- env 설정

```
export PKG_CONFIG_PATH=~/.local/lib/pkgconfig
```


## 2. MacOS 

- Pre-requisites:
```
sudo xcode-select --install
brew install autoconf automake libtool shtool pkg-config
brew install protobuf openssl
```

- grpc c++ 라이브러리 컴파일 & 설치
```
# install local
export GRPC_INSTALL_DIR=$HOME/.local
mkdir -p $GRPC_INSTALL_DIR
export PATH="$GRPC_INSTALL_DIR/bin:$PATH"
# make grpc lib from src
git clone --recurse-submodules -b v1.30.x https://github.com/grpc/grpc grpc_base
# make main lib
cd grpc_base
mkdir -p cmake/build
pushd cmake/build
cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=$GRPC_INSTALL_DIR \
      ../..
make -j4
make install
popd
# make others
export CFLAGS="--std=c++11"
export CXXFLAGS="--std=c++11"
mkdir -p third_party/abseil-cpp/cmake/build
pushd third_party/abseil-cpp/cmake/build
cmake -DCMAKE_INSTALL_PREFIX=$GRPC_INSTALL_DIR \
      -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE \
      ../..
make -j4
make install
popd
```
- env 설정

```
export PKG_CONFIG_PATH=~/.local/lib/pkgconfig:/opt/homebrew/lib/pkgconfig:/opt/homebrew/Cellar/openssl@1.1/1.1.1s/lib/pkgconfig
```

## 3. 공통: R에서 설치

```
install.packagas('devtools')
install.packages('openssl')
install.packages('Rcpp')
install.packages('RProtoBuf')
install.packages('curl')
install.packages('httr')
install.packages('jsonlite')
devtools::install_github("bareun-nlp/grpc")
devtools::install_github("bareun-nlp/RBareun")
```

  - 참고.1: [gRPC C++ - Building from source](https://github.com/grpc/grpc/blob/master/BUILDING.md)

  - 참고.2: 리눅스 R에서 devtools를 처음 설치하기 전에 필요한 라이브러리 설치
```
sudo apt install libxml2-dev libssl-dev libcurl4-openssl-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev
```
