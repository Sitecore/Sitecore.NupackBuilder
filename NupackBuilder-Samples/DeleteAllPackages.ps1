param
(
  [Parameter(Mandatory=$false,helpmessage="The feed to get packages from during processing")][string]$NugetFeed = "https://www.nuget.org/api/v2/",
  [Parameter(Mandatory=$true,helpmessage="The feed to delete packages from")][ValidateNotNullOrEmpty()][string]$Feed,  
  [Parameter(Mandatory=$true,helpmessage="The API key used when deleting")][ValidateNotNullOrEmpty()][string]$APIKey
)

cls

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$NugetModuleRoot = Split-Path -Parent $root
Set-location -Path $root
$nugetExecutable = "$root\nuget.exe"
if (!(Test-Path -Path $nugetExecutable -PathType Leaf))
{
	$sourceNugetExe = "http://nuget.org/nuget.exe"
	Invoke-WebRequest $sourceNugetExe -OutFile "$nugetExecutable"
}

if ((Test-Path -Path $nugetExecutable))
{
	$nugetArgs = ' update -self -PreRelease'
	$nugetCommand = "& '"+"$nugetExecutable"+"'" + $nugetArgs
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

$packages = ListAllPackages -feed $Feed -nugetFullPath $nugetExecutable
foreach($packageInfo in $packages)
{
	$package = $packageInfo.Split(" ")
	DeletePackageFromFeed `
						-moduleName $package[0] `
						-moduleVersion $package[1] `
						-nugetFullPath $nugetExecutable `
						-feed $Feed `
						-APIKey $APIKey
}