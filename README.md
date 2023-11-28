# This repository is the root of the artd-lib build <br> and the artd-gpu-engine.


### First you clone artd-build-root then ensure ruby and rake are present, and then do: "rake setup"<br><BR>The build scripts do not work on ruby 3.x.x but require 2.x.x  Ruby 2.6.10 is what is installed by default on MacOS Ventura.

## Mac

* You must have libpng installed via "brew install libpng" for graphics items
* default project generator is "Xcode"

## Windows ( not tested in a while )

* You mush have ruby and rake installed, all the rest is built.
* default project generator is "Visual Studio 17 2022"

### ruby rake Build targets

**Run these from this root directory** after cloning this root folder.

* **"rake setup"** downloads base subdirectories
   * Must be done as a single target on command line ie: "rake setup" NOT "rake setup someOtherTask"

* **"rake vendorLibs"** Downloads and builds third party libraries specified by stubs in "third-party"

* **"rake genProject"** Generate an IDE or buildable project using CMake
  * Outputs to "./build" 
  * vendorLibs is a dependency. ( this will do both )  
  * The Cmake generator for creating the project is specified in "./build-scripts/build-options.rb" 

* **"rake resources"** Copy or generate resources for the apps to the runtime area in ./build/bin
  * outputs to "./build/bin/resources" 

* **"rake cleanAll"** Delete the build directory, and all the third party library builds.
   * Will NOT delete third party source or library download caches, only the build output 
