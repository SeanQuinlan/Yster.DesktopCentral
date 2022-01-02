@{
    Path                     = "Yster.DesktopCentral.psd1"
    OutputDirectory          = "..\bin\Yster.DesktopCentral"
    Prefix                   = '.\_PrefixCode.ps1'
    SourceDirectories        = 'Private', 'Public'
    PublicFilter             = 'Public\*.ps1'
    VersionedOutputDirectory = $true
}
