# Get-DigitalObjects

This is a PowerShell tool designed to batch-download digital objects from an [AtoM](https://www.accesstomemory.org/en/) archive. URIs for digital objects are specified in an input CSV, possibly from an AtoM export CSV. The CSV should have a single digital object URI for each row in the `digitalObjectURI` column. You must have login access to the targeted AtoM, since you are required to log in to download the raw digital objects.

## Installation

### Prerequisites

1. Ensure you are running at least PowerShell version 5.1. The module supports PowerShell versions 5.1 through to 7.0. You can check the version by running `$PSVersionTable.PSVersion` in PowerShell.

2. [Make sure you have a PowerShell profile](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7#how-to-create-a-profile). For the uninitiated, a PowerShell profile is simply a file in your Documents folder, nothing more complicated.

3. On Windows, your script execution policy must be set to `Unrestricted`. If your execution policy is not `Unrestricted`, you may run into installation issues. You can see what your execution policy is by using `Get-ExecutionPolicy`. To update your execution policy, open PowerShell and run:

   `Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Force`

### Easy Install

This module is hosted on the [PowerShell Gallery](https://www.powershellgallery.com/packages/AtomDigitalObjectDownloader/0.0.1) and can be installed with `PowerShellGet`.

If you have never installed `AtomDigitalObjectDownloader`, run this command (the line starting with # does not need to be executed):

```powershell
# NOTE: If asked to trust packages from the PowerShell Gallery, answer yes to continue installation
PowershellGet\Install-Module AtomDigitalObjectDownloader -Scope CurrentUser -Force
```

If you have installed it before and want to update the module, run this command:

```powershell
PowerShellGet\Update-Module AtomDigitalObjectDownloader
```

After installing, it is recommended to import the module in your PowerShell profile. You may skip this step if you *really* don't want to do it.

To import the module in your profile, you will need to add the line `Import-Module AtomDigitalObjectDownloader` to your profile. To do it automatically, use:

```powershell
Add-Content $Profile "`nImport-Module AtomDigitalObjectDownloader" -NoNewLine
```

If you want to do it manually, open your profile with `notepad $Profile` and add the line `Import-Module AtomDigitalObjectDownloader` anywhere in the file.

### Manual Install for Developers

If you are a developer and are interested in modifying this module, there is a deploy script included in this repo that you don't get when you install via the Powershell Gallery. The deploy script is extremely useful for quickly updating the module code on your computer. Anytime you change one of the files, you can re-run the deploy script and the updated files will be deployed to your Modules folder.

To manually install the code, download or clone this repository, and run the included `DeployModule.ps1` script at the top level of this repository. To run the script, open up PowerShell in the same folder as the `DeployModule.ps1` script, and enter the command (optionally using the `-AutoAddImport` option):

```PowerShell
.\DeployModule.ps1 -AutoAddImport
```

This deploy script will copy the code for the `AtomDigitalObjectDownloader` module into your PowerShell Modules folder, and will add a new line to your profile that tells PowerShell to import the code when you launch PowerShell in the future. If you would prefer to manually edit your profile or otherwise do not want the deploy script to touch your profile file, you can forgo the `-AutoAddImport` option and manually add the line `Import-Module AtomDigitalObjectDownloader` to your profile. If you choose to go this route, the deploy script will let you know where your profile is, in case you forget.

## Using the Script

Once you've installed the module, you will have access to a command called `Get-DigitalObjects`. This is the command you'll use to download objects from an AtoM archive.

`Get-DigitalObjects` requires two things to start downloading objects:

1. A CSV exported from AtoM. This CSV must have a column named `digitalObjectURI` or `digitalObjectPath` with URLs to digital objects.
2. The base URL to your AtoM instance.

Let's assume you have a properly formatted CSV exported from AtoM at `C:\Users\you\digitalObjects.csv`, and your AtoM is accessible at `https://youratom.com`. Then, you can download the files in the CSV with:

```PowerShell
Get-DigitalObjects -CsvFile C:\Users\you\digitalObjects.csv -AtomUrl https://youratom.com
```

You will be required to log in to AtoM using your email and password to start downloading files.

Digital objects are downloaded to a folder called `Digital Objects` in the current folder by default. You may override this behaviour by specifying a `DestinationFolder`. To download all of the files into a folder called `Objects` in your downloads folder, you can do something like:

```PowerShell
Get-DigitalObjects -CsvFile C:\Users\you\digitalObjects.csv -AtomUrl https://youratom.com -DestinationFolder C:\Users\you\Downloads\Objects\
```

If you would prefer to compress all of the objects after they are downloaded into a zip archive, use the `-Compress` option:

```PowerShell
Get-DigitalObjects -CsvFile C:\Users\you\digitalObjects.csv -AtomUrl https://youratom.com -Compress
```

You may need to log into an F5 load balancer to get to AtoM. To do so, specify the `-RequireF5Login` option. You will be required to provide F5 credentials before providing your AtoM credentials if this option is specified.

### Other Parameters

You must always use the `-CsvFile` and `-AtomUrl` parameters, but there are a number of other optional parameters you can use to have finer control over the operation of `Get-DigitalObjects`. These are:

`-DestinationFolder [String]`: A custom-named folder you would like to download the files into. If the folder already exists and has files in it, the files will not be downloaded.

`-Compress`: Compress the folder into a zip when it is done downloading. Removes the old folder if the zip archive is created successfully.

`-RequireF5Login`: Log in to an F5 load balancer before accessing the AtoM archive.

## Testing

`Get-DigitalObjects` is tested using Pester 4. To run the tests, you must have Pester 4 installed. Pester can be complicated to get up and running, so I will not mention here how to install it since this is not the Pester documentation. These are useful resources for finding out how to install it:

- [Pester Installation Documentation](https://pester.dev/docs/introduction/installation)
- [PowerShell Gallery - Pester](https://www.powershellgallery.com/packages/Pester/4.6.0)

You should install version 4.6.0 or later.

To run the tests, make sure your PowerShell is in the same folder as the deploy script and this README. Then, use the command:

```PowerShell
Invoke-Pester AtomDigitalObjectDownloader
```
