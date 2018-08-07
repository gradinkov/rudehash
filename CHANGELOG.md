# RudeHash Changelog

## RudeHash 9.0 (TBD)

* New algos: PHI2, Skein
* Updates: ccminer-tpruvot 2.3, PowerShell 6.1.0-preview4
* Change DNS resolver to 1.1.1.1
* Fix Tribus missing from Config Editor

## RudeHash 8.0 (2018-04-01)

* New pools: TheBSODPool
* New coins: Denarius, GINcoin, Pigeoncoin
* New algos: Tribus, X16S
* New miners: ccminer-alexis-hsr, nevermore-x16s, suprminer
* Updates: ethminer v0.14.0rc2
* Add support for mining profiles
* Add support for hsrminer's API
* Add config generator & validator tool
* Add version info to monitoring
* Add installer
* Change config location to AppData
* Change miner/tool/temp location to LocalAppData
* Always show related help when requesting user input
* Remove Polytimos from zpool
* Fix displaying earnings less than 0.0001 BTC
* Fix zero earnings when WhatToMine/pool API request fails
* Fix Watchdog hash rate detection when miner API starts very slowly
* Fix mining nonexchangeable altcoins to altcoin wallet on Zergpool

## RudeHash 7.1 (2018-03-20)

* New pools: MasterHash
* Update Zergpool stratum addresses
* Fix WhatToMine calculations failing due to added DDoS protection
* Fix validating electricity cost

## RudeHash 7.0 (2018-03-18)

* New coins: Bulwark, Criptoreal, Garlicoin, Infinex, Polytimos, Zcoin
* New pools: Poolr
* New algos: Allium, Lyra2Z, Nist5
* New miners: ccminer-allium, ccminer-palginmod
* Updates: ccminer-klaust 8.21
* Add support for altcoin wallet payouts
* Add remarks for config options during First Run Wizard
* Sort possible values in First Run Wizard
* Use current pool's API for algo profit estimation
* Validate pool's IP address before using it
* Retry pool IP lookup 3 times
* Fix Zergpool auto-exchange checks
* Fix earnings estimates failing with certain regional settings

## RudeHash 6.0 (2018-03-14)

* Add support for Zergpool
* Add support for Bitcore, BitSend, Creativecoin, Folm Coin, Hshare, LUXCoin, Solaris, Trezarcoin
* Add support for TimeTravel10, Xevan
* Add support for ccminer-xevan, hsrminer-neoscrypt
* Clear DNS cache upon miner crash and use Quad9 DNS for resolution
* Don't require a restart when changing the region
* Re-download miner if deleted during mining
* Improve First Run Wizard
* Update ethminer to v0.14.0.dev4

## RudeHash 5.0 (2018-03-09)

* Add own site with monitoring
* Add 10 minutes dev fee after every 24 hours of continuous mining
* Add Suprnova support
* Add Keccak-C, X16R support
* Add Bitcoin Private, Ravencoin, Kreds support
* Add miner's uptime to statistics
* Add support for MPHStats monitoring
* Use IP address to connect to pool and update upon miner crash
* Fix erroneous stat requests during miner crashes
* Fix potential miner version check errors
* Fix failing WhatToMine estimates due to their changed formatting

## RudeHash 4.0 (2018-03-04)

* Add support for NiceHash pool
* Add power usage and hash rate monitoring
* Add profit estimation for coins
* Add earnings and profit estimation for algos via NiceHash API
* Add support for fiat currency conversion
* Add watchdog to restart if hash rate is repeatedly zero
* Add interactive config validation and first run wizard
* Add support for MultiPoolMiner's monitoring service
* Add support for extra miner paremeters
* Add support for ccminer-polytimos
* Add support for hsrminer
* Check downloaded miners' versions and update if needed
* Update DSTM to v0.6
* Update ethminer to v0.14.0.dev3
* Change config file format to JSON
* Fix pool fee not being deducted from earnings for algos
* Improved error handling

## RudeHash 3.0 (2018-02-26)

* Add support for algo mining
* Add support for zpool
* Add support for ccminer-phi
* Improved config validation
* Improved error handling
* Improved user interface
* Adjustments for MiningPoolHubStats

## RudeHash 2.1 (2018-02-23)

* Add support for Excavator
* Improved error handling

## RudeHash 2.0 (2018-02-18)

* Remove Bminer support
* Add support for ccminer-klaust, vertminer
* Add support for BitcoinGold, Ethereum, Feathercoin, Monacoin, Vertcoin
* Detect required algo automatically
* Improved error handling
* Improved user interface


## RudeHash 1.2 (2018-02-12)

* Add ccminer-tpruvot support
* Add Debug option
* Check coin-miner compatibility


## RudeHash 1.1 (2018-02-08)

* Download miners automatically
* Add support for Bminer, DSTM
* Allow setting the region

## RudeHash 1.0 (2018-02-06)

* Add support for Zec Miner
* Add support for ZCash, ZClassic, ZenCash
* Restart miner automatically
* Estimate daily income via WhatToMine
