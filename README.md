# RudeHash

![RudeHash](https://i.imgur.com/pOunR1T.png "RudeHash")

## About

RudeHash is a simple wrapper script to mine coins directly on NVIDIA GPUs. Features:

* Easy switching between supported coins and miners
* Automatic download of miners
* Income estimation using WhatToMine numbers
* Auto-restart upon miner crash

## Support

Coins:

| Coin | Algo |
|---|---|
| BTG | EquiHash |
| ETH | Ethash |
| FTC | NeoScrypt |
| MONA | Lyra2v2 |
| VTC | Lyra2v2 |
| ZCL | EquiHash |
| ZEC | EquiHash |
| ZEN | EquiHash |

Algos:

| Algo | Miner |
|---|---|
| Ethash | ethminer, Excavator |
| EquiHash | ccminer-tpruvot, DSTM, Excavator, Zec Miner |
| Lyra2v2 | ccminer-klaust, ccminer-tpruvot, Excavator, vertminer |
| NeoScrypt | ccminer-klaust, ccminer-tpruvot, Excavator |

Pools:

* Mining Pool Hub

## Installation

1. Download and install the latest release of:

* [NVIDIA Driver](https://www.geforce.com/drivers)
* [PowerShell Core](https://github.com/PowerShell/PowerShell/releases/latest) (x64 MSI recommended)
* [Visual C++ 2017 x64 Redistributable](https://go.microsoft.com/fwlink/?LinkId=746572) - for **Excavator**

2. Download and extract the [latest release of RudeHash](https://github.com/gradinkov/rudehash/releases/latest). 

3. Copy `rudehash.properties.example` to `rudehash.properties` and update the values as needed.

4. Finally, create a new shortcut: `pwsh.exe -Command C:\path\to\rudehash\rudehash.ps1`
