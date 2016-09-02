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
  [Parameter(Mandatory=$false)][Array]$platformModules,
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

	if(($platformModules -eq $null) -or ($platformModules.Count -eq 0))
	{
		$platformModules = "Sitecore.Analytics", `
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

	#if(($thirdpartycomponents -eq $null) -or ($thirdpartycomponents.PackageInfos.Count -eq 0))
	#{
	#	$thirdpartycomponents = Add-PlatformThirdPartyPackages
	#}

	Get-ChildItem $sitecoreRepositoryFolder -Filter "*.zip" | % {
	
	}

}