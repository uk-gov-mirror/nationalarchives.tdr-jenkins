#!/bin/bash
git config --global user.signingkey $GPG_KEY_ID
git config --global commit.gpgsign true
gpg-agent --allow-preset-passphrase --daemon
chown -R jenkins:jenkins /home/jenkins/.gnupg && find /home/jenkins/.gnupg -type f -exec chmod 600 {} \; && find /home/jenkins/.gnupg -type d -exec chmod 700 {} \;
echo -e "$GPG_KEY" | gpg --batch --import
echo $GPG_KEY_ID:6: | gpg --import-ownertrust
export KEYGRIP=$(gpg --list-keys --with-keygrip | grep Keygrip | cut -d'=' -f2 | xargs)
/usr/libexec/gpg-preset-passphrase -c $KEYGRIP <<< $PASSPHRASE
/usr/local/bin/jenkins-agent "$@"
