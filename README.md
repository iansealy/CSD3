CSD3
====

Setup:

```
mkdir ~/checkouts ~/containers
cd ~/checkouts
git clone git@github.com:iansealy/CSD3.git # Or https://github.com/iansealy/CSD3.git if you aren't iansealy
rm -f ~/.bashrc ~/.bash_profile ~/.profile ~/.bash_logout ~/.bash_history
ln -s ~/checkouts/CSD3/dotfiles/bashrc ~/.bashrc
ln -s ~/checkouts/CSD3/dotfiles/profile ~/.profile
ln -s ~/checkouts/CSD3/dotfiles/environ ~/.environ
ln -s ~/checkouts/CSD3/dotfiles/aliases ~/.aliases
ln -s ~/checkouts/CSD3/dotfiles/functions ~/.functions
ln -s ~/checkouts/CSD3/dotfiles/bash_logout ~/.bash_logout
ln -s ~/checkouts/CSD3/dotfiles/gitconfig ~/.gitconfig
ln -s ~/checkouts/CSD3/modulefiles ~/privatemodules
ln -s ~/checkouts/CSD3/packages ~/packages
ln -s ~/checkouts/CSD3/bin ~/bin
exit
```
