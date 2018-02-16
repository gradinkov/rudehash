$Config = ConvertFrom-StringData(Get-Content "$PSScriptRoot/rudehash.properties" -raw)
$MinersDir = [io.path]::combine($PSScriptRoot, "miners")
$ToolsDir = [io.path]::combine($PSScriptRoot, "tools")
$FirstRun = $true
$Config.Coin = $Config.Coin.ToLower()

$Coins =
@{
	"zcl" = [pscustomobject]@{ PoolPage = "zclassic"; WtmPage = "167-zcl-equihash"; Server = $Config.Region + ".equihash-hub.miningpoolhub.com"; Port = 20575; Algos = @("equihash") }
	"zec" = [pscustomobject]@{ PoolPage = "zcash"; WtmPage = "166-zec-equihash"; Server = $Config.Region + ".equihash-hub.miningpoolhub.com"; Port = 20570; Algos = @("equihash") }
	"zen" = [pscustomobject]@{ PoolPage = "zencash"; WtmPage = "185-zen-equihash"; Server = $Config.Region + ".equihash-hub.miningpoolhub.com"; Port = 20594; Algos = @("equihash") }
}

$Miners =
@{
	"zecminer" = [pscustomobject]@{ Url = "https://github.com/nanopool/ewbf-miner/releases/download/v0.3.4b/Zec.miner.0.3.4b.zip"; ArchiveFile = "zecminer.zip"; ExeFile = "miner.exe"; FilesInRoot = $true; Algos = @("equihash") }
	"dstm" = [pscustomobject]@{ Url = "https://github.com/nemosminer/DSTM-equihash-miner/releases/download/DSTM-0.5.8/zm_0.5.8_win.zip"; ArchiveFile = "dstm.zip"; ExeFile = "zm.exe"; FilesInRoot = $false; Algos = @("equihash") }
	"ccminer-tpruvot" = [pscustomobject]@{ Url = "https://github.com/tpruvot/ccminer/releases/download/2.2.4-tpruvot/ccminer-x64-2.2.4-cuda9.7z"; ArchiveFile = "ccminer-tpruvot.7z"; ExeFile = "ccminer-x64.exe"; FilesInRoot = $true; Algos = @("equihash", "neoscrypt", "lyra2v2", "nist5") }
}

$Tools =
@{
	"7zip" = [pscustomobject]@{ Url = "http://7-zip.org/a/7za920.zip"; ArchiveFile = "7zip.zip"; ExeFile = "7za.exe"; FilesInRoot = $true }
}

$RigStats =
[pscustomobject]@{
	Coin = $Config.Coin;
	Miner = $Config.Miner;
	Worker = $Config.Worker;
	HashRate = 0;
	Difficulty = 0;
	Profit = "";
}

function Initialize-Miner-Args ($Name)
{
	switch ($Name)
	{
		"zecminer" { $Args = "--server " + $Coins[$Config.Coin].Server + " --user " + $Config.User + "." + $Config.Worker + " --pass x --port " + $Coins[$Config.Coin].Port + " --api" }
		"dstm" { $Args = "--server " + $Coins[$Config.Coin].Server + " --user " + $Config.User + "." + $Config.Worker + " --pass x --port " + $Coins[$Config.Coin].Port + " --telemetry --noreconnect" }
		"ccminer-tpruvot" { $Args = "--algo=" + $Coins[$Config.Coin].Algos + " --url=stratum+tcp://" + $Coins[$Config.Coin].Server + ":" + $Coins[$Config.Coin].Port + " --user=" + $Config.User + "." + $Config.Worker + " --pass x" }
	}
	return $Args
}

# MPH API: https://github.com/miningpoolhub/php-mpos/wiki/API-Reference
function Get-HashRate ()
{
	$PoolUrl = "https://" + $Coins[$Config.Coin].PoolPage + ".miningpoolhub.com/index.php?page=api&action=getuserworkers&api_key=" + $Config.ApiKey
	$PoolJson = Invoke-WebRequest -Uri $PoolUrl | ConvertFrom-Json
	$PoolWorker = $PoolJson.getuserworkers.data | Where-Object -Property "username" -EQ -Value ($Config.User + "." + $Config.Worker)
	# getpoolstatus shows hashrate in H/s, getuserworkers uses kH/s, lovely!
	$HashRate = $PoolWorker.hashrate * 1000

	if (-Not ($HashRate))
	{
		$HashRate = 0
	}

	return $HashRate
}

function Get-Difficulty ()
{
	$PoolUrl = "https://" + $Coins[$Config.Coin].PoolPage + ".miningpoolhub.com/index.php?page=api&action=getpoolstatus&api_key=" + $Config.ApiKey
	$PoolJson = Invoke-WebRequest -Uri $PoolUrl | ConvertFrom-Json
	$Difficulty = $PoolJson.getpoolstatus.data.networkdiff
	#$Difficulty = $PoolJson.getdashboarddata.data.network.difficulty
	#$HashRate = $PoolJson.getdashboarddata.data.personal.hashrate

	return $Difficulty
}

function Measure-Profit ($HashRate, $Difficulty)
{
	#$WtmUrl = "https://whattomine.com/coins/" + $Coins[$Config.Coin].WtmPage + "?hr=" + $HashRate + "&d=$Difficulty&p=" + $Config.Power + "&cost=" + $Config.ElectricityCost + "&fee=" + $Config.PoolFee + "&commit=Calculate"
	$WtmUrl = "https://whattomine.com/coins/" + $Coins[$Config.Coin].WtmPage + "?hr=$HashRate&d=$Difficulty&p=0&cost=0&fee=" + $Config.PoolFee + "&commit=Calculate"
	$WtmHtml = Invoke-WebRequest -Uri $WtmUrl
	$WtmObj = $WtmHtml.Content -split "[`r`n]"
	$LineNo = $WtmObj | Select-String -Pattern "Estimated Rewards" | Select-Object -ExpandProperty 'LineNumber'

	return ($WtmObj | Select-Object -Index ($LineNo + 56)).Trim()
}

function Get-Archive ($Url, $FileName)
{
	$TempDir = [io.path]::combine($PSScriptRoot, "temp")

	if (Test-Path $TempDir)
	{
		Remove-Item -Recurse -Path $TempDir
	}

	New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

	$DestFile = [io.path]::combine($TempDir, $FileName)
	$Client = New-Object System.Net.WebClient
	Try
	{
		$Client.DownloadFile($Url, $DestFile)
	}
	Catch
	{
		Write-Host $_.Exception
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
			$DestPath = (Rename-Item -Path (Get-ChildItem -Directory $ArchiveDir | Select-Object -First 1).FullName -NewName $Name -PassThru).FullName
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

function Test-Miner ($Name)
{
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
			$DestPath = (Rename-Item -Path (Get-ChildItem -Directory $ArchiveDir | Select-Object -First 1).FullName -NewName $Name -PassThru).FullName
		}

		Move-Item -Force $DestPath $MinersDir
	}
}

function Write-Pretty ($BgColor, $String)
{
	$WindowWidth = $Host.UI.RawUI.MaxWindowSize.Width
	$SpaceCount = $WindowWidth - $String.length
	$String += " " * $SpaceCount

	Write-Host -ForegroundColor White -BackgroundColor $BgColor $String 
}

function Write-Stats ()
{
	$RigStats.HashRate = Get-HashRate
	$RigStats.Difficulty = Get-Difficulty
	$RigStats.Profit = Measure-Profit $RigStats.HashRate $RigStats.Difficulty
	$Sep = " `u{25CF} "

	#Clear-Host
	Write-Pretty Blue ("Worker: " + $RigStats.Worker + $Sep + "Coin: " + $RigStats.Coin.ToUpper() + $Sep + "Miner: " + $RigStats.Miner)

	if (-Not ($FirstRun) )
	{
		Write-Pretty Blue ("Hashrate: " + $RigStats.HashRate + " H/s" + $Sep + "Difficulty: "+ ([math]::Round($RigStats.Difficulty, 0)))
		Write-Pretty DarkGreen ("Estimated daily income: " + $RigStats.Profit)	
	}
}

function Write-Support ()
{
	$Table = New-Object System.Data.DataTable
	$Table.Columns.Add("Coin", "string") | Out-Null
	$Table.Columns.Add("Algo", "string") | Out-Null

	Write-Host "Supported coins:"
	foreach ($Key in $Coins.Keys)
	{
		$Row = $Table.NewRow()
		$Row.Coin = $Key
		$Algos = ""
		$Algos += foreach ($Algo in $Coins[$Key].Algos) { $Algo }
		$Row.Algo = $Algos
		$Table.Rows.Add($Row)
	}

	# use Format-Table to force flushing to screen immediately
	$Table | Format-Table
	$Table.Dispose()

	$Table = New-Object System.Data.DataTable
	$Table.Columns.Add("Miner", "string") | Out-Null
	$Table.Columns.Add("Algo", "string") | Out-Null

	Write-Host "Supported miners:"
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
	$Table | Format-Table
	$Table.Dispose()
}

function Test-Support ()
{
	$Match = $false

	foreach ($CoinAlgo in $Coins[$Config.Coin].Algos)
	{
		foreach	($MinerAlgo in $Miners[$Config.Miner].Algos)
		{
			if (($CoinAlgo -eq $MinerAlgo) -And ($CoinAlgo -eq $Config.Algo))
			{
				$Match = $true
			}
		}
	}

	if (-Not ($Match))
	{
		Write-Pretty Red ("Incompatible configuration! The selected coin cannot be mined with the selected miner and/or algo.")
		Write-Support
		Exit
	}
}

function Start-Miner ($Name)
{
	# restart automatically if the miner crashes
	while (1)
	{
		Write-Stats

		if ($FirstRun -or $Proc.HasExited)
		{
			$Exe = [io.path]::combine($MinersDir, $Name, $Miners[$Name].ExeFile)
			$Args = Initialize-Miner-Args $Name

			if ($Config.Debug -eq "true")
			{
				Write-Pretty Magenta ("$Exe $Args")
			}

			$Proc = Start-Process -FilePath $Exe -ArgumentList $Args -PassThru -NoNewWindow
		}

		$FirstRun = $false
		Start-Sleep -Seconds 60

		#Register-EngineEvent PowerShell.Exiting –Action { Stop-Process $Proc }
		#$MinerStats = Send-Tcp localhost 42000 '{"id":1, "method":"getstat"}\n' 10
	}
}

#Stop-Process $Proc

Clear-Host
Test-Tools
Test-Support
Test-Miner $Config.Miner
Start-Miner $Config.Miner
