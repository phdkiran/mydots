#!/usr/bin/env bash
conda env export -n base --file conda.ai.yml
pip list > pip.ai.list
pip freeze > requirements.txt


git config --global credential.https://github.com.username phdkiran
git config --global -edit

sudo apt-get install libgnome-keyring-dev
sudo make --directory=/usr/share/doc/git/contrib/credential/gnome-keyring
git config --global credential.helper /usr/share/doc/git/contrib/credential/gnome-keyring/git-credential-gnome-keyring





