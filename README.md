# Get-DigitalObjects

This is a PowerShell tool designed to batch-download digital objects from an [AtoM](https://www.accesstomemory.org/en/) archive. URIs for digital objects are specified in an input CSV, possibly from an AtoM export CSV. The CSV should have a single digital object URI for each row in the `digitalObjectURI` column. You must have login access to the targeted AtoM, since you are required to log in to download the raw digital objects.

[First, make sure you have a PowerShell profile](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7#how-to-create-a-profile).

For those who are not frequent PowerShell users, you may need to update your execution policy if you have never done so. Without having an Unrestricted execution policy, you will not be able to run the deploy script and PowerShell may not be able to load your profile. To update your execution policy, run:

```PowerShell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
```

After you have a profile and an appropriate execution policy set, download or clone this repository, and run the included `DeployModule.ps1` script at the top level of this repository. To run the script, open up PowerShell in the same folder as the `DeployModule.ps1` script, and enter the command (optionally using the `-AutoAddImport` option)

```PowerShell
.\DeployModule.ps1 -AutoAddImport
```

This deploy script will copy the code for the AtomDigitalObjectDownloader module into your PowerShell Modules folder, and will add a new line to your profile that tells PowerShell to import the code when you launch PowerShell in the future. If you would prefer to manually edit your profile or otherwise do not want the deploy script to touch your profile file, you can forgo the `-AutoAddImport` option and manually add the line `Import-Module AtomDigitalObjectDownloader` to your profile. If you choose to go this route, the deploy script will let you know where your profile is, in case you forget.

After deploying the code and adding the import statement manually in your profile if you chose to do so, you will need to close and re-open PowerShell to have access to the new command: `Get-DigitalObjects`.

## How to Use It

For each call to `Get-DigitalObjects`, it is necessary to pass it a CSV, and the base URL to the AtoM instance. The input CSV must either have a column named digitalObjectURI or digitalObjectPath. The CSV may also have other columns, but if any columns exist more than once in the file, it will fail.

Assuming you have a properly formatted CSV at `C:\Users\you\digitalObjects.csv`, and your AtoM is accessible at `https://youratom.com`, you can download the files with:

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

`Get-DigitalObjects` is tested using Pester 4. To run the tests, you must have Pester 4 installed. These are useful resources for finding out how to install it:

- [Pester Installation Documentation](https://pester.dev/docs/introduction/installation)
- [PowerShell Gallery - Pester](https://www.powershellgallery.com/packages/Pester/4.6.0)

You should install version 4.6.0 or later.

To run the tests, make sure your PowerShell is in the same folder as the deploy script and this README. Then, use the command:

```PowerShell
Invoke-Pester AtomDigitalObjectDownloader
```
