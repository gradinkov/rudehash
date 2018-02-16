# RudeHash

![RudeHash](https://i.imgur.com/EQLx5at.png "RudeHash")

## About

RudeHash is a simple wrapper script to mine coins directly. Features:

* Easy switching between supported coins and miners
* Automatic download of miners
* Income estimation using WhatToMine numbers
* Auto-restart upon miner crash

## Support

Coins:

| Coin | Algo |
|---|---|
| ZCL | EquiHash |
| ZEC | EquiHash |
| ZEN | EquiHash |

Algos:

| Algo | Miner |
|---|---|
| EquiHash | ccminer-tpruvot, DSTM, Zec Miner |

Pools:

* Mining Pool Hub

## Installation

* Download and install the [latest release of PowerShell Core](https://github.com/PowerShell/PowerShell/releases/latest) (x64 MSI recommended)
* Download and install the [latest release of Git for Windows](https://github.com/git-for-windows/git/releases/latest) (64 bit EXE recommended)
* Start **Git Bash** from the Start Menu and download RudeHash to your home directory:

~~~
git clone https://github.com/gradinkov/rudehash.git ${USERPROFILE}/rudehash
~~~

* Rename `rudehash.properties.example` to `rudehash.properties` and update the values as needed.
* Create a new shortcut: `pwsh.exe -Command %USERPROFILE%\rudehash\rudehash.ps1`

## Upgrading

Start **Git Bash** from the Start Menu, then:

~~~
cd ${USERPROFILE}/rudehash
git pull
~~~
