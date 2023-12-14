#!/bin/bash
# 安装 Ethereum-etl + erigon，后续需要指定版本

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'

next() {
 printf '%-70s\n' | sed 's/\ /-/g'
}

# 红色提示，且终止脚本
RED() {
    next && echo -e "$RED""$*""$PLAIN" && exit 1
}

# 绿色提示
GREEN() {
    next && echo -e "$GREEN""$*""$PLAIN"
}


# 依赖的环境监测
basic_env_check() {
    # 检测是否存在python3
    ( echo exit | python3 ) || RED 'Python3 exec failed'
    # 检测是否存在python3 pip
    ( python3 -m pip > /dev/null ) || RED 'Python3 pip exec failed'
}

# 依赖命令安装
yum_install() {
    yum install git wget gcc gcc-c++ python3 python3-devel make -y || RED 'Yum install failed'
}

# ethereum-etl 安装
etl_install() {
    # Ethereum-etl 依赖 cython cytoolz sqlalchemy pg8000
    # postgresql_init.py 依赖 pg8000 PyYAML
    # PyYAML 安装失败时，可以增加版本安装 "pyyaml==5.4.1"

    python3 -m pip install cython sqlalchemy pg8000 pyyaml==5.4.1 || RED 'Python3 pip install exec failed'
    python3 -m pip install cytoolz || RED 'Cytoolz install exec failed'

    python3 -m pip install ethereum-etl || RED 'Ethereum-etl install exec failed'
    ethereumetl > /dev/null && GREEN 'Ethereum-etl install succeeded'
}

# erigon 安装
erigon_install() {
    wget https://go.dev/dl/go1.20.12.linux-amd64.tar.gz && tar zxvf go1.20.12.linux-amd64.tar.gz || RED 'Go download failed'
    export PATH=`pwd`/go/bin/:$PATH
    git clone --recurse-submodules -j8 https://github.com/ledgerwatch/erigon.git || RED 'Git clone https://github.com/ledgerwatch/erigon.git exec failed'
    cd erigon && make -j 8 erigon || RED 'Erigon make failed'
    ./build/bin/erigon --help > /dev/null && GREEN 'Erigon install succeeded'
    cp ./build/bin/erigon "$root_dir/bin/"
    ln -s "$root_dir/bin/erigon" /usr/bin/
}

# postgresql 初始化
postgresql_init() {
    ( python3 "$pwd_dir"/postgresql_init.py && GREEN 'Postgresql initialization succeeded' ) || RED 'Postgresql initialization failed'
}

# 需要root用户执行
if [ "$(whoami)" != "root" ] ; then
 echo -e "$RED please use ROOT user! $PLAIN"
 exit 1
fi

# 脚本执行目录
pwd_dir=$(pwd)

# 安装目录
root_dir='/opt/eapi'
mkdir -p "$root_dir"/bin
cd "$root_dir"
yum_install
basic_env_check
etl_install
erigon_install
python3 "$pwd_dir/postgresql_init.py" || RED 'Postgresql initialization failed'
GREEN 'Successful installation!'