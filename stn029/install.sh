#!/bin/bash
wp="/usr/local/stn"
. $wp/functions.sh

install_stn() {
    latestVersion=$(curl https://github.com/FH0/stn/releases/latest | sed 's|.*tag/\(.*\)".*|\1|')
    if [ ! -z "$(uname -m | grep -E 'amd64|x86_64')" ]; then
        ARCH="x86_64-unknown-linux-musl"
    elif [ ! -z "$(uname -m | grep -E '86')" ]; then
        ARCH="i686-unknown-linux-musl"
    elif [ ! -z "$(uname -m | grep -E 'armv8|aarch64')" ]; then
        ARCH="aarch64-unknown-linux-musl"
    elif [ ! -z "$(uname -m | grep -E 'arm')" ]; then
        ARCH="arm-unknown-linux-musleabi"
    elif [ ! -z "$(uname -m | grep -E 'mips64')" ]; then
        # check little/big endian 0->big 1->little
        if [ "$(echo -n I | hexdump -o | awk '{ print substr($2,6,1); exit}')" == "1" ]; then
            ARCH="mips64el-unknown-linux-muslabi64"
        else
            ARCH="mips64-unknown-linux-muslabi64"
        fi
    elif [ ! -z "$(uname -m | grep -E 'mips')" ]; then
        # check little/big endian 0->big 1->little
        if [ "$(echo -n I | hexdump -o | awk '{ print substr($2,6,1); exit}')" == "1" ]; then
            ARCH="mipsel-unknown-linux-musl"
        else
            ARCH="mips-unknown-linux-musl"
        fi
    else
        colorEcho $RED "不支持的系统架构！"
        bash $wp/uninstall.sh >/dev/null 2>&1
        exit 1
    fi
    colorEcho $BLUE "正在下载最新核心 $ARCH-stn $latestVersion ..."
    curl -L -o $wp/stn "https://github.com/FH0/stn/releases/download/$latestVersion/$ARCH-stn"

    chmod -R 777 $wp

    colorEcho $BLUE "正在安装 stn 控制面板..."
    ip_info init
    cp $wp/manage_panel.sh /bin/stn

    colorEcho $BLUE "正在设置随机端口..."
    random=$(random_port)
    sed -i "s|address.*|address\": \"[::]:$random\",|" $wp/config.json

    colorEcho $BLUE "正在设置随机密码..."
    random=$(random_password 6)
    sed -i "s|password.*|password\": \"$random\",|" $wp/config.json

    colorEcho $BLUE "正在设置日志文件路径..."
    sed -i "s|log_file\".*|log_file\": \"$wp/running.log\",|" $wp/config.json

    colorEcho $BLUE "正在启动stn..."
    start_service
}

main() {
    cmd_need "hexdump"
    install_stn
    colorEcho $GREEN "stn安装完成！输入stn可进入控制面板！"
}

main
