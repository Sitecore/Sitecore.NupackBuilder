$TypeDefinitionSource = @"
namespace NupackBuilder
{
    using System;
    using System.Linq;
    using System.Collections.Generic;
    using System.Collections.Concurrent;

    public class Modules
    {
        public ConcurrentDictionary<string, ModulePlatformSupportInfo> ModulePlatformSupportInfos { get; protected set; }

        public Modules()
        {
            ModulePlatformSupportInfos = new ConcurrentDictionary<string, ModulePlatformSupportInfo>();
        }

        public void AddModulePlatformSupportInfo(ModulePlatformSupportInfo modulePlatformSupportInfo)
        {
            if (string.IsNullOrEmpty(modulePlatformSupportInfo.ModuleName) || string.IsNullOrEmpty(modulePlatformSupportInfo.ModuleVersion))
            {
                return;
            }

            if (!ModulePlatformSupportInfos.ContainsKey(modulePlatformSupportInfo.ModuleName + modulePlatformSupportInfo.ModuleVersion))
            {
                ModulePlatformSupportInfos.TryAdd(modulePlatformSupportInfo.ModuleName + modulePlatformSupportInfo.ModuleVersion, modulePlatformSupportInfo);
            }
        }

        public void RemoveModulePlatformSupportInfo(ModulePlatformSupportInfo modulePlatformSupportInfo)
        {
            if (string.IsNullOrEmpty(modulePlatformSupportInfo.ModuleName) || string.IsNullOrEmpty(modulePlatformSupportInfo.ModuleVersion))
            {
                return;
            }

            if (!ModulePlatformSupportInfos.ContainsKey(modulePlatformSupportInfo.ModuleName + modulePlatformSupportInfo.ModuleVersion))
            {
                return;
            }

            ModulePlatformSupportInfo removePackage;
            ModulePlatformSupportInfos.TryRemove(modulePlatformSupportInfo.ModuleName + modulePlatformSupportInfo.ModuleVersion, out removePackage);
        }

        public void UpdateModulePlatformSupportInfo(ModulePlatformSupportInfo modulePlatformSupportInfo)
        {
            if (string.IsNullOrEmpty(modulePlatformSupportInfo.ModuleName) || string.IsNullOrEmpty(modulePlatformSupportInfo.ModuleVersion))
            {
                return;
            }

            if (ModulePlatformSupportInfos.ContainsKey(modulePlatformSupportInfo.ModuleName + modulePlatformSupportInfo.ModuleVersion))
            {
                RemoveModulePlatformSupportInfo(modulePlatformSupportInfo);
            }

            AddModulePlatformSupportInfo(modulePlatformSupportInfo);
        }

        public ModulePlatformSupportInfo FindModulePlatformVersionsByModuleNameAndModuleVersion(string moduleName, string moduleVersion)
        {
            var modulePlatformSupportInfo = ModulePlatformSupportInfos.FirstOrDefault(
                pModuleInfo => 
                    pModuleInfo.Value.ModuleName.Equals(moduleName, StringComparison.InvariantCultureIgnoreCase)
                    && pModuleInfo.Value.ModuleVersion.Equals(moduleVersion, StringComparison.InvariantCultureIgnoreCase)
                );


            return modulePlatformSupportInfo.Value;
        }

        public ModulePlatformSupportInfo FindModulePlatformVersionsByFullName(string fullName)
        {
            var modulePlatformSupportInfo = ModulePlatformSupportInfos.FirstOrDefault(
                pModuleInfo =>
                    pModuleInfo.Value.FullName.Equals(fullName, StringComparison.InvariantCultureIgnoreCase)
                );


            return modulePlatformSupportInfo.Value;
        }

    }

    public class ModulePlatformSupportInfo
    {
        public ConcurrentDictionary<string, PackageInfo> PackageInfos { get; protected set; }

        public string FullName { get; protected set; }
        public string ModuleName { get; protected set; }

        public string ModuleVersion { get; protected set; }

        public string MinimumPlatformVersion { get; protected set; }

        public string MaximumPlatformVersion { get; protected set; }

        public bool OpenMaxRangeAllowed { get; protected set; }

        public bool SpecificVersion { get; protected set; }

        public ModulePlatformSupportInfo(string fullName, string moduleName, string moduleVersion, string minimumPlatformVersion, bool openMaxRangeAllowed, bool specificVersion) : this(fullName, moduleName, moduleVersion, minimumPlatformVersion, string.Empty, openMaxRangeAllowed, specificVersion)
        {
        }

        public ModulePlatformSupportInfo(string fullName, string moduleName, string moduleVersion, string minimumPlatformVersion, string maximumPlatformVersion, bool openMaxRangeAllowed, bool specificVersion)
        {
            PackageInfos = new ConcurrentDictionary<string, PackageInfo>();
            FullName = fullName;
            MinimumPlatformVersion = minimumPlatformVersion;
            ModuleName = moduleName;
            ModuleVersion = moduleVersion;
            MaximumPlatformVersion = maximumPlatformVersion;
            OpenMaxRangeAllowed = openMaxRangeAllowed;
            SpecificVersion = specificVersion;
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

        public PackageInfo FindPackageInfoByAssemblyName(string assemblyName)
        {
            var packageInfo = PackageInfos.FirstOrDefault(
                pInfo =>
                    pInfo.Value.PackageAssemblies.Find(
                        pAssembly =>
                            pAssembly.AssemblyName.Equals(assemblyName, StringComparison.InvariantCultureIgnoreCase)) != null);

            return packageInfo.Value;
        }
    }

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
        public bool PreRelease { get; protected set; }

        public List<PackageAssembly> PackageAssemblies { get; protected set; }

        public PackageInfo(string packageName, string packageVersion, bool preRelease)
        {
            PackageAssemblies = new List<PackageAssembly>();
            PackageName = packageName;
            PackageVersion = packageVersion;
            PreRelease = preRelease;
        }

        public PackageInfo(string packageName, string packageVersion, bool preRelease, PackageAssembly packageAssembly) : this(packageName, packageVersion, preRelease)
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
        public ConcurrentDictionary<string, PackageInfo> PackageInfos { get; protected set; }

        public Packages()
        {
            PackageInfos = new ConcurrentDictionary<string, PackageInfo>();
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
    if (!(Test-Path -Path "$installPath\packages\7-Zip.x64\tools\7z.exe"))
    {
        $nugetArgs = ' install 7-Zip.x64 -ExcludeVersion -o "' + $installPath + '\packages" -Source "' + $NugetFeed + '"'
        $nugetCommand = "& '$nugetFullPath'" + $nugetArgs
        Write-Log -Message "Installing 7-Zip.x64 nuget package to $installPath\packages ..." -Program "nuget"
        iex $nugetCommand -Verbose | Out-Null
        Write-Log -Message "Done installing 7-Zip.x64 nuget package to $installPath\packages ..." -Program "nuget"
    }
    return "$installPath\packages\7-Zip.x64\tools\7z.exe"
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

Function Add-ModulePlatformSupportInfo()
{
    $modules = [NupackBuilder.Modules]::new()

    # Data Exchange Framework 1.0 rev. 160625
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Data Exchange Framework 1.0 rev. 160625", "Data-Exchange-Framework", "1.0.160625", "8.1.151003", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    # Data Exchange Framework 1.1.0 rev. 160817
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Data Exchange Framework 1.1.0 rev. 160817", "Data-Exchange-Framework", "1.1.160817", "8.1.151003", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    # Data Exchange Framework 1.2.0 rev. 161212
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Data Exchange Framework 1.2.0 rev. 161212", "Data-Exchange-Framework", "1.2.161212", "8.1.151207", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    # Data Exchange Framework 1.3.0 rev. 170210
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Data Exchange Framework 1.3.0 rev. 170210", "Data-Exchange-Framework", "1.3.170210", "8.1.151207", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    # Data Exchange Framework 1.4.0 rev. 170419
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Data Exchange Framework 1.4.0 rev. 170419", "Data-Exchange-Framework", "1.4.170419", "8.1.151207", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Data Exchange Framework Remote SDK 1.0 rev. 160625
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Data Exchange Framework Remote SDK 1.0 rev. 160625", "Data-Exchange-Framework-Remote-SDK", "1.0.160625", "8.1.151003", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Data Exchange Framework Remote SDK 1.1.0 rev. 160817
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Data Exchange Framework Remote SDK 1.1.0 rev. 160817", "Data-Exchange-Framework-Remote-SDK", "1.1.160817", "8.1.151003", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Data Exchange Framework Remote SDK 1.2.0 rev. 161212
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Data Exchange Framework Remote SDK 1.2.0 rev. 161212", "Data-Exchange-Framework-Remote-SDK", "1.2.161212", "8.1.151207", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Data Exchange Framework Remote SDK 1.3.0
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Data Exchange Framework Remote SDK 1.3.0", "Data-Exchange-Framework-Remote-SDK", "1.3.170210", "8.1.151207", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Data Exchange Framework Remote SDK 1.4.0 rev. 170419
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Data Exchange Framework Remote SDK 1.4.0 rev. 170419", "Data-Exchange-Framework-Remote-SDK", "1.4.170419", "8.1.151207", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Sitecore Provider for Data Exchange Framework 1.0 rev. 160625
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Sitecore Provider for Data Exchange Framework 1.0 rev. 160625", "Sitecore-Provider-for-Data-Exchange-Framework", "1.0.160625", "8.1.151003", $true, $false)
    
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange", "1.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange", "1.0.160625", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.DataAccess", "1.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.DataAccess", "1.0.160625", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.Local", "1.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.Local", "1.0.160625", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)
    
    $modules.AddModulePlatformSupportInfo($module)

    #Sitecore Provider for Data Exchange Framework 1.1.0 rev. 160817
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Sitecore Provider for Data Exchange Framework 1.1.0 rev. 160817", "Sitecore-Provider-for-Data-Exchange-Framework", "1.1.160817", "8.1.151003", $true, $false)
    
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange", "1.1.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange", "1.1.160817", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.DataAccess", "1.1.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.DataAccess", "1.1.160817", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.Local", "1.1.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.Local", "1.1.160817", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)
    
    $modules.AddModulePlatformSupportInfo($module)

    #Sitecore Provider for Data Exchange Framework 1.2.0 rev. 161212
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Sitecore Provider for Data Exchange Framework 1.2.0 rev. 161212", "Sitecore-Provider-for-Data-Exchange-Framework", "1.2.161212", "8.1.151207", $true, $false)
    
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange", "1.2.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange", "1.2.161212", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.DataAccess", "1.2.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.DataAccess", "1.2.161212", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.Local", "1.2.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.Local", "1.2.161212", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)
    
    $modules.AddModulePlatformSupportInfo($module)

    #Sitecore Provider for Data Exchange Framework 1.3.0 rev. 170210
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Sitecore Provider for Data Exchange Framework 1.3.0 rev. 170210", "Sitecore-Provider-for-Data-Exchange-Framework", "1.3.170210", "8.1.151207", $true, $false)
    
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange", "1.3.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange", "1.3.170210", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.DataAccess", "1.3.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.DataAccess", "1.3.170210", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.Local", "1.3.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.Local", "1.3.170210", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)
    
    $modules.AddModulePlatformSupportInfo($module)

    #Sitecore Provider for Data Exchange Framework 1.4.0 rev. 170419
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Sitecore Provider for Data Exchange Framework 1.4.0 rev. 170419", "Sitecore-Provider-for-Data-Exchange-Framework", "1.4.170419", "8.1.151207", $true, $false)
    
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange", "1.4.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange", "1.4.170419", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.DataAccess", "1.4.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.DataAccess", "1.4.170419", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.Local", "1.4.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.Local", "1.4.170419", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)
    
    $modules.AddModulePlatformSupportInfo($module)


    #Dynamics CRM Provider for Data Exchange Framework 1.0 rev. 160625
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Dynamics CRM Provider for Data Exchange Framework 1.0 rev. 160625", "Dynamics-CRM-Provider-for-Data-Exchange-Framework", "1.0.160625", "8.1.151003", $true, $false)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange", "1.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange", "1.0.160625", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.DataAccess", "1.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.DataAccess", "1.0.160625", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.Local", "1.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.Local", "1.0.160625", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Dynamics CRM Provider for Data Exchange Framework 1.1.0 rev. 160817
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Dynamics CRM Provider for Data Exchange Framework 1.1.0 rev. 160817", "Dynamics-CRM-Provider-for-Data-Exchange-Framework", "1.1.160817", "8.1.151003", $true, $false)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange", "1.1.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange", "1.1.160817", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.DataAccess", "1.1.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.DataAccess", "1.1.160817", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.Local", "1.1.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.Local", "1.1.160817", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Dynamics CRM Provider for Data Exchange Framework 1.2.0 rev. 161212
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Dynamics CRM Provider for Data Exchange Framework 1.2.0 rev. 161212", "Dynamics-CRM-Provider-for-Data-Exchange-Framework", "1.2.161212", "8.1.151207", $true, $false)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange", "1.2.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange", "1.2.161212", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.DataAccess", "1.2.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.DataAccess", "1.2.161212", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.Local", "1.2.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.Local", "1.2.161212", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Dynamics CRM Provider for Data Exchange Framework 1.3.0 rev. 170210
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Dynamics CRM Provider for Data Exchange Framework 1.3.0 rev. 170210", "Dynamics-CRM-Provider-for-Data-Exchange-Framework", "1.3.170210", "8.1.151207", $true, $false)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange", "1.3.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange", "1.3.170210", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.DataAccess", "1.3.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.DataAccess", "1.3.170210", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.Local", "1.3.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.Local", "1.3.170210", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Dynamics CRM Provider for Data Exchange Framework 1.4.0 rev. 170419
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Dynamics CRM Provider for Data Exchange Framework 1.4.0 rev. 170419", "Dynamics-CRM-Provider-for-Data-Exchange-Framework", "1.4.170419", "8.1.151207", $true, $false)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange", "1.4.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange", "1.4.170419", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.DataAccess", "1.4.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.DataAccess", "1.4.170419", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.Local", "1.4.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.Local", "1.4.170419", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Data Exchange Framework SDK 1.4.0 rev. 170419
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Data Exchange Framework SDK 1.4.0 rev. 170419", "Data-Exchange-Framework-SDK", "1.4.170419", "8.1.151207", $true, $false)
    
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.DataExchange.Local", "1.4.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.DataExchange.Local", "1.4.170419", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)
    
    $modules.AddModulePlatformSupportInfo($module)

    #Sitecore Media Framework 21 rev 150625
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Sitecore Media Framework 21 rev 150625", "Sitecore-Media-Framework", "2.1.150625", "8.0.141212", "8.0.160115", $false, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Sitecore Media Framework 2.2 rev. 160927
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Sitecore Media Framework 2.2 rev. 160927", "Sitecore-Media-Framework", "2.2.160927", "8.2.160729", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Microsoft Dynamics CRM Security Provider-2.3.0 rev. 160829
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Microsoft Dynamics CRM Security Provider-2.3.0 rev. 160829", "Dynamics-CRM-Security-Provider", "2.3.160829", "8.2.160729", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Microsoft Dynamics CRM Security Provider 2.1.2 rev. 170118
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Microsoft Dynamics CRM Security Provider 2.1.2 rev. 170118", "Dynamics-CRM-Security-Provider", "2.1.170118", "8.0.141212", "8.1.0", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Microsoft Dynamics CRM Security Provider 2.2.3 rev. 170118
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Microsoft Dynamics CRM Security Provider 2.2.3 rev. 170118", "Dynamics-CRM-Security-Provider", "2.2.170118", "8.1.151003", "8.2.0", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Microsoft Dynamics CRM Security Provider 2.3.2 rev. 170118
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Microsoft Dynamics CRM Security Provider 2.3.2 rev. 170118", "Dynamics-CRM-Security-Provider", "2.3.170118", "8.2.160729", "8.3.0", $true, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Dynamics CRM Campaign Integration for WFFM 2.3 rev. 160829
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Dynamics CRM Campaign Integration for WFFM 2.3 rev. 160829", "Dynamics-CRM-Campaign-Integration-for-WFFM", "2.3.160829", "8.2.160729", $false, $true)
    
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("CRMSecurityProvider", "2.1.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("CRMSecurityProvider", "2.3.160829", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.Forms.Core", "8.1.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.Forms.Core", "8.2.160801", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.WFFM.Abstractions", "8.1.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.WFFM.Abstractions", "8.2.160801", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.WFFM.Actions", "8.1.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.WFFM.Actions", "8.2.160801", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms for Marketers  8.0 rev. 141217 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms for Marketers  8.0 rev. 141217 NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.0.141217", "8.0.141212", "8.0.150121", $false, $false)
    
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.EmailCampaign", "3.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.EmailCampaign", "3.0.141215,3.0.150126", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms for Marketers 8.0 rev. 150224 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms for Marketers 8.0 rev. 150224 NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.0.150224", "8.0.150223", $false, $true)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.EmailCampaign", "3.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.EmailCampaign", "3.0.150223", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms for Marketers 8.0 rev. 150429 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms for Marketers 8.0 rev. 150429 NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.0.150429", "8.0.150427", $false, $true)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.EmailCampaign", "3.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.EmailCampaign", "3.0.150429,3.1.150703", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms for Marketers 8.0 rev. 150625 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms for Marketers 8.0 rev. 150625 NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.0.150625", "8.0.150621", $false, $true)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.EmailCampaign", "3.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.EmailCampaign", "3.1.150811", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms for Marketers 8.0 rev. 151127 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms for Marketers 8.0 rev. 151127 NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.0.151127", "8.0.151127", "8.0.160115", $false, $false)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.EmailCampaign", "3.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.EmailCampaign", "3.1.151213", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms For Marketers 8.1 rev. 151008 Initial NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms For Marketers 8.1 rev. 151008 Initial NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.1.151008", "8.1.151003", $false, $true)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.EmailCampaign", "3.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.EmailCampaign", "3.2.151020", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms For Marketers 8.1 rev. 151217 Update-1 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms For Marketers 8.1 rev. 151217 Update-1 NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.1.151217", "8.1.151207", $false, $true)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.EmailCampaign", "3.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.EmailCampaign", "3.2.160127", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms For Marketers 8.1 rev. 160304 Update-2 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms For Marketers 8.1 rev. 160304 Update-2 NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.1.160304", "8.1.160302", $false, $true)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.EmailCampaign", "3.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.EmailCampaign", "3.2.160127", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms for Marketers 8.1 rev. 160523 NOT SC PACKAGE-
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms for Marketers 8.1 rev. 160523 NOT SC PACKAGE-", "Web-Forms-for-Marketers", "8.1.160523", "8.1.160519", $false, $true)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Sitecore.EmailCampaign", "3.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Sitecore.EmailCampaign", "3.3.160527", $false, $packageAssembly)
    $module.AddPackageInfo($packageInfo)

    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms for Marketers 8.2 rev. 160801 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms for Marketers 8.2 rev. 160801 NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.2.160801", "8.2.160729", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms for Marketers 8.2 rev. 161129 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms for Marketers 8.2 rev. 161129 NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.2.161129", "8.2.161115", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms for Marketers 8.2 rev. 170413 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms for Marketers 8.2 rev. 170413 NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.2.170413", "8.2.170407", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms for Marketers 8.2 rev. 170518 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms for Marketers 8.2 rev. 170518 NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.2.170518", "8.2.170614", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Web Forms for Marketers 8.2.5 rev. 170807 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Web Forms for Marketers 8.2.5 rev. 170807 NOT SC PACKAGE", "Web-Forms-for-Marketers", "8.2.170807", "8.2.170728", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Email Experience Manager 3.0 rev. 141215
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Email Experience Manager 3.0 rev. 141215", "Email-Experience-Manager", "3.0.141215", "8.0.141212", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Email Experience Manager 3.0 rev. 150126
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Email Experience Manager 3.0 rev. 150126", "Email-Experience-Manager", "3.0.150126", "8.0.150121", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Email Experience Manager 3.0 rev.150223 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Email Experience Manager 3.0 rev.150223 NOT SC PACKAGE", "Email-Experience-Manager", "3.0.150223", "8.0.150223", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Email Experience Manager 3.0 rev.150429 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Email Experience Manager 3.0 rev.150429 NOT SC PACKAGE", "Email-Experience-Manager", "3.0.150429", "8.0.150427", "8.0.160115", $false, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #EXM 3.1 rev. 150703
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("EXM 3.1 rev. 150703", "Email-Experience-Manager", "3.1.150703", "8.0.150427", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #EXM 3.1 rev. 150811 (Update-1)
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("EXM 3.1 rev. 150811 (Update-1)", "Email-Experience-Manager", "3.1.150811", "8.0.150621", "8.0.150812", $false, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Email Experience Manager 3.1.2 rev. 151213 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Email Experience Manager 3.1.2 rev. 151213 NOT SC PACKAGE", "Email-Experience-Manager", "3.1.151213", "8.0.151127", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Email Experience Manager 3.2.0 rev. 151020 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Email Experience Manager 3.2.0 rev. 151020 NOT SC PACKAGE", "Email-Experience-Manager", "3.2.151020", "8.1.151003", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Email Experience Manager 3.2.1 rev. 160127 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Email Experience Manager 3.2.1 rev. 160127 NOT SC PACKAGE", "Email-Experience-Manager", "3.2.160127", "8.1.151207", "8.1.160302", $false, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Email Experience Manager 3.3.0 rev. 160527 (not sc package)
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Email Experience Manager 3.3.0 rev. 160527 (not sc package)", "Email-Experience-Manager", "3.3.160527", "8.1.160519", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Email Experience Manager 3.4.0 rev. 161028 (not sc package)
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Email Experience Manager 3.4.0 rev. 161028 (not sc package)", "Email-Experience-Manager", "3.4.161028", "8.2.160729", "8.2.161115", $false, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Email Experience Manager 3.4.1 rev. 170105 (not sc package)
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Email Experience Manager 3.4.1 rev. 170105 (not sc package)", "Email-Experience-Manager", "3.4.170105", "8.2.161221", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Email Experience Manager 3.4.2 rev. 170713 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Email Experience Manager 3.4.2 rev. 170713 NOT SC PACKAGE", "Email-Experience-Manager", "3.4.170713", "8.2.170407", "8.2.170614", $false, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Email Experience Manager 3.5.0 rev. 170810 NOT SC PACKAGE
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Email Experience Manager 3.5.0 rev. 170810 NOT SC PACKAGE", "Email-Experience-Manager", "3.5.170810", "8.2.170728", $false, $true)
    $modules.AddModulePlatformSupportInfo($module)

    #Print Experience Manager 8.0 rev. 150202
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Print Experience Manager 8.0 rev. 150202", "Print-Experience-Manager", "8.0.150202", "8.0.141212", "8.2.161221", $false, $false)
    $modules.AddModulePlatformSupportInfo($module)

    #Sitecore Print Experience Manager 8.2 rev. 170509
    $module = [NupackBuilder.ModulePlatformSupportInfo]::new("Sitecore Print Experience Manager 8.2 rev. 170509", "Print-Experience-Manager", "8.2.170509", "8.2.170407", "8.2.170614", $false, $false)
    $modules.AddModulePlatformSupportInfo($module)

    return $modules
}

Function Add-PlatformThirdPartyPackages()
{
    $packages  = [NupackBuilder.Packages]::new()

    # Newtonsoft.Json.3.5.8
    #$packageAssembly = [NupackBuilder.PackageAssembly]::new("Newtonsoft.Json", "3.5.0.0", "neutral", "30ad4fe6b2a6aeed")
    #$packageInfo = [NupackBuilder.PackageInfo]::new("Newtonsoft.Json", "3.5.8", $false, $packageAssembly)
    #$packages.AddPackageInfo($packageInfo)

    # Newtonsoft.Json.4.5.9
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Newtonsoft.Json", "4.5.0.0", "neutral", "30ad4fe6b2a6aeed")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Newtonsoft.Json", "4.5.9", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    # Newtonsoft.Json.6.0.8
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Newtonsoft.Json", "6.0.0.0", "neutral", "30ad4fe6b2a6aeed")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Newtonsoft.Json", "6.0.8", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Newtonsoft.Json.9.0.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Newtonsoft.Json", "9.0.0.0", "neutral", "30ad4fe6b2a6aeed")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Newtonsoft.Json", "9.0.1", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    # Lucene.Net.3.0.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net", "3.0.3.0", "neutral", "85089178b9ac3181")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Lucene.Net", "3.0.3", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    # Lucene.Net.Contrib.3.0.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Analyzers", "3.0.3.0", "neutral", "85089178b9ac3181")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Lucene.Net.Contrib", "3.0.3", $false, $packageAssembly)
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Core", "3.0.3.0", "neutral", "85089178b9ac3181")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.FastVectorHighlighter", "3.0.3.0", "neutral", "85089178b9ac3181")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Highlighter", "2.3.2.1", "neutral", "85089178b9ac3181")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Memory", "1.0.0.0", "neutral", "85089178b9ac3181")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Queries", "3.0.3.0", "neutral", "85089178b9ac3181")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Regex", "3.0.3.0", "neutral", "85089178b9ac3181")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.SimpleFacetedSearch", "3.0.3.0", "neutral", "85089178b9ac3181")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.Snowball", "2.0.0.1", "neutral", "85089178b9ac3181")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Lucene.Net.Contrib.SpellChecker", "3.0.3.0", "neutral", "85089178b9ac3181")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #51Degrees.mobi-core.3.2.17.2
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("FiftyOne.Foundation", "3.2.17.2", "neutral", "e0b3a8da0bbce49c")
    $packageInfo = [NupackBuilder.PackageInfo]::new("51Degrees.mobi-core", "3.2.17.2", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Antlr.3.5.0.2
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Antlr3.Runtime", "3.5.0.2", "neutral", "eb42632606e9261f")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Antlr", "3.5.0.2", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #CommonServiceLocator.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Antlr3.Runtime", "1.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("CommonServiceLocator", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #EnterpriseLibrary.Common.6.0.1304.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Practices.EnterpriseLibrary.Common", "6.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("EnterpriseLibrary.Common", "6.0.1304.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #EnterpriseLibrary.TransientFaultHandling.6.0.1304.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling", "6.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("EnterpriseLibrary.TransientFaultHandling", "6.0.1304.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #EnterpriseLibrary.TransientFaultHandling.Caching.6.0.1304.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.Caching", "6.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("EnterpriseLibrary.TransientFaultHandling.Caching", "6.0.1304.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #EnterpriseLibrary.TransientFaultHandling.Configuration.6.0.1304.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.Configuration", "6.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("EnterpriseLibrary.TransientFaultHandling.Configuration", "6.0.1304.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #EnterpriseLibrary.TransientFaultHandling.Data.6.0.1304.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.Data", "6.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("EnterpriseLibrary.TransientFaultHandling.Data", "6.0.1304.1", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #EnterpriseLibrary.TransientFaultHandling.ServiceBus.6.0.1304.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.ServiceBus", "6.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("EnterpriseLibrary.TransientFaultHandling.ServiceBus", "6.0.1304.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #EnterpriseLibrary.TransientFaultHandling.WindowsAzure.Storage.6.0.1304.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.WindowsAzure.Storage", "6.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("EnterpriseLibrary.TransientFaultHandling.WindowsAzure.Storage", "6.0.1304.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)


    #HtmlAgilityPack.1.4.9.5
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("HtmlAgilityPack", "1.4.9.5", "neutral", "bd319b19eaf3b43a")
    $packageInfo = [NupackBuilder.PackageInfo]::new("HtmlAgilityPack", "1.4.9.5", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #HtmlAgilityPack.1.4.6
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("HtmlAgilityPack", "1.4.6.0", "neutral", "bd319b19eaf3b43a")
    $packageInfo = [NupackBuilder.PackageInfo]::new("HtmlAgilityPack", "1.4.6", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.Cors.5.2.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Cors", "5.2.3.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.Cors", "5.2.3", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.Identity.Core.2.2.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.AspNet.Identity.Core", "2.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.Identity.Core", "2.2.1", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #YUICompressor.NET.2.1.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Yahoo.Yui.Compressor", "2.1.1.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("YUICompressor.NET", "2.1.1", $false, $packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Iesi.Collections", "1.0.1.0", "neutral", "aa95f207798dfdb4")
    $packageInfo.AddPackageAssembly($packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("EcmaScript.NET", "1.0.1.0", "neutral", "null")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #mongocsharpdriver.1.10.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("MongoDB.Bson", "1.10.0.62", "neutral", "f686731cfb9cc103")
    $packageInfo = [NupackBuilder.PackageInfo]::new("mongocsharpdriver", "1.10.0", $false, $packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("MongoDB.Driver", "1.10.0.62", "neutral", "f686731cfb9cc103")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #mongocsharpdriver.1.8.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("MongoDB.Bson", "1.8.3.9", "neutral", "f686731cfb9cc103")
    $packageInfo = [NupackBuilder.PackageInfo]::new("mongocsharpdriver", "1.8.3", $false, $packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("MongoDB.Driver", "1.8.3.9", "neutral", "f686731cfb9cc103")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #mongocsharpdriver.2.4.4
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("MongoDB.Driver.Legacy", "2.4.4.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("mongocsharpdriver", "2.4.4", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #MongoDB.Bson.2.4.4
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("MongoDB.Bson", "2.4.4.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("MongoDB.Bson", "2.4.4", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #MongoDB.Driver.2.4.4
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("MongoDB.Driver", "2.4.4.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("MongoDB.Driver", "2.4.4", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #MongoDB.Driver.Core.2.4.4
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("MongoDB.Driver.Core", "2.4.4.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("MongoDB.Driver.Core", "2.4.4", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    

    #SolrNet.0.4.0.4001
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("SolrNet", "0.4.0.4001", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("SolrNet", "0.4.0.4001", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #SolrNet.0.4.0-beta2 - can't be used since nuget doesn't allow creation of final packages with prereleases - and this is the one we use.
    #$packageAssembly = [NupackBuilder.PackageAssembly]::new("SolrNet", "0.4.0.2002", "neutral", "bc21753e8aa334cb")
    #$packageInfo = [NupackBuilder.PackageInfo]::new("SolrNet", "0.4.0-beta2", $true, $packageAssembly)
    #$packages.AddPackageInfo($packageInfo)

    #RazorGenerator.Mvc.2.4.9
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("RazorGenerator.Mvc", "2.0.0.0", "neutral", "7b26dc2a43f6a0d4")
    $packageInfo = [NupackBuilder.PackageInfo]::new("RazorGenerator.Mvc", "2.4.9", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #protobuf-net.2.0.0.668
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("protobuf-net", "2.0.0.668", "neutral", "257b51d87d2e4d67")
    $packageInfo = [NupackBuilder.PackageInfo]::new("protobuf-net", "2.0.0.668", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Ninject.3.2.2
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Ninject", "3.2.0.0", "neutral", "c7192dc5380945e7")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Ninject", "3.2.2", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #WebActivatorEx.2.0.6
    #$packageAssembly = [NupackBuilder.PackageAssembly]::new("WebActivatorEx", "2.0.0.0", "neutral", "7b26dc2a43f6a0d4")
    #$packageInfo = [NupackBuilder.PackageInfo]::new("WebActivatorEx", "2.0.6", $false, $packageAssembly)
    #$packages.AddPackageInfo($packageInfo)

    #WebActivatorEx.2.2.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("WebActivatorEx", "2.0.0.0", "neutral", "7b26dc2a43f6a0d4")
    $packageInfo = [NupackBuilder.PackageInfo]::new("WebActivatorEx", "2.2.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)


    #Markdown.1.14.6
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("MarkdownSharp", "1.14.5.0", "neutral", "eb89951a0d41ab86")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Markdown", "1.14.6", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Facebook.5.4.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Facebook", "5.4.1.0", "neutral", "58cb4f2111d1e6de")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Facebook", "5.4.1", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.Identity.Owin.2.2.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.AspNet.Identity.Owin", "2.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.Identity.Owin", "2.2.1", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.Mvc.5.1.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Mvc", "5.1.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.Mvc", "5.1.3", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.Mvc.5.2.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Mvc", "5.2.3.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.Mvc", "5.2.3", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.Razor.3.2.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Razor", "3.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.Razor", "3.2.3", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.WebPages.3.2.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Helpers", "3.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebPages", "3.2.3", $false, $packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.WebPages.Deployment", "3.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo.AddPackageAssembly($packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.WebPages", "3.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo.AddPackageAssembly($packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.WebPages.Razor", "3.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.WebApi.5.2.3

    #Microsoft.AspNet.WebApi.Client.5.1.2
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Net.Http.Formatting", "5.1.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Client", "5.1.2", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.WebApi.Client.5.2.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Net.Http.Formatting", "5.2.3.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Client", "5.2.3", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.WebApi.Core.5.1.2
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Http", "5.1.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Core", "5.1.2", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.WebApi.Core.5.2.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Http", "5.2.3.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Core", "5.2.3", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.WebApi.WebHost.5.1.2
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Http.WebHost", "5.1.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.WebHost", "5.1.2", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.WebApi.WebHost.5.2.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Http.WebHost", "5.2.3.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.WebHost", "5.2.3", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Web.Infrastructure.1.0.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Web.Infrastructure", "1.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Web.Infrastructure", "1.0.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.OData.5.9.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.OData", "5.9.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.OData", "5.9.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

     #Microsoft.AspNet.OData.6.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.OData", "6.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.OData", "6.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.OData.Core.6.15.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.OData.Core", "6.15.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.OData.Core", "6.15.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.OData.Core.7.2.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.OData.Core", "7.2.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.OData.Core", "7.2.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.OData.Edm.6.15.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.OData.Edm", "6.15.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.OData.Edm", "6.15.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.OData.Edm.7.2.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.OData.Edm", "7.2.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.OData.Edm", "7.2.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Owin.3.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Owin", "3.1.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Owin", "3.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Owin.Host.SystemWeb.3.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Owin.Host.SystemWeb", "3.1.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Owin.Host.SystemWeb", "3.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Owin.Security.3.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Owin.Security", "3.1.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Owin.Security", "3.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Owin.Security.ActiveDirectory.3.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Owin.Security.ActiveDirectory", "3.1.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Owin.Security.ActiveDirectory", "3.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Owin.Security.Cookies.3.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Owin.Security.Cookies", "3.1.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Owin.Security.Cookies", "3.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Owin.Security.Jwt.3.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Owin.Security.Jwt", "3.1.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Owin.Security.Jwt", "3.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Owin.Security.OAuth.3.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Owin.Security.OAuth", "3.1.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Owin.Security.OAuth", "3.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Spatial.6.15.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Spatial", "6.15.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Spatial", "6.15.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Spatial.7.2.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Spatial", "7.2.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Spatial", "7.2.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.DotNet.InternalAbstractions.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.DotNet.InternalAbstractions", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.DotNet.InternalAbstractions", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.CommandLineUtils.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.CommandLineUtils", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.CommandLineUtils", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Configuration.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Configuration", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Configuration", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Configuration.Abstractions.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Configuration.Abstractions", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Configuration.Abstractions", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Configuration.Binder.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Configuration.Binder", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Configuration.Binder", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Configuration.CommandLine.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Configuration.CommandLine", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Configuration.CommandLine", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Configuration.EnvironmentVariables.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Configuration.EnvironmentVariables", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Configuration.EnvironmentVariables", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Configuration.FileExtensions.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Configuration.FileExtensions", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Configuration.FileExtensions", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Configuration.Ini.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Configuration.Ini", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Configuration.Ini", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Configuration.Json.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Configuration.Json", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Configuration.Json", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Configuration.Xml.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Configuration.Xml", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Configuration.Xml", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.DependencyInjection.Abstractions.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.DependencyInjection.Abstractions", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.DependencyInjection.Abstractions", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.DependencyInjection.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.DependencyInjection", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.DependencyInjection", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.DependencyModel.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.DependencyModel", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.DependencyModel", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.FileProviders.Abstractions.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.FileProviders.Abstractions", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.FileProviders.Abstractions", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.FileProviders.Physical.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.FileProviders.Physical", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.FileProviders.Physical", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.FileSystemGlobbing.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.FileSystemGlobbing", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.FileSystemGlobbing", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Logging.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Logging", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Logging", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Logging.Abstractions.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Logging.Abstractions", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Logging.Abstractions", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Options.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Options", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Options", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.PlatformAbstractions.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.PlatformAbstractions", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.PlatformAbstractions", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.Extensions.Primitives.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Extensions.Primitives", "1.0.0.0", "neutral", "adb9793829ddae60")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Extensions.Primitives", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #SharpZipLib.0.86.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("ICSharpCode.SharpZipLib", "0.86.0.518", "neutral", "1b03e6acf1164f73")
    $packageInfo = [NupackBuilder.PackageInfo]::new("SharpZipLib", "0.86.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.WebApi.Cors.5.1.2
    #$packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Http.Cors", "5.1.0.0", "neutral", "31bf3856ad364e35")
    #$packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Cors", "5.1.2", $false, $packageAssembly)
    #$packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.WebApi.Cors.5.2.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Http.Cors", "5.2.3.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Cors", "5.2.3", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.Web.Optimization.1.1.3
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Web.Optimization", "1.1.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.Web.Optimization", "1.1.3", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)    

    #Microsoft.IdentityModel.Protocol.Extensions.1.0.4.403061554
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.IdentityModel.Protocol.Extensions", "1.0.40306.1554", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.IdentityModel.Protocol.Extensions", "1.0.4.403061554", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #CommonServiceLocation.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Practices.ServiceLocation", "1.0.0.0", "neutral", "59d6d24383174ac4")
    $packageInfo = [NupackBuilder.PackageInfo]::new("CommonServiceLocation", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.Collections.NonGeneric.4.0.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Collections.NonGeneric", "4.0.1.0", "neutral", "b03f5f7f11d50a3a")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.Collections.NonGeneric", "4.0.1", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.ComponentModel.Primitives.4.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.ComponentModel.Primitives", "4.1.0.0", "neutral", "b03f5f7f11d50a3a")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.ComponentModel.Primitives", "4.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.ComponentModel.TypeConverter.4.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.ComponentModel.TypeConverter", "4.1.0.0", "neutral", "b03f5f7f11d50a3a")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.ComponentModel.TypeConverter", "4.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.Interactive.Async.3.1.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Interactive.Async", "3.0.3000.0", "neutral", "94bc3704cddfc263")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.Interactive.Async", "3.1.1", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.Interactive.Async.Providers.3.1.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Interactive.Async.Providers", "3.0.1000.0", "neutral", "94bc3704cddfc263")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.Interactive.Async.Providers", "3.1.1", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.IO.4.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.IO", "4.1.0.0", "neutral", "b03f5f7f11d50a3a")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.IO", "4.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.Reflection.4.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Reflection", "4.1.0.0", "neutral", "b03f5f7f11d50a3a")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.Reflection", "4.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.Runtime.4.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Runtime", "4.1.0.0", "neutral", "b03f5f7f11d50a3a")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.Runtime", "4.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.Runtime.Extensions.4.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Runtime.Extensions", "4.1.0.0", "neutral", "b03f5f7f11d50a3a")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.Runtime.Extensions", "4.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.Runtime.InteropServices.4.1.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Runtime.InteropServices", "4.1.0.0", "neutral", "b03f5f7f11d50a3a")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.Runtime.InteropServices", "4.1.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.IdentityModel.Tokens.Jwt.4.0.2.206221351
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.IdentityModel.Tokens.Jwt", "4.0.20622.1351", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.IdentityModel.Tokens.Jwt", "4.0.2.206221351", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.IdentityModel.Tokens.Jwt.4.0.4.403061554
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.IdentityModel.Tokens.Jwt", "4.0.40306.1554", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.IdentityModel.Tokens.Jwt", "4.0.4.403061554", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.IdentityModel.Tokens.Jwt.5.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.IdentityModel.Tokens.Jwt", "5.0.0.127", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.IdentityModel.Tokens.Jwt", "5.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)    

    #System.Net.Http.4.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Net.Http", "4.0.0.0", "neutral", "b03f5f7f11d50a3a")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.Net.Http", "4.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #System.Runtime.InteropServices.RuntimeInformation.4.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Runtime.InteropServices.RuntimeInformation", "4.0.0.0", "neutral", "b03f5f7f11d50a3a")
    $packageInfo = [NupackBuilder.PackageInfo]::new("System.Runtime.InteropServices.RuntimeInformation", "4.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Microsoft.AspNet.WebApi.Extensions.Compression.Server.2.0.6
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.AspNet.WebApi.Extensions.Compression.Server", "2.0.0.0", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.AspNet.WebApi.Extensions.Compression.Server", "2.0.6", $false, $packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("System.Net.Http.Extensions.Compression.Core", "2.0.0.0", "neutral", "null")
    $packageInfo.AddPackageAssembly($packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    # WebGrease.1.6.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("WebGrease", "1.6.5135.21930", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("WebGrease", "1.6.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #StackExchange.Redis.StrongName.1.0.488
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("StackExchange.Redis.StrongName", "1.0.316.0", "neutral", "c219ff1ca8c2ce46")
    $packageInfo = [NupackBuilder.PackageInfo]::new("StackExchange.Redis.StrongName", "1.0.488", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Remotion.Linq.2.1.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Remotion.Linq", "2.1.0.0", "neutral", "fee00910d6e5f53b")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Remotion.Linq", "2.1.1", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Mvp.Xml.2.3.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Mvp.Xml", "2.3.0.0", "neutral", "6ead800d778c9b9f")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Mvp.Xml", "2.3.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #Owin.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Owin", "1.0.0.0", "neutral", "f0ebd12fd5e55cc5")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Owin", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

        
    return $packages
}

Function Add-ModulesThirdPartyPackages()
{
    $packages  = Add-PlatformThirdPartyPackages    

    # Heijden.Dns.1.0.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Heijden.Dns", "1.0.0.1", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Heijden.Dns", "1.0.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #AntiXssLibrary.4.2.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("AntiXssLibrary", "4.2.0.0", "neutral", "d127efab8a9c114f")
    $packageInfo = [NupackBuilder.PackageInfo]::new("antixss", "4.2.1", $false, $packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("HtmlSanitizationLibrary", "4.2.0.0", "neutral", "d127efab8a9c114f")
    $packageInfo.AddPackageAssembly($packageAssembly)

    $packages.AddPackageInfo($packageInfo)

    #AntiXssLibrary.4.3.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("AntiXssLibrary", "4.3.0.0", "neutral", "d127efab8a9c114f")
    $packageInfo = [NupackBuilder.PackageInfo]::new("antixss", "4.3.0", $false, $packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("HtmlSanitizationLibrary", "4.3.0.0", "neutral", "d127efab8a9c114f")
    $packageInfo.AddPackageAssembly($packageAssembly)

    $packages.AddPackageInfo($packageInfo)

    #microsoft.crmsdk.coreassemblies.7.1.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Crm.Sdk.Proxy", "7.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.CrmSdk.CoreAssemblies", "7.1.1", $false, $packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Xrm.Sdk", "7.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo.AddPackageAssembly($packageAssembly)

    $packages.AddPackageInfo($packageInfo)

    #microsoft.crmsdk.coreassemblies.8.2.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Crm.Sdk.Proxy", "8.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.CrmSdk.CoreAssemblies", "8.2.0", $false, $packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Xrm.Sdk", "8.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo.AddPackageAssembly($packageAssembly)

    $packages.AddPackageInfo($packageInfo)

    # Microsoft.CrmSdk.Deployment.7.1.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Xrm.Sdk.Deployment", "7.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.CrmSdk.Deployment", "7.1.1", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    # Microsoft.CrmSdk.Deployment.8.2.0
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Xrm.Sdk.Deployment", "8.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.CrmSdk.Deployment", "8.2.0", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)
        
    #Microsoft.IdentityModel.6.1.7600.16394
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.IdentityModel", "3.5.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.IdentityModel", "6.1.7600.16394", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    #unity.2.1.505.2
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Practices.Unity", "2.1.505.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.Practices.Unity", "2.1.505.2", $false, $packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Practices.Unity.Configuration", "2.1.505.0", "neutral", "31bf3856ad364e35")
    $packageInfo.AddPackageAssembly($packageAssembly)

    $packages.AddPackageInfo($packageInfo)

    # Microsoft.CrmSdk.Extensions.7.1.0.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Xrm.Client.CodeGeneration", "7.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo = [NupackBuilder.PackageInfo]::new("Microsoft.CrmSdk.Extensions", "7.1.0.1", $false, $packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Xrm.Client", "7.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo.AddPackageAssembly($packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Xrm.Portal", "7.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo.AddPackageAssembly($packageAssembly)

    $packageAssembly = [NupackBuilder.PackageAssembly]::new("Microsoft.Xrm.Portal.Files", "7.0.0.0", "neutral", "31bf3856ad364e35")
    $packageInfo.AddPackageAssembly($packageAssembly)

    $packages.AddPackageInfo($packageInfo)

    #ZXing.2.1.1
    $packageAssembly = [NupackBuilder.PackageAssembly]::new("zxing", "1.0.4727.18517", "neutral", "null")
    $packageInfo = [NupackBuilder.PackageInfo]::new("ZXing", "2.1.1", $false, $packageAssembly)
    $packages.AddPackageInfo($packageInfo)

    return $packages
}

Function UnZipDLLFiles (
  [Parameter(Mandatory=$true)][string]$installPath,
  [Parameter(Mandatory=$true)][string]$ArchivePath,  
  [Parameter(Mandatory=$true)][string]$TargetPath, 
  [Parameter(Mandatory=$true)][string]$Filter,  
  [switch]$SuppressOutput,
  [Parameter(Mandatory=$false)][string]$NugetFeed = "https://www.nuget.org/api/v2/",
  [Parameter(Mandatory=$true)][string]$nugetFullPath,
  [switch]$doNotDeleteTargetPath
)
{
    $deleteTargetPath = $true
    if($doNotDeleteTargetPath)
    {
        $deleteTargetPath = $false
    }
  
  if (!(Test-Path -Path $ArchivePath))
  {
    Write-Log -Message "The archive to extract was not found: $ArchivePath" -Level "Error"
  }
    
  if(($deleteTargetPath -eq $true) -and (Test-Path -Path $TargetPath ))
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

  Write-Log "$unzipcommand"

  if ($SuppressOutput)
  {
    # Write-Log -Message "Extracting files from $ArchivePath to $TargetPath..." -Program "7z"
    iex $unzipcommand | Out-Null
    # Write-Log -Message "Done Extracting files from $ArchivePath to $TargetPath..." -Program "7z"
  }
  else
  {
    iex $unzipcommand
  }  
}

Function UnZipFiles (
  [Parameter(Mandatory=$true)][string]$installPath,
  [Parameter(Mandatory=$true)][string]$ArchivePath,  
  [Parameter(Mandatory=$true)][string]$TargetPath, 
  [switch]$SuppressOutput,
  [Parameter(Mandatory=$false)][string]$NugetFeed = "https://www.nuget.org/api/v2/",
  [Parameter(Mandatory=$true)][string]$nugetFullPath,
  [switch]$doNotDeleteTargetPath
)
{
    $deleteTargetPath = $true
    if($doNotDeleteTargetPath)
    {
        $deleteTargetPath = $false
    }
  
  if (!(Test-Path -Path $ArchivePath))
  {
    Write-Log -Message "The archive to extract was not found: $ArchivePath" -Level "Error"
  }
    
  if(($deleteTargetPath -eq $true) -and (Test-Path -Path $TargetPath ))
  {
    $child_items = ([array] (Get-ChildItem -Path $TargetPath -Recurse -Force))
        if ($child_items) 
        {
            #$null = $child_items | Remove-Item -Force -Recurse | Out-Nul
            foreach($child_item in $child_items)
            {
                if(Test-Path -Path $child_item)
                {
                    $null = Remove-Item $child_item -Force -Recurse | Out-Null
                }       
            }


        }
        if(Test-Path -Path $TargetPath)
        {
            $null = Remove-Item $TargetPath -Force -Recurse | Out-Null
        }
  }
  
  if (!(Test-Path -Path $TargetPath))
  {
    New-Item -Path $TargetPath -ItemType directory | Out-Null
  }
  
  $FileNameNoExtension = [io.path]::GetFileNameWithoutExtension($ArchivePath)
  [string]$pathTo7z = $(Get-7z -installPath $installPath -nugetFullPath $nugetFullPath -NugetFeed $NugetFeed)
  $unzipargs = ' x "' + $ArchivePath + '" -o"' + $TargetPath + '" -y'
  $unzipcommand = "& '$pathTo7z'" + $unzipargs

  Write-Log "$unzipcommand"

  if ($SuppressOutput)
  {
    # Write-Log -Message "Extracting files from $ArchivePath to $TargetPath..." -Program "7z"
    iex $unzipcommand | Out-Null
    # Write-Log -Message "Done Extracting files from $ArchivePath to $TargetPath..." -Program "7z"
  }
  else
  {
    iex $unzipcommand
  }  
}
