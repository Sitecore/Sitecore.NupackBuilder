$currentPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$NugetModuleRoot = Split-Path -Parent $currentPath

$CommonModule = Get-Module -Name NupackBuilder-Common
if ($CommonModule -eq $null)
{	
	Import-Module $NugetModuleRoot\NupackBuilder-Common -DisableNameChecking
}

Function ListAllPackages(
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$true)][string]$feed
)
{
	$listargs = ' list -Source "'+$feed+'" -AllVersions -Prerelease 2>&1'
	$listcommand = "& '$nugetFullPath'" + $listargs
	$returnValue = iex $listcommand

	if($returnValue.GetType() -ne [System.Object[]])
	{
		return @()
	}
	else
	{
		return $returnValue
	}
}

Function UploadNugetPackage(
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$true)][string]$packageFileName,
	[Parameter(Mandatory=$true)][string]$uploadFeed,
	[Parameter(Mandatory=$true)][string]$uploadAPIKey,
	[Parameter(Mandatory=$false)][string]$verbosity = "normal"

)
{
	switch ($verbosity)
	{
		"normal" {$verbosityValue = "normal"}
		"quiet" {$verbosityValue = "quiet"}
		"detailed" {$verbosityValue = "detailed"}
		default {$verbosityValue = "quiet"}
	} 

	$pushargs = ' push "' + $packageFileName + '" -ApiKey "'+$uploadAPIKey+'" -Source "'+$uploadFeed+'" -Timeout 600 -NonInteractive -Verbosity ' + $verbosityValue
	$pushcommand = "& '$nugetFullPath'" + $pushargs
	iex $pushcommand    
}

Function DeletePackageFromFeed(
	[Parameter(Mandatory=$true)][string]$moduleName,
	[Parameter(Mandatory=$true)][string]$moduleVersion,
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$true)][string]$feed,
	[Parameter(Mandatory=$true)][string]$APIKey,
	[Parameter(Mandatory=$false)][string]$verbosity = "normal"
)
{
	switch ($verbosity)
	{
		"normal" {$verbosityValue = "normal"}
		"quiet" {$verbosityValue = "quiet"}
		"detailed" {$verbosityValue = "detailed"}
		default {$verbosityValue = "quiet"}
	}
	$deleteargs = ' delete ' + $moduleName + ' ' + $moduleVersion + ' -ApiKey "'+$APIKey+'" -Source "'+$feed+'" -NonInteractive -Verbosity ' + $verbosityValue
	$deletecommand = "& '$nugetFullPath'" + $deleteargs
	iex $deletecommand
}

Function PackNuspecFile(
	[Parameter(Mandatory=$true)][string]$nuspecfilename,
	[Parameter(Mandatory=$true)][string]$packageDirectory,
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$false)][string]$verbosity = "normal"
)
{
	switch ($verbosity)
	{
		"normal" {$verbosityValue = "normal"}
		"quiet" {$verbosityValue = "quiet"}
		"detailed" {$verbosityValue = "detailed"}
		default {$verbosityValue = "quiet"}
	}
	if($packageDirectory.EndsWith("\"))
	{
		$packageDirectory = $packageDirectory.Substring(0,$packageDirectory.Length-1)
	}

	$packargs = ' pack "' + $nuspecfilename + '" -OutputDirectory "' + $packageDirectory + '" -NonInteractive -Verbosity ' + $verbosityValue
	$packcommand = "& '$nugetFullPath'" + $packargs
	iex $packcommand    
}

Function CreateMetaPackage(
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$true)][string]$frameworkVersion,
	[Parameter(Mandatory=$true)][string]$frameWorkVersionLong,
	[Parameter(Mandatory=$true)][string]$moduleName,
	[Parameter(Mandatory=$true)][string]$version,
	[Parameter(Mandatory=$true)][string]$title,
	[Parameter(Mandatory=$true)][string]$description,
	[Parameter(Mandatory=$true)][string]$summary,
	[Parameter(Mandatory=$true)][string]$nuspecDirectory,
	[Parameter(Mandatory=$true)][string]$packageDirectory,
	[Parameter(Mandatory=$true)][Array]$moduleDependencies,
	[Parameter(Mandatory=$false)][bool]$uploadPackages = $false,
	[Parameter(Mandatory=$true)][string]$uploadFeed,
	[Parameter(Mandatory=$true)][string]$uploadAPIKey
)
{
$nuspecfilename = "$nuspecDirectory$moduleName.$version.nuspec"
$packageFileName = "$packageDirectory$moduleName.$version.nupkg"
$nl = [Environment]::NewLine
$currentYear = [DateTime]::UtcNow.Year
$nuspecMetadata = @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
	<metadata minClientVersion="2.8">
		<id>$moduleName</id>
		<version>$version</version>
		<title>$moduleName</title>
		<authors>Sitecore Corporation A/S</authors>
		<owners>Sitecore Corporation A/S</owners>
		<iconUrl>https://mygetwwwsitecore.blob.core.windows.net/feedicons/sc-packages.png</iconUrl>   
		<licenseUrl>https://doc.sitecore.net/~/media/C23E989268EC4FA588108F839675A5B6.pdf</licenseUrl>     
		<projectUrl>http://doc.sitecore.net/</projectUrl>
		<requireLicenseAcceptance>false</requireLicenseAcceptance>
		<description>Description : $moduleName.</description>
		<summary>Summary : $moduleName.</summary>
		<copyright>&#169; $currentYear Sitecore Corporation A/S. All rights reserved. Sitecore&#174; is a registered trademark of Sitecore Corporation A/S.</copyright>
		<language>en-US</language>
		<developmentDependency>true</developmentDependency>
"@ + $nl
if($moduleDependencies.Count -gt 0)
{
	$nuspecMetadata += '        <dependencies>' + $nl
	$nuspecMetadata += '            <group targetFramework="' + $frameWorkVersionLong + '">' + $nl
	foreach($moduleDependency in $moduleDependencies)
	{
			$nuspecMetadata += '                <dependency id="' + $moduleDependency.ModuleName + '" version="[' + $moduleDependency.ModuleVersion + ']" />' + $nl
	}
	$nuspecMetadata += '            </group>' + $nl
	$nuspecMetadata += '        </dependencies>' + $nl
}
$nuspecMetadata += @"
	</metadata>
</package>
"@
	$nuspecMetadata | Out-File $nuspecfilename -Encoding ASCII
	PackNuspecFile -nuspecfilename $nuspecfilename -packageDirectory $packageDirectory -nugetFullPath $nugetFullPath
	if($uploadPackages -eq $true)
	{
		UploadNugetPackage -packageFileName $packageFileName -uploadFeed $uploadFeed -uploadAPIKey $uploadAPIKey -nugetFullPath $nugetFullPath
		
	}
}

Function CreateAssembliesNuspecFile(
	[Parameter(Mandatory=$true)][string]$readDirectory,
	[Parameter(Mandatory=$true)][string]$fileName,
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
	[Parameter(Mandatory=$true)][System.Array]$assemblies,
	[Parameter(Mandatory=$true)][NupackBuilder.Packages]$thirdpartycomponents,
	[Parameter(Mandatory=$false)][bool]$addThirdPartyReferences = $true,
	[Parameter(Mandatory=$false)][bool]$isSitecoreModule = $false,
	[Parameter(Mandatory=$false)][NupackBuilder.ModulePlatformSupportInfo]$modulePlatformSupportInfo
)
{
	
	if (!(Test-Path -Path $nuspecDirectory))
	{
		New-Item $nuspecDirectory -type directory | Out-Null
	}
	
	$bytes   = [System.IO.File]::ReadAllBytes($fileName)
	$loaded  = [System.Reflection.Assembly]::Load($bytes)
	$filenameOnly = [io.path]::GetFileName($_.FullName)

	$moduleName = [io.path]::GetFileNameWithoutExtension($fileName)

	$metaModuleName = $moduleName
	if($createFileVersionPackages -eq $true)
	{
		$moduleName = $filenameOnly
	}

	if($resolveDependencies -ne $true)
	{
		$moduleName = "$moduleName.NoReferences"
	}
	
	$pathToFile = [io.path]::GetDirectoryName($fileName)
	if($isSitecoreModule -eq $false)
	{
		$version = $SitecoreVersion
	}
	else
	{
		$version = $modulePlatformSupportInfo.ModuleVersion
	}

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
	if($createFileVersionPackages)
	{
		$version = [string](get-item "$fileName").VersionInfo.FileVersion
		$version = $version.Substring(0, $version.LastIndexOf("."))
	}
	$nuspecfilename = "$nuspecDirectory$moduleName.$version.nuspec"
	$packageFileName = "$packageDirectory$moduleName.$version.nupkg"
	$nl = [Environment]::NewLine
	$currentYear = [DateTime]::UtcNow.Year

	$dependencies = $null
	$dependencies = @()
	$scdependencies = $null
	$scdependencies = @()
	$frameworkAssemblies = $null
	$frameworkAssemblies = @()
	$notIncludedDependencies = $null
	$notIncludedDependencies = @()

	$loadeddependencies =  $loaded.GetReferencedAssemblies()

	if($resolveDependencies -eq $true)
	{
		foreach($dep in $loadeddependencies)
		{
			$someName = $dep.Name
			if(((Test-Path -Path "$readDirectory$someName.dll") -and ($isSitecoreModule -eq $false)) -or ((Test-Path -Path "$readDirectory$someName.dll") -and ($isSitecoreModule -eq $true) -and (!$dep.Name.ToLower().StartsWith("sitecore.experienceeditor"))) )
			{
				if($dep.Name.ToLower().StartsWith("sitecore.")) 
				{
					$objComponent = New-Object System.Object
					$objComponent | Add-Member -type NoteProperty -name PackageName -value $someName
					$objComponent | Add-Member -type NoteProperty -name Version -value $version
					$packageNameExists = $false

					for ($n=0; $n -lt $dependencies.Count; $n++)
					{
						if ($dependencies[$n].PackageName.ToLower() -eq $someName.ToLower()) 
						{
							$packageNameExists = $true
							$n = $dependencies.Count                            
						}
					}
					
					if($packageNameExists -eq $false)
					{
						$dependencies += $objComponent
					}
				}
		
				elseif(($addThirdPartyReferences -eq $true) -and (!$dep.Name.ToLower().StartsWith("mscorlib")) -and (!$dep.Name.ToLower().StartsWith("sysglobl")))
				{
					## Sorting out the commercial ones
					if((!$dep.Name.ToLower().StartsWith("netbiscuits.onpremise")) -and (!$dep.Name.ToLower().StartsWith("oracle.dataaccess")) -and (!$dep.Name.ToLower().StartsWith("ithit.webdav.server")) -and (!$dep.Name.ToLower().StartsWith("telerik")) -and (!$dep.Name.ToLower().StartsWith("stimulsoft")) -and (!$dep.Name.ToLower().StartsWith("componentart")) -and (!$dep.Name.ToLower().StartsWith("radeditor")) -and (!$dep.Name.ToLower().StartsWith("chilkatdotnet2"))) 
					{
						$depFileName ="$readDirectory$someName.dll"

						# $assemblyItem = Get-Item -Path $depFileName
						# $assemblyItemFileVersion = $assemblyItem.VersionInfo.FileVersion
						# $assemblyItemProductVersion = $assemblyItem.VersionInfo.ProductVersion
						$readbytes = $null
						$deploaded = $null
						$assemblyName = $null
						$readbytes   = [System.IO.File]::ReadAllBytes($depFileName)
						$deploaded  = [System.Reflection.Assembly]::Load($readbytes)
						$assemblyName = $deploaded.GetName()
						$assemblyItemVersion = $assemblyName.Version
						$assemblyItemName = $assemblyName.Name
						$addeddAssembly = $false

						if(($thirdpartycomponents -ne $null) -and ($thirdpartycomponents.PackageInfos.Count -ne 0))
						{
							$existingPackage = $null
							$existingPackage = $thirdpartycomponents.FindPackageInfoByAssemblyNameAndAssemblyVersion($assemblyItemName, $assemblyItemVersion)

							if(($isSitecoreModule -eq $false) -and ($existingPackage.PackageName -eq "Microsoft.AspNet.WebPages") -and (($SitecoreVersion.StartsWith("7.2.")) -or ($SitecoreVersion.StartsWith("8.0."))))
							{
								$existingPackage = $null
								$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Helpers", "3.0.0.0", "neutral", "31bf3856ad364e35")
								$existingPackage = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebPages", "3.1.2", $false, $packageAssembly)

								$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.WebPages.Deployment", "3.0.0.0", "neutral", "31bf3856ad364e35")
								$existingPackage.AddPackageAssembly($packageAssembly)

								$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.WebPages", "3.0.0.0", "neutral", "31bf3856ad364e35")
								$existingPackage.AddPackageAssembly($packageAssembly)

								$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.WebPages.Razor", "3.0.0.0", "neutral", "31bf3856ad364e35")
								$existingPackage.AddPackageAssembly($packageAssembly)
								
							}

							if(($existingPackage -ne $null) -and ($existingPackage.PreRelease -ne $true))
							{
								$objComponent = New-Object System.Object
								$objComponent | Add-Member -type NoteProperty -name PackageName -value $existingPackage.PackageName
								$objComponent | Add-Member -type NoteProperty -name Version -value $existingPackage.PackageVersion


								$packageNameExists = $false
								for ($j=0; $j -lt $dependencies.Count; $j++)
								{
									if ($dependencies[$j].PackageName.ToLower() -eq $existingPackage.PackageName.ToLower()) 
									{
										$addeddAssembly = $true
										$packageNameExists = $true                            
										$j = $dependencies.Count
									}
								}

								if($packageNameExists -eq $false)
								{
									$addeddAssembly = $true
									$dependencies += $objComponent
								}
							}
						}
						if($addeddAssembly -eq $false)
						{
							$notIncludedDependencies += "$someName.dll"
						}

					}
					else
					{
						$notIncludedDependencies += "$someName.dll"
					}
				}
				else
				{
					$notIncludedDependencies += "$someName.dll"
				}
			}
			else
			{
				if(($isSitecoreModule -eq $true) -and (($dep.Name.ToLower().StartsWith("sitecore.")) -or ($dep.Name.ToLower().StartsWith("crmsecurityprovider")))) 
				{
					$assemblyItemVersion = $dep.Version
					$assemblyItemName = $dep.Name
					$addeddAssembly = $false
					if(($modulePlatformSupportInfo -ne $null) -and ($modulePlatformSupportInfo.PackageInfos.Count -ne 0))
					{
						$existingPackage = $null
						$existingPackage = $modulePlatformSupportInfo.FindPackageInfoByAssemblyName($assemblyItemName)
						if(($existingPackage -ne $null) -and ($existingPackage.PreRelease -ne $true))
						{
							$objComponent = New-Object System.Object
							$objComponent | Add-Member -type NoteProperty -name PackageName -value $existingPackage.PackageName
							$objComponent | Add-Member -type NoteProperty -name Version -value $existingPackage.PackageVersion


							$packageNameExists = $false
							for ($j=0; $j -lt $dependencies.Count; $j++)
							{
								if ($dependencies[$j].PackageName.ToLower() -eq $existingPackage.PackageName.ToLower()) 
								{
									$addeddAssembly = $true
									$packageNameExists = $true                            
									$j = $dependencies.Count
								}
							}

							if($packageNameExists -eq $false)
							{
								$addeddAssembly = $true
								$dependencies += $objComponent
							}
						}
					}
					if(($addeddAssembly -eq $false) -and (!($dep.Name.ToLower().StartsWith("sitecore.emailcampaign"))))
					{
						# most likely this is the Sitecore platform dependencies in modules
						$objComponent = New-Object System.Object
						$objComponent | Add-Member -type NoteProperty -name PackageName -value $someName
						$objComponent | Add-Member -type NoteProperty -name MinimumPlatformVersion -value $modulePlatformSupportInfo.MinimumPlatformVersion
						$objComponent | Add-Member -type NoteProperty -name MaximumPlatformVersion -value $modulePlatformSupportInfo.MaximumPlatformVersion
						$objComponent | Add-Member -type NoteProperty -name OpenMaxRangeAllowed -value $modulePlatformSupportInfo.OpenMaxRangeAllowed
						$objComponent | Add-Member -type NoteProperty -name SpecificVersion -value $modulePlatformSupportInfo.SpecificVersion
						$packageNameExists = $false

						for ($n=0; $n -lt $scdependencies.Count; $n++)
						{
							if ($scdependencies[$n].PackageName.ToLower() -eq $someName.ToLower()) 
							{
								$packageNameExists = $true
								$n = $scdependencies.Count                            
							}
						}
					
						if($packageNameExists -eq $false)
						{
							$scdependencies += $objComponent
						}
					}
				}
				elseif(($addThirdPartyReferences -eq $true) -and (!$dep.Name.ToLower().StartsWith("mscorlib")) -and (!$dep.Name.ToLower().StartsWith("sysglobl")))
				{
					## Sorting out the commercial ones
					if((!$dep.Name.ToLower().StartsWith("netbiscuits.onpremise")) -and (!$dep.Name.ToLower().StartsWith("oracle.dataaccess")) -and (!$dep.Name.ToLower().StartsWith("ithit.webdav.server")) -and (!$dep.Name.ToLower().StartsWith("telerik")) -and (!$dep.Name.ToLower().StartsWith("stimulsoft")) -and (!$dep.Name.ToLower().StartsWith("componentart")) -and (!$dep.Name.ToLower().StartsWith("radeditor")) -and (!$dep.Name.ToLower().StartsWith("chilkatdotnet2")))
					{
						$depFileName ="$readDirectory$someName.dll"
						$assemblyItemVersion = $dep.Version
						$assemblyItemName = $dep.Name
						$addeddAssembly = $false

						if(($thirdpartycomponents -ne $null) -and ($thirdpartycomponents.PackageInfos.Count -ne 0))
						{
							$existingPackage = $null
							$existingPackage = $thirdpartycomponents.FindPackageInfoByAssemblyNameAndAssemblyVersion($assemblyItemName, $assemblyItemVersion)
							if(($existingPackage -ne $null) -and ($existingPackage.PreRelease -ne $true))
							{
								$objComponent = New-Object System.Object
								$objComponent | Add-Member -type NoteProperty -name PackageName -value $existingPackage.PackageName
								$objComponent | Add-Member -type NoteProperty -name Version -value $existingPackage.PackageVersion


								$packageNameExists = $false
								for ($j=0; $j -lt $dependencies.Count; $j++)
								{
									if ($dependencies[$j].PackageName.ToLower() -eq $existingPackage.PackageName.ToLower()) 
									{
										$addeddAssembly = $true
										$packageNameExists = $true                            
										$j = $dependencies.Count
									}
								}

								if($packageNameExists -eq $false)
								{
									$addeddAssembly = $true
									$dependencies += $objComponent
								}
							}
						}
						if($addeddAssembly -eq $false)
						{
							if(($dep.Name.ToLower().StartsWith("system.")) -or ($dep.Name.ToLower().Equals("windowsbase")) -or ($dep.Name.ToLower().Equals("system")) -or ($dep.Name.ToLower().Equals("mscorlib")) -or ($dep.Name.ToLower().Equals("sysglobl")) -or ($dep.Name.ToLower().StartsWith("microsoft.")))
							{
								# assemblies that are not part of our zip - normally these are referenced through the .NET framework, GAC or abstractions references for the .NET version
								# It's GAC GAC :-)
								# We would not add frameworkassemblies, since it is not always needed
								$frameworkAssemblies += $someName
							}
							else
							{
								$notIncludedDependencies += "$someName.dll"
							}
						}

					}
					elseif(($dep.Name.ToLower().StartsWith("system.")) -or ($dep.Name.ToLower().Equals("windowsbase")) -or ($dep.Name.ToLower().Equals("system")) -or ($dep.Name.ToLower().Equals("mscorlib")) -or ($dep.Name.ToLower().Equals("sysglobl")) -or ($dep.Name.ToLower().StartsWith("microsoft.")))
					{
						# assemblies that are not part of our zip - normally these are referenced through the .NET framework, GAC or abstractions references for the .NET version
						# It's GAC GAC :-)
						# We would not add frameworkassemblies, since it is not always needed
						$frameworkAssemblies += $someName
					}
					else
					{
						$notIncludedDependencies += "$someName.dll"
					}
				}
				elseif(($dep.Name.ToLower().StartsWith("system.")) -or ($dep.Name.ToLower().Equals("windowsbase")) -or ($dep.Name.ToLower().Equals("system")) -or ($dep.Name.ToLower().Equals("mscorlib")) -or ($dep.Name.ToLower().Equals("sysglobl")) -or ($dep.Name.ToLower().StartsWith("microsoft.")))
				{
					# assemblies that are not part of our zip - normally these are referenced through the .NET framework, GAC or abstractions references for the .NET version
					# It's GAC GAC :-)
					# We would not add frameworkassemblies, since it is not always needed
					$frameworkAssemblies += $someName
				}
				else
				{
					# This is the REAL missing assemblies.
					$notIncludedDependencies += "$someName.dll"
				}
			}
		}
	}
	else
	{
		foreach($dep in $loadeddependencies)
		{
			$someName = $dep.Name
			if(Test-Path -Path "$readDirectory$someName.dll" )
			{
				$notIncludedDependencies += "$someName.dll"
			}
		}
	}

$nuspecMetadata = @"
<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd">
	<metadata minClientVersion="2.8">
		<id>$moduleName</id>
		<version>$version</version>
		<title>$moduleName</title>
		<authors>Sitecore Corporation A/S</authors>
		<owners>Sitecore Corporation A/S</owners>
		<iconUrl>https://mygetwwwsitecore.blob.core.windows.net/feedicons/sc-packages.png</iconUrl> 
		<licenseUrl>https://doc.sitecore.net/~/media/C23E989268EC4FA588108F839675A5B6.pdf</licenseUrl>       
		<projectUrl>http://doc.sitecore.net/</projectUrl>
		<requireLicenseAcceptance>false</requireLicenseAcceptance>
"@
if($notIncludedDependencies.Count -gt 0)
{
	$joinedNoDep = $notIncludedDependencies -join ", " | Out-String 
	if($resolveDependencies -eq $true)
	{
		Write-Host "ModuleName : $moduleName" -ForegroundColor Red
		Write-Host "Missing : $joinedNoDep" -ForegroundColor Cyan
	}
	$nuspecMetadata += $nl + '        <description>Missing assembly dependencies : ' + $joinedNoDep + '</description>' + $nl
}
else
{
	$nuspecMetadata += $nl + '        <description>Description : ' + $moduleName + '.</description>' + $nl
}
$nuspecMetadata += @"
		<summary>Summary : $moduleName.</summary>
		<copyright>&#169; $currentYear Sitecore Corporation A/S. All rights reserved. Sitecore&#174; is a registered trademark of Sitecore Corporation A/S.</copyright>
		<language>en-US</language>
		<developmentDependency>true</developmentDependency>
"@ + $nl

if($resolveDependencies -eq $true)
{
	if(($dependencies.Count -gt 0) -or (($isSitecoreModule -eq $true) -and ($scdependencies.Count -gt 0)))
	{
		$nuspecMetadata += $nl + '        <dependencies>' + $nl
		$nuspecMetadata +=       '                <group targetFramework="'+$frameWorkVersionLong+'">' + $nl
		foreach($uniqueDependeny in $dependencies)
		{
			$dependencyPackageName = $uniqueDependeny.PackageName
			if(($dependencyPackageName.ToLower().StartsWith("sitecore.")))
			{
				if($createFileVersionPackages)
				{                    
					$assembly = ($assemblies | Select-Object Name, FileVersion, AssemblyVersion) -match "$dependencyPackageName.dll"
					$dependencyVersion = $assembly.FileVersion
					$dependencyVersion = $dependencyVersion.Substring(0, $dependencyVersion.LastIndexOf("."))
					$nuspecMetadata += '                        <dependency id="'+$dependencyPackageName+'.dll" version="['+$dependencyVersion+']" />' + $nl
				}
				else
				{
					$nuspecMetadata += '                        <dependency id="'+$dependencyPackageName+'" version="['+$uniqueDependeny.Version+']" />' + $nl
				}
			}
			else
			{
				$nuspecMetadata += '                        <dependency id="'+$dependencyPackageName+'" version="['+$uniqueDependeny.Version+']" />' + $nl
			}
		}

		if(($isSitecoreModule -eq $true) -and ($scdependencies.Count -gt 0))
		{
			foreach($scuniqueDependeny in $scdependencies)
			{
				$scdependencyPackageName = $scuniqueDependeny.PackageName
				if(($scdependencyPackageName.ToLower().StartsWith("sitecore.")))
				{
					if($scuniqueDependeny.SpecificVersion -eq $true)
					{
						$nuspecMetadata += '                        <dependency id="'+$scdependencyPackageName+'" version="['+$scuniqueDependeny.MinimumPlatformVersion+']" />' + $nl
					}
					elseif(($scuniqueDependeny.SpecificVersion -eq $false) -and ($scuniqueDependeny.OpenMaxRangeAllowed -eq $true))
					{
						# 1.0
						$versionString = $scuniqueDependeny.MinimumPlatformVersion
						$nuspecMetadata += '                        <dependency id="'+$scdependencyPackageName+'" version="'+$versionString+'" />' + $nl
					}
					elseif(($scuniqueDependeny.SpecificVersion -eq $false) -and ($scuniqueDependeny.OpenMaxRangeAllowed -eq $false))
					{
						#[1.0,2.0]
						$versionString = '['+$scuniqueDependeny.MinimumPlatformVersion+','+$scuniqueDependeny.MaximumPlatformVersion+']'
						$nuspecMetadata += '                        <dependency id="'+$scdependencyPackageName+'" version="'+$versionString+'" />' + $nl
					}
				}
			}
		}

		$nuspecMetadata += '                </group>' + $nl
		$nuspecMetadata += '        </dependencies>' + $nl
	}
	
}
$nuspecMetadata += @" 
</metadata>
	<files>
		<file src="$fileName" target="lib\$frameworkVersion\$filenameOnly" />
	</files>
</package>
"@
	$nuspecMetadata | Out-File $nuspecfilename -Encoding ASCII
	PackNuspecFile -nuspecfilename $nuspecfilename -packageDirectory $packageDirectory -nugetFullPath $nugetFullPath
	if($uploadPackages -eq $true)
	{
		UploadNugetPackage -packageFileName $packageFileName -uploadFeed $uploadFeed -uploadAPIKey $uploadAPIKey -nugetFullPath $nugetFullPath
	}
	if($createFileVersionPackages -eq $true)
	{
		$moduleObject ='' | select ModuleName, ModuleVersion
		$moduleDependencies = @()
		$moduleObject.ModuleName = $moduleName
		$moduleObject.ModuleVersion = $version
		$moduleDependencies += $moduleObject
		CreateMetaPackage `
							  -nugetFullPath $nugetFullPath `
							  -frameworkVersion $frameworkVersion `
							  -frameWorkVersionLong $frameWorkVersionLong `
							  -moduleName $metaModuleName `
							  -Version $SitecoreVersion `
							  -title $filenameOnly `
							  -description $filenameOnly `
							  -summary $filenameOnly `
							  -nuspecDirectory $nuspecDirectory `
							  -packageDirectory $packageDirectory `
							  -moduleDependencies $moduleDependencies `
							  -uploadPackages $uploadPackages `
							  -uploadFeed $uploadFeed `
							  -uploadAPIKey $uploadAPIKey
	}

	if($loaded -ne $null)
	{
		$loaded = $null
	}
}