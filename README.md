# RudeHash

![RudeHash](https://i.imgur.com/kQO48jP.png "RudeHash")

## About

RudeHash is a wrapper script to mine coins and algos on NVIDIA GPUs, written in PowerShell. Features:

* Easy switching between supported pools, coins, algos and miners
* Automatic download of miners
* Auto-restart upon miner crash
* Earnings and profit estimation, using WhatToMine for coins and NiceHash for algos
* Watchdog to restart mining automatically if hash rate is repeatedly zero
* Interactive first run wizard
* Miner status reporting to MultiPoolMiner's monitoring service

## Installation

1. Download and install the latest release of:

* [NVIDIA Driver](https://www.geforce.com/drivers)
* [PowerShell Core](https://github.com/PowerShell/PowerShell/releases/latest) (x64 MSI recommended)
* [Visual C++ 2017 x64 Redistributable](https://go.microsoft.com/fwlink/?LinkId=746572) - for **Excavator**

2. Download and extract the [latest release of RudeHash](https://github.com/gradinkov/rudehash/releases/latest).

3. Finally, create a new shortcut: `pwsh.exe -Command C:\path\to\rudehash\rudehash.ps1`

## Support

Algos:

| Algo | Miner |
|---|---|
| Ethash | ethminer, Excavator |
| EquiHash | ccminer-tpruvot, DSTM, Excavator, Zec Miner |
| HSR | ccminer-tpruvot, hsrminer |
| Keccak-C | ccminer-tpruvot |
| Lyra2v2 | ccminer-klaust, ccminer-tpruvot, Excavator, vertminer |
| NeoScrypt | ccminer-klaust, ccminer-tpruvot, Excavator |
| PHI1612 | ccminer-phi, ccminer-tpruvot |
| Polytimos | ccminer-polytimos, ccminer-tpruvot |
| X16R | ccminer-rvn |

Coins:

| Coin | Algo |
|---|---|
| BTCP | EquiHash |
| BTG | EquiHash |
| ETH | Ethash |
| FTC | NeoScrypt |
| MONA | Lyra2v2 |
| KREDS | Lyra2v2 |
| RVN | X16R |
| VTC | Lyra2v2 |
| ZCL | EquiHash |
| ZEC | EquiHash |
| ZEN | EquiHash |

Pools:

| Pool | Mining modes |
|---|---|
| Mining Pool Hub | algo, coin |
| NiceHash | algo |
| Suprnova | coin |
| zpool | algo |

## Monitoring

For health checks, you should most definitely check out MultiPoolMiner monitoring. [Obtain](https://multipoolminer.io/monitor/) your key, then set this same key in RudeHash, and you're ready to go.

![MPM](https://i.imgur.com/i8NtDH6.png "MPHStats")

For performance reports I recommend the incredibly awesome [MiningPoolHubStats](https://miningpoolhubstats.com/user).
RudeHash adjusts the miner arguments so that you can easily identify your individual rigs, and it works well even if you mix pools.

![MPHStats](https://i.imgur.com/NpcUbUd.png "MPHStats")

Finally, you can check the pool's corresponding status page:

* NiceHash: `https://www.nicehash.com/miner/<wallet>`
* zpool: `https://zpool.ca/?address=<wallet>`

## FAQ

* What's the point of this tool? I could mine with just a one line batch file!

That's correct. But when you make your choice, you gotta find the stratum URL, the port number, the algo, the corresponding miner, the miner's specific command line arguments... and once you pick a different mining target, you can start it all over again. On all your rigs. This constant messing around quickly becomes a tedious burden.

With RudeHash, you can forget about all of this. Just edit your config: select pool, algo and miner from a pre-defined, well-tested list, enter your credentials, and start mining!

* Why algo/coin mining? I could increase my profits with a sophisticated algo-switching miner!

Algo-switching is based on the idea of relatively short spikes in exchange rates of a particular coin. It kinda worked for a while on NiceHash, where the pool operates on a PPS scheme, _and_ you are credited in BTC within minutes. On other pools you're usually working in a PPLNS or similar scheme, and your earnings are on exchanges for _several hours_. Which totally defeats the whole purpose, i.e. quickly mining and exchanging a coin while it's hot.

In fact, not even NiceHash' algo-switching works currently, because buyers are constantly manipulating the market with cancelled orders, and so most people end up disabling all but 1 or 2 algos.

* Dev fee. What dev fee?

I see no point in adding dev fee to an open source, plain text script. Anyone could remove it with 1 minute of work anyway. Instead, I'd greatly appreciate physical crypto coin gifts, [some](https://cdn.shopify.com/s/files/1/2143/9931/products/gold_2048x2048.jpg?v=1502697786) [of](http://physical-coin.com/wp-content/uploads/2018/01/s-l16005.jpg) [them](http://i.imgur.com/ctche9p.jpg) look pretty darn awesome.

* AMD support?

Actually, I'm not certain that RudeHash does _not_ work with AMD hardware. I just don't test it _at all_, because I have zero AMD hardware at hand, and by the look of things it will stay that way.
