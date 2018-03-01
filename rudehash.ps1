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

if (Test-Path "$PSScriptRoot/rudehash.properties")
{
	$Config = ConvertFrom-StringData(Get-Content "$PSScriptRoot/rudehash.properties" -raw)
}
else
{
	Write-Pretty-Error ("Properties file 'rudehash.properties' not found! Please create it. Example:")
	Write-Pretty-Info (Get-Content "$PSScriptRoot/rudehash.properties.example")
	Exit-RudeHash
}

$MinersDir = [io.path]::combine($PSScriptRoot, "miners")
$ToolsDir = [io.path]::combine($PSScriptRoot, "tools")
$TempDir = [io.path]::combine($PSScriptRoot, "temp")
$FirstRun = $true
$MinerPort = 28178

$Pools =
@{
	"mph" =
	@{
		PoolFee = 1.1
		Authless = $false
		CoinMining = $true
		Regions = $true
		Algos =
		@{
			"ethash" = @{ Server = $Config.Region + ".ethash-hub.miningpoolhub.com"; Port = 17020 }
			"equihash" = @{ Server = $Config.Region + ".equihash-hub.miningpoolhub.com"; Port = 17023 }
			"lyra2v2" = @{ Server = "hub.miningpoolhub.com"; Port = 17018 }
			"neoscrypt" = @{ Server = "hub.miningpoolhub.com"; Port = 17012 }
		}
	}
	"zpool" =
	@{
		PoolFee = 2
		Authless = $true
		CoinMining = $false
		Regions = $false
		Algos =
		@{
			"equihash" = @{ Server = "equihash.mine.zpool.ca"; Port = 2142 }
			"lyra2v2" = @{ Server = "lyra2v2.mine.zpool.ca"; Port = 4533 }
			"neoscrypt" = @{ Server = "neoscrypt.mine.zpool.ca"; Port = 4233 }
			"phi" = @{ Server = "phi.mine.zpool.ca"; Port = 8333 }
		}
	}
}

$Coins =
@{
	"btg" = @{ PoolPage = "bitcoin-gold"; WtmPage = "214-btg-equihash"; Server = $Config.Region + ".equihash-hub.miningpoolhub.com"; Port = 20595; Algo = "equihash" }
	"eth" = @{ PoolPage = "ethereum"; WtmPage = "151-eth-ethash"; Server = $Config.Region + ".ethash-hub.miningpoolhub.com"; Port = 20535; Algo = "ethash" }
	"ftc" = @{ PoolPage = "feathercoin"; WtmPage = "8-ftc-neoscrypt"; Server = "hub.miningpoolhub.com"; Port = 20510; Algo = "neoscrypt" }
	"mona" = @{ PoolPage = "monacoin"; WtmPage = "148-mona-lyra2rev2"; Server = "hub.miningpoolhub.com"; Port = 20593; Algo = "lyra2v2" }
	"vtc" = @{ PoolPage = "vertcoin"; WtmPage = "5-vtc-lyra2rev2"; Server = "hub.miningpoolhub.com"; Port = 20507; Algo = "lyra2v2" }
	"zcl" = @{ PoolPage = "zclassic"; WtmPage = "167-zcl-equihash"; Server = $Config.Region + ".equihash-hub.miningpoolhub.com"; Port = 20575; Algo = "equihash" }
	"zec" = @{ PoolPage = "zcash"; WtmPage = "166-zec-equihash"; Server = $Config.Region + ".equihash-hub.miningpoolhub.com"; Port = 20570; Algo = "equihash" }
	"zen" = @{ PoolPage = "zencash"; WtmPage = "185-zen-equihash"; Server = $Config.Region + ".equihash-hub.miningpoolhub.com"; Port = 20594; Algo = "equihash" }
}

$Miners =
@{
	"ccminer-klaust" = @{ Url = "https://github.com/KlausT/ccminer/releases/download/8.20/ccminer-820-cuda91-x64.zip"; ArchiveFile = "ccminer-klaust.zip"; ExeFile = "ccminer.exe"; FilesInRoot = $true; Algos = @("lyra2v2", "neoscrypt"); Api = $true }
	"ccminer-phi" = @{ Url = "https://github.com/216k155/ccminer-phi-anxmod/releases/download/ccminer%2Fphi-1.0/ccminer-phi-1.0.zip"; ArchiveFile = "ccminer-phi.zip"; ExeFile = "ccminer.exe"; FilesInRoot = $false; Algos = @("phi"); Api = $true }
	"ccminer-tpruvot" = @{ Url = "https://github.com/tpruvot/ccminer/releases/download/2.2.4-tpruvot/ccminer-x64-2.2.4-cuda9.7z"; ArchiveFile = "ccminer-tpruvot.7z"; ExeFile = "ccminer-x64.exe"; FilesInRoot = $true; Algos = @("equihash", "lyra2v2", "neoscrypt"); Api = $true }
	"dstm" = @{ Url = "https://github.com/nemosminer/DSTM-equihash-miner/releases/download/DSTM-0.5.8/zm_0.5.8_win.zip"; ArchiveFile = "dstm.zip"; ExeFile = "zm.exe"; FilesInRoot = $false; Algos = @("equihash"); Api = $true }
	"ethminer" = @{ Url = "https://github.com/ethereum-mining/ethminer/releases/download/v0.14.0.dev1/ethminer-0.14.0.dev1-Windows.zip"; ArchiveFile = "ethminer.zip"; ExeFile = "ethminer.exe"; FilesInRoot = $false; Algos = @("ethash"); Api = $true }
	"excavator" = @{ Url = "https://github.com/nicehash/excavator/releases/download/v1.4.4a/excavator_v1.4.4a_NVIDIA_Win64.zip"; ArchiveFile = "excavator.zip"; ExeFile = "excavator.exe"; FilesInRoot = $false; Algos = @("ethash", "equihash", "lyra2v2", "neoscrypt"); Api = $true }
	"vertminer" = @{ Url = "https://github.com/vertcoin-project/vertminer-nvidia/releases/download/v1.0-stable.2/vertminer-nvdia-v1.0.2_windows.zip"; ArchiveFile = "vertminer.zip"; ExeFile = "vertminer.exe"; FilesInRoot = $false; Algos = @("lyra2v2"); Api = $true }
	"zecminer" = @{ Url = "https://github.com/nanopool/ewbf-miner/releases/download/v0.3.4b/Zec.miner.0.3.4b.zip"; ArchiveFile = "zecminer.zip"; ExeFile = "miner.exe"; FilesInRoot = $true; Algos = @("equihash"); Api = $true }
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
@(
	"asia"
	"europe"
	"us-east"
)

# MPH returns all hashrates in kH/s but WTM uses different magnitudes for different algos
$WtmModifiers =
@{
	"ethash" = 1000000
	"equihash" = 1
	"lyra2v2" = 1000
	"neoscrypt" = 1000
}

$AlgoNames =
@{
	"ethash" = "Ethash"
	"equihash" = "Equihash"
	"lyra2v2" = "Lyra2REv2"
	"neoscrypt" = "NeoScrypt"
	"phi" = "PHI1612"
}

$NiceHashAlgos =
@{
	"equihash" = @{ Id = 24; Modifier = 1000000 }
	"ethash" = @{ Id = 20; Modifier = 1000000000 }
	"lyra2v2" = @{ Id = 14; Modifier = 1000000000000 }
	"neoscrypt" = @{ Id = 8; Modifier = 1000000000 }
}

function Get-Coin-Support ()
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

function Get-Miner-Support ()
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

function Get-Pool-Support ()
{
	$Table = New-Object System.Data.DataTable
	$Table.Columns.Add("Pool", "string") | Out-Null
	$Table.Columns.Add("Algo", "string") | Out-Null

	$Support += "Supported pools and algos:"
	foreach ($Key in $Pools.Keys)
	{
		$Row = $Table.NewRow()
		$Row.Pool = $Key
		$Algos = ""
		$Algos += foreach ($Algo in $Pools[$Key].Algos.Keys) { $Algo }
		$Row.Algo = $Algos
		$Table.Rows.Add($Row)
	}

	# use Format-Table to force flushing to screen immediately
	$Support += Out-String -InputObject ($Table | Format-Table)
	$Table.Dispose()

	return $Support
}

function Test-Property-Pool ()
{
	if (-Not ($Config.Pool))
	{
		Write-Pretty-Error ("Pool must be set!")
		Exit-RudeHash
	}

	if (-Not ($Pools.ContainsKey($Config.Pool)))
	{
		Write-Pretty-Error ("The """ + $Config.Pool + """ pool is not supported!")
		$Sep = "`u{00b7} "

		Write-Pretty-Info "Supported pools:"
		foreach ($Pool in $Pools.Keys)
		{
			Write-Pretty-Info ($Sep + $Pool)
		}

		Exit-RudeHash
	}
}

function Test-BtcWallet ($Address)
{
	if ($Address.StartsWith("1") -Or $Address.StartsWith("3") -Or $Address.StartsWith("bc1"))
	{
		return $true
	}
	else
	{
		return $false
	}
}

function Test-Property-Credentials ()
{
	if (-Not ($Config.Worker))
	{
		Write-Pretty-Error ("Worker must be set!")
		Exit-RudeHash
	}

	if ($Pools[$Config.Pool].Authless)
	{
		if (-Not ($Config.Wallet))
		{
			Write-Pretty-Error ("""" + $Config.Pool + """ is anonymous, wallet address must be set!")
			Exit-RudeHash
		}
		else
		{
			if (-Not (Test-BtcWallet $Config.Wallet))
			{
				Write-Pretty-Error ("Bitcoin wallet address is in incorrect format, please check it!")
				Exit-RudeHash
			}
		}
	}
	else
	{
		if (-Not ($Config.User))
		{
			Write-Pretty-Error ("""" + $Config.Pool + """ implements authentication, username must be set!")
			Exit-RudeHash
		}

		# if (-Not ($Config.ApiKey))
		# {
		# 	Write-Pretty-Error ("""" + $Config.Pool + """ implements authentication, API key must be set!")
		# 	Exit-RudeHash
		# }
	}
}

function Test-Property-Coin ()
{
	if ($Config.Coin)
	{
		$Config.Coin = $Config.Coin.ToLower()

		if (-Not ($Coins.ContainsKey($Config.Coin)))
		{
			Write-Pretty-Error ("The """ + $Config.Coin.ToUpper() + """ coin is not supported!")
			$Sep = "`u{00b7} "

			Write-Pretty-Info "Supported coins:"
			foreach ($Coin in $Coins.Keys)
			{
				Write-Pretty-Info ($Sep + $Coin.ToUpper())
			}

			Exit-RudeHash
		}
	}
}

function Test-Property-Miner ()
{
	if (-Not ($Config.Miner))
	{
		Write-Pretty-Error ("Miner must be set!")
		Exit-RudeHash
	}

	if (-Not ($Miners.ContainsKey($Config.Miner)))
	{
		Write-Pretty-Error ("The """ + $Config.Miner + """ miner is not supported!")
		$Sep = "`u{00b7} "

		Write-Pretty-Info "Supported miners:"
		foreach ($Miner in $Miners.Keys)
		{
			Write-Pretty-Info ($Sep + $Miner)
		}

		Exit-RudeHash
	}
}

function Test-Property-Algo ()
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
			$Sep = "`u{00b7} "

			Write-Pretty-Info "Supported algos:"
			foreach ($Algo in $Algos)
			{
				Write-Pretty-Info ($Sep + $Algo)
			}

			Exit-RudeHash
		}
	}
}

function Test-Property-Region ()
{
	if ($Pools[$Config.Pool].Regions)
	{
		if (-Not ($Config.Region))
		{
			Write-Pretty-Error ("Region must be set!")
			Exit-RudeHash
		}

		if (-Not ($Regions.Contains($Config.Region)))
		{
			Write-Pretty-Error ("The """ + $Config.Region + """ region is not supported!")
			$Sep = "`u{00b7} "

			Write-Pretty-Info "Supported regions:"
			foreach ($Region in $Regions)
			{
				Write-Pretty-Info ($Sep + $Region)
			}

			Exit-RudeHash
		}
	}
}

function Test-Compatibility ()
{
	$Config.CoinMode = $false

	if ($Config.Coin)
	{
		if (-Not ($Pools[$Config.Pool].CoinMining))
		{
			Write-Pretty-Error ("Coin mining is not supported on """ + $Config.Pool + """, please unset the 'Coin' property!")
			Exit-RudeHash
		}
		else
		{
			# use coin algo if coin is specified
			$Config.Algo = $Coins[$Config.Coin].Algo
			$Config.CoinMode = $true
		}
	}

	$MinerMatch = $false

	foreach	($MinerAlgo in $Miners[$Config.Miner].Algos)
	{
		if ($Config.Algo -eq $MinerAlgo)
		{
			$MinerMatch = $true
		}
	}

	if (-Not ($MinerMatch))
	{
		if ($Config.Coin)
		{
			Write-Pretty-Error ("Incompatible configuration! """ + $Config.Coin.ToUpper() + """ cannot be mined with """ + $Config.Miner + """.")
			Write-Pretty-Info (Get-Coin-Support)
		}
		else
		{
			Write-Pretty-Error ("Incompatible configuration! """ + $Config.Algo + """ cannot be mined with """ + $Config.Miner + """.")
		}

		Write-Pretty-Info (Get-Miner-Support)
		Exit-RudeHash
	}

	if (-Not ($Pools[$Config.Pool].Algos.ContainsKey($Config.Algo)))
	{
		Write-Pretty-Error ("Incompatible configuration! """ + $Config.Algo + """ cannot be mined on """ + $Config.Pool + """.")
		Write-Pretty-Info (Get-Pool-Support)
		Exit-RudeHash
	}

	# configuration is good, let's set up globals
	if ($Config.CoinMode)
	{
		$Config.Server = $Coins[$Config.Coin].Server
		$Config.Port = $Coins[$Config.Coin].Port
	}
	else
	{
		$Config.Server = $Pools[$Config.Pool].Algos[$Config.Algo].Server
		$Config.Port = $Pools[$Config.Pool].Algos[$Config.Algo].Port
	}
}

function Test-Property-Cost ()
{
	if ($Miners[$Config.Miner].Api)
	{
		if (-Not ($Config.ElectricityCost))
		{
			Write-Pretty-Error ("Electricity cost must be set!")
			Exit-RudeHash
		}

		try
		{
			$Config.ElectricityCost = [System.Convert]::ToDouble($Config.ElectricityCost)
		}
		catch
		{
			Write-Pretty-Error ("Invalid electricity cost, """ + $Config.ElectricityCost + """ is not a number!")
			Exit-RudeHash
		}
	}
}

function Test-Properties ()
{
	Test-Property-Pool
	Test-Property-Credentials
	Test-Property-Region
	Test-Property-Coin
	Test-Property-Miner
	Test-Property-Algo
	Test-Compatibility
	Test-Property-Cost
}

$RigStats =
[pscustomobject]@{
	GpuCount = 0;
	HashRate = 0;
	Difficulty = 0;
	PowerUsage = 0;
	Earnings = 0;
	Profit = 0;
	ExchangeRate = 0;
}

function Initialize-Temp ()
{
	try
	{
		if (Test-Path $TempDir -ErrorAction Stop)
		{
			Remove-Item -Recurse -Path $TempDir -ErrorAction Stop
		}

		New-Item -ItemType Directory -Path $TempDir -Force -ErrorAction Stop | Out-Null
	}
	catch
	{
		Write-Pretty-Error "Error setting up temporary directory! Do we have write access?"

		if ($Config.Debug -eq "true")
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

		if ($Config.Debug -eq "true")
		{
			Write-Pretty-Debug $_.Exception
		}

		if ($Critical -eq "true")
		{
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

function Resolve-Pool-Ip ()
{
	try
	{
		$Ip = ([System.Net.DNS]::GetHostEntry($Config.Server).AddressList[0].IPAddressToString)	
	}
	catch
	{
		Write-Pretty-Error "Error resolving pool IP addess! Is your network connection working?"

		if ($Config.Debug -eq "true")
		{
			Write-Pretty-Debug $_.Exception
		}

		Exit-RudeHash
	}
	
	return $Ip
}

function Get-GpuCount ()
{
	$ErrorStr = "Malformed miner API response."

	switch ($Config.Miner)
	{
		{$_ -in "ccminer-klaust", "ccminer-phi", "ccminer-tpruvot", "vertminer"}
		{
			$Response = Read-Miner-Api 'summary' $false

			try 
			{
				$Count = $Response.Split("|")[0].Split(";")[4].Split("=")[1]
			}
			catch
			{
				Write-Pretty-Error $ErrorStr

				if ($Config.Debug -eq "true")
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
				$Response = $ResponseRaw | ConvertFrom-Json
				$Count = $Response.result.length
			}
			catch
			{
				Write-Pretty-Error $ErrorStr

				if ($Config.Debug -eq "true")
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
				$Response = $ResponseRaw | ConvertFrom-Json
				$Count = $Response.result[3].Split(";").length
			}
			catch
			{
				Write-Pretty-Error $ErrorStr

				if ($Config.Debug -eq "true")
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		"excavator"
		{
			$ResponseRaw = Read-Miner-Api '{"id":1,"method":"device.list","params":[]}' $true
			$Response = $ResponseRaw | ConvertFrom-Json
			$Count = $Response.devices.length
		}

		"zecminer"
		{
			$ResponseRaw = Read-Miner-Api '{"id":"0", "method":"getstat"}' $false

			try
			{
				$Response = $ResponseRaw | ConvertFrom-Json
				$Count = $Response.result.length
			}
			catch
			{
				Write-Pretty-Error $ErrorStr

				if ($Config.Debug -eq "true")
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

	if ($Config.Debug -eq "true")
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
		{"id":1,"method":"algorithm.add","params":["$($ExcavatorAlgos[$Config.Algo])","$(Resolve-Pool-Ip):$($Config.Port)","$($User):$($Pass)"]}
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

		if ($Config.Debug -eq "true")
		{
			Write-Pretty-Debug $_.Exception
		}

		Exit-RudeHash
	}
	
}

function Initialize-Miner-Args ()
{
	if ($Pools[$Config.Pool].Authless)
	{
		$PoolUser = $Config.Wallet
		$PoolPass = "c=BTC,ID=" + $Config.Worker
	}
	else
	{
		$PoolUser = $Config.User + "." + $Config.Worker
		$PoolPass = "x"
	}

	switch ($Config.Miner)
	{
		{$_ -in "ccminer-klaust", "ccminer-phi", "ccminer-tpruvot"} { $Args = "--algo=" + $Config.Algo + " --url=stratum+tcp://" + $Config.Server + ":" + $Config.Port + " --user=" + $PoolUser + " --pass " + $PoolPass + " --api-bind 127.0.0.1:" + $MinerPort }
		"dstm" { $Args = "--server " + $Config.Server + " --user " + $PoolUser + " --pass " + $PoolPass + " --port " + $Config.Port + " --telemetry=127.0.0.1:" + $MinerPort + " --noreconnect" }
		"ethminer" { $Args = "--cuda --stratum " + $Config.Server + ":" + $Config.Port + " --userpass " + $PoolUser + ":" + $PoolPass + " --api-port " + $MinerPort }
		"excavator"
		{
			Initialize-Excavator $PoolUser $PoolPass
			$Args = "-c " + [io.path]::combine($TempDir, "excavator.json") + " -p " + $MinerPort
		}
		"vertminer" { $Args = "-o stratum+tcp://" + $Config.Server + ":" + $Config.Port + " -u " + $PoolUser + " -p " + $PoolPass + " --api-bind 127.0.0.1:" + $MinerPort }
		"zecminer" { $Args = "--server " + $Config.Server + " --user " + $PoolUser + " --pass " + $PoolPass + " --port " + $Config.Port + " --api 127.0.0.1:" + $MinerPort }
	}

	return $Args
}

# MPH API: https://github.com/miningpoolhub/php-mpos/wiki/API-Reference
function Get-HashRate-Mph ()
{
	$PoolUrl = "https://" + $Coins[$Config.Coin].PoolPage + ".miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=" + $Config.ApiKey

	try
	{
		$PoolJson = Invoke-WebRequest -Uri $PoolUrl -UseBasicParsing -ErrorAction SilentlyContinue | ConvertFrom-Json
		$PoolWorker = $PoolJson.getuserworkers.data | Where-Object -Property "username" -EQ -Value ($Config.User + "." + $Config.Worker)
		# getpoolstatus shows hashrate in H/s, getuserworkers uses kH/s, lovely!
		$HashRate = $PoolWorker.hashrate * 1000
	}
	catch
	{
		$HashRate = 0
		Write-Pretty-Error "Pool API call failed! Have you set your API key correctly?"

		if ($Config.Debug -eq "true")
		{
			Write-Pretty-Debug $_.Exception
		}
	}

	if (-Not ($HashRate))
	{
		$HashRate = 0
	}

	$RigStats.HashRate = ([math]::Round($HashRate, 0))
}

function Get-HashRate-Miner ()
{
	$HashRate = 0
	$ErrorStr = "Malformed miner API response."

	switch ($Config.Miner)
	{
		{$_ -in "ccminer-klaust", "ccminer-phi", "ccminer-tpruvot", "vertminer"}
		{
			$Response = Read-Miner-Api 'threads' $false

			try 
			{
				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$HashRate += $Response.Split("|")[$i].Split(";")[8].Split("=")[1]
				}

				# ccminer returns KH/s
				$HashRate *= 1000
			}
			catch
			{
				Write-Pretty-Error $ErrorStr

				if ($Config.Debug -eq "true")
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
				$Response = $ResponseRaw | ConvertFrom-Json

				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$HashRate += $Response.result[$i].sol_ps
				}
			}
			catch
			{
				Write-Pretty-Error $ErrorStr

				if ($Config.Debug -eq "true")
				{
					Write-Pretty-Debug $_.Exception
				}
			}
		}

		"ethminer"
		{
			$ResponseRaw = Read-Miner-Api '{"id":0,"jsonrpc":"2.0","method":"miner_getstat1"}' $false

			try
			{
				$Response = $ResponseRaw | ConvertFrom-Json
				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$HashRate += $Response.result[3].Split(";")[$i]
				}

				# ethminer returns KH/s
				$HashRate *= 1000
			}
			catch
			{
				Write-Pretty-Error $ErrorStr

				if ($Config.Debug -eq "true")
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
				if ($Config.Debug -eq "true")
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
				$Response = $ResponseRaw | ConvertFrom-Json

				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$HashRate += $Response.result[$i].speed_sps
				}
			}
			catch
			{
				Write-Pretty-Error $ErrorStr

				if ($Config.Debug -eq "true")
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

function Get-Difficulty-Mph ()
{
	$PoolUrl = "https://" + $Coins[$Config.Coin].PoolPage + ".miningpoolhub.com/index.php?page=api&action=getpoolstatus&api_key=" + $Config.ApiKey

	try
	{
		$PoolJson = Invoke-WebRequest -Uri $PoolUrl -UseBasicParsing | ConvertFrom-Json
		$Difficulty = $PoolJson.getpoolstatus.data.networkdiff
		#$Difficulty = $PoolJson.getdashboarddata.data.network.difficulty
		#$HashRate = $PoolJson.getdashboarddata.data.personal.hashrate
	}
	catch
	{
		$Difficulty = 0
		Write-Pretty-Error "Pool API call failed! Have you set your API key correctly?"

		if ($Config.Debug -eq "true")
		{
			Write-Pretty-Debug $_.Exception
		}
	}

	return $Difficulty
}

function Get-PowerUsage ()
{
	$PowerUsage = 0
	$ErrorStr = "Malformed miner API response."

	switch ($Config.Miner)
	{
		{$_ -in "ccminer-klaust", "ccminer-phi", "ccminer-tpruvot", "vertminer"}
		{
			$Response = Read-Miner-Api 'threads' $false

			try 
			{
				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$PowerUsage += $Response.Split("|")[$i].Split(";")[4].Split("=")[1]
				}
			}
			catch
			{
				Write-Pretty-Error $ErrorStr

				if ($Config.Debug -eq "true")
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
				$Response = $ResponseRaw | ConvertFrom-Json

				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$PowerUsage += $Response.result[$i].power_usage
				}
			}
			catch
			{
				Write-Pretty-Error $ErrorStr

				if ($Config.Debug -eq "true")
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
					if ($Config.Debug -eq "true")
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
				$Response = $ResponseRaw | ConvertFrom-Json

				for ($i = 0; $i -lt $RigStats.GpuCount; $i++)
				{
					$PowerUsage += $Response.result[$i].gpu_power_usage
				}
			}
			catch
			{
				Write-Pretty-Error $ErrorStr

				if ($Config.Debug -eq "true")
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
	if ($Config.CoinMode)
	{
		$HashRate = $RigStats.HashRate / $WtmModifiers[$Config.Algo]
		$WtmUrl = "https://whattomine.com/coins/" + $Coins[$Config.Coin].WtmPage + "?hr=" + $HashRate + "&p=0&cost=0&fee=" + $Pools[$Config.Pool].PoolFee + "&commit=Calculate"
	
		try
		{
			$WtmHtml = Invoke-WebRequest -Uri $WtmUrl -UseBasicParsing -ErrorAction SilentlyContinue
		}
		catch
		{
			Write-Pretty-Error "WhatToMine request failed!"
	
			if ($Config.Debug -eq "true")
			{
				Write-Pretty-Debug $_.Exception
			}
		}
		
		$WtmObj = $WtmHtml.Content -split "[`r`n]"
		$LineNo = $WtmObj | Select-String -Pattern "Estimated Rewards" | Select-Object -ExpandProperty 'LineNumber'

		try
		{
			$BtcEarnings = [System.Convert]::ToDouble(($WtmObj | Select-Object -Index ($LineNo + 47)).Trim())
			$RigStats.Earnings = [math]::Round($BtcEarnings, 8)
		}
		catch
		{
			Write-Pretty-Error "Malformed WhatToMine response."
	
			if ($Config.Debug -eq "true")
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
			$Price = $Response.result.stats[$NiceHashAlgos[$Config.Algo].Id].price
			$RigStats.Earnings = [math]::Round(($HashRate * $Price), 8)
		}
		catch
		{
			Write-Pretty-Error "NiceHash request failed!"
	
			if ($Config.Debug -eq "true")
			{
				Write-Pretty-Debug $_.Exception
			}
		}
	}
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

		if ($Config.Debug -eq "true")
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
			Remove-Item -Recurse -Path $ToolDir
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

function Test-Miner ()
{
	$Name = $Config.Miner
	$MinerDir = [io.path]::combine($MinersDir, $Name)
	$MinerExe = [io.path]::combine($MinerDir, $Miners[$Name].ExeFile)

	if (-Not (Test-Path -LiteralPath $MinersDir))
	{
		New-Item -ItemType Directory -Path $MinersDir | Out-Null
	}

	if (-Not (Test-Path -LiteralPath $MinerExe))
	{
		if (Test-Path -LiteralPath $MinerDir)
		{
			Remove-Item -Recurse -Path $MinerDir
		}

		Write-Pretty-Info ("Downloading " + $Config.Miner + "...")
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

	if ($Config.CoinMode)
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

	$Host.UI.RawUI.WindowTitle = "RudeHash" + $Sep + "Pool: " + $Config.Pool + $Sep + $WalletStr + $WorkerStr + $CoinStr + "Algo: " + $AlgoNames[$Config.Algo] + $Sep + "Miner: " + $Config.Miner
}

function Write-Stats ()
{
	if ($Miners[$Config.Miner].Api)
	{
		if ($RigStats.GpuCount -eq 0)
		{
			Get-GpuCount
		}
		else
		{
			$Sep = " `u{2219} "

			Get-HashRate
			Get-PowerUsage

			# ccminer often reports 0 watts
			if ($RigStats.PowerUsage -gt 0)
			{
				$PowerUsageStr = $Sep + "Power Usage: " + $RigStats.PowerUsage + " W"
			}

			Write-Pretty-Info ("Number of GPUs: " + $RigStats.GpuCount + $Sep + "Hash Rate: " + (Get-HashRate-Pretty $RigStats.HashRate) + $PowerUsageStr)

			# use WTM for coins, NH for algos
			if ($Config.CoinMode -Or $NiceHashAlgos.ContainsKey($Config.Algo))
			{
				Measure-Earnings
				Write-Pretty-Earnings ("Estimated daily earnings: " + $RigStats.Earnings + " BTC")
			}
		}	
	}
}

function Start-Miner ()
{
	# restart automatically if the miner crashes
	while (1)
	{
		# get GPU count quickly, but not on excavator, it knows the GPU count already
		if ($FirstRun -And $Miners[$Config.Miner].Api -And (-Not($Config.Miner -eq "excavator")))
		{
			$Delay = 15
		}
		else
		{
			$Delay = 60
		}

		if ($FirstRun -or $Proc.HasExited)
		{
			$Exe = [io.path]::combine($MinersDir, $Config.Miner, $Miners[$Config.Miner].ExeFile)
			$Args = Initialize-Miner-Args

			if ($Config.Debug -eq "true")
			{
				Write-Pretty-Debug ("$Exe $Args")
			}

			if ($Proc.HasExited)
			{
				Write-Pretty-Error ("Miner has crashed, restarting...")
			}

			$Proc = Start-Process -FilePath $Exe -ArgumentList $Args -PassThru -NoNewWindow
		}

		Start-Sleep -Seconds $Delay
		Write-Stats
		$FirstRun = $false

		#Register-EngineEvent PowerShell.Exiting –Action { Stop-Process $Proc }
	}
}

#Stop-Process $Proc
Write-Pretty-Header
Initialize-Temp
Test-Properties
Set-WindowTitle
Test-Tools
Test-Miner
Start-Miner
