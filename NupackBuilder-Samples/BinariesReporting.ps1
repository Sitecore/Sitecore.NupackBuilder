param
(
  [Parameter(Mandatory=$false,helpmessage="The feed to get packages from during processing")][string]$NugetFeed = "https://www.nuget.org/api/v2/",
  [Parameter(Mandatory=$true,helpmessage="The folder to read Sitecore zip files from")][ValidateNotNullOrEmpty()][string]$sitecoreRepositoryFolder  
)

cls

if (!(Test-Path -Path $sitecoreRepositoryFolder))
{
	New-Item $sitecoreRepositoryFolder -type directory -Force | Out-Null
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$NugetModuleRoot = Split-Path -Parent $root
Set-location -Path $root
if (!(Test-Path -Path "$sitecoreRepositoryFolder\nuget.exe" -PathType Leaf))
{
	$sourceNugetExe = "http://nuget.org/nuget.exe"
	Invoke-WebRequest $sourceNugetExe -OutFile "$sitecoreRepositoryFolder\nuget.exe"
}

if ((Test-Path -Path "$sitecoreRepositoryFolder\nuget.exe"))
{
	$nugetArgs = ' update -self -PreRelease'
	$nugetCommand = "& '"+"$sitecoreRepositoryFolder\nuget.exe"+"'" + $nugetArgs
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

$nugetExecutable = $sitecoreRepositoryFolder + "nuget.exe"

Get-ChildItem $sitecoreRepositoryFolder -Filter "*.zip" | % {
	$sitecorezipFileNameOnly = $_.Name    
$FileNameNoExtension = [io.path]::GetFileNameWithoutExtension($sitecorezipFileNameOnly)
$archivePath = "$sitecoreRepositoryFolder$sitecorezipFileNameOnly"
$targetDirectory = "$sitecoreRepositoryFolder$FileNameNoExtension\bin\"
$nuspecDirectory = "$sitecoreRepositoryFolder$FileNameNoExtension\nuspec\"
$packageDirectory = "$sitecoreRepositoryFolder$FileNameNoExtension\nupack\"
$SitecoreVersion = $FileNameNoExtension.ToLower().Replace("sitecore ", "").Replace(" rev. ",".").Replace("rev. ",".").Replace(" rev.",".").Replace(".zip","").Trim()
$nugetExecutable = $sitecoreRepositoryFolder + "nuget.exe"
$frameworVersion = "NET45"

UnZipDLLFiles -installPath $root `
	-ArchivePath $archivePath `
	-TargetPath $targetDirectory `
	-SuppressOutput `
	-nugetFullPath $nugetExecutable `
	-NugetFeed $NugetFeed `
	-Filter "*\Website\bin\*.dll"

# Reporting
$assemblies=Get-ChildItem $targetDirectory -rec |
ForEach-Object {
	try {
		$_ | Add-Member NoteProperty FileVersion ($_.VersionInfo.FileVersion)
		$_ | Add-Member NoteProperty AssemblyVersion ([Reflection.AssemblyName]::GetAssemblyName($_.FullName).Version)
		$_ | Add-Member NoteProperty AssemblyFullName ([Reflection.AssemblyName]::GetAssemblyName($_.FullName).FullName)
	} catch {}
	$_
}

$references = Get-ChildItem $targetDirectory -rec | % {
	$original = [io.path]::GetFileName($_.FullName)
	$bytes   = [System.IO.File]::ReadAllBytes($_.FullName)
	$loaded  = [System.Reflection.Assembly]::Load($bytes)
	$name    = $loaded.ManifestModule
	$loaded.GetReferencedAssemblies() | % {
		$toAdd='' | select Who,FullName,Name,Version, Original, ShouldBe
		if($_.FullName.ToLower().StartsWith("sitecore."))
		{
			$matchValue = $_.Name
			$assembly = ($assemblies | Select-Object Name, FileVersion, AssemblyVersion, AssemblyFullName) -match "$matchValue.dll"

			if($assembly -ne $null)
			{
				if($_.Version -ne $assembly.AssemblyVersion)
				{
					$toAdd.Who,$toAdd.FullName,$toAdd.Name,$toAdd.Version, $toAdd.Original, $toAdd.ShouldBe = $loaded,$_.FullName,$_.Name,$_.Version, $original, $assembly.AssemblyVersion
				}
			}         
				
		}
		$toAdd
		if($loaded -ne $null)
		{
			$loaded = $null
		}
	}
}
	
$references | 
	Group-Object Original, FullName, ShouldBe | 
	Select-Object -expand Name | 
	Sort-Object
}
