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

Function CreatePlatformPackage(
	[Parameter(Mandatory=$true)][string]$readDirectory,
	[Parameter(Mandatory=$true)][string]$nuspecDirectory,
	[Parameter(Mandatory=$true)][string]$packageDirectory,
	[Parameter(Mandatory=$true)][string]$SitecoreVersion,
	[Parameter(Mandatory=$false)][bool]$resolveDependencies = $true,
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$true)][string]$frameworkVersion,
	[Parameter(Mandatory=$false)][bool]$uploadPackages = $false,
	[Parameter(Mandatory=$true)][string]$uploadFeed,
	[Parameter(Mandatory=$true)][string]$uploadAPIKey,
	[Parameter(Mandatory=$false)][bool]$createFileVersionPackages = $false,
	[Parameter(Mandatory=$false)][Array]$platformModules
)
{
	$frameWorkVersionLong = ".NETFramework4.5"
	switch ($frameworkVersion)
	{
		"NET45" {$frameWorkVersionLong = ".NETFramework4.5"}
		"NET451" {$frameWorkVersionLong = ".NETFramework4.5.1"}
		"NET452" {$frameWorkVersionLong = ".NETFramework4.5.2"}
		"NET46" {$frameWorkVersionLong = ".NETFramework4.6"}
		"NET461" {$frameWorkVersionLong = ".NETFramework4.6.1"}
		default {$frameWorkVersionLong = ".NETFramework4.5"}
	}  

	$moduleDependencies = @()

	foreach($platformModule in $platformModules)
	{        
		Get-ChildItem $packageDirectory -Recurse -Force -Filter "$platformModule*.Component.$SitecoreVersion.nupkg" | % {
			
			$moduleObject ='' | select ModuleName, ModuleVersion
			$moduleObject.ModuleName = [string]$_.Name.Replace(".$SitecoreVersion.nupkg", "")
			$moduleObject.ModuleVersion = $SitecoreVersion
			$moduleDependencies += $moduleObject
		}        
	}

	$excludeArray = @()
	foreach($platformModule in $platformModules)
	{
		$excludeArray += "$platformModule.*"
	}

	$excludeArray += "Sitecore.*.dll.*.nupkg"
	$excludeArray += "Sitecore.*.NoReferences.*.nupkg"
	$excludeArray += "Sitecore.*.NoReferences"

	Get-ChildItem $packageDirectory -recurse -exclude $excludeArray| % {
		if (!$_.Name.Contains(".NoReferences"))
		{
			$moduleObject ='' | select ModuleName, ModuleVersion
			$moduleObject.ModuleName = [string]$_.Name.Replace(".$SitecoreVersion.nupkg", "")
			$moduleObject.ModuleVersion = $SitecoreVersion
			$moduleDependencies += $moduleObject
		}
	}

	if($moduleDependencies -ne $null) 
	{
		if (($moduleDependencies.Count -gt 0))
		{
			CreateMetaPackage `
				-nugetFullPath $nugetFullPath `
				-frameworkVersion $frameworkVersion `
				-frameWorkVersionLong $frameWorkVersionLong `
				-moduleName "Sitecore" `
				-Version $SitecoreVersion `
				-title "Sitecore" `
				-description "Sitecore" `
				-summary "Sitecore" `
				-nuspecDirectory $nuspecDirectory `
				-packageDirectory $packageDirectory `
				-moduleDependencies $moduleDependencies `
				-uploadPackages $uploadPackages `
				-uploadFeed $uploadFeed `
				-uploadAPIKey $uploadAPIKey
		}
	}
}

Function CreatePlatformModulePackages(
	[Parameter(Mandatory=$true)][string]$readDirectory,
	[Parameter(Mandatory=$true)][string]$nuspecDirectory,
	[Parameter(Mandatory=$true)][string]$packageDirectory,
	[Parameter(Mandatory=$true)][string]$SitecoreVersion,
	[Parameter(Mandatory=$false)][bool]$resolveDependencies = $true,
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$true)][string]$frameworkVersion,
	[Parameter(Mandatory=$false)][bool]$uploadPackages = $false,
	[Parameter(Mandatory=$true)][string]$uploadFeed,
	[Parameter(Mandatory=$true)][string]$uploadAPIKey,
	[Parameter(Mandatory=$false)][bool]$createFileVersionPackages = $false,
	[Parameter(Mandatory=$false)][Array]$platformModules
)
{
	# $packages=Get-ChildItem $packageDirectory -Recurse -Force   
	
	$frameWorkVersionLong = ".NETFramework4.5"
	switch ($frameworkVersion)
	{
		"NET45" {$frameWorkVersionLong = ".NETFramework4.5"}
		"NET451" {$frameWorkVersionLong = ".NETFramework4.5.1"}
		"NET452" {$frameWorkVersionLong = ".NETFramework4.5.2"}
		"NET46" {$frameWorkVersionLong = ".NETFramework4.6"}
		"NET461" {$frameWorkVersionLong = ".NETFramework4.6.1"}
		default {$frameWorkVersionLong = ".NETFramework4.5"}
	}  

	foreach($platformModule in $platformModules)
	{
		$moduleDependencies = @()
		Get-ChildItem $packageDirectory -Recurse -Force -Filter "$platformModule*.$SitecoreVersion.nupkg" | % {
			if(!$_.Name.Contains(".NoReferences"))
			{
				$moduleObject ='' | select ModuleName, ModuleVersion
				$moduleObject.ModuleName = [string]$_.Name.Replace(".$SitecoreVersion.nupkg", "")
				$moduleObject.ModuleVersion = $SitecoreVersion
				$moduleDependencies += $moduleObject
			}
		}

		if($moduleDependencies -ne $null) 
		{
			if (($moduleDependencies.Count -gt 0))
			{
				CreateMetaPackage `
					-nugetFullPath $nugetFullPath `
					-frameworkVersion $frameworkVersion `
					-frameWorkVersionLong $frameWorkVersionLong `
					-moduleName "$platformModule.Component" `
					-Version $SitecoreVersion `
					-title "$platformModule.Component" `
					-description "$platformModule.Component" `
					-summary "$platformModule.Component" `
					-nuspecDirectory $nuspecDirectory `
					-packageDirectory $packageDirectory `
					-moduleDependencies $moduleDependencies `
					-uploadPackages $uploadPackages `
					-uploadFeed $uploadFeed `
					-uploadAPIKey $uploadAPIKey
			}
		}
	}
}

Function CreatePlatformNuGetPackages(
	[Parameter(Mandatory=$true)][string]$readDirectory,
	[Parameter(Mandatory=$true)][string]$nuspecDirectory,
	[Parameter(Mandatory=$true)][string]$packageDirectory,
	[Parameter(Mandatory=$true)][string]$SitecoreVersion,
	[Parameter(Mandatory=$false)][bool]$resolveDependencies = $true,
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$true)][string]$frameworkVersion,
	[Parameter(Mandatory=$false)][bool]$uploadPackages = $false,
	[Parameter(Mandatory=$true)][string]$uploadFeed,
	[Parameter(Mandatory=$true)][string]$uploadAPIKey,
	[Parameter(Mandatory=$false)][bool]$createFileVersionPackages = $false,
	[Parameter(Mandatory=$true)][NupackBuilder.Packages]$thirdpartycomponents,
	[Parameter(Mandatory=$false)][bool]$addThirdPartyReferences = $true
)
{
	if((Test-Path -Path $packageDirectory ))
	{
		$child_items = ([array] (Get-ChildItem -Path $packageDirectory -Recurse -Force))
		if ($child_items) {
			$null = $child_items | Remove-Item -Force -Recurse | Out-Null
		}
		$null = Remove-Item $packageDirectory -Force | Out-Null
	}

	if((Test-Path -Path $nuspecDirectory ))
	{
		$child_items = ([array] (Get-ChildItem -Path $nuspecDirectory -Recurse -Force))
		if ($child_items) {
			$null = $child_items | Remove-Item -Force -Recurse | Out-Null
		}
		$null = Remove-Item $nuspecDirectory -Force | Out-Null
	}

	if (!(Test-Path -Path $nuspecDirectory))
	{
		New-Item $nuspecDirectory -type directory | Out-Null
	}

	if (!(Test-Path -Path $packageDirectory))
	{
		New-Item $packageDirectory -type directory | Out-Null
	}

	$assemblies=Get-ChildItem $readDirectory -Recurse -Force |
	ForEach-Object {
		try {
			$_ | Add-Member NoteProperty FileVersion ($_.VersionInfo.FileVersion)
			$_ | Add-Member NoteProperty AssemblyVersion ([Reflection.AssemblyName]::GetAssemblyName($_.FullName).Version)
		} catch {}
		$_
	} 
	
	Get-ChildItem $readDirectory -Recurse -Force -Filter "sitecore.*" | % {
			CreateAssembliesNuspecFile  -fileName $_.FullName `
							  -readDirectory $readDirectory `
							  -nuspecDirectory $nuspecDirectory `
							  -SitecoreVersion $SitecoreVersion `
							  -resolveDependencies $resolveDependencies `
							  -packageDirectory $packageDirectory `
							  -nugetFullPath $nugetFullPath `
							  -frameworkVersion $frameworkVersion `
							  -uploadPackages $uploadPackages `
							  -uploadFeed $uploadFeed `
							  -uploadAPIKey $uploadAPIKey `
							  -createFileVersionPackages $createFileVersionPackages `
							  -assemblies $assemblies `
							  -thirdpartycomponents $thirdpartycomponents `
							  -addThirdPartyReferences $addThirdPartyReferences

			CreateAssembliesNuspecFile  -fileName $_.FullName `
							  -readDirectory $readDirectory `
							  -nuspecDirectory $nuspecDirectory `
							  -SitecoreVersion $SitecoreVersion `
							  -resolveDependencies $false `
							  -packageDirectory $packageDirectory `
							  -nugetFullPath $nugetFullPath `
							  -frameworkVersion $frameworkVersion `
							  -uploadPackages $uploadPackages `
							  -uploadFeed $uploadFeed `
							  -uploadAPIKey $uploadAPIKey `
							  -createFileVersionPackages $createFileVersionPackages `
							  -assemblies $assemblies `
							  -thirdpartycomponents $thirdpartycomponents `
							  -addThirdPartyReferences $addThirdPartyReferences
	}
}

Function CreatePlatformPackages(
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

	if(($thirdpartycomponents -eq $null) -or ($thirdpartycomponents.PackageInfos.Count -eq 0))
	{
		$thirdpartycomponents = Add-ThirdPartyPackages
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "Newtonsoft.Json" -AssemblyNames @("Newtonsoft.Json.dll") -Versions @("4.5.9", "6.0.8")
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "Lucene.Net" -AssemblyNames @("Lucene.Net.dll") -Versions @("3.0.3")
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "Lucene.Net.Contrib" -AssemblyNames @("Lucene.Net.Contrib.Analyzers.dll", "Lucene.Net.Contrib.Core.dll", "Lucene.Net.Contrib.FastVectorHighlighter.dll", "Lucene.Net.Contrib.Highlighter.dll", "Lucene.Net.Contrib.Memory.dll", "Lucene.Net.Contrib.Queries.dll", "Lucene.Net.Contrib.Regex.dll", "Lucene.Net.Contrib.SimpleFacetedSearch.dll", "Lucene.Net.Contrib.Snowball.dll", "Lucene.Net.Contrib.SpellChecker.dll") -Versions @("3.0.3")
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "HtmlAgilityPack" -AssemblyNames @("HtmlAgilityPack.dll") -Versions @("1.4.6")
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "YUICompressor.NET" -AssemblyNames @("Yahoo.Yui.Compressor.dll") -Versions @("2.1.1")
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "mongocsharpdriver" -AssemblyNames @("MongoDB.Driver.dll", "MongoDB.Bson.dll") -Versions @("1.10.0")
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "SolrNet" -AssemblyNames @("SolrNet.dll") -Versions @("0.4.0.4001")
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "RazorGenerator.Mvc" -AssemblyNames @("RazorGenerator.Mvc.dll") -Versions @("2.4.2")
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "protobuf-net" -AssemblyNames @("protobuf-net.dll") -Versions @("2.0.0.668")
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "Ninject" -AssemblyNames @("Ninject.dll") -Versions @("3.2.2")
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "WebActivatorEx" -AssemblyNames @("WebActivatorEx.dll") -Versions @("2.0.6")
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "Markdown" -AssemblyNames @("MarkdownSharp.dll") -Versions @("1.14.6")
		#$thirdpartycomponents += Add-ThirdPartyComponent -PackageName "Facebook" -AssemblyNames @("Facebook.dll") -Versions @("5.4.1")
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

		if($SitecoreVersion.StartsWith("6"))
		{
			Write-Log -Message "We don't support Sitecore versions prior to 7.0 - yet" -Program "Powershell" -Level "warn"
			return
		}

		switch ($SitecoreVersion.Remove($SitecoreVersion.LastIndexOf(".")))
		{
			"7.0" {
					$frameworVersion = "NET45"
					$createFileVersionPackages = $false
				  }
			"7.1" {
					$frameworVersion = "NET45"
					$createFileVersionPackages = $false
				  }
			"7.2" {
					$frameworVersion = "NET45"
					$createFileVersionPackages = $false
				  }
			"7.5" {
					$frameworVersion = "NET45"
					$createFileVersionPackages = $false
				  }
			"8.0" {
					$frameworVersion = "NET45"
					$createFileVersionPackages = $false
				  }
			"8.1" {
					$frameworVersion = "NET45"
					$createFileVersionPackages = $false
				  }
			"8.2" {
					$frameworVersion = "NET452"
					$createFileVersionPackages = $false
				  } 
			default {
					$frameworVersion = "NET452"
					$createFileVersionPackages = $false
				  }

		}

		UnZipDLLFiles -installPath $root `
		  -ArchivePath $archivePath `
		  -TargetPath $targetDirectory `
		  -nugetFullPath $nugetExecutable `
		  -NugetFeed $NugetFeed `
		  -SuppressOutput `
		  -Filter "*\Website\bin\*.dll"

		CreatePlatformNuGetPackages -readDirectory $targetDirectory `
			-nuspecDirectory $nuspecDirectory `
			-packageDirectory $packageDirectory `
			-SitecoreVersion $SitecoreVersion `
			-resolveDependencies $true `
			-nugetFullPath $nugetExecutable `
			-frameworkVersion $frameworVersion `
			-uploadPackages $uploadPackages `
			-uploadFeed $uploadFeed `
			-uploadAPIKey $uploadAPIKey `
			-createFileVersionPackages $createFileVersionPackages `
			-thirdpartycomponents $thirdpartycomponents `
			-addThirdPartyReferences $addThirdPartyReferences

		CreatePlatformModulePackages -readDirectory $targetDirectory `
			-nuspecDirectory $nuspecDirectory `
			-packageDirectory $packageDirectory `
			-SitecoreVersion $SitecoreVersion `
			-resolveDependencies $true `
			-nugetFullPath $nugetExecutable `
			-frameworkVersion $frameworVersion `
			-uploadPackages $uploadPackages `
			-uploadFeed $uploadFeed `
			-uploadAPIKey $uploadAPIKey `
			-createFileVersionPackages $createFileVersionPackages `
			-platformModules $platformModules

		CreatePlatformPackage -readDirectory $targetDirectory `
			-nuspecDirectory $nuspecDirectory `
			-packageDirectory $packageDirectory `
			-SitecoreVersion $SitecoreVersion `
			-resolveDependencies $true `
			-nugetFullPath $nugetExecutable `
			-frameworkVersion $frameworVersion `
			-uploadPackages $uploadPackages `
			-uploadFeed $uploadFeed `
			-uploadAPIKey $uploadAPIKey `
			-createFileVersionPackages $createFileVersionPackages `
			-platformModules $platformModules
	}
}