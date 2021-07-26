#!/bin/bash
git config --global user.signingkey $GPG_KEY_ID
git config --global gpg.program /usr/local/bin/git-gpg
git config --global commit.gpgsign true
echo -e "$GPG_KEY" | gpg --batch --import
echo $GPG_KEY_ID:6: | gpg --import-ownertrust
/usr/local/bin/jenkins-agent "$@"