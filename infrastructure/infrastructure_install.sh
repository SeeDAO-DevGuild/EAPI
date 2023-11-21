#!/bin/bash
# 安装 Ethereum-etl + erigon，后续需要指定版本

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'

# 脚本执行目录
pwd_dir=$(pwd)

# 安装目录
root_dir='/opt/eapi'
mkdir -p "$root_dir"/bin

# 需要root用户执行
if [ `whoami` != "root" ] ; then
 echo -e '$RED please use ROOT user! $PLAIN'
 exit 1
fi

next() {
 printf '%-70s\n' | sed 's/\ /-/g'
}

# 红色提示
RED() {
    ( next && echo -e "$RED""$1""$PLAIN" && exit 1 )
}

# 绿色提示
GREEN() {
    ( next && echo -e "$GREEN""$1""$PLAIN" && exit 1 )
}


# 依赖的环境监测
basic_env_check() {
    # 检测是否存在python3
    ( echo exit | python3 ) || RED 'python3 exec failed'
    # 检测是否存在python3 pip
    ( python3 -m pip ) || RED 'python3 pip exec failed'
}

# 依赖命令安装
yum_install() {
    yum install git wget
}

# ethereum-etl 安装
etl_install() {
    # Ethereum-etl 依赖 cython cytoolz sqlalchemy pg8000
    # postgresql_init.py 依赖 pg8000 PyYAML

    python3 -m pip install cython cytoolz sqlalchemy pg8000 PyYAML || RED 'python3 pip install exec failed'
    python3 -m pip install ethereum-etl || RED 'ethereum-etl install exec failed'
    ethereumetl > /dev/null && GREEN 'ethereum-etl install succeeded'
}

# erigon 安装
erigon_install() {
    git clone --recurse-submodules -j8 https://github.com/ledgerwatch/erigon.git || RED 'git clone https://github.com/ledgerwatch/erigon.git exec failed'
    cd erigion && make -j 8 erigon
    ./build/bin/erigon --help > /dev/null && GREEN 'erigon install succeeded'
    cp ./build/bin/erigon "$root_dir/bin/"
}

# postgresql 初始化
postgresql_init() {
    ( python3 "$pwd_dir"/postgresql_init.py && GREEN 'postgresql initialization succeeded' ) || RED 'postgresql initialization failed'
}