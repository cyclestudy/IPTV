#!/bin/ash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[ $EUID -ne 0 ] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

# Check OS and set release variable
if [ -f /etc/os-release ]; then
    . /etc/os-release
    release=$ID
elif [ -f /usr/lib/os-release ]; then
    . /usr/lib/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi
echo "The OS release is: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "arch: $(arch)"

os_version=""
os_version=$(grep "^VERSION_ID" /etc/os-release | cut -d '=' -f2 | tr -d '"' | tr -d '.')

if [ "${release}" = "alpine" ]; then
    echo "Your OS is Alpine Linux"
else
    echo -e "${red}Your operating system is not supported by this script.${plain}\n"
    exit 1
fi

install_base() {
    apk update && apk add wget curl tar tzdata
}

gen_random_string() {
    local length="$1"
    tr -dc 'a-zA-Z0-9' </dev/urandom | head -c "$length"
}

config_after_install() {
    # Here you can add any configuration steps if needed
    echo "Configuration completed."
}

install_x-ui() {
    cd /usr/local/

    # 获取最新版本，加入 ghproxy 镜像支持，避免 API 请求次数限制
    tag_version=$(curl -Ls "https://ghp.ci/https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    
    # 如果获取版本失败，则使用指定版本
    if [ -z "$tag_version" ]; then
        echo -e "${yellow}Failed to fetch x-ui version. Defaulting to version v2.3.5.${plain}"
        tag_version="v2.3.5"
    fi

    echo -e "Installing x-ui version: ${tag_version}"
    wget -O /usr/local/x-ui-linux-$(arch).tar.gz https://ghp.ci/https://github.com/MHSanaei/3x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz
    if [ $? -ne 0 ]; then
        echo -e "${red}Failed to download x-ui. Please check your network connection.${plain}"
        exit 1
    fi

    if [ -d /usr/local/x-ui/ ]; then
        systemctl stop x-ui
        rm -rf /usr/local/x-ui/
    fi

    tar zxvf x-ui-linux-$(arch).tar.gz
    rm x-ui-linux-$(arch).tar.gz -f
    cd x-ui
    chmod +x x-ui

    cp -f x-ui.service /etc/init.d/
    chmod +x /etc/init.d/x-ui
    ln -s /usr/local/x-ui/x-ui /usr/bin/x-ui
    config_after_install

    /etc/init.d/x-ui start
    echo -e "${green}x-ui ${tag_version}${plain} installation finished, it is running now..."
    echo -e "----------------------------------------------"
    echo -e "x-ui control commands:"
    echo -e "x-ui start        - Start"
    echo -e "x-ui stop         - Stop"
    echo -e "x-ui restart      - Restart"
    echo -e "x-ui status       - Current Status"
    echo -e "----------------------------------------------"
}

echo -e "${green}Running...${plain}"
install_base
install_x-ui
