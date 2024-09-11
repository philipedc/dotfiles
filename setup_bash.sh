#!/bin/bash -e

# Colors
RC='\033[0m'    
RED='\033[31m'
YELLOW='\033[33m'
GREEN='\033[32m'

# Optional packages
ZOXIDE=""
TMUX=""

# Function Definitions

ask_question() {
    local QUESTION="$1"
    local VARIABLE="$2"
    local VALUE_IF_YES="$3"

    while true; do
        echo -e "${YELLOW}$QUESTION (y/n)${RC}"  # Use -e to enable interpretation of backslash escapes
        read response
        case $response in
            [yY]* ) eval "$VARIABLE=$VALUE_IF_YES"; break;;
            [nN]* ) break;;
            * ) echo -e "${RED}Invalid response. Please, type y or n.${RC}";;
        esac
    done
}

command_exists() {
    command -v "$1" > /dev/null
}

check_env() {
    echo -e "${YELLOW}Checking environment...${RC}"
    local POSSIBLE_PACKAGE_MANAGERS="apt apt-get dnf pacman yum zypper apk nix-env"

    for pm in $POSSIBLE_PACKAGE_MANAGERS; do
        if command_exists "$pm"; then
            PACKAGE_MANAGER="$pm"
            break
        fi
    done
    if [ -z "$PACKAGE_MANAGER" ]; then
        echo -e "${RED}No package manager found. Exiting.${RC}"
        exit 1
    fi

    if command_exists "sudo"; then
        SUDO_CMD="sudo"
    elif command_exists "doas" && [ -f "/etc/doas.conf" ]; then
        SUDO_CMD="doas"
    else
        SUDO_CMD="su -c"
    fi

    echo -e "${GREEN}Using package manager: $PACKAGE_MANAGER${RC}"

    # Check if the current directory is writable
    SCRIPT_PATH=$(dirname "$(realpath "$0")")
    if [ ! -w "$SCRIPT_PATH" ]; then
        echo -e "${RED}Current directory is not writable. Exiting.${RC}"
        exit 1
    fi

    POSSIBLE_SUPERGROUPS="wheel sudo root adm"
    for sg in $POSSIBLE_SUPERGROUPS; do
        if groups | grep -q "$sg"; then
            SUGROUP="$sg"
            break
        fi
    done
    if [ -z "$SUGROUP" ]; then
        echo -e "${RED}No supergroup found. Exiting.${RC}"
        exit 1
    fi

    if ! groups | grep -q "$SUGROUP"; then
        echo -e "${RED}Current user is not in the $SUGROUP group. Exiting.${RC}"
        exit 1
    fi
}

install_packages() {
    echo -e "${YELLOW}Installing packages...${RC}"
    local DEPENDENCIES="bash bash-completion ripgrep trash-cli $TMUX $ZOXIDE"

    if [ "$PACKAGE_MANAGER" = "apt" ]; then
        $SUDO_CMD $PACKAGE_MANAGER install -y $DEPENDENCIES
    fi
}

configure_package() {

	local PACKAGE_NAME="$1"
	local SYSTEM_CONFIGURATION_PATH="$2"
	local SCRIPT_CONFIGURATION_PATH="${BUILD_DIR}/$(basename ${SYSTEM_CONFIGURATION_PATH})"

	# if package was not chosen, return
	if [ -z "$PACKAGE_NAME" ]; then
		return
	fi

	echo -e "${YELLOW}Configuring package ${PACKAGE_NAME}...${RC}"

	if [ -f "$SYSTEM_CONFIGURATION_PATH" ]; then
		echo -e "${GREEN}Configuration file already exists. Moving current configuration to trash.${RC}"
		trash "$SYSTEM_CONFIGURATION_PATH"
	fi
	echo -e "${GREEN}Creating configuration file: ${SYSTEM_CONFIGURATION_PATH}${RC}"
	mv "${SCRIPT_CONFIGURATION_PATH}" "$SYSTEM_CONFIGURATION_PATH"
}

# Main script

ask_question "Do you want to install zoxide?" "ZOXIDE" "zoxide"
ask_question "Do you want to install tmux?" "TMUX" "tmux"

# Create a temporary build directory
BUILD_DIR=$(mktemp -d)

# Check if string BUILD_DIR is empty
if [ -z "$BUILD_DIR" ]; then
    echo -e "${RED}Failed to run 'mktemp -d'. Exiting.${RC}"
    exit 1
fi


echo -e "${YELLOW}Cloning repository into: ${BUILD_DIR}${RC}"
git clone --depth=1 https://github.com/philipedc/config $BUILD_DIR --quiet
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Successfully cloned repository${RC}"
else
    echo -e "${RED}Failed to clone repository${RC}"
    exit 1
fi

check_env
install_packages
configure_package "$TMUX" "${HOME}/.tmux.conf"
configure_package "bash" "${HOME}/.bashrc"