param
(
  [Parameter(Mandatory=$false,helpmessage="The feed to get packages from during processing")][string]$NugetFeed = "https://www.nuget.org/api/v2/",
  [Parameter(Mandatory=$true,helpmessage="The target folder to read Sitecore zip files from")][ValidateNotNullOrEmpty()][string]$sitecoreOldVersionRepositoryFolder,
  [Parameter(Mandatory=$true,helpmessage="The target folder to read Sitecore zip files from")][ValidateNotNullOrEmpty()][string]$sitecoreNewVersionRepositoryFolder
)

cls

if (!(Test-Path -Path $sitecoreOldVersionRepositoryFolder))
{
	New-Item $sitecoreOldVersionRepositoryFolder -type directory -Force | Out-Null
}

if (!(Test-Path -Path $sitecoreNewVersionRepositoryFolder))
{
	New-Item $sitecoreNewVersionRepositoryFolder -type directory -Force | Out-Null
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$NugetModuleRoot = Split-Path -Parent $root
Set-location -Path $root
if (!(Test-Path -Path "$sitecoreOldVersionRepositoryFolder\nuget.exe" -PathType Leaf))
{
	$sourceNugetExe = "http://nuget.org/nuget.exe"
	Invoke-WebRequest $sourceNugetExe -OutFile "$sitecoreOldVersionRepositoryFolder\nuget.exe"
}

if (!(Test-Path -Path "$sitecoreNewVersionRepositoryFolder\nuget.exe" -PathType Leaf))
{
	$sourceNugetExe = "http://nuget.org/nuget.exe"
	Invoke-WebRequest $sourceNugetExe -OutFile "$sitecoreNewVersionRepositoryFolder\nuget.exe"
}

if ((Test-Path -Path "$sitecoreOldVersionRepositoryFolder\nuget.exe"))
{
	$nugetArgs = ' update -self -PreRelease'
	$nugetCommand = "& '"+"$sitecoreOldVersionRepositoryFolder\nuget.exe"+"'" + $nugetArgs
	iex $nugetCommand -Verbose | Out-Null
	
}

if ((Test-Path -Path "$sitecoreNewVersionRepositoryFolder\nuget.exe"))
{
	$nugetArgs = ' update -self -PreRelease'
	$nugetCommand = "& '"+"$sitecoreNewVersionRepositoryFolder\nuget.exe"+"'" + $nugetArgs
	iex $nugetCommand -Verbose | Out-Null
	
}

$PlatformModule = Get-Module -Name NupackBuilder-Platform
if ($PlatformModule -eq $null)
{
	Import-Module $NugetModuleRoot\NupackBuilder-Platform -DisableNameChecking
}
else
{
	Remove-Module $PlatformModule -Force
	Import-Module $NugetModuleRoot\NupackBuilder-Platform -DisableNameChecking
}

$nugetOldVersionExecutable = $sitecoreOldVersionRepositoryFolder + "nuget.exe"
$nugetNewVersionExecutable = $sitecoreNewVersionRepositoryFolder + "nuget.exe"

$oldVersionTargetDirectory = ""
$newVersionTargetDirectory = ""


Get-ChildItem $sitecoreOldVersionRepositoryFolder -Filter "*.zip" | % {
	$sitecorezipFileNameOnly = $_.Name    
	$FileNameNoExtension = [io.path]::GetFileNameWithoutExtension($sitecorezipFileNameOnly)
	$archivePath = "$sitecoreOldVersionRepositoryFolder$sitecorezipFileNameOnly"
	$oldVersionTargetDirectory = "$sitecoreOldVersionRepositoryFolder$FileNameNoExtension\bin\"
	$nugetOldVersionExecutable = $sitecoreOldVersionRepositoryFolder + "nuget.exe"

	UnZipDLLFiles -installPath $root `
		-ArchivePath $archivePath `
		-TargetPath $oldVersionTargetDirectory `
		-SuppressOutput `
		-nugetFullPath $nugetOldVersionExecutable `
		-NugetFeed $NugetFeed `
		-Filter "*\Website\bin\*.dll"
}

Get-ChildItem $sitecoreNewVersionRepositoryFolder -Filter "*.zip" | % {
	$sitecorezipFileNameOnly = $_.Name    
	$FileNameNoExtension = [io.path]::GetFileNameWithoutExtension($sitecorezipFileNameOnly)
	$archivePath = "$sitecoreNewVersionRepositoryFolder$sitecorezipFileNameOnly"
	$newVersionTargetDirectory = "$sitecoreNewVersionRepositoryFolder$FileNameNoExtension\bin\"
	$nugetNewVersionExecutable = $sitecoreNewVersionRepositoryFolder + "nuget.exe"

	UnZipDLLFiles -installPath $root `
		-ArchivePath $archivePath `
		-TargetPath $newVersionTargetDirectory `
		-SuppressOutput `
		-nugetFullPath $nugetNewVersionExecutable `
		-NugetFeed $NugetFeed `
		-Filter "*\Website\bin\*.dll"
}

# Reporting
$oldVersionAssemblies=Get-ChildItem $oldVersionTargetDirectory -rec |
ForEach-Object {
	try {
		$_ | Add-Member NoteProperty AssemblyFileVersion ($_.VersionInfo.FileVersion)
		$_ | Add-Member NoteProperty AssemblyVersion ([Reflection.AssemblyName]::GetAssemblyName($_.FullName).Version)
		$_ | Add-Member NoteProperty AssemblyFullName ($_.FullName)
		$_ | Add-Member NoteProperty AssemblyName ($_.Name)
	} catch {}
	$_
}

$references = Get-ChildItem $newVersionTargetDirectory -rec | % {
	$original = [io.path]::GetFileName($_.FullName)
	$bytes   = [System.IO.File]::ReadAllBytes($_.FullName)
	$loaded  = [System.Reflection.Assembly]::Load($bytes)
	$name    = $loaded.ManifestModule
	$loadedAssemblyName = $loaded.GetName()

	

	if(1 -eq 1)
	{
		# Report wrong Assembly Version
		if(($loadedAssemblyName.FullName.ToLower().StartsWith("sitecore.")) -and (!$loadedAssemblyName.FullName.ToLower().StartsWith("sitecore.nexus")))
		{
			$assemblyItemVersion = $loadedAssemblyName.Version
			$assemblyItemName = $loadedAssemblyName.Name
			$foundObject = $null

			$foundObject = ($oldVersionAssemblies | Select-Object AssemblyFileVersion, AssemblyVersion, AssemblyFullName, AssemblyName) -match "$assemblyItemName.dll"
			
			if(($foundObject -ne $null) -and ($foundObject.AssemblyVersion -ne $assemblyItemVersion))
			{
				$foundObjectAssemblyName = $foundObject.AssemblyName
				$foundObjectAssemblyVersion = $foundObject.AssemblyVersion
				Write-Host "$foundObjectAssemblyName, $foundObjectAssemblyVersion, $assemblyItemVersion"
			}
			

		}
	}
}



$references | 
	Group-Object Original, FullName, ShouldBe | 
	Select-Object -expand Name | 
	Sort-Object

