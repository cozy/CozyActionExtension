# CozyActionExtension
```
$ cordova prepare
$ open Cozy\ Drive.xcworkspace
```
- Click on the project file, then add a target: iOS Action Extension (when prompted to add scheme, say yes)
- Name it CozyActionExtension, save it in the project folder (sibling of Cozy Drive.xcworkspace)
- Select CozyActionExtension target, Build Settings tab, search for "Asset":
- Field "Asset Catalog App Icon Set Name" => put "AppIcon"
- Field "Asset Catalog Launch Image Set Name" => remove "LaunchImage"
- Quit Xcode, then remove the CozyActionExtension folder
- Now clone this repo w/ git:
```
$ git clone https://github.com/maestun/CozyActionExtension.git
$ open Cozy\ Drive.xcworkspace
```
- In project explorer, select CozyActionExtension group, right click and Add Files to Cozy Drive
- Select CozyActionExtension.xcassets

Now you should be able to build the extension and debug.
