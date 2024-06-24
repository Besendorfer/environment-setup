#!/usr/bin/env bash
#
# Referenced from https://gist.github.com/codeinthehole/26b37efa67041e1307db
#
# Last update: March 2018
#
# Let us begin

VERBOSE=false
FORCE=false
while true; do
    case "$1" in
        -f | --force ) FORCE=true; shift ;;
        -v | --verbose ) VERBOSE=true; shift ;;
        -h | --help ) cat << 'EOF'
usage: ./build.sh [--verbose][--force][--help]
Preps your machine by installing and configuring commonly needed programs

OPTIONS
    -h, --help
        Prints the help you are reading right now

    -v, --verbose
        Displays more information about what commands are run

    -f, --force
        Overwrites existing configurations

EOF
        exist ;;
        * ) break ;;
    esac
done

# Error handling
# Verbose adds 'x' which spits out each line run
if [[ "$VERBOSE" == true ]]; then
    echo "Verbose turned on...";
    set -Eeuox pipefail
else
    set -Eeou pipefail
fi

echo "Starting Build, you will be prompted, stay attentive..."

if [[ "$FORCE" == true ]] || ! git config --global --get user.name > /dev/null 2>&1; then
    read -p "Please enter your name for git [Teancum Besendorfer]: " name
    name=${name:-Teancum Besendorfer}
fi

if [[ "$FORCE" == true ]] || ! git config --global --get user.email > /dev/null 2>&1; then
    read -p "Please enter your email for git [teancum@besendorfer.net]: " email
    email=${email:-teancum@besendorfer.net}
fi

# Prevent Mac from holding your hand and allow non-app store programs to be run.
if [[ $(spctl --status) != 'assessments disabled' ]]; then
    echo "Allowing non-app store installs..."
    sudo spctl --master-disable
fi

# Ensure Xcode is installed
if test ! $(which xcode-select); then
    echo "Installing xcode tools..."
    xcode-select --install
fi

# Check for Homebrew, install if we don't have it
if test ! $(which brew); then
    echo "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew doctor
fi

# Update homebrew recipes
brew update

# Install Brew native packages. Do it one at a time because brew is stupid and will stop at the first one already installed
echo "Installing Brew Packages..."
brew list bash-completion   > /dev/null 2>&1 || brew install bash-completion
brew list bash-git-prompt   > /dev/null 2>&1 || brew install bash-git-prompt
brew list git               > /dev/null 2>&1 || brew install git
brew list node              > /dev/null 2>&1 || brew install node
brew list npm               > /dev/null 2>&1 || brew install npm
brew list nvm               > /dev/null 2>&1 || brew install nvm
brew list thefuck           > /dev/null 2>&1 || brew install thefuck
brew list yarn              > /dev/null 2>&1 || brew install yarn

# Install Casks
echo "Installing Cask Apps..."
brew list --cask caffeine           > /dev/null 2>&1 || brew install --cask caffeine
brew list --cask firefox            > /dev/null 2>&1 || brew install --cask firefox
brew list --cask google-chrome      > /dev/null 2>&1 || brew install --cask google-chrome
brew list --cask postman            > /dev/null 2>&1 || brew install --cask postman
brew list --cask tableplus          > /dev/null 2>&1 || brew install --cask tableplus
brew list --cask slack              > /dev/null 2>&1 || brew install --cask slack
brew list --cask tunnelblick        > /dev/null 2>&1 || brew install --cask tunnelblick
brew list --cask visual-studio-code > /dev/null 2>&1 || brew install --cask visual-studio-code
brew list --cask sequel-pro         > /dev/null 2>&1 || brew install --cask sequel-pro
brew list --cask sublime-text       > /dev/null 2>&1 || brew install --cask sublime-text
brew list --cask vagrant            > /dev/null 2>&1 || brew install --cask vagrant
brew list --cask vlc                > /dev/null 2>&1 || brew install --cask vlc

# We need to know if virtual box was installed for later, so this is a little more verbase
VIRTUALBOXINSTALLFAILED=false
if brew list --cask virtualbox > /dev/null 2>&1; then
    if ! brew install --cask virtualbox; then
        VIRTUALBOXINSTALLFAILED=true
    fi
fi

echo "Cleaning up brew..."
brew cleanup

# echo "Installing vagrant plugins"
vagrant plugin install vagrant-cachier
vagrant plugin install vagrant-share

echo "Installing vscode extensions..."
code --install-extension bmewburn.vscode-intelephense-client
code --install-extension eamodio.gitlens
code --install-extension editorconfig.editorconfig
# code --install-extension felixbecker.php-debug
code --install-extension ms-vscode.vscode-typescript-tslint-plugin
code --install-extension msjsdiag.debugger-for-chrome
code --install-extension neilbrayfield.php-docblocker

# Install composer
# Note - As of March 2018, there is no vanilla brew package for composer
if test ! $(which composer); then
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f composer-setup.php
fi

# Install Meld
if [ -f /Applications/Meld.app ]; then
    echo "Installing Meld..."
    curl -Lo $TMPDIR/meldmerge.dmg https://github.com/yousseb/meld/releases/download/osx-19/meldmerge.dmg
    sudo hdiutil attach $TMPDIR/meldmerge.dmg
    sudo cp -R /Volumes/Meld\ Merge/Meld.app /Applications
    sudo hdiutil unmount /Volumes/Meld\ Merge/
    rm -f $TMPDIR/meldmerge.dmg
fi

# Write the git config, setting up meld as the difftool
# Note this will not overwrite existing settings
echo "Setting up git config..."
([[ "$FORCE" != true ]] && git config --global --get merge.tool                     > /dev/null 2>&1) || git config --global merge.tool meld
([[ "$FORCE" != true ]] && git config --global --get mergetool.keepBackup           > /dev/null 2>&1) || git config --global mergetool.keepBackup false
([[ "$FORCE" != true ]] && git config --global --get mergetool.meld.trustexitcode   > /dev/null 2>&1) || git config --global mergetool.meld.trustexitcode true
([[ "$FORCE" != true ]] && git config --global --get mergetool.meld.cmd             > /dev/null 2>&1) || git config --global mergetool.meld.cmd 'open -W -a Meld --args "$LOCAL" "$BASE" "$REMOTE" --output="$MERGED"'
([[ "$FORCE" != true ]] && git config --global --get diff.tool                      > /dev/null 2>&1) || git config --global diff.tool meld
([[ "$FORCE" != true ]] && git config --global --get difftool.meld.trustexitcode    > /dev/null 2>&1) || git config --global difftool.meld.trustexitcode true
([[ "$FORCE" != true ]] && git config --global --get difftool.meld.cmd              > /dev/null 2>&1) || git config --global difftool.meld.cmd 'open -W -a Meld --args "$LOCAL" "$REMOTE"'
([[ "$FORCE" != true ]] && git config --global --get color.ui                       > /dev/null 2>&1) || git config --global color.ui true
([[ "$FORCE" != true ]] && git config --global --get push.default                   > /dev/null 2>&1) || git config --global push.default simple
([[ "$FORCE" != true ]] && git config --global --get user.email                     > /dev/null 2>&1) || git config --global user.email "$email"
([[ "$FORCE" != true ]] && git config --global --get user.name                      > /dev/null 2>&1) || git config --global user.name "$name"
([[ "$FORCE" != true ]] && git config --global --get core.pager                     > /dev/null 2>&1) || git config --global core.pager 'less -x5,9'
([[ "$FORCE" != true ]] && git config --global --get core.editor                    > /dev/null 2>&1) || git config --global core.editor 'code --wait --new-window'
([[ "$FORCE" != true ]] && git config --global --get pull.ff                        > /dev/null 2>&1) || git config --global pull.ff only
([[ "$FORCE" != true ]] && git config --global --get alias.cleanup                  > /dev/null 2>&1) || git config --global alias.cleanup '!git fetch -p; git branch --merged | egrep -v '"'"'^\*|master|develop'"'"' | xargs -n 1 git branch -d'
([[ "$FORCE" != true ]] && git config --global --get alias.mv-i                     > /dev/null 2>&1) || git config --global alias.mv-i '!cd -- ${GIT_PREFIX:-.}; git mv "$1" "$2.tmp"; git mv "$2.tmp" "$2" #'
([[ "$FORCE" != true ]] && git config --global --get rerere.enabled                 > /dev/null 2>&1) || git config --global rerere.enabled 1

# Setup bash_profile to point to bashrc
touch ~/.bash_profile
grep -qF '~/.bashrc' ~/.bash_profile || echo "if [ -f ~/.bashrc ]; then . ~/.bashrc; fi" >> ~/.bash_profile

# Add ll alias
grep -qF 'alias ll' ~/.bashrc || echo 'alias ll="ls -alF"' >> ~/.bashrc

# Add bash_completion (Caveats fixup)
grep -qF 'bash_completion' ~/.bashrc || \
cat << 'EOF' >> ~/.bashrc
[[ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]] && . "$(brew --prefix)/etc/profile.d/bash_completion.sh"
EOF

# Add bash-git-prompt (Caveats fixup)
grep -qF 'gitprompt' ~/.bashrc || \
cat << 'EOF' >> ~/.bashrc
if [ -f "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh" ]; then
  __GIT_PROMPT_DIR=$(brew --prefix)/opt/bash-git-prompt/share
  source "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh"
fi
EOF

# Add nvm (Caveats fixup)
mkdir -p ~/.nvm
grep -qF 'NVM_DIR' ~/.bashrc || \
cat << 'EOF' >> ~/.bashrc
export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && . "$(brew --prefix)/opt/nvm/nvm.sh" # This loads nvm
EOF

# Add thefuck (Caveats fixup)
grep -qF 'thefuck' ~/.bashrc || \
cat << 'EOF' >> ~/.bashrc
eval $(thefuck --alias)
EOF

# Add composer installs to path
grep -qF 'composer' ~/.bashrc || \
cat << 'EOF' >> ~/.bashrc
export PATH="$PATH:$HOME/.composer/vendor/bin"
EOF

# Make ssh keys persist after boots
touch ~/.ssh/config
grep -qF "UseKeychain" ~/.ssh/config || \
cat << 'EOF' >> ~/.ssh/config
Host *
    AddKeysToAgent yes
    UseKeychain yes
EOF

# Notify on completion
echo "Build Complete"
source ~/.bashrc

# Warn about virtualbox Caveats
if [[ "$VIRTUALBOXINSTALLFAILED" == true ]]; then
    echo "WARNING: Because of mac security I failed to install virtualbox"
    echo "         Follow the Caveat below, then run `brew cask install virtualbox`"
    brew cask info virtualbox | sed -n -e '/Caveats/,$p'
fi