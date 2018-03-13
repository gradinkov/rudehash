# RudeHash Changelog

## RudeHash 5.1 (TBD)

* Add support for Bitcore

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
