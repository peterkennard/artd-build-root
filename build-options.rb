myDir = File.dirname(File.expand_path(__FILE__));
require "#{myDir}/ensure-rakish.rb"

require "rakish";
require "rakish/GitModule";
require "rakish/CppProjects.rb";
require "rakish/JavaProjects.rb";


if(File.exists? "#{myDir}/../build-options.rb")
    require "#{myDir}/../build-options.rb"
end

require "rakish"
require "rakish/CppProjects.rb";
require "rakish/JavaProjects.rb";

module Rakish

log.debug("loading build-options");
myDir = File.dirname(File.expand_path(__FILE__));
addToRubySearchPath("#{myDir}/build-scripts");

# standard targets for this build tree

task :vendorLibs do
end

task :cmakeGen do
end

task :genProject => [ :vendorLibs, :cmakeGen ] do
end

Rakish.Configuration :include=>[ CppProjectConfig, JavaProjectConfig ] do |cfg|

    cfg.verbose = false;
    cfg.buildDir = "#{myDir}/build";

    cfg.resourceDir = "#{cfg.buildDir}/production/.artd";
    cfg.java_home = ENV['JAVA_HOME'];
    cpp = cfg.cpp;

    cpp.cppDefine('ARTD_SUPPORT_STD_STRING');
    # this is likely a bit obsolete as we arenow delagating a lot more to CMake
    cpp.setToolchain('rakish/CMakeCppTools.rb', "CMakeBased" );

    if(cpp.targetPlatform =~ /Windows/)

        cpp.setCMakeGenerator("Visual Studio 17 2022");

    elsif(cpp.targetPlatform =~ /Mac/ )

        # override defaults here for the XCode build
        cfg.nativeLibDir = "#{cfg.buildDir}/lib/Debug";
        cfg.binDir = "#{cfg.buildDir}/bin/Debug";

        cpp.setCMakeGenerator("Xcode");

        # cpp.setCMakeGenerator("Unix Makefiles");
    end
end

end # Rakish
