# This repository is the root of the artlib build.
### first you clone this install ruby and rake and then do: "rake setup" 

## Windows

* You mush have ruby and rake installed, all the rest is built.
* default project generator is "Visual Studio 16 2019"
## Mac

* You must have libpng installed via "brew install libpng" for graphics items
* default project generator is "Xcode"

### ruby rake Build targets

**Run from root directory** after cloning this root folder.

* **"rake setup"** downloads base subdirectories
   * Must be done as a single target on command line ie: "rake setup" NOT "rake setup someOtherTask"

* **"rake vendorLibs"** Downloads and builds third party libraries specified in "third-party"

* **"rake genProject"** Generate an IDE or buildable project
  * Outputs to "./build" 
  * vendorLibs is a dependency. ( this will do both )  
  * The Cmake generator for creating the project is specified in "./build-options.rb" 

* **"rake resources"** Copy or generate resources for the apps to the runtime area in ./build/bin
  * outputs to "./build/bin/resources" 

* **"rake cleanAll"** Delete the build directory, and all the third party library builds.
   * Will NOT delete third party source or library download caches, only the build output 