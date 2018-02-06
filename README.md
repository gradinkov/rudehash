# RudeHash

![RudeHash](https://i.imgur.com/EQLx5at.png "RudeHash")

## About

RudeHash is a simple wrapper script to mine coins directly. Features:

* Easy switching between supported coins:
  * ZCL
  * ZEC
  * ZEN
* Income estimation using WhatToMine numbers
* Auto-restart upon miner crash

It has the potential to become multi-pool and multi-miner, but right now it only supports Mining Pool Hub and Zec Miner.

## Installation

* Download and install the [latest release of PowerShell Core](https://github.com/PowerShell/PowerShell/releases/latest) (x64 MSI recommended)
* Download and install the [latest release of Git for Windows](https://github.com/git-for-windows/git/releases/latest) (64 bit EXE recommended)
* Download [EWBF's Zec Miner](https://github.com/nanopool/ewbf-miner/releases) and extract as `%USERPROFILE%\tools\zecminer\miner.exe`
* Start **Git Bash** from the Start Menu and download RudeHash to `%USERPROFILE%\tools`:

~~~
git clone https://github.com/gradinkov/rudehash.git ${USERPROFILE}/tools/rudehash
~~~

* Rename `rudehash.properties.example` to `rudehash.properties` and update the values as needed.
* Create a new shortcut:
  * Target: `pwsh.exe -Command %USERPROFILE%\tools\rudehash\rudehash.ps1`
  * Start in: `%USERPROFILE%\tools\rudehash`
