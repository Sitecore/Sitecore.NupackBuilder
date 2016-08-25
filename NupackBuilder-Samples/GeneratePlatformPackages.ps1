param
(
  [Parameter(Mandatory=$false,helpmessage="The feed to get packages from during processing")][string]$NugetFeed = "https://www.nuget.org/api/v2/",
  [Parameter(Mandatory=$true,helpmessage="The feed to upload packages to")][ValidateNotNullOrEmpty()][string]$UploadFeed,  
  [Parameter(Mandatory=$true,helpmessage="The API key used when uploading")][ValidateNotNullOrEmpty()][string]$UploadAPIKey,
  [Parameter(Mandatory=$true,helpmessage="The folder to read Sitecore zip files from")][ValidateNotNullOrEmpty()][string]$SitecoreRepositoryFolder,
  [Parameter(Mandatory=$false,helpmessage="If specified 3rd party references will NOT be added to the packages")][switch]$DisableThirdPartyReferences,
  [Parameter(Mandatory=$false,helpmessage="If specified packages will be uploaded to the feed, otherwise packages will only be created locally")][switch]$UploadPackages
)

cls

if (!(Test-Path -Path $SitecoreRepositoryFolder))
{
	throw('No repository folder exists at the location "'+$SitecoreRepositoryFolder+'"')
	exit(-1)
}

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$NugetModuleRoot = Split-Path -Parent $root
Set-location -Path $root
if (!(Test-Path -Path "$SitecoreRepositoryFolder\nuget.exe" -PathType Leaf))
{
	$sourceNugetExe = "http://nuget.org/nuget.exe"
	Invoke-WebRequest $sourceNugetExe -OutFile "$SitecoreRepositoryFolder\nuget.exe"
}

if ((Test-Path -Path "$SitecoreRepositoryFolder\nuget.exe"))
{
	$nugetArgs = ' update -self -PreRelease'
	$nugetCommand = "& '"+"$SitecoreRepositoryFolder\nuget.exe"+"'" + $nugetArgs
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

$nugetExecutable = $SitecoreRepositoryFolder + "nuget.exe"

$upload = $false
if($UploadPackages)
{
	$upload = $true
}

$addThirdPartyReferences = $true
if($DisableThirdPartyReferences)
{
	$addThirdPartyReferences = $false
}

CreatePlatformPackages `
	  -NugetFeed $NugetFeed `
	  -sitecoreRepositoryFolder $SitecoreRepositoryFolder `
	  -uploadPackages $upload `
	  -uploadFeed $UploadFeed `
	  -uploadAPIKey $UploadAPIKey `
	  -addThirdPartyReferences $addThirdPartyReferences `
	  -root $root `
	  -nugetExecutable $nugetExecutable