$ConfigFile = [io.path]::combine($PSScriptRoot, "rudehash.json")
$MinersDir = [io.path]::combine($PSScriptRoot, "miners")
$ToolsDir = [io.path]::combine($PSScriptRoot, "tools")
$TempDir = [io.path]::combine($PSScriptRoot, "temp")
[System.Collections.Hashtable]$Config = @{}
[System.Collections.Hashtable]$FileConfig = @{}
[System.Collections.Hashtable]$SessionConfig = @{}
$FirstRun = $false
$FirstLoop = $true
# $RegionChange = $false
$MinerPort = 28178
$BlockchainUrl = "https://blockchain.info/ticker"
$MonitoringUrl = "https://rudehash.org/monitor/miner.php"
$MphStatsUrl = "https://miningpoolhubstats.com/api/worker/"
$ZergpoolCoinsUrl = "http://api.zergpool.com:8080/api/currencies"
$MinerApiErrorStr = "Malformed miner API response."

Clear-Host

function Exit-RudeHash ()
{
	Read-Host -Prompt "Press Enter to exit..."
	Exit
}

function Write-Pretty ($BgColor, $String)
{
	$WindowWidth = $Host.UI.RawUI.MaxWindowSize.Width

	ForEach ($Line in $($String -split "`r`n"))
	{
		$SpaceCount = $WindowWidth - ($Line.length % $WindowWidth)
		$Line += " " * $SpaceCount

		Write-Host -ForegroundColor White -BackgroundColor $BgColor $Line
	}
}

function Write-Pretty-Header ()
{
	$WindowWidth = $Host.UI.RawUI.MaxWindowSize.Width - 1
	$String += "`u{2219}" * $WindowWidth

	Write-Pretty DarkCyan $String
	Write-Pretty DarkCyan "RudeHash NVIDIA Miner `u{00a9} gradinkov"
	Write-Pretty DarkCyan $String
}

function Write-Pretty-Error ($String)
{
	Write-Pretty Red $String
}

function Write-Pretty-Debug ($String)
{
	Write-Pretty Magenta $String
}

function Write-Pretty-Info ($String)
{
	Write-Pretty DarkBlue $String
}

function Write-Pretty-Earnings ($String)
{
	Write-Pretty DarkGreen $String
}

if (Test-Path $ConfigFile)
{
	try
	{
		$Config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json -AsHashtable

		# make sure we don't fail if the file is empty
		if (-Not ($Config))
		{
			[System.Collections.Hashtable]$Config = @{}
			$FirstRun = $true
		}
	}
	catch [System.Management.Automation.PSInvalidOperationException]
	{
		Write-Pretty-Error "Error parsing '$ConfigFile'! Do you have an option set multiple times?"
		Exit-RudeHash
	}
	catch
	{
		Write-Pretty-Error "Error accessing '$ConfigFile'!"
		Exit-RudeHash
	}
}
else
{
	$FirstRun = $true

	try
	{
		New-Item $ConfigFile -ItemType File | Out-Null
	}
	catch
	{
		Write-Pretty-Error "Error creating '$ConfigFile'!"
		Exit-RudeHash
	}
}

$Pools =
@{
	"miningpoolhub" =
	@{
		PoolFee = 1.1
		Authless = $false
		Regions = $true
		StratumProto = 0
		Algos =
		@{
			"ethash" = @{ Server = "%REGION%ethash-hub.miningpoolhub.com"; Port = 17020 }
			"equihash" = @{ Server = "%REGION%equihash-hub.miningpoolhub.com"; Port = 17023 }
			"lyra2v2" = @{ Server = "hub.miningpoolhub.com"; Port = 17018 }
			"neoscrypt" = @{ Server = "hub.miningpoolhub.com"; Port = 17012 }
		}
		Coins =
		@{
			"btg" = @{ Server = "%REGION%equihash-hub.miningpoolhub.com"; Port = 20595 }
			"eth" = @{ Server = "%REGION%ethash-hub.miningpoolhub.com"; Port = 20535 }
			"ftc" = @{ Server = "hub.miningpoolhub.com"; Port = 20510 }
			"mona" = @{ Server = "hub.miningpoolhub.com"; Port = 20593 }
			"vtc" = @{ Server = "hub.miningpoolhub.com"; Port = 20507 }
			"zcl" = @{ Server = "%REGION%equihash-hub.miningpoolhub.com"; Port = 20575 }
			"zec" = @{ Server = "%REGION%equihash-hub.miningpoolhub.com"; Port = 20570 }
			"zen" = @{ Server = "%REGION%equihash-hub.miningpoolhub.com"; Port = 20594 }
		}
	}

	"nicehash" =
	@{
		PoolFee = 2
		Authless = $true
		Regions = $true
		StratumProto = 2
		Algos =
		@{
			"ethash" = @{ Server = "daggerhashimoto.%REGION%nicehash.com"; Port = 3353 }
			"equihash" = @{ Server = "equihash.%REGION%nicehash.com"; Port = 3357 }
			"lyra2v2" = @{ Server = "lyra2rev2.%REGION%nicehash.com"; Port = 3347 }
			"neoscrypt" = @{ Server = "neoscrypt.%REGION%nicehash.com"; Port = 3341 }
		}
	}

	"suprnova" =
	@{
		PoolFee = 1.0
		Authless = $false
		Regions = $false
		StratumProto = 2
		Coins =
		@{
			"bsd" = @{ Server = "bsd.suprnova.cc"; Port = 8686 }
			"btcp" = @{ Server = "btcp.suprnova.cc"; Port = 6822 }
			"btg" = @{ Server = "btg.suprnova.cc"; Port = 8816 }
			"btx" = @{ Server = "btx.suprnova.cc"; Port = 3629 }
			"eth" = @{ Server = "eth.suprnova.cc"; Port = 5000 }
			"mona" = @{ Server = "mona.suprnova.cc"; Port = 2995 }
			"kreds" = @{ Server = "kreds.suprnova.cc"; Port = 7196 }
			"rvn" = @{ Server = "rvn.suprnova.cc"; Port = 6667 }
			"vtc" = @{ Server = "vtc.suprnova.cc"; Port = 5678 }
			"zcl" = @{ Server = "zcl.suprnova.cc"; Port = 4042 }
			"zec" = @{ Server = "zec.suprnova.cc"; Port = 2142 }
			"zen" = @{ Server = "zen.suprnova.cc"; Port = 3618 }
		}
	}

	"zergpool" =
	@{
		PoolFee = 0
		Authless = $true
		Regions = $true
		StratumProto = 0
		Algos =
		@{
			"bitcore" = @{ Server = "%REGION%mine.zergpool.com"; Port = 3556 }
			"hsr" = @{ Server = "%REGION%mine.zergpool.com"; Port = 7433 }
			"keccakc" = @{ Server = "%REGION%mine.zergpool.com"; Port = 5134 }
			"lyra2v2" = @{ Server = "%REGION%mine.zergpool.com"; Port = 4533 }
			"neoscrypt" = @{ Server = "%REGION%mine.zergpool.com"; Port = 4233 }
			"phi" = @{ Server = "%REGION%mine.zergpool.com"; Port = 8333 }
			"x16r" = @{ Server = "%REGION%mine.zergpool.com"; Port = 3636 }
			"xevan" = @{ Server = "%REGION%mine.zergpool.com"; Port = 3739 }
		}
		Coins =
		@{
			"bsd" = @{ Server = "%REGION%mine.zergpool.com"; Port = 3739 }
			"btx" = @{ Server = "%REGION%mine.zergpool.com"; Port = 3556 }
			"crea" = @{ Server = "%REGION%mine.zergpool.com"; Port = 5134 }
			"flm" = @{ Server = "%REGION%mine.zergpool.com"; Port = 8333 }
			"ftc" = @{ Server = "%REGION%mine.zergpool.com"; Port = 4233 }
			"hsr" = @{ Server = "%REGION%mine.zergpool.com"; Port = 7433 }
			"lux" = @{ Server = "%REGION%mine.zergpool.com"; Port = 8333 }
			"mona" = @{ Server = "%REGION%mine.zergpool.com"; Port = 4533 }
			"rvn" = @{ Server = "%REGION%mine.zergpool.com"; Port = 3636 }
			"tzc" = @{ Server = "%REGION%mine.zergpool.com"; Port = 4233 }
			"vtc" = @{ Server = "%REGION%mine.zergpool.com"; Port = 4533 }
			"xlr" = @{ Server = "%REGION%mine.zergpool.com"; Port = 3739 }
		}
	}

	"zpool" =
	@{
		PoolFee = 2
		Authless = $true
		Regions = $false
		StratumProto = 0
		Algos =
		@{
			"bitcore" = @{ Server = "bitcore.mine.zpool.ca"; Port = 3556 }
			"equihash" = @{ Server = "equihash.mine.zpool.ca"; Port = 2142 }
			"hsr" = @{ Server = "hsr.mine.zpool.ca"; Port = 7433 }
			"keccakc" = @{ Server = "keccakc.mine.zpool.ca"; Port = 5134 }
			"lyra2v2" = @{ Server = "lyra2v2.mine.zpool.ca"; Port = 4533 }
			"neoscrypt" = @{ Server = "neoscrypt.mine.zpool.ca"; Port = 4233 }
			"phi" = @{ Server = "phi.mine.zpool.ca"; Port = 8333 }
			"polytimos" = @{ Server = "polytimos.mine.zpool.ca"; Port = 8463 }
			"xevan" = @{ Server = "xevan.mine.zpool.ca"; Port = 3739 }
		}
	}
}

$Coins =
@{
	"bsd" = @{ WtmPage = "201-bsd-xevan"; Algo = "xevan" }
	"btcp" = @{ Algo = "equihash" }
	"btg" = @{ WtmPage = "214-btg-equihash"; Algo = "equihash" }
	"btx" = @{ WtmPage = "202-btx-timetravel10"; Algo = "bitcore" }
	"crea" = @{ WtmPage = "199-crea-keccak-c"; Algo = "keccakc" }
	"eth" = @{ WtmPage = "151-eth-ethash"; Algo = "ethash" }
	"flm" = @{ Algo = "phi" }
	"ftc" = @{ WtmPage = "8-ftc-neoscrypt"; Algo = "neoscrypt" }
	"hsr" = @{ Algo = "hsr" }
	"mona" = @{ WtmPage = "148-mona-lyra2rev2"; Algo = "lyra2v2" }
	"kreds" = @{ Algo = "lyra2v2" }
	"lux" = @{ WtmPage = "212-lux-phi1612"; Algo = "phi" }
	"rvn" = @{ Algo = "x16r" }
	"tzc" = @{ WtmPage = "215-tzc-neoscrypt"; Algo = "neoscrypt" }
	"vtc" = @{ WtmPage = "5-vtc-lyra2rev2"; Algo = "lyra2v2" }
	"xlr" = @{ WtmPage = "179-xlr-xevan"; Algo = "xevan" }
	"zcl" = @{ WtmPage = "167-zcl-equihash"; Algo = "equihash" }
	"zec" = @{ WtmPage = "166-zec-equihash"; Algo = "equihash" }
	"zen" = @{ WtmPage = "185-zen-equihash"; Algo = "equihash" }
}

$Miners =
@{
	"ccminer-klaust" = @{ Url = "https://github.com/KlausT/ccminer/releases/download/8.20/ccminer-820-cuda91-x64.zip"; ArchiveFile = "ccminer-klaust.zip"; ExeFile = "ccminer.exe"; FilesInRoot = $true; Algos = @("lyra2v2", "neoscrypt"); Api = $true }
	"ccminer-phi" = @{ Url = "https://github.com/216k155/ccminer-phi-anxmod/releases/download/ccminer%2Fphi-1.0/ccminer-phi-1.0.zip"; ArchiveFile = "ccminer-phi.zip"; ExeFile = "ccminer.exe"; FilesInRoot = $false; Algos = @("phi"); Api = $true; Version = "1.0" }
	"ccminer-rvn" = @{ Url = "https://github.com/MSFTserver/ccminer/releases/download/2.2.5-rvn/ccminer-x64-2.2.5-rvn-cuda9.7z"; ArchiveFile = "ccminer-rvn.7z"; ExeFile = "ccminer-x64.exe"; FilesInRoot = $true; Algos = @("x16r"); Api = $true; Version = "2.2.5" }
	"ccminer-polytimos" = @{ Url = "https://github.com/punxsutawneyphil/ccminer/releases/download/polytimosv2/ccminer-polytimos_v2.zip"; ArchiveFile = "ccminer-polytimos.zip"; ExeFile = "ccminer.exe"; FilesInRoot = $true; Algos = @("polytimos"); Api = $true }
	"ccminer-tpruvot" = @{ Url = "https://github.com/tpruvot/ccminer/releases/download/2.2.4-tpruvot/ccminer-x64-2.2.4-cuda9.7z"; ArchiveFile = "ccminer-tpruvot.7z"; ExeFile = "ccminer-x64.exe"; FilesInRoot = $true; Algos = @("bitcore", "equihash", "hsr", "keccakc", "lyra2v2", "neoscrypt", "phi", "polytimos"); Api = $true; Version = "2.2.4" }
	"ccminer-xevan" = @{ Url = "https://github.com/krnlx/ccminer-xevan/releases/download/0.1/ccminer.exe"; ArchiveFile = "ccminer-xevan.exe"; ExeFile = "ccminer-xevan.exe"; FilesInRoot = $true; Algos = @("xevan"); Api = $true }
	"dstm" = @{ Url = "https://github.com/nemosminer/DSTM-equihash-miner/releases/download/DSTM-0.6/zm_0.6_win.zip"; ArchiveFile = "dstm.zip"; ExeFile = "zm.exe"; FilesInRoot = $false; Algos = @("equihash"); Api = $true; Version = "0.6" }
	"ethminer" = @{ Url = "https://github.com/ethereum-mining/ethminer/releases/download/v0.14.0.dev4/ethminer-0.14.0.dev4-Windows.zip"; ArchiveFile = "ethminer.zip"; ExeFile = "ethminer.exe"; FilesInRoot = $false; Algos = @("ethash"); Api = $true; Version = "0.14.0.dev4" }
	"excavator" = @{ Url = "https://github.com/nicehash/excavator/releases/download/v1.4.4a/excavator_v1.4.4a_NVIDIA_Win64.zip"; ArchiveFile = "excavator.zip"; ExeFile = "excavator.exe"; FilesInRoot = $false; Algos = @("ethash", "equihash", "lyra2v2", "neoscrypt"); Api = $true; Version = "1.4.4a_nvidia" }
	"hsrminer" = @{ Url = "https://github.com/palginpav/hsrminer/raw/master/HSR%20algo/Windows/hsrminer_hsr.zip"; ArchiveFile = "hsrminer.zip"; ExeFile = "hsrminer_hsr.exe"; FilesInRoot = $true; Algos = @("hsr"); Api = $false; Version = "1.0" }
	"vertminer" = @{ Url = "https://github.com/vertcoin-project/vertminer-nvidia/releases/download/v1.0-stable.2/vertminer-nvdia-v1.0.2_windows.zip"; ArchiveFile = "vertminer.zip"; ExeFile = "vertminer.exe"; FilesInRoot = $false; Algos = @("lyra2v2"); Api = $true; Version = "1.0.1" }
	"zecminer" = @{ Url = "https://github.com/nanopool/ewbf-miner/releases/download/v0.3.4b/Zec.miner.0.3.4b.zip"; ArchiveFile = "zecminer.zip"; ExeFile = "miner.exe"; FilesInRoot = $true; Algos = @("equihash"); Api = $true; Version = "0.3.4b" }
}

$ExcavatorAlgos =
@{
	"ethash" = "daggerhashimoto"
	"equihash" = "equihash"
	"lyra2v2" = "lyra2rev2"
	"neoscrypt" = "neoscrypt"
}

$Tools =
@{
	"7zip" = [pscustomobject]@{ Url = "http://7-zip.org/a/7za920.zip"; ArchiveFile = "7zip.zip"; ExeFile = "7za.exe"; FilesInRoot = $true }
}

$Regions =
@{
	"miningpoolhub" = @("asia", "europe", "us-east")
	"nicehash" = @("br", "eu", "hk", "in", "jp", "usa")
	# zergpool uses "" for usa, we gotta fix this later
	"zergpool" = @("usa", "europe")
}

# MPH returns all hashrates in kH/s but WTM uses different magnitudes for different algos
$WtmModifiers =
@{
	"bitcore" = 1000000
	"ethash" = 1000000
	"equihash" = 1
	"keccakc" = 1000000
	"lyra2v2" = 1000
	"neoscrypt" = 1000
	"phi" = 1000000
	"xevan" = 1000000
}

$AlgoNames =
@{
	"bitcore" = "TimeTravel10"
	"ethash" = "Ethash"
	"equihash" = "Equihash"
	"hsr" = "HSR"
	"keccakc" = "Keccak-C"
	"lyra2v2" = "Lyra2REv2"
	"neoscrypt" = "NeoScrypt"
	"phi" = "PHI1612"
	"polytimos" = "Polytimos"
	"x16r" = "X16R"
	"xevan" = "Xevan"
}

$PoolNames =
@{
	"miningpoolhub" = "Mining Pool Hub"
	"nicehash" = "NiceHash"
	"suprnova" = "Suprnova"
	"zergpool" = "Zergpool"
	"zpool" = "zpool"
}

$NiceHashAlgos =
@{
	"equihash" = @{ Id = 24; Modifier = 1000000 }
	"ethash" = @{ Id = 20; Modifier = 1000000000 }
	"lyra2v2" = @{ Id = 14; Modifier = 1000000000000 }
	"neoscrypt" = @{ Id = 8; Modifier = 1000000000 }
}

# we build this dynamically
[System.Collections.Hashtable]$BtcRates = @{}

function Set-Property ($Name, $Value, $Permanent)
{
	$Config.$Name = $Value

	if ($Permanent)
	{
		try
		{
			$Config | ConvertTo-Json | Out-File -FilePath $ConfigFile -Encoding utf8NoBOM
		}
		catch
		{
			Write-Pretty-Error "Error writing '$ConfigFile'!"

			if ($Config.Debug)
			{
				Write-Pretty-Debug $_.Exception
			}
		}
	}
}

function Get-CoinSupport ()
{
	$Table = New-Object System.Data.DataTable
	$Table.Columns.Add("Coin", "string") | Out-Null
	$Table.Columns.Add("Algo", "string") | Out-Null

	$Support = "Supported coins and their algos:"
	foreach ($Key in $Coins.Keys)
	{
		$Row = $Table.NewRow()
		$Row.Coin = $Key.ToUpper()
		$Algos = ""
		$Algos += $Coins[$Key].Algo
		$Row.Algo = $Algos
		$Table.Rows.Add($Row)
	}

	# use Format-Table to force flushing to screen immediately
	$Support += Out-String -InputObject ($Table | Format-Table)
	$Table.Dispose()

	return $Support
}

function Get-MinerSupport ()
{
	$Table = New-Object System.Data.DataTable
	$Table.Columns.Add("Miner", "string") | Out-Null
	$Table.Columns.Add("Algo", "string") | Out-Null

	$Support += "Supported miners and algos:"
	foreach ($Key in $Miners.Keys)
	{
		$Row = $Table.NewRow()
		$Row.Miner = $Key
		$Algos = ""
		$Algos += foreach ($Algo in $Miners[$Key].Algos) { $Algo }
		$Row.Algo = $Algos
		$Table.Rows.Add($Row)
	}

	# use Format-Table to force flushing to screen immediately
	$Support += Out-String -InputObject ($Table | Format-Table)
	$Table.Dispose()

	return $Support
}

function Get-AlgoSupport ()
{
	return Get-MinerSupport
}

function Get-PoolSupport ()
{
	$Table = New-Object System.Data.DataTable
	$Table.Columns.Add("Pool", "string") | Out-Null
	$Table.Columns.Add("Modes", "string") | Out-Null
	$Table.Columns.Add("Payout", "string") | Out-Null

	$Support += "Supported pools, mining modes and payout methods:"
	foreach ($Key in $Pools.Keys)
	{
		$Row = $Table.NewRow()
		$Row.Pool = $Key
		$ModeStr = ""

		if ($Pools[$Key].Algos)
		{
			$ModeStr += "algo "
		}

		if ($Pools[$Key].Coins)
		{
			$ModeStr += "coin "
		}

		$Row.Modes = $ModeStr

		if ($Pools[$Key].Authless)
		{
			$Row.Payout = "BTC wallet"
		}
		else
		{
			$Row.Payout = "Site balance"
		}

		$Table.Rows.Add($Row)
	}

	# use Format-Table to force flushing to screen immediately
	$Support += Out-String -InputObject ($Table | Format-Table)
	$Table.Dispose()

	$Table = New-Object System.Data.DataTable
	$Table.Columns.Add("Pool", "string") | Out-Null
	$Table.Columns.Add("Algo", "string") | Out-Null

	$Support += "Supported algos:"
	foreach ($Key in $Pools.Keys)
	{
		if ($Pools[$Key].Algos)
		{
			$Row = $Table.NewRow()
			$Row.Pool = $Key
			$Algos = ""
			$Algos += foreach ($Algo in $Pools[$Key].Algos.Keys) { $Algo }
			$Row.Algo = $Algos
			$Table.Rows.Add($Row)
		}
	}

	# use Format-Table to force flushing to screen immediately
	$Support += Out-String -InputObject ($Table | Format-Table)
	$Table.Dispose()

	$Table = New-Object System.Data.DataTable
	$Table.Columns.Add("Pool", "string") | Out-Null
	$Table.Columns.Add("Coin", "string") | Out-Null

	$Support += "Supported coins:"
	foreach ($Key in $Pools.Keys)
	{
		if ($Pools[$Key].Coins)
		{
			$Row = $Table.NewRow()
			$Row.Pool = $Key
			$Coins = ""
			$Coins += foreach ($Coin in $Pools[$Key].Coins.Keys) { $Coin }
			$Row.Coin = $Coins
			$Table.Rows.Add($Row)
		}
	}

	# use Format-Table to force flushing to screen immediately
	$Support += Out-String -InputObject ($Table | Format-Table)
	$Table.Dispose()

	return $Support
}

function Get-RegionSupport ()
{
	$Table = New-Object System.Data.DataTable
	$Table.Columns.Add("Pool", "string") | Out-Null
	$Table.Columns.Add("Regions", "string") | Out-Null

	$Support += "Pools with regions:"
	foreach ($Key in $Regions.Keys)
	{
		$Row = $Table.NewRow()
		$Row.Pool = $Key
		$Regs = ""
		$Regs += foreach ($Region in $Regions[$Key]) { $Region }
		$Row.Regions = $Regs
		$Table.Rows.Add($Row)
	}

	# use Format-Table to force flushing to screen immediately
	$Support += Out-String -InputObject ($Table | Format-Table)
	$Table.Dispose()

	return $Support
}

function Test-DebugProperty ()
{
	try
	{
		$Config.Debug = [System.Convert]::ToBoolean($Config.Debug)
		return $true
	}
	catch
	{
		Write-Pretty-Error ("'Debug' property is in incorrect format, it must be 'true' or 'false'!")
		return $false
	}
}

function Test-WatchdogProperty ()
{
	try
	{
		$Config.Watchdog = [System.Convert]::ToBoolean($Config.Watchdog)
		return $true
	}
	catch
	{
		Write-Pretty-Error ("'Watchdog' property is in incorrect format, it must be 'true' or 'false'!")

		if ($Config.Debug)
		{
			Write-Pretty-Debug $_.Exception
		}

		return $false
	}
}

function Test-MonitoringKeyProperty ()
{
	# if the user presses enter, the key will be deleted altogether
	# we can't do much here without making the key mandatory
	if ($Config.MonitoringKey)
	{
		$Uuid = New-Guid
		$Res = [Guid]::TryParse($Config.MonitoringKey, [ref]$Uuid)

		if (-Not $Res)
		{
			$Uuid = New-Guid

			Write-Pretty-Error ("Monitoring key is in incorrect format! New random key for you:")
			Write-Pretty-Info ($Uuid.Guid)

			return $false
		}
		else
		{
			return $true
		}
	}
	else
	{
		return $true
	}
}

function Test-MphApiKeyProperty ()
{
	if ($Config.MphApiKey)
	{
		if ($Config.MphApiKey.length -ne 64)
		{
			Write-Pretty-Error ("MPH API key is in incorrect format, check it here: https://miningpoolhub.com/?page=account&action=edit")
			return $false
		}
		else
		{
			return $true
		}
	}
	else
	{
		return $true
	}
}

function Test-PoolProperty ()
{
	if (-Not ($Config.Pool))
	{
		Write-Pretty-Error ("Pool must be set!")
		return $false
	}
	elseif (-Not ($Pools.ContainsKey($Config.Pool)))
	{
		Write-Pretty-Error ("The """ + $Config.Pool + """ pool is not supported!")
		Write-Pretty-Info (Get-PoolSupport)

		return $false
	}
	else
	{
		return $true
	}
}

function Test-WorkerProperty ()
{
	$Pattern = "^[a-zA-Z0-9]{1,15}$"

	if (-Not ($Config.Worker))
	{
		Write-Pretty-Error ("Worker must be set!")
		return $false
	}
	elseif (-Not ($Config.Worker -match $Pattern))
	{
			Write-Pretty-Error ("Worker name is in invalid format! Use a maximum of 15 letters and numbers!")
			return $false
	}
	else
	{
		return $true
	}
}

function Test-Wallet ($Address, $Symbol)
{
	switch ($Symbol)
	{
		"BTC"
		{
			if ((-Not ($Address.length -lt 26)) -And (-Not ($Address.length -gt 34)) -And ($Address.StartsWith("1") -Or $Address.StartsWith("3") -Or $Address.StartsWith("bc1")))
			{
				return $true
			}
			else
			{
				return $false
			}
		}
		Default { return $false }
	}

}

function Test-WalletProperty ()
{
	if ($Config.Wallet)
	{
		if (Test-Wallet $Config.Wallet "BTC")
		{
			return $true
		}
		else
		{
			Write-Pretty-Error ("Bitcoin wallet address is in incorrect format, please check it!")
			return $false
		}
	}
	else
	{
		return $true
	}
}

function Test-UserProperty ()
{
	if ($Config.User)
	{
		$Pattern = "^[a-zA-Z0-9]{1,20}$"

		if ($Config.User -match $Pattern)
		{
			return $true
		}
		else
		{
			Write-Pretty-Error ("User name is in invalid format! Use a maximum of 20 letters and numbers!")
			return $false
		}
	}
	else
	{
		return $true
	}
}

function Test-RegionProperty ()
{
	if ($Config.Region)
	{
		# make the array of dynamic size
		[System.Collections.ArrayList]$ValidRegions = @()

		# build a list of available regions
		foreach ($Pool in $Regions.Keys)
		{
			foreach ($Region in $Regions[$Pool])
			{
				if (-Not ($ValidRegions.Contains($Region)))
				{
					$ValidRegions.Add($Region) | Out-Null
				}
			}
		}

		if ($ValidRegions.Contains($Config.Region))
		{
			return $true
		}
		else
		{
			Write-Pretty-Error ("The """ + $Config.Region + """ region does not exist!")
			Write-Pretty-Info (Get-RegionSupport)

			return $false
		}
	}
	else
	{
		return $true
	}
}

function Test-CoinProperty ()
{
	if ($Config.Coin)
	{
		$Config.Coin = $Config.Coin.ToLower()

		if (-Not ($Coins.ContainsKey($Config.Coin)))
		{
			Write-Pretty-Error ("The """ + $Config.Coin.ToUpper() + """ coin is not supported!")
			Write-Pretty-Info (Get-CoinSupport)

			return $false
		}
		else
		{
			return $true
		}
	}
	else
	{
		return $true
	}
}

function Test-MinerProperty ()
{
	if (-Not ($Config.Miner))
	{
		Write-Pretty-Error ("Miner must be set!")
		return $false
	}
	elseif (-Not ($Miners.ContainsKey($Config.Miner)))
	{
		Write-Pretty-Error ("The """ + $Config.Miner + """ miner is not supported!")
		Write-Pretty-Info (Get-MinerSupport)

		return $false
	}
	else
	{
		return $true
	}
}

function Test-AlgoProperty ()
{
	if ($Config.Algo)
	{
		# make the array of dynamic size
		[System.Collections.ArrayList]$Algos = @()
		#$Coll = {$Algos}.Invoke()

		# build a list of available algos
		foreach ($Miner in $Miners.Keys)
		{
			foreach ($Algo in $Miners[$Miner].Algos)
			{
				if (-Not ($Algos.Contains($Algo)))
				{
					$Algos.Add($Algo) | Out-Null
				}
			}
		}

		if (-Not ($Algos.Contains($Config.Algo)))
		{
			Write-Pretty-Error ("The """ + $Config.Algo + """ algo is not supported!")
			Write-Pretty-Info(Get-AlgoSupport)

			return $false
		}
		else
		{
			return $true
		}
	}
	else
	{
		return $true
	}
}

function Test-CoinExchangeSupport ()
{
	if ($Config.Pool -eq "zergpool")
	{
		if ($Config.Debug)
		{
			Write-Pretty-Debug "Checking coin's exchange support..."
		}

		try
		{
			$Response = Invoke-RestMethod -Uri $ZergpoolCoinsUrl -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue

			if ($Response.($Config.Coin).noautotrade -eq 0)
			{
				return $true
			}
			else
			{
				return $false
			}
		}
		catch
		{
			Write-Pretty-Error "Error determining if the selected coin can be exchanged! RudeHash cannot continue."

			if ($Config.Debug)
			{
				Write-Pretty-Debug $_.Exception
			}

			Exit-RudeHash
		}
	}
	else
	{
		return $true
	}
}

function Receive-Choice ($A, $B)
{
	$Name = ""

	while (-Not ($Name.Equals($A) -Or $Name.Equals($B)))
	{
		$Name = Read-Host "Please specify the property you want to modify ('$($A)' or '$($B)')"

		# capitalization
		if ($Name.Length -gt 1)
		{
			$Name = ($Name.Substring(0,1).ToUpper() + $Name.Substring(1).ToLower())
		}
		else
		{
			$Name = $Name.ToUpper()
		}
	}

	return $Name
}

function Receive-Property ($Name, $Mandatory)
{
	if ($Mandatory)
	{
		return Read-Host "Enter value for ""$($Name)"""
	}
	else
	{
		return Read-Host "Enter value for ""$($Name)"" (or press Return to delete)"
	}
}

function Initialize-Property ($Name, $Mandatory, $Force)
{
	if ($Config.Debug)
	{
		Write-Pretty-Debug "Evaluating $Name property..."
	}

	if ($Force)
	{
		$Ret = Receive-Property $Name $Mandatory
		Set-Property $Name $Ret $true
	}

	# awesome trick from https://wprogramming.wordpress.com/2011/07/18/dynamic-function-and-variable-access-in-powershell/
	while (-Not (& (Get-ChildItem "Function:Test-$($Name)Property")))
	{
		$Ret = Receive-Property $Name $Mandatory
		Set-Property $Name $Ret $true
	}
}

function Test-Compatibility ()
{
	if ($Pools[$Config.Pool].Authless)
	{
		if (-Not ($Config.Wallet))
		{
			Write-Pretty-Error ("""" + $Config.Pool + """ is anonymous, wallet address must be set!")
			$Choice = Receive-Choice "Wallet" "Pool"
			$Config.$Choice = ""
			Initialize-Property $Choice $true $true
			Test-Compatibility
		}
	}
	elseif (-Not ($Config.User))
	{
		Write-Pretty-Error ("""" + $Config.Pool + """ implements authentication, user name must be set!")
		$Choice = Receive-Choice "User" "Pool"
		$Config.$Choice = ""
		Initialize-Property $Choice $true $true
		Test-Compatibility
	}

	if ($Pools[$Config.Pool].Regions)
	{
		if (-Not ($Config.Region))
		{
			Write-Pretty-Error ("Region must be set for the """ + $Config.Pool + """ pool!")
			$Choice = Receive-Choice "Region" "Pool"
			$Config.$Choice = ""

			# if ($Choice.ToLower() -eq "region")
			# {
			# 	$RegionChange = $true
			# }

			Initialize-Property $Choice $true $true
			Test-Compatibility
		}
		if (-Not ($Regions[$Config.Pool].Contains($Config.Region)))
		{
			Write-Pretty-Error ("The """ + $Config.Region + """ region is not supported on the """ + $Config.Pool + """ pool!")
			$Choice = Receive-Choice "Region" "Pool"
			$Config.$Choice = ""

			# if ($Choice.ToLower() -eq "region")
			# {
			# 	$RegionChange = $true
			# }

			Initialize-Property $Choice $true $true
			Test-Compatibility
		}
	}

	$SessionConfig.CoinMode = $false

	if ($Config.Coin)
	{
		if (-Not ($Pools[$Config.Pool].Coins))
		{
			Write-Pretty-Error ("Coin mining is not supported on """ + $Config.Pool + """!")
			Write-Pretty-Info (Get-CoinSupport)
			Write-Pretty-Info (Get-PoolSupport)
			$Choice = Receive-Choice "Coin" "Pool"
			$Config.$Choice = ""
			Initialize-Property $Choice $true $true
			Test-Compatibility
		}
		elseif (-Not ($Pools[$Config.Pool].Coins.ContainsKey($Config.Coin)))
		{
			Write-Pretty-Error ("The """ + $Config.Coin + """ coin is not supported on """ + $Config.Pool + """!")
			Write-Pretty-Info (Get-CoinSupport)
			Write-Pretty-Info (Get-PoolSupport)
			$Choice = Receive-Choice "Coin" "Pool"
			$Config.$Choice = ""
			Initialize-Property $Choice $true $true
			Test-Compatibility
		}
		elseif (-Not (Test-CoinExchangeSupport))
		{
			Write-Pretty-Error ("The """ + $Config.Coin + """ coin cannot be exchanged on """ + $Config.Pool + """!")
			$Choice = Receive-Choice "Coin" "Pool"
			$Config.$Choice = ""
			Initialize-Property $Choice $true $true
			Test-Compatibility
		}
		else
		{
			# use coin algo if coin is specified
			$Config.Algo = $Coins[$Config.Coin].Algo
			$SessionConfig.CoinMode = $true
		}
	}
	elseif (-Not $Config.Algo)
	{
		Write-Pretty-Error ("You specified neither a coin nor an algo!")
		Write-Pretty-Info (Get-CoinSupport)
		Write-Pretty-Info (Get-MinerSupport)
		$Choice = Receive-Choice "Coin" "Algo"
		$Config.$Choice = ""
		Initialize-Property $Choice $true $true
		Test-Compatibility
	}
	elseif (-Not ($Pools[$Config.Pool].Algos))
	{
		Write-Pretty-Error ("Algo mining is not supported on """ + $Config.Pool + """!")
		Write-Pretty-Info (Get-PoolSupport)
		$Choice = Receive-Choice "Coin" "Pool"
		$Config.$Choice = ""
		Initialize-Property $Choice $true $true
		Test-Compatibility
	}
	# reason for elseif: if the coin is supported on the pool, its algo doesn't need to be checked
	elseif (-Not ($Pools[$Config.Pool].Algos.ContainsKey($Config.Algo)))
	{
		Write-Pretty-Error ("Incompatible configuration! """ + $Config.Algo + """ cannot be mined on """ + $Config.Pool + """.")
		Write-Pretty-Info (Get-PoolSupport)
		$Choice = Receive-Choice "Algo" "Pool"
		$Config.$Choice = ""
		Initialize-Property $Choice $true $true
		Test-Compatibility
	}

	if (-Not ($Miners[$Config.Miner].Algos.Contains($Config.Algo)))
	{
		if ($Config.Coin)
		{
			Write-Pretty-Error ("Incompatible configuration! The """ + $Config.Coin.ToUpper() + """ coin cannot be mined with """ + $Config.Miner + """.")
			Write-Pretty-Info (Get-CoinSupport)
			Write-Pretty-Info (Get-MinerSupport)
			$Choice = Receive-Choice "Coin" "Miner"
			$Config.$Choice = ""
			Initialize-Property $Choice $true $true
			Test-Compatibility
		}
		else
		{
			Write-Pretty-Error ("Incompatible configuration! The """ + $Config.Algo + """ algo cannot be mined with """ + $Config.Miner + """.")
			Write-Pretty-Info (Get-MinerSupport)
			$Choice = Receive-Choice "Algo" "Miner"
			$Config.$Choice = ""
			Initialize-Property $Choice $true $true
			Test-Compatibility
		}
	}

	# configuration is good, let's set up globals
	if ($SessionConfig.CoinMode)
	{
		$SessionConfig.Server = $Pools[$Config.Pool].Coins[$Config.Coin].Server
		$SessionConfig.Port = $Pools[$Config.Pool].Coins[$Config.Coin].Port
	}
	else
	{
		$SessionConfig.Server = $Pools[$Config.Pool].Algos[$Config.Algo].Server
		$SessionConfig.Port = $Pools[$Config.Pool].Algos[$Config.Algo].Port
	}

	if ($Pools[$Config.Pool].Regions)
	{
		# zergpool uses no prefix for usa region, wonderful
		if (($Config.Pool -eq "zergpool") -And ($Config.Region -eq "usa"))
		{
			$RegionStr = ""
		}
		else
		{
			$RegionStr = $Config.Region + "."
		}

		$SessionConfig.Server = $SessionConfig.Server -Replace "%REGION%",$RegionStr
	}

	if ($Miners[$Config.Miner].Api)
	{
		$SessionConfig.Api = $true
	}
}

function Get-Currency-Support ()
{
	$SessionConfig.Rates = $false

	try
	{
		$ResponseRaw = Invoke-WebRequest -Uri $BlockchainUrl -UseBasicParsing
		$Response = $ResponseRaw | ConvertFrom-Json -AsHashtable

		foreach ($Currency in $Response.Keys)
		{
			$BtcRates.Add($Currency, $Response[$Currency].buy)
		}

		$SessionConfig.Rates = $true
	}
	catch
	{
		Write-Pretty-Error "Error obtaining BTC exchange rates! BTC to Fiat conversion is disabled."

		if ($Config.Debug)
		{
			Write-Pretty-Debug $_.Exception
		}
	}
}

function Test-CurrencyProperty ()
{
	if (-Not $SessionConfig.Rates)
	{
		Get-Currency-Support
	}

	if ($SessionConfig.Api -And $SessionConfig.Rates)
	{
		if (-Not ($Config.Currency))
		{
			Write-Pretty-Error ("Currency must be set!")
			return $false
		}

		$Config.Currency = $Config.Currency.ToUpper()

		if (-Not ($BtcRates.Contains($Config.Currency)))
		{
			Write-Pretty-Error ("The """ + $Config.Currency + """ currency is not supported!")
			$Sep = "`u{00b7} "

			Write-Pretty-Info "Supported currencies:"
			foreach ($Currency in $BtcRates.Keys)
			{
				Write-Pretty-Info ($Sep + $Currency)
			}

			return $false
		}
		else
		{
			return $true
		}
	}
	else
	{
		return $true
	}
}

function Test-ElectricityCostProperty ()
{
	if ($SessionConfig.Api -And $SessionConfig.Rates)
	{
		if (-Not ($Config.ElectricityCost))
		{
			Write-Pretty-Error ("Electricity cost must be set!")
			return $false
		}

		try
		{
			$Config.ElectricityCost = [System.Convert]::ToDouble($Config.ElectricityCost)
			return $true
		}
		catch
		{
			Write-Pretty-Error ("Invalid electricity cost, """ + $Config.ElectricityCost + """ is not a number!")
			return $false
		}
	}
	else
	{
		return $true
	}
}

function Test-ExtraArgsProperty ()
{
	# we don't care what the user enters, impossible to check
	return $true
}

function Initialize-Properties ()
{
	if ($FirstRun)
	{
		Write-Pretty-Info ("Welcome to RudeHash! Let's set up your configuration.")
		Write-Pretty-Info ("We'll ask your input for all config options. Some are optional, you can skip")
		Write-Pretty-Info ("those by pressing 'Enter'. Don't worry, if you try to specify an incompatible")
		Write-Pretty-Info ("setup, we will tell you and ask you to modify it. Not all options are used in")
		Write-Pretty-Info ("all scenarios, e.g. wallet address is unused on pools with their own balances.")
	}

	Initialize-Property "Debug" $true $FirstRun
	Initialize-Property "Watchdog" $true $FirstRun
	Initialize-Property "MonitoringKey" $false $FirstRun
	Initialize-Property "MphApiKey" $false $FirstRun

	if ($FirstRun)
	{
		Write-Pretty-Info (Get-PoolSupport)
	}
	Initialize-Property "Pool" $true $FirstRun

	Initialize-Property "Worker" $true $FirstRun
	Initialize-Property "Wallet" $false $FirstRun
	Initialize-Property "User" $false $FirstRun

	if ($FirstRun)
	{
		Write-Pretty-Info (Get-RegionSupport)
	}
	Initialize-Property "Region" $false $FirstRun

	if ($FirstRun)
	{
		Write-Pretty-Info (Get-CoinSupport)
	}
	Initialize-Property "Coin" $false $FirstRun

	if ($FirstRun)
	{
		Write-Pretty-Info (Get-MinerSupport)
	}
	Initialize-Property "Miner" $true $FirstRun

	# don't print the same info again, algos depend on miners
	Initialize-Property "Algo" $false $FirstRun

	Test-Compatibility

	Initialize-Property "Currency" $true $FirstRun
	Initialize-Property "ElectricityCost" $true $FirstRun
	Initialize-Property "ExtraArgs" $false $FirstRun
}

$RigStats =
[pscustomobject]@{
	GpuCount = 0;
	HashRate = 0;
	Difficulty = 0;
	PowerUsage = 0;
	EarningsBtc = 0;
	EarningsFiat = 0;
	Profit = 0;
	ExchangeRate = 0;
	FailedChecks = 0;
	DevMinutes = 0;
	Pid = 0;
	Uptime = New-TimeSpan;
}

function Initialize-Temp ()
{
	try
	{
		if (Test-Path $TempDir -ErrorAction Stop)
		{
			Remove-Item -Recurse -Force -Path $TempDir -ErrorAction Stop
		}

		New-Item -ItemType Directory -Path $TempDir -Force -ErrorAction Stop | Out-Null
	}
	catch
	{
		Write-Pretty-Error "Error setting up temporary directory! Do we have write access?"

		if ($Config.Debug)
		{
			Write-Pretty-Debug $_.Exception
		}

		Exit-RudeHash
	}
}

function Read-Miner-Api ($Request, $Critical)
{
	$Timeout = 10

	try
	{
		$Client = New-Object System.Net.Sockets.TcpClient "127.0.0.1", $MinerPort
		$Stream = $Client.GetStream()
		$Writer = New-Object System.IO.StreamWriter $Stream
		$Reader = New-Object System.IO.StreamReader $Stream
		$Client.SendTimeout = $Timeout * 1000
		$Client.ReceiveTimeout = $Timeout * 1000
		$Writer.AutoFlush = $true

		$Writer.WriteLine($Request)
		$Response = $Reader.ReadLine()
	}
	catch
	{
		Write-Pretty-Error "Error connecting to miner API!"

		if ($Config.Debug)
		{
			Write-Pretty-Debug $_.Exception
		}

		if ($Critical -eq "true")
		{
			Write-Pretty-Error "Critical error, RudeHash cannot continue."
			Exit-RudeHash
		}
	}
	finally
	{
		if ($Reader) { $Reader.Close() }
		if ($Writer) { $Writer.Close() }
		if ($Stream) { $Stream.Close() }
		if ($Client) { $Client.Close() }
	}

	return $Response
}

function Resolve-PoolIp ()
{
	try
	{
		$Ip = ([System.Net.DNS]::GetHostEntry($SessionConfig.Server).AddressList[0].IPAddressToString)
	}
	catch
	{
		Write-Pretty-Error "Error resolving pool IP addess! Is your network connection working?"

		if ($Config.Debug)
		{
			Write-Pretty-Debug $_.Exception
		}

		# it's better than nothing, it might start working during stratum connection
		$Ip = $SessionConfig.Server
	}

	return $Ip
}

function Get-GpuCount ()
{
	switch ($Config.Miner)
	{
		{$_ -in "ccminer-klaust", "ccminer-phi", "ccminer-polytimos", "ccminer-rvn", "ccminer-tpruvot", "ccminer-xevan", "vertminer"}
		{
			$Response = Read-Miner-Api 'summary' $false

			try
			{
				$Count = $Response.Split("|")[0].Split(";")[4].Split("=")[1]
			}
			catch
			{
				Write-Pretty-Error $MinerApiErrorStr

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		"dstm"
		{
			# dstm accepts any string as request, let's use the same as ccminer
			$ResponseRaw = Read-Miner-Api 'summary' $false

			try
			{
				$Response = $ResponseRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
				$Count = $Response.result.length
			}
			catch
			{
				Write-Pretty-Error $MinerApiErrorStr

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		# api: https://github.com/ethereum-mining/ethminer/issues/295#issuecomment-353755310
		"ethminer"
		{
			$ResponseRaw = Read-Miner-Api '{"id":0,"jsonrpc":"2.0","method":"miner_getstat1"}' $false

			try
			{
				$Response = $ResponseRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
				$Count = $Response.result[3].Split(";").length
			}
			catch
			{
				Write-Pretty-Error $MinerApiErrorStr

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		"excavator"
		{
			$ResponseRaw = Read-Miner-Api '{"id":1,"method":"device.list","params":[]}' $true
			$Response = $ResponseRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
			$Count = $Response.devices.length
		}

		"zecminer"
		{
			$ResponseRaw = Read-Miner-Api '{"id":"0", "method":"getstat"}' $false

			try
			{
				$Response = $ResponseRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
				$Count = $Response.result.length
			}
			catch
			{
				Write-Pretty-Error $MinerApiErrorStr

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}
	}

	$RigStats.GpuCount = $Count
}

function Start-Excavator ()
{
	$Excavator = [io.path]::combine($MinersDir, "excavator", "excavator.exe")
	$Args = "-p $MinerPort"

	if ($Config.Debug)
	{
		Write-Pretty-Debug ("$Excavator $Args")
	}

	$Proc = Start-Process -FilePath $Excavator -ArgumentList $Args -PassThru -NoNewWindow -RedirectStandardOutput nul
	Write-Pretty-Info "Determining the number of GPUs..."
	Start-Sleep -Seconds 5
	return $Proc
}

function Initialize-Json ($User, $Pass)
{
	$Count = $RigStats.GpuCount
	$ExcavatorJson = @"
[
	{"time":0,"commands":[
		{"id":1,"method":"algorithm.add","params":["$($ExcavatorAlgos[$Config.Algo])","$(Resolve-PoolIp):$($SessionConfig.Port)","$($User):$($Pass)"]}
	]},
	{"time":3,"commands":[
		$(for ($i = 0; $i -lt $Count; $i++)
		{
			$Line = "{""id"":1,""method"":""worker.add"",""params"":[""0"",""$i""]}"
			if (($Count - $i) -gt 1)
			{
				$Line += ",`r`n"
			}
			Write-Output $Line
		})
	]},
	{"time":10,"loop":20,"commands":[
		$(for ($i = 0; $i -lt $Count; $i++)
		{
			$Line = "{""id"":1,""method"":""worker.print.speed"",""params"":[""$i""]}"
			if (($Count - $i) -gt 1)
			{
				$Line += ",`r`n"
			}
			Write-Output $Line
		})
	]}
]
"@
	#{"id":1,"method":"algorithm.print.speeds","params":[]}
	return $ExcavatorJson
}

function Initialize-Excavator ($User, $Pass)
{
	$Proc = Start-Excavator
	Get-GpuCount
	Stop-Process $Proc

	Write-Pretty-Info ($RigStats.GpuCount.ToString() + " GPUs detected.")

	$Json = Initialize-Json $User $Pass
	$JsonFile = [io.path]::combine($TempDir, "excavator.json")

	try
	{
		Set-Content -LiteralPath $JsonFile -Value $Json -ErrorAction Stop
	}
	catch
	{
		Write-Pretty-Error "Error writing Excavator JSON file! Make sure the file is not locked by another process!"

		if ($Config.Debug)
		{
			Write-Pretty-Debug $_.Exception
		}

		Exit-RudeHash
	}
}

function Initialize-MinerArgs ()
{
	switch ($Config.Pool)
	{
		{$_ -in "miningpoolhub", "suprnova" }
		{
			$PoolUser = $Config.User + "." + $Config.Worker
			$PoolPass = "x"
		}
		"nicehash"
		{
			# https://www.nicehash.com/help/how-to-create-a-worker
			$PoolUser = $Config.Wallet + "." + $Config.Worker
			$PoolPass = "x"
		}
		"zergpool"
		{
			$PoolUser = $Config.Wallet

			if ($SessionConfig.CoinMode)
			{
				# zergpool only accepts the coin in uppercase
				$PoolPass = "c=BTC,mc="+ $Config.Coin.ToUpper() + ",ID=" + $Config.Worker
			}
			else
			{
				$PoolPass = "c=BTC,ID=" + $Config.Worker
			}
		}
		"zpool"
		{
			$PoolUser = $Config.Wallet
			# zpool only guarantees BTC payouts, so we enforce it, potentially suboptimal coin is better than completely lost mining
			$PoolPass = "c=BTC,ID=" + $Config.Worker
		}
	}

	# always update the IP, the miner could've crashed because of an IP change to begin with
	$PoolIp = Resolve-PoolIp

	switch ($Config.Miner)
	{
		{$_ -in "ccminer-klaust", "ccminer-phi", "ccminer-rvn", "ccminer-tpruvot", "ccminer-xevan" } { $Args = "--algo=" + $Config.Algo + " --url=stratum+tcp://" + $PoolIp + ":" + $SessionConfig.Port + " --user=" + $PoolUser + " --pass " + $PoolPass + " --api-bind 127.0.0.1:" + $MinerPort }
		"ccminer-polytimos" { $Args = "--algo=poly --url=stratum+tcp://" + $PoolIp + ":" + $SessionConfig.Port + " --user=" + $PoolUser + " --pass " + $PoolPass + " --api-bind 127.0.0.1:" + $MinerPort }
		"dstm" { $Args = "--server " + $PoolIp + " --user " + $PoolUser + " --pass " + $PoolPass + " --port " + $SessionConfig.Port + " --telemetry=127.0.0.1:" + $MinerPort + " --noreconnect" }
		"ethminer" { $Args = "--cuda --stratum " + $PoolIp + ":" + $SessionConfig.Port + " --userpass " + $PoolUser + ":" + $PoolPass + " --api-port " + $MinerPort + " --stratum-protocol " + $Pools[$Config.Pool].StratumProto }
		"excavator"
		{
			Initialize-Excavator $PoolUser $PoolPass
			$Args = "-c " + [io.path]::combine($TempDir, "excavator.json") + " -p " + $MinerPort
		}
		"hsrminer" { $Args = "--url=stratum+tcp://" + $PoolIp + ":" + $SessionConfig.Port + " --userpass=" + $PoolUser + ":" + $PoolPass }
		"vertminer" { $Args = "-o stratum+tcp://" + $PoolIp + ":" + $SessionConfig.Port + " -u " + $PoolUser + " -p " + $PoolPass + " --api-bind 127.0.0.1:" + $MinerPort }
		"zecminer" { $Args = "--server " + $PoolIp + " --user " + $PoolUser + " --pass " + $PoolPass + " --port " + $SessionConfig.Port + " --api 127.0.0.1:" + $MinerPort }
	}

	if ($Config.ExtraArgs)
	{
		$Args += " " + $Config.ExtraArgs
	}

	return $Args
}

# MPH API: https://github.com/miningpoolhub/php-mpos/wiki/API-Reference
# function Get-HashRate-Mph ()
# {
# 	$PoolUrl = "https://" + $Coins[$Config.Coin].PoolPage + ".miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=" + $Config.ApiKey

# 	try
# 	{
# 		$PoolJson = Invoke-WebRequest -Uri $PoolUrl -UseBasicParsing -ErrorAction SilentlyContinue | ConvertFrom-Json
# 		$PoolWorker = $PoolJson.getuserworkers.data | Where-Object -Property "username" -EQ -Value ($Config.User + "." + $Config.Worker)
# 		# getpoolstatus shows hashrate in H/s, getuserworkers uses kH/s, lovely!
# 		$HashRate = $PoolWorker.hashrate * 1000
# 	}
# 	catch
# 	{
# 		$HashRate = 0
# 		Write-Pretty-Error "Pool API call failed! Have you set your API key correctly?"

# 		if ($Config.Debug)
# 		{
# 			Write-Pretty-Debug $_.Exception
# 		}
# 	}

# 	if (-Not ($HashRate))
# 	{
# 		$HashRate = 0
# 	}

# 	$RigStats.HashRate = ([math]::Round($HashRate, 0))
# }

function Get-HashRate-Miner ()
{
	$HashRate = 0

	switch ($Config.Miner)
	{
		{$_ -in "ccminer-klaust", "ccminer-phi", "ccminer-polytimos", "ccminer-rvn", "ccminer-tpruvot", "ccminer-xevan", "vertminer"}
		{
			$Response = Read-Miner-Api 'threads' $false

			try
			{
				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$GpuStr = $Response.Split("|")[$i]
					[System.Collections.Hashtable]$GpuStats = @{}

					foreach ($Item in $GpuStr.Split(";"))
					{
						$GpuStats.Add($Item.Split("=")[0], $Item.Split("=")[1])
					}

					$HashRate += $GpuStats["KHS"]
					$GpuStats.Clear()
				}

				# ccminer returns KH/s
				$HashRate *= 1000
			}
			catch
			{
				Write-Pretty-Error $MinerApiErrorStr

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		"dstm"
		{
			# dstm accepts any string as request, let's use the same as ccminer
			$ResponseRaw = Read-Miner-Api 'summary' $false

			try
			{
				$Response = $ResponseRaw | ConvertFrom-Json -ErrorAction SilentlyContinue

				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$HashRate += $Response.result[$i].sol_ps
				}
			}
			catch
			{
				Write-Pretty-Error $MinerApiErrorStr

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		"ethminer"
		{
			$ResponseRaw = Read-Miner-Api '{"id":0,"jsonrpc":"2.0","method":"miner_getstathr"}' $false

			try
			{
				$Response = $ResponseRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
				$HashRate = $Response.result.ethhashrate
			}
			catch
			{
				Write-Pretty-Error $MinerApiErrorStr

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		"excavator"
		{
			$ResponseRaw = Read-Miner-Api '{"id":1,"method":"algorithm.list","params":[]}' $false

			try
			{
				$Response = $ResponseRaw | ConvertFrom-Json -ErrorAction SilentlyContinue

				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$HashRate += $Response.algorithms.workers[$i].speed[0]
				}
			}
			catch
			{
				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		"zecminer"
		{
			$ResponseRaw = Read-Miner-Api '{"id":"0", "method":"getstat"}' $false

			try
			{
				$Response = $ResponseRaw | ConvertFrom-Json -ErrorAction SilentlyContinue

				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$HashRate += $Response.result[$i].speed_sps
				}
			}
			catch
			{
				Write-Pretty-Error $MinerApiErrorStr

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}
	}

	$RigStats.HashRate = ([math]::Round($HashRate, 0))
}

function Get-HashRate ()
{
	Get-HashRate-Miner
}

function Get-HashRate-Pretty ($HashRate)
{
	if ($HashRate -ge 1000000)
	{
		return (([math]::Round(($HashRate / 1000000), 2)).ToString() + " MH/s")
	}
	elseif ($HashRate -ge 1000)
	{
		return (([math]::Round(($HashRate / 1000), 2)).ToString() + " kH/s")
	}
	else
	{
		return ([math]::Round($HashRate, 2).ToString() + " H/s")
	}
}

# function Get-Difficulty-Mph ()
# {
# 	$PoolUrl = "https://" + $Coins[$Config.Coin].PoolPage + ".miningpoolhub.com/index.php?page=api&action=getpoolstatus&api_key=" + $Config.ApiKey

# 	try
# 	{
# 		$PoolJson = Invoke-WebRequest -Uri $PoolUrl -UseBasicParsing | ConvertFrom-Json
# 		$Difficulty = $PoolJson.getpoolstatus.data.networkdiff
# 		#$Difficulty = $PoolJson.getdashboarddata.data.network.difficulty
# 		#$HashRate = $PoolJson.getdashboarddata.data.personal.hashrate
# 	}
# 	catch
# 	{
# 		$Difficulty = 0
# 		Write-Pretty-Error "Pool API call failed! Have you set your API key correctly?"

# 		if ($Config.Debug)
# 		{
# 			Write-Pretty-Debug $_.Exception
# 		}
# 	}

# 	return $Difficulty
# }

function Get-PowerUsage ()
{
	$PowerUsage = 0

	switch ($Config.Miner)
	{
		{$_ -in "ccminer-klaust", "ccminer-phi", "ccminer-polytimos", "ccminer-rvn", "ccminer-tpruvot", "ccminer-xevan", "vertminer"}
		{
			$Response = Read-Miner-Api 'threads' $false

			try
			{
				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$GpuStr = $Response.Split("|")[$i]
					[System.Collections.Hashtable]$GpuStats = @{}

					foreach ($Item in $GpuStr.Split(";"))
					{
						$GpuStats.Add($Item.Split("=")[0], $Item.Split("=")[1])
					}

					$PowerUsage += $GpuStats["POWER"]
					$GpuStats.Clear()
				}

				# these return mW instead of W, because reasons
				# in fact, ccminer-phi might also return mW, but I really don't know coz it always returns 0 lol
				if ($Config.Miner -eq "ccminer-klaust" -Or $Config.Miner -eq "ccminer-rvn" -Or $Config.Miner -eq "ccminer-tpruvot" -Or $Config.Miner -eq "ccminer-xevan")
				{
					$PowerUsage /= 1000
				}
			}
			catch
			{
				Write-Pretty-Error $MinerApiErrorStr

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		"dstm"
		{
			# dstm accepts any string as request, let's use the same as ccminer
			$ResponseRaw = Read-Miner-Api 'summary' $false

			try
			{
				$Response = $ResponseRaw | ConvertFrom-Json -ErrorAction SilentlyContinue

				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$PowerUsage += $Response.result[$i].power_usage
				}
			}
			catch
			{
				Write-Pretty-Error $MinerApiErrorStr

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		"ethminer"
		{
			$ResponseRaw = Read-Miner-Api '{"id":0,"jsonrpc":"2.0","method":"miner_getstathr"}' $false

			try
			{
				$Response = $ResponseRaw | ConvertFrom-Json -ErrorAction SilentlyContinue

				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$PowerUsage += [math]::Round($Response.result.powerusages[$i], 0)
				}
			}
			catch
			{
				Write-Pretty-Error $MinerApiErrorStr

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		"excavator"
		{
			for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
			{
				$ResponseRaw = Read-Miner-Api '{"id":1,"method":"device.get","params":["0"]}' $false

				try
				{
					$Response = $ResponseRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
					$PowerUsage += ([math]::Round($Response.gpu_power_usage, 0))
				}
				catch
				{
					if ($Config.Debug)
					{
						Write-Pretty-Debug $_.Exception
					}
				}
			}
		}

		"zecminer"
		{
			$ResponseRaw = Read-Miner-Api '{"id":"0", "method":"getstat"}' $false

			try
			{
				$Response = $ResponseRaw | ConvertFrom-Json -ErrorAction SilentlyContinue

				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$PowerUsage += $Response.result[$i].gpu_power_usage
				}
			}
			catch
			{
				Write-Pretty-Error $MinerApiErrorStr

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}
	}

	$RigStats.PowerUsage = $PowerUsage
}

function Measure-Earnings ()
{
	if ($SessionConfig.CoinMode)
	{
		$HashRate = $RigStats.HashRate / $WtmModifiers[$Config.Algo]
		$WtmUrl = "https://whattomine.com/coins/" + $Coins[$Config.Coin].WtmPage + "?hr=" + $HashRate + "&p=0&cost=0&fee=" + $Pools[$Config.Pool].PoolFee + "&commit=Calculate"

		try
		{
			$WtmHtml = Invoke-WebRequest -Uri $WtmUrl -UseBasicParsing -ErrorAction SilentlyContinue
		}
		catch
		{
			Write-Pretty-Error "WhatToMine request failed! Is your network connection working?"

			if ($Config.Debug)
			{
				Write-Pretty-Debug $_.Exception
			}
		}

		$WtmObj = $WtmHtml.Content -split "[`r`n]"
		$LineNo = $WtmObj | Select-String -Pattern "Estimated Rewards" | Select-Object -ExpandProperty 'LineNumber'

		try
		{
			$BtcEarnings = [System.Convert]::ToDouble(($WtmObj | Select-Object -Index ($LineNo + 46)).Trim())
			$RigStats.EarningsBtc = [math]::Round($BtcEarnings, 8)

			if ($SessionConfig.Rates)
			{
				$RigStats.EarningsFiat = [math]::Round(($RigStats.EarningsBtc * $BtcRates[$Config.Currency]), 2)
			}
		}
		catch
		{
			Write-Pretty-Error "Malformed WhatToMine response."

			if ($Config.Debug)
			{
				Write-Pretty-Debug $_.Exception
			}
		}
	}
	else
	{
		$HashRate = $RigStats.HashRate / $NiceHashAlgos[$Config.Algo].Modifier

		try
		{
			$ResponseRaw = Invoke-WebRequest -Uri "https://api.nicehash.com/api?method=stats.global.24h" -UseBasicParsing -ErrorAction SilentlyContinue
			$Response = $ResponseRaw | ConvertFrom-Json
			$Multiplier = 1 - ($Pools[$Config.Pool].PoolFee / 100)
			$Price = $Response.result.stats[$NiceHashAlgos[$Config.Algo].Id].price * $Multiplier
			$RigStats.EarningsBtc = [math]::Round(($HashRate * $Price), 8)

			if ($SessionConfig.Rates)
			{
				$RigStats.EarningsFiat = [math]::Round(($RigStats.EarningsBtc * $BtcRates[$Config.Currency]), 2)
			}
		}
		catch
		{
			Write-Pretty-Error "NiceHash request failed! Is your network connection working?"

			if ($Config.Debug)
			{
				Write-Pretty-Debug $_.Exception
			}
		}
	}
}

function Update-ExchangeRates ()
{
	try
	{
		$ResponseRaw = Invoke-WebRequest -Uri $BlockchainUrl -UseBasicParsing
		$Response = $ResponseRaw | ConvertFrom-Json -AsHashtable

		foreach ($Currency in $Response.Keys)
		{
			$BtcRates[$Currency] = $Response[$Currency].buy
		}
	}
	catch
	{
		Write-Pretty-Error "Error updating BTC exchange rates! Is your network connection working?"

		if ($Config.Debug)
		{
			Write-Pretty-Debug $_.Exception
		}
	}
}

function Measure-Profit ()
{
	Update-ExchangeRates
	$RigStats.Profit = [math]::Round($RigStats.EarningsFiat - ($Config.ElectricityCost * $RigStats.PowerUsage * 24 / 1000), 2)
}

function Get-Archive ($Url, $FileName)
{
	$DestFile = [io.path]::combine($TempDir, $FileName)
	$Client = New-Object System.Net.WebClient

	try
	{
		$Client.DownloadFile($Url, $DestFile)
	}
	catch
	{
		Write-Pretty-Error "Error downloading package! Is your network connection working?"

		if ($Config.Debug)
		{
			Write-Pretty-Debug $_.Exception
		}

		Exit-RudeHash
	}

	return $TempDir
}

function Expand-Stuff ($File, $DestDir)
{
	if ($File.EndsWith(".7z"))
	{
		Start-Process -FilePath ([io.path]::combine($ToolsDir, "7zip", $Tools["7zip"].ExeFile)) -ArgumentList ("x -o$DestDir $File") -NoNewWindow -Wait
	}
	elseif ($File.EndsWith(".exe"))
	{
		New-Item -ItemType Directory -Path $DestDir | Out-Null
		Move-Item -Path $File -Destination $DestDir
	}
	else
	{
		Expand-Archive -LiteralPath $File -DestinationPath $DestDir
	}
}

function Test-Tool ($Name)
{
	$ToolDir = [io.path]::combine($ToolsDir, $Name)
	$ToolExe = [io.path]::combine($ToolDir, $Tools[$Name].ExeFile)

	if (-Not (Test-Path -LiteralPath $ToolsDir))
	{
		New-Item -ItemType Directory -Path $ToolsDir | Out-Null
	}

	if (-Not (Test-Path -LiteralPath $ToolExe))
	{
		if (Test-Path -LiteralPath $ToolDir)
		{
			Remove-Item -Recurse -Force -Path $ToolDir
		}

		Write-Pretty-Info ("Downloading " + $Name + "...")
		$ArchiveDir = (Get-Archive ($Tools[$Name].Url) ($Tools[$Name].ArchiveFile))

		if ($Tools[$Name].FilesInRoot)
		{
			$DestPath = ([io.path]::combine($ArchiveDir, $Name))
		}
		else
		{
			$DestPath = $ArchiveDir
		}

		Expand-Stuff ([io.path]::combine($ArchiveDir, $Tools[$Name].ArchiveFile)) $DestPath

		if (-Not ($Tools[$Name].FilesInRoot))
		{
			# don't try to rename tool dir to itself
			if (((Get-ChildItem -Directory $ArchiveDir | Select-Object -First 1).FullName).Split('\')[-1] -eq $Name)
			{
				$DestPath = [io.path]::combine($ArchiveDir, $Name)
			}
			else
			{
				$DestPath = (Rename-Item -Path (Get-ChildItem -Directory $ArchiveDir | Select-Object -First 1).FullName -NewName $Name -PassThru).FullName
			}
		}

		Move-Item -Force $DestPath $ToolsDir
	}
}

function Test-Tools ()
{
	foreach ($Tool in $Tools.Keys)
	{
		Test-Tool $Tool
	}
}

function Get-MinerOutput ($Exe, $Argus)
{
	$ProcInfo = New-Object System.Diagnostics.ProcessStartInfo
	$ProcInfo.FileName = $Exe
	# stupid PowerShell, $Args is a reserved word
	$ProcInfo.Arguments = $Argus
	$ProcInfo.RedirectStandardOutput = $true
	#$ProcInfo.RedirectStandardError = $true
	$ProcInfo.UseShellExecute = $false

	$Proc = New-Object System.Diagnostics.Process
	$Proc.StartInfo = $ProcInfo
	$Proc.Start() | Out-Null
	$Proc.WaitForExit()
	$Str = $Proc.StandardOutput.ReadToEnd()
	#$Str += $Proc.StandardError.ReadToEnd()

	return $Str
}

function Get-MinerVersion ($Name)
{
	$MinerDir = [io.path]::combine($MinersDir, $Name)
	$MinerExe = [io.path]::combine($MinerDir, $Miners[$Name].ExeFile)

	try {
		switch ($Name)
		{
			# klaust messes up stdio, can't determine version reliably
			#"ccminer-klaust" { $VersionStr = (Get-MinerOutput $MinerExe "-V").Split("`r`n")[0].Split(" ")[1].Split("-")[0] }
			"ccminer-phi" { $VersionStr = (Get-MinerOutput $MinerExe "-V").Split("`r`n")[0].Split("-")[1] }
			{$_ -in "ccminer-rvn", "ccminer-tpruvot"} { $VersionStr = (Get-MinerOutput $MinerExe "-V").Split("`r`n")[0].Split(" ")[2] }
			"dstm" { $VersionStr = (Get-MinerOutput $MinerExe "").Split("`r`n")[0].Split(" ")[1].Split(",")[0] }
			"ethminer" { $VersionStr = (Get-MinerOutput $MinerExe "-V").Split("`r`n")[0].Split(" ")[2].Split("+")[0] }
			"excavator" { $VersionStr = (Get-MinerOutput $MinerExe "-h").Split("`r`n")[2].Trim().Split(" ")[1].Substring(1) }
			"hsrminer" { $VersionStr = (Get-MinerOutput $MinerExe "-h").Split("`r`n")[17].Trim().Split(" ")[3] }
			"vertminer" { $VersionStr = (Get-MinerOutput $MinerExe "-V").Split("`r`n")[0].Split(" ")[2] }
			"zecminer" { $VersionStr = (Get-MinerOutput $MinerExe "-V").Split("`r`n")[1].Split("|")[1].Trim().Split(" ")[4] }
		}
	}
	catch
	{
		$VersionStr = "UNKNOWN"
	}

	return $VersionStr
}

function Test-Miner ($Name)
{
	$MinerDir = [io.path]::combine($MinersDir, $Name)
	$MinerExe = [io.path]::combine($MinerDir, $Miners[$Name].ExeFile)

	# create main miners dir if missing
	if (-Not (Test-Path -LiteralPath $MinersDir))
	{
		New-Item -ItemType Directory -Path $MinersDir | Out-Null
	}

	$MinerExists = Test-Path -LiteralPath $MinerExe

	# update check
	if ($Miners[$Name].Version)
	{
		$LatestVer = $Miners[$Name].Version
		$VersionStr = " v" + $LatestVer

		if ($MinerExists)
		{
			$CurrentVer = Get-MinerVersion $Name

			if (-Not ($LatestVer -eq $CurrentVer))
			{
				if ($CurrentVer -eq "UNKNOWN")
				{
					Write-Pretty-Info ("Unknown " + $Name + " version found, it will be replaced with v" + $LatestVer + ".")
				}
				else
				{
					Write-Pretty-Info ($Name + " v" + $CurrentVer + " found, it will be updated to v" + $LatestVer + ".")
				}

				try
				{
					Remove-Item -Recurse -Force -Path $MinerDir
				}
				catch
				{
					Write-Pretty-Error ("Error removing " + $Name + " v" + $CurrentVer + "!")
					Exit-RudeHash
				}

				$MinerExists = $false
			}
			elseif ($Config.Debug)
			{
				Write-Pretty-Debug ($Name + " v" + $CurrentVer + " found, it is the latest version.")
			}
		}
	}

	if (-Not $MinerExists)
	{
		if (Test-Path -LiteralPath $MinerDir)
		{
			Remove-Item -Recurse -Force -Path $MinerDir
		}

		Write-Pretty-Info ("Downloading " + $Name + $VersionStr + "...")
		$ArchiveDir = (Get-Archive ($Miners[$Name].Url) ($Miners[$Name].ArchiveFile))

		if ($Miners[$Name].FilesInRoot)
		{
			$DestPath = ([io.path]::combine($ArchiveDir, $Name))
		}
		else
		{
			$DestPath = $ArchiveDir
		}

		Expand-Stuff ([io.path]::combine($ArchiveDir, $Miners[$Name].ArchiveFile)) $DestPath

		if (-Not ($Miners[$Name].FilesInRoot))
		{
			# don't try to rename miner dir to itself
			if (((Get-ChildItem -Directory $ArchiveDir | Select-Object -First 1).FullName).Split('\')[-1] -eq $Name)
			{
				$DestPath = [io.path]::combine($ArchiveDir, $Name)
			}
			else
			{
				$DestPath = (Rename-Item -Path (Get-ChildItem -Directory $ArchiveDir | Select-Object -First 1).FullName -NewName $Name -PassThru).FullName
			}
		}

		Move-Item -Force $DestPath $MinersDir
	}
}

function Set-WindowTitle ()
{
	# $Sep = " `u{25a0 | 25bc} "
	$Sep = " `u{2219} "

	if ($SessionConfig.CoinMode)
	{
		$CoinStr = ("Coin: " + $Config.Coin.ToUpper() + $Sep)
	}
	else
	{
		$CoinStr = ""
	}

	if ($Pools[$Config.Pool].Authless)
	{
		$WalletStr = "Wallet: " + $Config.Wallet + $Sep
		$WorkerStr = "Worker: " + $Config.Worker + $Sep
	}
	else
	{
		$WalletStr = ""
		$WorkerStr = "Worker: " + $Config.User + "." + $Config.Worker + $Sep
	}

	$Host.UI.RawUI.WindowTitle = "RudeHash" + $Sep + "Pool: " + $PoolNames[$Config.Pool] + $Sep + $WalletStr + $WorkerStr + $CoinStr + "Algo: " + $AlgoNames[$Config.Algo] + $Sep + "Miner: " + $Config.Miner
}

function Update-MinerUptime ()
{
	try
	{
		$Proc = Get-Process -Id $RigStats.Pid -ErrorVariable Err -ErrorAction SilentlyContinue
		$RigStats.Uptime = New-TimeSpan -Start $Proc.StartTime -End (Get-Date)
	}
	catch
	{
		Write-Pretty-Error "Error while checking the miner's uptime!"

		if ($Config.Debug)
		{
			Write-Pretty-Debug $Err
		}
	}
}

function Get-PrettyUptime ()
{
	return "$($RigStats.Uptime.Days)d $($RigStats.Uptime.Hours)h $($RigStats.Uptime.Minutes)m"
}

function Read-Stats ()
{
	Update-MinerUptime

	if ($SessionConfig.DevMining)
	{
		$RigStats.HashRate = 0;
		$RigStats.PowerUsage = 0;
		$RigStats.EarningsBtc = 0;
	}
	elseif ($SessionConfig.Api)
	{
		if ($RigStats.GpuCount -eq 0)
		{
			Get-GpuCount
		}
		else
		{
			Get-HashRate
			Get-PowerUsage

			if (($SessionConfig.CoinMode -And $Coins[$Config.Coin].WtmPage) -Or (-Not ($SessionConfig.CoinMode) -And $NiceHashAlgos.ContainsKey($Config.Algo)))
			{
				Measure-Earnings

				if ($SessionConfig.Rates)
				{
					if ($RigStats.PowerUsage -gt 0)
					{
						Measure-Profit
					}
				}
			}
		}
	}
}

function Write-Stats ()
{
	if ($SessionConfig.DevMining)
	{
		Write-Pretty-Info ("Dev mining minutes " + $RigStats.DevMinutes  + "/10")
	}
	elseif ($SessionConfig.Api)
	{
		if (-Not ($RigStats.GpuCount -eq 0))
		{
			$Sep = " `u{2219} "

			# ccminer-phi seems to always report 0 watts
			if ($RigStats.PowerUsage -gt 0)
			{
				$PowerUsageStr = $Sep + "Power Usage: " + $RigStats.PowerUsage + " W"
			}

			Write-Pretty-Info ("Uptime: " + (Get-PrettyUptime) + $Sep + "Number of GPUs: " + $RigStats.GpuCount + $Sep + "Hash Rate: " + (Get-HashRate-Pretty $RigStats.HashRate) + $PowerUsageStr)

			# use WTM for coins, NH for algos
			if (($SessionConfig.CoinMode -And $Coins[$Config.Coin].WtmPage) -Or (-Not ($SessionConfig.CoinMode) -And $NiceHashAlgos.ContainsKey($Config.Algo)))
			{
				# we could keep trying to obtain exchange rates, but if it would eventually succeed and the
				# list didn't contain the currency specified in the config, it'd result in indexing errors
				# or we could re-check the property, but then it'd cause mining to stop; neither is desirable
				if ($SessionConfig.Rates)
				{
					$FiatStr = " / " + $RigStats.EarningsFiat + " " + $Config.Currency

					if ($RigStats.PowerUsage -gt 0)
					{
						$ProfitStr = $Sep + "Daily profit: " + $RigStats.Profit + " " + $Config.Currency
					}
				}

				Write-Pretty-Earnings ("Daily earnings: " + $RigStats.EarningsBtc + " BTC" + $FiatStr + $ProfitStr)
			}
		}
	}
}

function Start-Miner ()
{
	# in the extremely rare case of AV deleting the miner, or even 7-Zip, try to re-download
	Test-Tools
	Test-Miner $Config.Miner

	$Exe = [io.path]::combine($MinersDir, $Config.Miner, $Miners[$Config.Miner].ExeFile)
	$Args = Initialize-MinerArgs

	if ($Config.Debug)
	{
		Write-Pretty-Debug ("Stratum address: " + $SessionConfig.Server + ":" + $SessionConfig.Port)
		Write-Pretty-Debug ("Miner command line: $Exe $Args")
	}

	$Proc = Start-Process -FilePath $Exe -ArgumentList $Args -PassThru -NoNewWindow
	$RigStats.Pid = $Proc.Id
	return $Proc
}

function Enable-DevMining ()
{
	# we could just re-read the config file but that might cause a file access error in the middle of the day
	# let's just make sure we don't do anything risky
	$FileConfig.Pool = $Config.Pool
	$Config.Pool = "zpool"

	$FileConfig.Algo = $Config.Algo
	$Config.Algo = "equihash"

	$FileConfig.Miner = $Config.Miner
	$Config.Miner = "dstm"

	$FileConfig.Coin = $Config.Coin
	$Config.Coin = ""

	$FileConfig.Wallet = $Config.Wallet
	$Config.Wallet = "1HFapEBFTyaJ74SULTJ5oN5BK3C5AYHWzk"

	$FileConfig.ExtraArgs = $Config.ExtraArgs
	$Config.ExtraArgs = ""

	# update server, port, etc
	Test-Compatibility
}

function Disable-DevMining ()
{
	$Config.Pool = $FileConfig.Pool
	$Config.Algo = $FileConfig.Algo
	$Config.Miner = $FileConfig.Miner
	$Config.Coin = $FileConfig.Coin
	$Config.Wallet = $FileConfig.Wallet
	$Config.ExtraArgs = $FileConfig.ExtraArgs

	# update server, port, etc
	Test-Compatibility
}

function Test-DevMining ($Proc)
{
	if ($SessionConfig.DevMining)
	{
		$RigStats.DevMinutes += 1
	}
	# only start devfee processing if user's miner has been running for 24 hours straight
	elseif ($RigStats.Uptime.Hours -ge 24)
	{
		Write-Pretty-Info ("Starting dev mining...")
		Enable-DevMining
		Stop-Process $Proc
		Start-Sleep 5
		$Proc = Start-Miner
		$SessionConfig.DevMining = $true
	}

	if ($RigStats.DevMinutes -ge 10)
	{
		Write-Pretty-Info ("Stopping dev mining...")
		Disable-DevMining
		Stop-Process $Proc
		Start-Sleep 5
		$Proc = Start-Miner
		$RigStats.DevMinutes = 0
		$SessionConfig.DevMining = $false
	}

	return $Proc
}

function Ping-Miner ($Proc)
{
	if ($SessionConfig.Api -And $Config.Watchdog -And (-Not ($SessionConfig.DevMining)))
	{
		if ($RigStats.HashRate -eq 0)
		{
			$RigStats.FailedChecks += 1

			if ($RigStats.FailedChecks -ge 2)
			{
				$Suffix = "s"
			}

			if ($Config.Debug)
			{
				Write-Pretty-Debug ("Watchdog detected zero hash rate " + $RigStats.FailedChecks + " time" + $Suffix + ".")
			}
		}

		if ($RigStats.FailedChecks -ge 5)
		{
			Write-Pretty-Error "Watchdog detected zero hash rate, restarting miner..."
			Stop-Process $Proc
			# let the dust settle
			Start-Sleep 5
			$Proc = Start-Miner
			$RigStats.FailedChecks = 0
		}
	}

	return $Proc
}

function Ping-Monitoring ()
{
	if ($Config.MonitoringKey -Or $Config.MphApiKey)
	{
		if ($SessionConfig.DevMining)
		{
			$Name = "dev fee"
			$Active = ($RigStats.DevMinutes * 10).ToString() + " %"
		}
		else
		{
			$Name = $Config.Miner
			$Active = Get-PrettyUptime
		}

		$MinerStats= @{
			Name = $Name
			Path = $Miners[$Config.Miner].ExeFile
			Type = @()
			PID = $RigStats.Pid
			Active = $Active
			Algorithm = @($AlgoNames[$Config.Algo])
			Pool = @($PoolNames[$Config.Pool])
			'BTC/day' = $RigStats.EarningsBtc
		}

		# if sent as array, MPM Monitoring displays it as H/s regardless of suffix
		# if not sent as array, MPH Stats errors out completely
		# because reasons.
		$HashRate = Get-HashRate-Pretty $RigStats.HashRate

		if ($Config.MonitoringKey)
		{
			try
			{
				$MinerStats.Add("CurrentSpeed", $HashRate)
				$MinerStats.Add("EstimatedSpeed", $HashRate)
				$MinerJson = ConvertTo-Json @($MinerStats)
				$MinerStats.Remove("CurrentSpeed")
				$MinerStats.Remove("EstimatedSpeed")

				$Response = Invoke-RestMethod -Uri $MonitoringUrl -Method Post -Body @{ address = $Config.MonitoringKey; workername = $Config.Worker; miners = $MinerJson; profit = $RigStats.EarningsBtc } -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue

				if ($Config.Debug)
				{
					#Write-Pretty-Debug $MinerJson
					Write-Pretty-Debug ("Monitoring server response: $Response")
				}
			}
			catch
			{
				Write-Pretty-Error "Error while pinging the monitoring server!"

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		if ($Config.MphApiKey)
		{
			try
			{
				$MinerStats.Add("CurrentSpeed", @($HashRate))
				$MinerStats.Add("EstimatedSpeed", @($HashRate))
				$MinerJson = ConvertTo-Json @($MinerStats)

				$Response = Invoke-RestMethod -Uri ($MphStatsUrl + $Config.MphApiKey) -Method Post -Body @{ workername = $Config.Worker; miners = $MinerJson; profit = $RigStats.EarningsBtc } -UseBasicParsing -TimeoutSec 10 -ErrorAction SilentlyContinue
			}
			catch
			{
				Write-Pretty-Error "Error while pinging the MiningPoolHubStats server!"

				if ($Config.Debug)
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}
	}
}

function Start-RudeHash ()
{
	# restart automatically if the miner crashes
	while (1)
	{
		# get GPU count quickly, but not on excavator, it knows the GPU count already
		if ($FirstLoop -And $SessionConfig.Api -And (-Not($Config.Miner -eq "excavator")))
		{
			$Delay = 15
		}
		else
		{
			$Delay = 60
		}

		if ($FirstLoop -or $Proc.HasExited)
		{
			if ($Proc.HasExited)
			{
				Write-Pretty-Error ("Miner has crashed, restarting...")
			}

			$Proc = Start-Miner
		}
		else
		{
			Read-Stats
			$Proc = Ping-Miner $Proc
			$Proc = Test-DevMining $Proc
			Write-Stats
			Ping-Monitoring
		}

		Start-Sleep -Seconds $Delay

		$FirstLoop = $false
	}
}

Write-Pretty-Header
Initialize-Temp
Initialize-Properties
Set-WindowTitle
Test-Miner "dstm"
Start-RudeHash
