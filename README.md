# PhotoScrollerNetwork2
Demo app that uses the new PhotoScrollerSwiftPackage, updated PhotoScrollerNetwork code

1) Add the Package using Xcode->File->Packages with the URL of https://github.com/dhoerl/PhotoScrollerSwiftPackage

2) Open the Build Phases, and in the Package shown in the left file pane, drag the Libraries/libturbojpeg.a file into the link
   section. It will appear just above the PhotoScrollerSwiftPackage that should already be there

3) In Build settings, under library search paths, add:
   "$(BUILD_DIR)/../../SourcePackages/checkouts/PhotoScrollerSwiftPackage/Libraries"

