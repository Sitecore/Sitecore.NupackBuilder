$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$NugetModuleRoot = Split-Path -Parent $currentPath

$NugetModule = Get-Module -Name NupackBuilder-Nuget
if ($NugetModule -eq $null)
{	
	Import-Module $NugetModuleRoot\NupackBuilder-Nuget -DisableNameChecking
}

$CommonModule = Get-Module -Name NupackBuilder-Common
if ($CommonModule -eq $null)
{	
	Import-Module $NugetModuleRoot\NupackBuilder-Common -DisableNameChecking
}

Function CreateModulePackages(
  [Parameter(Mandatory=$false)][string]$NugetFeed = "https://www.nuget.org/api/v2/",
  [Parameter(Mandatory=$true)][string]$sitecoreRepositoryFolder,
  [Parameter(Mandatory=$true)][bool]$uploadPackages,
  [Parameter(Mandatory=$true)][string]$uploadFeed,
  [Parameter(Mandatory=$true)][string]$uploadAPIKey,
  [Parameter(Mandatory=$false)][Array]$modules,
  [Parameter(Mandatory=$false)][NupackBuilder.Packages]$thirdpartycomponents,
  [Parameter(Mandatory=$false)][bool]$addThirdPartyReferences = $true,
  [Parameter(Mandatory=$true)][string]$root,
  [Parameter(Mandatory=$true)][string]$nugetExecutable
)
{
	write-host "                                                                                                    " -foregroundcolor "red" –backgroundcolor "white"
	write-host "                 ,;':.                                                                              " -foregroundcolor "red" –backgroundcolor "white"
	write-host "              ``;'';'''''                                                                            " -foregroundcolor "red" –backgroundcolor "white"
	write-host "             ;';'''''''';.                                                                          " -foregroundcolor "red" –backgroundcolor "white"
	write-host "            '''',     ;''':                                                                         " -foregroundcolor "red" –backgroundcolor "white"
	write-host "           ;';'         '''                                                                         " -foregroundcolor "red" –backgroundcolor "white"
	write-host "           '''           '';                   #'                                       ''          " -foregroundcolor "red" –backgroundcolor "white"
	write-host "          '''          ;',;'``                  #'                                       ''          " -foregroundcolor "red" –backgroundcolor "white"
	write-host "          '''         ';'``;;'       ,####  ##  ###   ####;   +###'  ####+   ###  ####+  ``           " -foregroundcolor "red" –backgroundcolor "white"
	write-host "          ''.         ,''''''       #;     ##  #'   ##  ``#  +#     ##   #; .#   ##   #:             " -foregroundcolor "red" –backgroundcolor "white"
	write-host "          ';          . '';''       ##``    ##  #'   #``   #+ #+    ``#    ## ,#   #'   ##             " -foregroundcolor "red" –backgroundcolor "white"
	write-host "          ''          ;.'''''        '##``  ##  #'   ####### #:    :#    ## ,#   #######             " -foregroundcolor "red" –backgroundcolor "white"
	write-host "          '',         :';;'''          ;#`` ##  #'   #``      #+    .#    ## ,#   #'                  " -foregroundcolor "red" –backgroundcolor "white"
	write-host "          '''        ;: `` '':           #' ##  ##   ##      ##     #'   #+ ,#   ##                  " -foregroundcolor "red" –backgroundcolor "white"
	write-host "          :''``     ;``;``';;''        #####  ##  ;###  #####   ##### ``#####  ,#    #####              " -foregroundcolor "red" –backgroundcolor "white"
	write-host "           ''; ,.::', ';,';'          .                ````      .``     .            ````               " -foregroundcolor "red" –backgroundcolor "white"
	write-host "           .'';``:';'''.:'''                                                                         " -foregroundcolor "red" –backgroundcolor "white"
	write-host "            :'''',   :''''                                                                          " -foregroundcolor "red" –backgroundcolor "white"
	write-host "             .';';'''''''                                                                           " -foregroundcolor "red" –backgroundcolor "white"
	write-host "               :'''''''``                                                                            " -foregroundcolor "red" –backgroundcolor "white"

	if(($modules -eq $null) -or ($modules.Count -eq 0))
	{
		$modules =	"Sitecore.Analytics", `
					"Sitecore.Buckets", `
					"Sitecore.CES", `
					"Sitecore.Cintel", `
					"Sitecore.Cloud", `
					"Sitecore.Commerce", `
					"Sitecore.ContentSearch", `
					"Sitecore.ContentTesting", `
					"Sitecore.ExperienceAnalytics", `
					"Sitecore.ExperienceEditor", `
					"Sitecore.FXM", `
					"Sitecore.ListManagement", `
					"Sitecore.Marketing", `
					"Sitecore.Mvc", `
					"Sitecore.PathAnalyzer", `
					"Sitecore.Services", `
					"Sitecore.SessionProvider", `
					"Sitecore.Social", `
					"Sitecore.Speak", `
					"Sitecore.Xdb"
	}

	if(($thirdpartycomponents -eq $null) -or ($thirdpartycomponents.PackageInfos.Count -eq 0))
	{
		$thirdpartycomponents = Add-ModulesThirdPartyPackages
	}

	Get-ChildItem $sitecoreRepositoryFolder -Filter "*.zip" | % {
		$sitecorezipFileNameOnly = $_.Name
		$FileNameNoExtension = [io.path]::GetFileNameWithoutExtension($sitecorezipFileNameOnly)
		$archivePath = "$sitecoreRepositoryFolder$sitecorezipFileNameOnly"
		$targetDirectory = "$sitecoreRepositoryFolder$FileNameNoExtension\bin\"
		$nuspecDirectory = "$sitecoreRepositoryFolder$FileNameNoExtension\nuspec\"
		$packageDirectory = "$sitecoreRepositoryFolder$FileNameNoExtension\nupack\"
		$SitecoreVersion = $FileNameNoExtension.ToLower().Replace("sitecore ", "").Replace(" rev. ",".").Replace("rev. ",".").Replace(" rev.",".").Replace(".zip","").Trim()
		$frameworVersion = "NET45"

		UnZipDLLFiles -installPath $root `
		  -ArchivePath $archivePath `
		  -TargetPath $targetDirectory `
		  -nugetFullPath $nugetExecutable `
		  -NugetFeed $NugetFeed `
		  -Filter "*\package.zip\files\bin\*.dll"
	
	}

}