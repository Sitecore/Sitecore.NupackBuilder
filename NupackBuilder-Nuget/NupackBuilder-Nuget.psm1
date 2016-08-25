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
	[Parameter(Mandatory=$true)][string]$uploadAPIKey
)
{
	$pushargs = ' push "' + $packageFileName + '" -ApiKey "'+$uploadAPIKey+'" -Source "'+$uploadFeed+'" -Timeout 600 -NonInteractive -Verbosity normal'
	$pushcommand = "& '$nugetFullPath'" + $pushargs
	iex $pushcommand    
}

Function DeletePackageFromFeed(
	[Parameter(Mandatory=$true)][string]$moduleName,
	[Parameter(Mandatory=$true)][string]$moduleVersion,
	[Parameter(Mandatory=$true)][string]$nugetFullPath,
	[Parameter(Mandatory=$true)][string]$feed,
	[Parameter(Mandatory=$true)][string]$APIKey
)
{
	$deleteargs = ' delete ' + $moduleName + ' ' + $moduleVersion + ' -ApiKey "'+$APIKey+'" -Source "'+$feed+'" -NonInteractive -Verbosity normal'
	$deletecommand = "& '$nugetFullPath'" + $deleteargs
	iex $deletecommand
}

Function PackNuspecFile(
	[Parameter(Mandatory=$true)][string]$nuspecfilename,
	[Parameter(Mandatory=$true)][string]$packageDirectory,
	[Parameter(Mandatory=$true)][string]$nugetFullPath
)
{
	if($packageDirectory.EndsWith("\"))
	{
		$packageDirectory = $packageDirectory.Substring(0,$packageDirectory.Length-1)
	}

	$packargs = ' pack "' + $nuspecfilename + '" -OutputDirectory "' + $packageDirectory + '" -NonInteractive -Verbosity normal'
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
		<iconUrl>http://www.sitecore.net/favicon.ico</iconUrl>   
		<licenseUrl>https://sdn.sitecore.net/upload/sitecoreeula.pdf</licenseUrl>     
		<projectUrl>http://dev.sitecore.net/</projectUrl>
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
	[Parameter(Mandatory=$false)][bool]$addThirdPartyReferences = $true

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
	$version = $SitecoreVersion
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
	$notIncludedDependencies = $null
	$notIncludedDependencies = @()

	$loadeddependencies =  $loaded.GetReferencedAssemblies()

	if($resolveDependencies -eq $true)
	{
		foreach($dep in $loadeddependencies)
		{
			$someName = $dep.Name
			if(Test-Path -Path "$readDirectory$someName.dll" )
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
		
				elseif(($addThirdPartyReferences -eq $true) -and (!$dep.Name.ToLower().StartsWith("microsoft.")) -and (!$dep.Name.ToLower().StartsWith("system.")) -and (!$dep.Name.ToLower().StartsWith("system")) -and (!$dep.Name.ToLower().StartsWith("mscorlib")) -and (!$dep.Name.ToLower().StartsWith("sysglobl")))
				{
					# Reporting dependencies

					## Sorting out the commercial ones

					if((!$dep.Name.ToLower().StartsWith("netbiscuits.onpremise")) -and (!$dep.Name.ToLower().StartsWith("oracle.dataaccess")) -and (!$dep.Name.ToLower().StartsWith("ithit.webdav.server")) -and (!$dep.Name.ToLower().StartsWith("telerik")) -and (!$dep.Name.ToLower().StartsWith("stimulsoft")) -and (!$dep.Name.ToLower().StartsWith("componentart")) -and (!$dep.Name.ToLower().StartsWith("radeditor")))
					{
						$depFileName = $readDirectory + $dep.Name + ".dll"

						#Write-Host $depFileName
						$assemblyItem = Get-Item -Path $depFileName
						$assemblyItemFileVersion = $assemblyItem.VersionInfo.FileVersion
						$assemblyItemProductVersion = $assemblyItem.VersionInfo.ProductVersion
						$Occurrences = $assemblyItemFileVersion.Split(".").GetUpperBound(0).ToString()
						switch ($Occurrences)
						{
							"2" {$assemblyItemSemVerVersion = $assemblyItemFileVersion}
							"3" {$assemblyItemSemVerVersion = $assemblyItemFileVersion.Substring(0, $assemblyItemFileVersion.LastIndexOf("."))}
							default {$assemblyItemSemVerVersion = "0.0.0"}
						}                    

						$assemblyItemVersion = $dep.Version
					
						$assemblyItemName = $dep.Name

						$depbytes   = [System.IO.File]::ReadAllBytes($depFileName)
						$deploaded  = [System.Reflection.Assembly]::Load($depbytes)

						$assemblyItemNameDLL = "$assemblyItemName.dll"

						$addeddAssembly = $false

						if(($thirdpartycomponents -ne $null) -and ($thirdpartycomponents.PackageInfos.Count -ne 0))
						{
							$existingPackage = $null
							$existingPackage = $thirdpartycomponents.FindPackageInfoByAssemblyNameAndAssemblyVersion($assemblyItemName, $assemblyItemVersion)
							if($existingPackage -ne $null)
							{
								# Write-Host "Package found : "$existingPackage.PackageName -ForegroundColor Yellow
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
									#Write-Host "$assemblyItemName,FileVersion=$assemblyItemFileVersion, Version=$assemblyItemVersion, ProductVersion=$assemblyItemProductVersion, SemverVersion=$assemblyItemSemVerVersion" -ForegroundColor Yellow
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
		<iconUrl>http://www.sitecore.net/favicon.ico</iconUrl> 
		<licenseUrl>https://sdn.sitecore.net/upload/sitecoreeula.pdf</licenseUrl>       
		<projectUrl>http://dev.sitecore.net/</projectUrl>
		<requireLicenseAcceptance>false</requireLicenseAcceptance>
"@
if($notIncludedDependencies.Count -gt 0)
{
	$joinedNoDep = $notIncludedDependencies -join "," | Out-String 
	# Write-Host "ModuleName : $moduleName" -ForegroundColor Red
	# Write-Host "Missing : $joinedNoDep" -ForegroundColor Cyan
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
	if($dependencies.Count -gt 0)
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