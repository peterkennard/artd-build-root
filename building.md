# Building It All

## Windows

You mush have ruby and rake installed, all the rest is built
The build target genProject will generate a Visual Studio 2019 project in the ./build folder

## Mac

You must have libpng installed via "brew install libpng"
The build target genProject will generate an Xcode project in the ./build folder

### Common Build targets

From the root directory after cloning this root folder.

* "rake setup"  # downloads base subdirectories
* "rake genProject" # will download needed third party source, build it, and generate an IDE project
* "rake resources" # will copy or generate resources for the apps to the runtime area in ./build/bin