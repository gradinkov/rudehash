$Config = ConvertFrom-StringData(Get-Content "$PSScriptRoot/rudehash.properties" -raw)
$MinersDir = [io.path]::combine($PSScriptRoot, "miners")
$FirstRun = $true

$Coins =
@{
	"ZCL" = [pscustomobject]@{ PoolPage = "zclassic"; WtmPage = "167-zcl-equihash"; Server = $Config.Region + ".equihash-hub.miningpoolhub.com"; Port = 20575 }
	"ZEC" = [pscustomobject]@{ PoolPage = "zcash"; WtmPage = "166-zec-equihash"; Server = $Config.Region + ".equihash-hub.miningpoolhub.com"; Port = 20570 }
	"ZEN" = [pscustomobject]@{ PoolPage = "zencash"; WtmPage = "185-zen-equihash"; Server = $Config.Region + ".equihash-hub.miningpoolhub.com"; Port = 20594 }
}

$Miners =
@{
	"zecminer" = [pscustomobject]@{ Url = "https://github.com/nanopool/ewbf-miner/releases/download/v0.3.4b/Zec.miner.0.3.4b.zip"; ArchiveFile = "zecminer.zip"; ExeFile = "miner.exe"; FilesInRoot = $true }
	"bminer" = [pscustomobject]@{ Url = "https://www.bminercontent.com/releases/bminer-v5.3.0-e337b9a-amd64.zip"; ArchiveFile = "bminer.zip"; ExeFile = "bminer.exe"; FilesInRoot = $false }
	"dstm" = [pscustomobject]@{ Url = "https://github.com/nemosminer/DSTM-equihash-miner/releases/download/DSTM-0.5.8/zm_0.5.8_win.zip"; ArchiveFile = "dstm.zip"; ExeFile = "zm.exe"; FilesInRoot = $false }
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
		"bminer" { $Args = "-uri stratum+ssl://" + $Config.User + "." + $Config.Worker + "@" + $Coins[$Config.Coin].Server + ":" + $Coins[$Config.Coin].Port + " -api 127.0.0.1:1880" }
		"dstm" { $Args = "--server " + $Coins[$Config.Coin].Server + " --user " + $Config.User + "." + $Config.Worker + " --pass x --port " + $Coins[$Config.Coin].Port + " --telemetry --noreconnect" }
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

		Expand-Archive -LiteralPath ([io.path]::combine($ArchiveDir, $Miners[$Name].ArchiveFile)) -DestinationPath $DestPath

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

	#Clear-Host
	Write-Pretty Blue ("Worker: " + $RigStats.Worker + " ● Coin: " + $RigStats.Coin + " ● Miner: " + $RigStats.Miner)
	Write-Pretty Blue ("Hashrate: " + $RigStats.HashRate + " H/s ● Difficulty: "+ ([math]::Round($RigStats.Difficulty, 0)))
	Write-Pretty DarkGreen ("Estimated daily income: " + $RigStats.Profit)
}

function Start-Miner ($Name)
{
	# restart automatically if the miner crashes
	while (1)
	{
		if ($FirstRun -or $Proc.HasExited)
		{
			$Proc = Start-Process -FilePath ([io.path]::combine($MinersDir, $Name, $Miners[$Name].ExeFile)) -ArgumentList (Initialize-Miner-Args $Name) -PassThru -NoNewWindow
		}

		Write-Stats
		Start-Sleep -Seconds 60
		$FirstRun = $false
		#Register-EngineEvent PowerShell.Exiting –Action { Stop-Process $Proc }
		#$MinerStats = Send-Tcp localhost 42000 '{"id":1, "method":"getstat"}\n' 10
	}
}

#Stop-Process $Proc

Test-Miner $Config.Miner
Start-Miner $Config.Miner
