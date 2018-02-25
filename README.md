# RudeHash

![RudeHash](https://i.imgur.com/pOunR1T.png "RudeHash")

## About

RudeHash is a wrapper script to mine coins and algos on NVIDIA GPUs, written in PowerShell. Features:

* Easy switching between supported pools, coins, algos and miners
* Automatic download of miners
* Auto-restart upon miner crash
* Coin mining earnings estimation, using WhatToMine numbers

## Installation

1. Download and install the latest release of:

* [NVIDIA Driver](https://www.geforce.com/drivers)
* [PowerShell Core](https://github.com/PowerShell/PowerShell/releases/latest) (x64 MSI recommended)
* [Visual C++ 2017 x64 Redistributable](https://go.microsoft.com/fwlink/?LinkId=746572) - for **Excavator**

2. Download and extract the [latest release of RudeHash](https://github.com/gradinkov/rudehash/releases/latest). 

3. Copy `rudehash.properties.example` to `rudehash.properties` and update the values as needed.

4. Finally, create a new shortcut: `pwsh.exe -Command C:\path\to\rudehash\rudehash.ps1`

## Support

Algos:

| Algo | Miner |
|---|---|
| Ethash | ethminer, Excavator |
| EquiHash | ccminer-tpruvot, DSTM, Excavator, Zec Miner |
| Lyra2v2 | ccminer-klaust, ccminer-tpruvot, Excavator, vertminer |
| NeoScrypt | ccminer-klaust, ccminer-tpruvot, Excavator |
| PHI1612 | ccminer-phi |

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

Pools:

| Pool | Mining modes |
|---|---|
| Mining Pool Hub | algo, coin |
| zpool | algo |

## Statistics

For performance reports I recommend the incredibly awesome [MiningPoolHubStats](https://miningpoolhubstats.com/user).
RudeHash adjusts the miner arguments so that you can easily identify your individual rigs, and it works well even if you mix pools.

![MPHStats](https://i.imgur.com/NpcUbUd.png "MPHStats")
