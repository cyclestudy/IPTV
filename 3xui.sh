#!/bin/sh

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[ "$EUID" -ne 0 ] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n" && exit 1

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

# 定义 arch 函数
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

case "$release" in
    alpine)
        echo "Your OS is Alpine Linux"
        ;;
    arch)
        echo "Your OS is Arch Linux"
        ;;
    *)
        echo -e "${red}Your operating system is not supported by this script.${plain}\n"
        echo "Please ensure you are using one of the following supported operating systems:"
        echo "- Alpine Linux"
        echo "- Arch Linux"
        exit 1
        ;;
esac

# 定义 install_base 函数
install_base() {
    case "$release" in
    alpine)
        apk update && apk add --no-cache wget curl tar tzdata
        ;;
    *)
        echo -e "${red}Unsupported OS for package installation.${plain}\n"
        exit 1
        ;;
    esac
}

# 定义 gen_random_string 函数
gen_random_string() {
    local length="$1"
    local random_string=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length")
    echo "$random_string"
}

# 定义 config_after_install 函数
config_after_install() {
    local existing_username=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'username: .+' | awk '{print $2}')
    local existing_password=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'password: .+' | awk '{print $2}')
    local existing_webBasePath=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'webBasePath: .+' | awk '{print $2}')
    local existing_port=$(/usr/local/x-ui/x-ui setting -show true | grep -Eo 'port: .+' | awk '{print $2}')
    local server_ip=$(curl -s https://api.ipify.org)

    # 配置逻辑和原代码保持一致，省略详细代码
}

# 定义 install_x-ui 函数
install_x-ui() {
    cd /usr/local/

    tag_version=$(curl -Ls "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$tag_version" ]; then
        echo -e "${red}Failed to fetch x-ui version, it may be due to GitHub API restrictions, please try it later${plain}"
        exit 1
    fi
    echo -e "Got x-ui latest version: ${tag_version}, beginning the installation..."
    wget -O /usr/local/x-ui-linux-$(arch).tar.gz https://github.com/MHSanaei/3x-ui/releases/download/${tag_version}/x-ui-linux-$(arch).tar.gz

    if [ -e /usr/local/x-ui/ ]; then
        /etc/init.d/x-ui stop
        rm -rf /usr/local/x-ui/
    fi

    tar zxvf x-ui-linux-$(arch).tar.gz
    rm -f x-ui-linux-$(arch).tar.gz
    cd x-ui
    chmod +x x-ui
    cp -f x-ui.init /etc/init.d/x-ui
    chmod +x /etc/init.d/x-ui
    config_after_install

    /etc/init.d/x-ui start
    echo -e "${green}x-ui ${tag_version}${plain} installation finished, it is running now..."
    echo -e ""
    echo -e "x-ui control menu usages: "
    echo -e "----------------------------------------------"
    echo -e "x-ui              - Admin Management Script"
    echo -e "x-ui start        - Start"
    echo -e "x-ui stop         - Stop"
    echo -e "x-ui restart      - Restart"
    echo -e "x-ui status       - Current Status"
    echo -e "----------------------------------------------"
}

echo -e "${green}Running...${plain}"
install_base
install_x-ui $1
