SpaceVim Config
===============

Custom configuration for [SpaceVim](https://spacevim.org/)

## Instalation
Clone this repository in the `$HOME` directory of the windows user and rename it to `.SpaceVim.d`.

## Setup
This configuration is shared between wsl ubuntu vim and windows gvim. From `wsl` create a symlink to the `.SpaceVim.d` folder in the windows `$HOME` directory.

```
$ ln -s /mnt/c/Users/[user_name]/.SpaceVim.d ~
```

## Features
* Disable relative number
* Set font `DroidSansMono NF` and font-size `18`
* Enable buffer for custom [user-configuration](https://github.com/DanSM-5/user-configuration) files
