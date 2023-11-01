# Windows Sandbox for Basic SUIFW Tests

## Quick startup

Just run / double-click on  `startupSandbox.bat`

## Prerequisites

Any Windows machine able to run a Windows Sandbox

## Conventions

### Folders

|Folder|Remapped to disk|Mapped to host folder|Notes
|-|-|-|-
|`c:\k`|`K:`|`${env:currentDirectory}/../../Installation/Artifacts/`|Installation artifacts folder`
|`c:\l`|`L:`|`${env:currentDirectory}/../../Installation/Licenses/`|Licenses folder. Expand here the zip file received from Software AG logistics department. Never commit these, the licenses are to be considered as "secrets"
|`c:\p`|`P:`|`${env:currentDirectory}/../../../`|This git repo project folder
|`c:\s`|`S:`|`${env:currentDirectory}/inside/`|Local sandbox guest folders
|`c:\x`|`X:`|Not mapped|Installation home disk according to Markem Imaje's conventions
|`c:\y`|`Y:`|`${env:currentDirectory}/logs/`|Logging volume according to Markem Imaje's conventions
