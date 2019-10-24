#!/usr/bin/env bash

set -eu -o pipefail

# Surrounding in brackets ensures that the whole install script runs
# and not just a part of it if there's a strange partial download or
# buffering issue.
{

# Let's make some pretty stuff
COLOR_RESET="\e[0m"
COLOR_WHITE="\e[1;37m"
COLOR_BLACK="\e[0;30m"
COLOR_BLUE="\e[0;34m"
COLOR_LIGHT_BLUE="\e[1;34m"
COLOR_GREEN="\e[0;32m"
COLOR_LIGHT_GREEN="\e[1;32m"
COLOR_CYAN="\e[0;36m"
COLOR_LIGHT_CYAN="\e[1;36m"
COLOR_RED="\e[0;31m"
COLOR_LIGHT_RED="\e[1;31m"
COLOR_PURPLE="\e[0;35m"
COLOR_LIGHT_PURPLE="\e[1;35m"
COLOR_BROWN="\e[0;33m"
COLOR_YELLOW="\e[1;33m"
COLOR_GRAY="\e[0;30m"
COLOR_LIGHT_GRAY="\e[0;37m"
SYMBOL_TICK="✔"
SYMBOL_CROSS="✖"
SYMBOL_WARN="⚠"

GITHUB_FILE_PATH="https://raw.githubusercontent.com/devopsmakers/macstrap/master/files/"

detect_profile() {
    local DETECTED_PROFILE
    DETECTED_PROFILE=''
    local SHELLTYPE
    SHELLTYPE="$(basename "/$SHELL")"

    if [ "$SHELLTYPE" = "bash" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            DETECTED_PROFILE="$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            DETECTED_PROFILE="$HOME/.bash_profile"
        fi
    elif [ "$SHELLTYPE" = "zsh" ]; then
        DETECTED_PROFILE="$HOME/.zshrc"
    fi

    if [ ! -z "$DETECTED_PROFILE" ]; then
        echo "$DETECTED_PROFILE"
    fi
}

ensure_bin_dirs() {
    if [ ! -d "$HOME/.bin" ]; then
        echo "${COLOR_YELLOW}${SYMBOL_WARN}${COLOR_RESET} Missing user bin directory. Attempting to create"
        mkdir -p "$HOME/.bin"
        chmod 0700 "$HOME/.bin"
        chown $USER:admin "$HOME/.bin"
    fi
    if [ ! -d "$HOME/.macstrap" ]; then
        echo "${COLOR_YELLOW}${SYMBOL_WARN}${COLOR_RESET} Missing user macstrap config directory. Attempting to create"
        mkdir -p "$HOME/.macstrap"
        chmod 0700 "$HOME/.macstrap"
        chown $USER:admin "$HOME/.macstrap"
    fi
    if [ ! -d "/usr/local/bin" ]; then
        echo "${COLOR_YELLOW}${SYMBOL_WARN}${COLOR_RESET} Missing install directory. Attempting to create, will prompt for your admin password:"
        local USER="$(whoami)"
        sudo mkdir /usr/local/bin
        sudo chmod 0775 /usr/local/bin
        sudo chown $USER:admin /usr/local/bin
    fi
}

ensure_xcode() {
    xcode-select --install 2>/dev/null || echo "${COLOR_GREEN}${SYMBOL_TICK}${COLOR_RESET} XCode tools installed"
}

grab_file() {
    if [ -f "${HOME}/$1" ]; then
        mv "${HOME}/$1" "${HOME}/$1.bak"
    fi
    curl --fail "${GITHUB_FILE_PATH}/$1" -o "${HOME}/$1"
    if [ ! -z $2 ]; then
        chmod $2 "${HOME}/$1"
    fi
}

install_homebrew() {
    brew --version || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    /usr/local/bin/brew doctor
}

install_zsh() {
    /usr/local/bin/brew install zsh
    grep -q /usr/local/bin/zsh /etc/shells || sudo -s 'echo /usr/local/bin/zsh >> /etc/shells'
    chsh -s /usr/local/bin/zsh
    if [ ! -d "${HOME}/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    fi
    if [ ! -d "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
    fi
}

install_iterm2() {
    if [ ! -d /Applications/iTerm.app ]; then
        brew cask install iterm2
    fi
    curl -o "/Library/Fonts/MesloLGS NF.ttf" https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/S/Regular/complete/Meslo%20LG%20S%20Regular%20Nerd%20Font%20Complete.ttf
}

function iterm_run_macstrap() {
    osascript &>/dev/null <<EOF
        tell application "iTerm"
            activate
            set term to (make new terminal)
            tell term
                launch session "Default Session"
                tell the last session
                    delay 1
                    write text "macstrap -H"
                end
            end
        end tell
EOF
}

install_main() {
    ensure_bin_dirs
    ensure_xcode

    # We use homebrew for just about everything
    install_homebrew
    # Install and configure oh-my-zsh shell
    install_zsh

    install_iterm2

    # Get the files that we want to install to $HOME
    grab_file ".zshrc" "0700"
    grab_file ".p10k.zsh" "0700"
    grab_file ".myrc" "0700"
    grab_file ".bin/macstrap" "0500"
    grab_file ".bin/open" "0500"
    grab_file ".macstrap/config.json"
    grab_file "Library/Preferences/com.googlecode.iterm2.plist"

    echo "Install completed."
    echo ""
    echo "Note: Some tools will require a new terminal window"
    echo ""

    if [ -z $UP ]; then
        iterm_run_macstrap
    fi

    shell_reset
}

shell_reset() {
    unset -f detect_profile ensure_bin_dirs ensure_xcode install_homebrew install_zsh install_iterm2 grab_file install_main shell_reset iterm_run_macstrap
}

install_main

}
