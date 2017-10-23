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

Function CreateModulePackage(
	[Parameter(Mandatory=$true)][string]$readDirectory,
	[Parameter(Mandatory=$true)][string]$nuspecDirectory,
	[Parameter(Mandatory=$true)][string]$packageDirectory,
	[Parameter(Mandatory=$true)][string]$ModuleVersion,
	[Parameter(Mandatory=$true)][string]$ModuleName,
	[Parameter(Mandatory=$false)][bool]$resolveDependencies = $true,
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$true)][string]$frameworkVersion,
	[Parameter(Mandatory=$false)][bool]$uploadPackages = $false,
	[Parameter(Mandatory=$true)][string]$uploadFeed,
	[Parameter(Mandatory=$true)][string]$uploadAPIKey,
	[Parameter(Mandatory=$false)][bool]$createFileVersionPackages = $false
)
{
	$frameWorkVersionLong = Get-FrameworkVersion -frameworkVersion $frameworkVersion  

	$moduleDependencies = @()
	$excludeArray = @()
	$excludeArray += "Sitecore.*.dll.*.nupkg"
	$excludeArray += "Sitecore.*.NoReferences.*.nupkg"
	$excludeArray += "Sitecore.*.NoReferences"

	Get-ChildItem $packageDirectory -recurse -exclude $excludeArray| % {
		if (!$_.Name.Contains(".NoReferences"))
		{
			$moduleObject ='' | select ModuleName, ModuleVersion
			$moduleObject.ModuleName = [string]$_.Name.Replace(".$ModuleVersion.nupkg", "")
			$moduleObject.ModuleVersion = $ModuleVersion
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
				-moduleName $ModuleName `
				-Version $ModuleVersion `
				-title $ModuleName `
				-description $ModuleName `
				-summary $ModuleName `
				-nuspecDirectory $nuspecDirectory `
				-packageDirectory $packageDirectory `
				-moduleDependencies $moduleDependencies `
				-uploadPackages $uploadPackages `
				-uploadFeed $uploadFeed `
				-uploadAPIKey $uploadAPIKey
		}
	}
}

Function CreateModuleNuGetPackages(
	[Parameter(Mandatory=$true)][string]$readDirectory,
	[Parameter(Mandatory=$true)][string]$nuspecDirectory,
	[Parameter(Mandatory=$true)][string]$packageDirectory,
	[Parameter(Mandatory=$true)][string]$moduleVersion,
	[Parameter(Mandatory=$true)][string]$moduleName,
	[Parameter(Mandatory=$false)][bool]$resolveDependencies = $true,
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$true)][string]$frameworkVersion,
	[Parameter(Mandatory=$false)][bool]$uploadPackages = $false,
	[Parameter(Mandatory=$true)][string]$uploadFeed,
	[Parameter(Mandatory=$true)][string]$uploadAPIKey,
	[Parameter(Mandatory=$false)][bool]$createFileVersionPackages = $false,
	[Parameter(Mandatory=$true)][NupackBuilder.Packages]$thirdpartycomponents,
	[Parameter(Mandatory=$false)][bool]$addThirdPartyReferences = $true,
	[Parameter(Mandatory=$true)][NupackBuilder.ModulePlatformSupportInfo]$modulePlatformSupportInfo
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

	$excluded = @("zxing.dll", "MSCaptcha.dll", "AjaxMin.dll", "ChilkatDotNet2.x32", "ChilkatDotNet2.x32", "ChilkatDotNet2.dll", "Heijden.Dns.dll", "Microsoft.Crm.Sdk.Proxy.dll", "Microsoft.Xrm.Client.dll", "Microsoft.Xrm.Sdk.Deployment.dll", "Microsoft.Xrm.Sdk.dll", "Sitecore.ExperienceEditor.dll", "Microsoft.IdentityModel.dll", "Microsoft.Practices.Unity.dll")

	Get-ChildItem -Path "$readDirectory*" -Recurse -Force -Filter "*.dll" -Exclude $excluded | % {
			CreateAssembliesNuspecFile  -fileName $_.FullName `
							  -readDirectory $readDirectory `
							  -nuspecDirectory $nuspecDirectory `
							  -SitecoreVersion $ModuleVersion `
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
							  -addThirdPartyReferences $addThirdPartyReferences `
							  -isSitecoreModule $true `
							  -modulePlatformSupportInfo $modulePlatformSupportInfo
			
			CreateAssembliesNuspecFile  -fileName $_.FullName `
							  -readDirectory $readDirectory `
							  -nuspecDirectory $nuspecDirectory `
							  -SitecoreVersion $ModuleVersion `
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
							  -addThirdPartyReferences $addThirdPartyReferences `
							  -isSitecoreModule $true `
							  -modulePlatformSupportInfo $modulePlatformSupportInfo
	}
}

Function CreateModulePackages(
  [Parameter(Mandatory=$false)][string]$NugetFeed = "https://www.nuget.org/api/v2/",
  [Parameter(Mandatory=$true)][string]$sitecoreRepositoryFolder,
  [Parameter(Mandatory=$true)][bool]$uploadPackages,
  [Parameter(Mandatory=$true)][string]$uploadFeed,
  [Parameter(Mandatory=$true)][string]$uploadAPIKey,
  [Parameter(Mandatory=$false)][Array]$modules,
  [Parameter(Mandatory=$false)][NupackBuilder.Packages]$thirdpartycomponents,
  [Parameter(Mandatory=$false)][NupackBuilder.Modules]$sitecoreModulesInformation,
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

	if(($thirdpartycomponents -eq $null) -or ($thirdpartycomponents.PackageInfos.Count -eq 0))
	{
		$thirdpartycomponents = Add-ModulesThirdPartyPackages
	}
	
	if(($sitecoreModulesInformation -eq $null) -or ($sitecoreModulesInformation.ModulePlatformSupportInfos.Count -eq 0))
	{
		$sitecoreModulesInformation = Add-ModulePlatformSupportInfo
	}

	Get-ChildItem $sitecoreRepositoryFolder -Filter "*.zip" | % {
		$sitecorezipFileNameOnly = $_.Name
		$FileNameNoExtension = [io.path]::GetFileNameWithoutExtension($sitecorezipFileNameOnly)

		$moduleInfo = $null;
		$moduleInfo = $sitecoreModulesInformation.FindModulePlatformVersionsByFullName($FileNameNoExtension)
	
		if($moduleInfo -ne $null)
		{	
			$archivePath = "$sitecoreRepositoryFolder$sitecorezipFileNameOnly"
			$targetDirectory = "$sitecoreRepositoryFolder$FileNameNoExtension\bin\"
			$nuspecDirectory = "$sitecoreRepositoryFolder$FileNameNoExtension\nuspec\"
			$packageDirectory = "$sitecoreRepositoryFolder$FileNameNoExtension\nupack\"
			$ModuleName = $moduleInfo.ModuleName
			$ModuleVersion = $moduleInfo.ModuleVersion
			$frameworVersion = "NET45"

			#Write-Host "ModuleName : $ModuleName" -ForegroundColor Red
			#Write-Host "ModuleVersion : $ModuleVersion" -ForegroundColor Red

			UnZipDLLFiles -installPath $root `
			  -ArchivePath $archivePath `
			  -TargetPath $targetDirectory `
			  -nugetFullPath $nugetExecutable `
			  -NugetFeed $NugetFeed `
			  -Filter "package.zip" `
			  -SuppressOutput

			$packageZipFile = $targetDirectory + 'package.zip'
			if (Test-Path -Path $packageZipFile)
			{
				UnZipDLLFiles -installPath $root `
				  -ArchivePath $packageZipFile `
				  -TargetPath $targetDirectory `
				  -nugetFullPath $nugetExecutable `
				  -NugetFeed $NugetFeed `
				  -Filter "files\bin\*.dll" `
				  -SuppressOutput `
				  -doNotDeleteTargetPath

				Remove-Item $packageZipFile -Force | Out-Null

			}
			else
			{
				#no package.zip inside the zip file but still a Sitecore package
				UnZipDLLFiles -installPath $root `
				  -ArchivePath $archivePath `
				  -TargetPath $targetDirectory `
				  -nugetFullPath $nugetExecutable `
				  -NugetFeed $NugetFeed `
				  -Filter "files\bin\*.dll" `
				  -SuppressOutput

				$dlls = $null
				$dllCount = 0
				$dlls = Get-ChildItem $targetDirectory -Filter "*.dll"
				$dllCount = (Get-ChildItem $targetDirectory -Filter "*.dll" | measure).Count
				
				if(($dlls -eq $null) -or ($dllCount -eq 0))
				{
					#no package.zip inside the zip file and not a Sitecore package but have bin folder
					UnZipDLLFiles -installPath $root `
					  -ArchivePath $archivePath `
					  -TargetPath $targetDirectory `
					  -nugetFullPath $nugetExecutable `
					  -NugetFeed $NugetFeed `
					  -Filter "bin\*.dll" `
					  -SuppressOutput
				}

				$dlls = $null
				$dllCount = 0
				$dlls = Get-ChildItem $targetDirectory -Filter "*.dll"
				$dllCount = (Get-ChildItem $targetDirectory -Filter "*.dll" | measure).Count
				
				if(($dlls -eq $null) -or ($dllCount -eq 0))
				{
					#no package.zip inside the zip file and not a Sitecore package but does not have bin folder
					UnZipDLLFiles -installPath $root `
					  -ArchivePath $archivePath `
					  -TargetPath $targetDirectory `
					  -nugetFullPath $nugetExecutable `
					  -NugetFeed $NugetFeed `
					  -Filter "*.dll" `
					  -SuppressOutput
				}

				$dlls = $null
				$dllCount = 0
				$dlls = Get-ChildItem $targetDirectory -Filter "*.dll"
				$dllCount = (Get-ChildItem $targetDirectory -Filter "*.dll" | measure).Count
				
				if(($dlls -eq $null) -or ($dllCount -eq 0))
				{
					#Somebody decided to deploy a sitecore package packed inside a zip packed inside a zip packed inside a zip.... DOH!
					UnZipDLLFiles -installPath $root `
					  -ArchivePath $archivePath `
					  -TargetPath $targetDirectory `
					  -nugetFullPath $nugetExecutable `
					  -NugetFeed $NugetFeed `
					  -Filter "*.zip" `
					  -SuppressOutput `
					  -doNotDeleteTargetPath

					Get-ChildItem $targetDirectory -Filter "*.zip" | % {
						$subsitecorezipFileNameOnly = $_.Name
						$subarchivePath = "$targetDirectory$subsitecorezipFileNameOnly"

						UnZipDLLFiles -installPath $root `
						  -ArchivePath $subarchivePath `
						  -TargetPath $targetDirectory `
						  -nugetFullPath $nugetExecutable `
						  -NugetFeed $NugetFeed `
						  -Filter "package.zip" `
						  -SuppressOutput `
						  -doNotDeleteTargetPath

						$packageZipFile = $targetDirectory + 'package.zip'
						if (Test-Path -Path $packageZipFile)
						{
							UnZipDLLFiles -installPath $root `
							  -ArchivePath $packageZipFile `
							  -TargetPath $targetDirectory `
							  -nugetFullPath $nugetExecutable `
							  -NugetFeed $NugetFeed `
							  -Filter "files\bin\*.dll" `
							  -SuppressOutput `
							  -doNotDeleteTargetPath
							
							  Remove-Item $packageZipFile -Force | Out-Null
						}
						
						#else
						#{
							#no package.zip inside the zip file and not a Sitecore package but have bin folder
						#	UnZipDLLFiles -installPath $root `
						#	  -ArchivePath $subarchivePath `
						#	  -TargetPath $targetDirectory `
						#	  -nugetFullPath $nugetExecutable `
						#	  -NugetFeed $NugetFeed `
						#	  -Filter "bin\*.dll" `
						#	  -SuppressOutput `
						#	  -doNotDeleteTargetPath
						#}

						Remove-Item $subarchivePath -Force | Out-Null
					}
				}
			}

			$dlls = $null
			$dllCount = 0
			$excluded = @("zxing.dll", "MSCaptcha.dll", "AjaxMin.dll", "ChilkatDotNet2.x32", "ChilkatDotNet2.x32", "ChilkatDotNet2.dll", "Heijden.Dns.dll", "Microsoft.Crm.Sdk.Proxy.dll", "Microsoft.Xrm.Client.dll", "Microsoft.Xrm.Sdk.Deployment.dll", "Microsoft.Xrm.Sdk.dll", "Sitecore.ExperienceEditor.dll", "Sitecore.Integration.Common.dll", "Microsoft.IdentityModel.dll", "Microsoft.Practices.Unity.dll")
			$dll = Get-ChildItem -Path "$targetDirectory*" -Filter "*.dll" -Exclude $excluded | Select-Object -First 1
			$dllCount = (Get-ChildItem $targetDirectory -Filter "*.dll" | measure).Count
				
			if(($dll -ne $null) -or ($dllCount -gt 0))
			{
				# There are binaries
				$original = $null
				$bytes = $null
				$loaded = $null
				$customAttributes = $null
				$targetFramework = $null
				$frameworkDisplayNameArg = $null

				$original = [io.path]::GetFileName($dll.FullName)
				$bytes   = [System.IO.File]::ReadAllBytes($dll.FullName)
				$loaded  = [System.Reflection.Assembly]::Load($bytes)

				$customAttributes = $loaded.GetCustomAttributesData()
				if($customAttributes -ne $null)
				{
					$targetFramework = $customAttributes | Where-Object {$_.AttributeType -like "System.Runtime.Versioning.TargetFrameworkAttribute"} | Select-Object -First 1

					if($targetFramework -ne $null)
					{
						$frameworkName = [String]$targetFramework.ConstructorArguments[0].Value;
						$frameworkDisplayNameArg = $targetFramework.NamedArguments | Where-Object {$_.MemberName -like "FrameworkDisplayName" }| Select-Object -First 1
						if($frameworkDisplayNameArg -ne $null)
						{
							$frameworkDisplayName = [String]$frameworkDisplayNameArg.TypedValue.Value;
				
							switch ($frameworkName)
							{
								".NETFramework,Version=v4.5" {
										$frameworVersion = "NET45"
										$createFileVersionPackages = $false
									  }	
								".NETFramework,Version=v4.5.2" {
										$frameworVersion = "NET452"
										$createFileVersionPackages = $false
									  }					
                                ".NETFramework,Version=v4.6.2" {
										$frameworVersion = "NET462"
										$createFileVersionPackages = $false
									  }	
								default {
										$frameworVersion = "NET45"
										$createFileVersionPackages = $false
									  }
							}
						}
					}
				}

				#Write-Host $frameworVersion -ForegroundColor Yellow

				# Create packages here
				CreateModuleNuGetPackages -readDirectory $targetDirectory `
					-nuspecDirectory $nuspecDirectory `
					-packageDirectory $packageDirectory `
					-ModuleVersion $moduleVersion `
					-ModuleName $moduleName `
					-resolveDependencies $true `
					-nugetFullPath $nugetExecutable `
					-frameworkVersion $frameworVersion `
					-uploadPackages $uploadPackages `
					-uploadFeed $uploadFeed `
					-uploadAPIKey $uploadAPIKey `
					-createFileVersionPackages $createFileVersionPackages `
					-thirdpartycomponents $thirdpartycomponents `
					-addThirdPartyReferences $addThirdPartyReferences `
					-modulePlatformSupportInfo $moduleInfo

				CreateModulePackage -readDirectory $targetDirectory `
					-nuspecDirectory $nuspecDirectory `
					-packageDirectory $packageDirectory `
					-ModuleVersion $ModuleVersion `
					-ModuleName $ModuleName `
					-resolveDependencies $true `
					-nugetFullPath $nugetExecutable `
					-frameworkVersion $frameworVersion `
					-uploadPackages $uploadPackages `
					-uploadFeed $uploadFeed `
					-uploadAPIKey $uploadAPIKey `
					-createFileVersionPackages $createFileVersionPackages
				
				$frameworkDisplayNameArg = $null
				$targetFramework = $null
				$customAttributes = $null
				$loaded = $null
				$bytes = $null
				$original = $null
				
			}
			
		}
	
	}

}