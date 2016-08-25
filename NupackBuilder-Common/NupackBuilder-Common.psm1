$TypeDefinitionSource = @"
  namespace NupackBuilder
{
	using System;
	using System.Linq;

	public class PackageAssembly
	{
		public string AssemblyName { get; protected set; }
		public string AssemblyVersion { get; protected set; }
		public string AssemblyCulture { get; protected set; }
		public string AssemblyPublicKeyToken { get; protected set; }

		public PackageAssembly(string assemblyName, string assemblyVersion, string assemblyCulture, string assemblyPublicKeyToken)
		{
			AssemblyName = assemblyName;
			AssemblyVersion = assemblyVersion;
			AssemblyCulture = assemblyCulture;
			AssemblyPublicKeyToken = assemblyPublicKeyToken;
		}
	}

	public class PackageInfo
	{
		public string PackageName { get; protected set; }
		public string PackageVersion { get; protected set; }

		public System.Collections.Generic.List<PackageAssembly> PackageAssemblies { get; protected set; }

		public PackageInfo(string packageName, string packageVersion)
		{
			PackageAssemblies = new System.Collections.Generic.List<PackageAssembly>();
			PackageName = packageName;
			PackageVersion = packageVersion;
		}

		public PackageInfo(string packageName, string packageVersion, PackageAssembly packageAssembly) : this(packageName, packageVersion)
		{
			PackageAssemblies.Add(packageAssembly);
		}

		public void AddPackageAssembly(PackageAssembly packageAssembly)
		{
			PackageAssemblies.Add(packageAssembly);
		}
	}

	public class Packages
	{
		public System.Collections.Concurrent.ConcurrentDictionary<string, PackageInfo> PackageInfos { get; protected set; }

		public Packages()
		{
			PackageInfos = new System.Collections.Concurrent.ConcurrentDictionary<string, PackageInfo>();
		}

		public void AddPackageInfo(PackageInfo packageInfo)
		{
			if (string.IsNullOrEmpty(packageInfo.PackageName) || string.IsNullOrEmpty(packageInfo.PackageVersion))
			{
				return;
			}

			if (!PackageInfos.ContainsKey(packageInfo.PackageName + packageInfo.PackageVersion))
			{
				PackageInfos.TryAdd(packageInfo.PackageName + packageInfo.PackageVersion, packageInfo);
			}
		}

		public void RemovePackageInfo(PackageInfo packageInfo)
		{
			if (string.IsNullOrEmpty(packageInfo.PackageName) || string.IsNullOrEmpty(packageInfo.PackageVersion))
			{
				return;
			}

			if (!PackageInfos.ContainsKey(packageInfo.PackageName + packageInfo.PackageVersion))
			{
				return;
			}

			PackageInfo removePackage;
			PackageInfos.TryRemove(packageInfo.PackageName + packageInfo.PackageVersion, out removePackage);
		}

		public void UpdatePackageInfo(PackageInfo packageInfo)
		{
			if (string.IsNullOrEmpty(packageInfo.PackageName) || string.IsNullOrEmpty(packageInfo.PackageVersion))
			{
				return;
			}

			if (PackageInfos.ContainsKey(packageInfo.PackageName + packageInfo.PackageVersion))
			{
				RemovePackageInfo(packageInfo);
			}

			AddPackageInfo(packageInfo);
		}

		public PackageInfo FindPackageInfoByAssemblyNameAndAssemblyVersion(string assemblyName, string assemblyVersion)
		{
			var packageInfo = PackageInfos.FirstOrDefault(
				pInfo =>
					pInfo.Value.PackageAssemblies.Find(
						pAssembly =>
							pAssembly.AssemblyName.Equals(assemblyName, StringComparison.InvariantCultureIgnoreCase) &&
							pAssembly.AssemblyVersion.Equals(assemblyVersion,
								StringComparison.InvariantCultureIgnoreCase)) != null);

			return packageInfo.Value;
		}
	}
}
"@

Add-Type -TypeDefinition $TypeDefinitionSource

Function Write-Log(
  [string][Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]$Message,
  [string]$Program = "PowerShell",
  [string]$Level = "INFO",
  [string]$foregroundcolor = "Green",
  [switch]$silent
)
{
  $msg="[$(Get-Date -Format T)] [$Level] $Message" 
  if (-not $silent.IsPresent) 
  {
	switch ($Level) 
	{ 
	  "info"    
	  {
		if ($foregroundcolor)
		{
		  Write-Host "$msg" -foregroundcolor $foregroundcolor
		}
		else
		{
		  Write-Host "$msg"
		}
	  } 
	  "inform"  
	  {
		Write-Host "$msg"
	  } 
	  "warn"    
	  {
		Write-Host "$msg" -foregroundcolor Yellow
		$global:warningcount++
	  } 
	  "warni"   
	  {
		 Write-Host "$msg" -foregroundcolor Yellow
		 $global:warningcount++
	  }
	  "warning" 
	  {
		Write-Host "$msg" -foregroundcolor Yellow
		$global:warningcount++
	  }
	  "err"     
	  {
		Write-Host "$msg" -foregroundcolor Red
		$global:errorcount++
		#throw
		exit(-1)
	  } 
	  "error"   
	  {
		Write-Host "$msg" -foregroundcolor Red
		$global:errorcount++
		#throw
		exit(-1)
	  } 
	  default {Write-Host "$msg"}
	}
  }
}

Function Get-7z(
[Parameter(Mandatory=$false)][string]$NugetFeed = "https://www.nuget.org/api/v2/",
[Parameter(Mandatory=$true)][string]$installPath,
[Parameter(Mandatory=$true)][string]$nugetFullPath
)
{
	if (!(Test-Path -Path "$installPath\packages\7-Zip.CommandLine\tools\7za.exe"))
	{
		$nugetArgs = ' install 7-Zip.CommandLine -ExcludeVersion -o "' + $installPath + '\packages" -Source "' + $NugetFeed + '"'
		$nugetCommand = "& '$nugetFullPath'" + $nugetArgs
		Write-Log -Message "Installing 7-Zip.CommandLine nuget package to $installPath\packages ..." -Program "nuget"
		iex $nugetCommand -Verbose | Out-Null
		Write-Log -Message "Done installing 7-Zip.CommandLine nuget package to $installPath\packages ..." -Program "nuget"
	}
	return "$installPath\packages\7-Zip.CommandLine\tools\7za.exe"
}

Function Add-ThirdPartyComponent(
[Parameter(Mandatory=$true)][string]$PackageName,
[Parameter(Mandatory=$true)][Array]$AssemblyNames,
[Parameter(Mandatory=$true)][Array]$Versions
)
{
	$thirdpartycomponents = @()
	$objThirdPartyComponent = New-Object System.Object
	$objThirdPartyComponent | Add-Member -type NoteProperty -name PackageName -value $PackageName
	$objThirdPartyComponent | Add-Member -type NoteProperty -name AssemblyNames -value $AssemblyNames
	$objThirdPartyComponent | Add-Member -type NoteProperty -name Versions -value $Versions
	$thirdpartycomponents += $objThirdPartyComponent
	return $thirdpartycomponents

}

Function UnZipDLLFiles (
  [Parameter(Mandatory=$true)][string]$installPath,
  [Parameter(Mandatory=$true)][string]$ArchivePath,  
  [Parameter(Mandatory=$true)][string]$TargetPath, 
  [Parameter(Mandatory=$true)][string]$Filter,  
  [switch]$SuppressOutput,
  [Parameter(Mandatory=$false)][string]$NugetFeed = "https://www.nuget.org/api/v2/",
  [Parameter(Mandatory=$true)][string]$nugetFullPath
)
{
  
  if (!(Test-Path -Path $ArchivePath))
  {
	Write-Log -Message "The archive to extract was not found: $ArchivePath" -Level "Error"
  }
	
  if((Test-Path -Path $TargetPath ))
  {
	$child_items = ([array] (Get-ChildItem -Path $TargetPath -Recurse -Force))
		if ($child_items) {
			$null = $child_items | Remove-Item -Force -Recurse | Out-Null
		}
		$null = Remove-Item $TargetPath -Force | Out-Null
  }
  
  if (!(Test-Path -Path $TargetPath))
  {
	New-Item -Path $TargetPath -ItemType directory | Out-Null
  }
  
  $FileNameNoExtension = [io.path]::GetFileNameWithoutExtension($ArchivePath)
  [string]$pathTo7z = $(Get-7z -installPath $installPath -nugetFullPath $nugetFullPath -NugetFeed $NugetFeed)
  $unzipargs = ' e -r "' + $ArchivePath + '" "' + $Filter + '" -o"' + $TargetPath + '" -y'
  $unzipcommand = "& '$pathTo7z'" + $unzipargs
  
  if ($SuppressOutput)
  {
	Write-Log -Message "Extracting files from $ArchivePath to $TargetPath..." -Program "7z"
	iex $unzipcommand | Out-Null
	Write-Log -Message "Done Extracting files from $ArchivePath to $TargetPath..." -Program "7z"
  }
  else
  {
	iex $unzipcommand
  }  
}
