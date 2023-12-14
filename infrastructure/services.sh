#!/bin/bash
# 基础层服务控制脚本

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
PLAIN='\033[0m'

next() {
 printf '%-70s\n' | sed 's/\ /-/g'
}

# 红色提示
RED() {
    next && echo -e "$RED""$*""$PLAIN" && exit 1
}

# 绿色提示
GREEN() {
    next && echo -e "$GREEN""$*""$PLAIN"
}

pwd_dir=$(pwd)
config_path="$pwd_dir/../config.yaml"

# 启动基础环境
start() {

    # 读取配置文件
    config_base_data=$(cat $config_path | grep -i ^base -A 3) || RED "config.yaml Error"
    config_postgresql_data=$(cat $config_path | grep ^postgresql -A 5) 
    config_erigon_data=$(cat $config_path | grep -i ^erigon -A 5)
    base_logs_path=$(echo "$config_base_data" | grep log_dir | awk -F'"' '{print $2}')
    mkdir -p $base_logs_path > /dev/null 2>&1
    erigon_log_file="$base_logs_path"/erigon.log
    ethereumetl_log_file="$base_logs_path"/ethereumetl.log


    postgres_host=$(echo "$config_postgresql_data" | grep host | awk -F'"' '{print $2}')
    postgres_port=$(echo "$config_postgresql_data" | grep port | awk -F'"' '{print $2}')
    postgres_db=$(echo "$config_postgresql_data" | grep dbname | awk -F'"' '{print $2}')
    postgres_user=$(echo "$config_postgresql_data" | grep user | awk -F'"' '{print $2}')
    postgres_pass=$(echo "$config_postgresql_data" | grep pass | awk -F'"' '{print $2}')

    erigon_host=$(echo "$config_erigon_data" | grep host | awk -F'"' '{print $2}')
    erigon_http_port=$(echo "$config_erigon_data" | grep http_port | awk -F'"' '{print $2}')
    erigon_private_port=$(echo "$config_erigon_data" | grep private_port | awk -F'"' '{print $2}')
    erigon_data_dir=$(echo "$config_erigon_data" | grep data_dir | awk -F'"' '{print $2}')


    GREEN 'Postgresql 数据库'
    echo $postgres_host:$postgres_port/$postgres_db $postgres_user


    # erigon 启动
    # 后续：启动失败应终止
    erigon  --datadir="$erigon_data_dir" --chain=dev --http.enabled --http.addr 0.0.0.0 --http.port "$erigon_http_port" --private.api.addr=localhost:"$erigon_private_port" --mine --http.api=eth,erigon,web3,net,debug,trace,txpool,parity,admin --http.corsdomain="*" --http.trace=true --rpc.allow-unprotected-txs >> "$erigon_log_file" 2>&1 & 

    # ethereum-etl 启动
    ethereumetl stream --provider-uri http://"$erigon_host":"$erigon_http_port"  -e block,transaction,log,token_transfer,trace,contract,token --output postgresql+pg8000://"$postgres_user":"$postgres_pass"@"$postgres_host":"$postgres_port"/"$postgres_db" >> "$ethereumetl_log_file" 2>&1 &

    GREEN "基础环境启动完毕"
    exit 0
}


if [ "$1" = "start" ]; then
    start
fi