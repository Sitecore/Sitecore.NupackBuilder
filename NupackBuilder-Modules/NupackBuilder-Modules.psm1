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

			Write-Host "ModuleName : $ModuleName" -ForegroundColor Red
			Write-Host "ModuleVersion : $ModuleVersion" -ForegroundColor Red

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
			$excluded = @("MSCaptcha.dll", "AjaxMin.dll")
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
								default {
										$frameworVersion = "NET45"
										$createFileVersionPackages = $false
									  }
							}
						}
					}
				}

				Write-Host $frameworVersion -ForegroundColor Yellow

				# Create packages here
				
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