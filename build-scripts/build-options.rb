myDir = File.dirname(File.expand_path(__FILE__));
require "#{myDir}/ensure-rakish.rb"

require "rakish"
require "rakish/CppProjects.rb";
require "rakish/JavaProjects.rb";
require "rakish/IntellijConfig.rb";
require "rakish/GitModule";

Rakish.addToRubySearchPath("#{myDir}");

# standard targets for this build tree

task :vendorLibs do
end

task :cmakeGen do
end

task :genProject => [ :vendorLibs, :cmakeGen ] do
end

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

Rakish.Configuration :include=>[ IntellijConfig, CppProjectConfig, JavaProjectConfig] do |cfg|

	myDir = File.dirname(File.expand_path(__FILE__));

    cfg.thirdPartyPath = File.expand_path("#{myDir}/../third-party");
    cfg.artdlibPath = File.expand_path("#{myDir}/../native-libs");

    # set up global target dependencies.

    log = Rakish.log;

	cfg.verbose = false;
	cfg.artdRoot = File.expand_path("#{myDir}/..");

    if(cfg.intellij) # we are running this from an intellij UI
        ij = cfg.intellij
		cfg.buildDir = ij.outputPath;
    else
		cfg.buildDir = "#{cfg.artdRoot}/build";
    end
#    cfg.resourceDir = "#{cfg.buildDir}/production/.didi";

    cfg.java_home = "#{ENV['JAVA_HOME']}";

	cfg.ant_home = ENV['ANT_HOME'] || '/usr/share/ant';

	java = cfg.java;

    if(cfg.intellij) # we are running this from an intellij UI
        java.addJavacFlags(cfg.intellij.javacFlags);
    else
        java.addJavacFlags("-Xlint:unchecked -encoding ISO-8859-1");
    end

    java.addJarSearchPath("#{myDir}/../third-party-jars");
	java.addClassPaths( 'log4j-1.2.17.jar' );

#     # tomcat deployment options
#
# 	tomcatConfig = BuildConfig.new
# 	tomcatConfig.enableNewFields do |tc|
#     	tc.managerURL = "http://localhost:8081/manager/text";
#     	tc.managerUsername = "admin";
#     	tc.managerPassword = "tomcat4521";
# 	end

#    cfg.tomcatConfig = tomcatConfig;

# test server config
#	tomcatConfig = BuildConfig.new
#	tomcatConfig.enableNewFields do |tc|
#    	tc.managerURL = "http://localhost:8082/manager/text";
#    	tc.managerUsername = "admin";
#    	tc.managerPassword = "tomcat4521";
#	end

    cpp = cfg.cpp;

    cpp.cppDefine('ARTD_SUPPORT_STD_STRING');
    # this is likely a bit obsolete as we are now delegating a lot more to CMake
    cpp.setToolchain('rakish/CMakeCppTools.rb', "CMakeBased" );

    if(cpp.targetPlatform =~ /Windows/)

        cfg.nativeLibDir = "#{cfg.buildDir}/lib/Debug";
        cfg.binDir = "#{cfg.buildDir}/bin/Debug";
        cpp.setCMakeGenerator("Visual Studio 17 2022");

    elsif(cpp.targetPlatform =~ /Mac/ )

        # override defaults here for the XCode build
        cfg.nativeLibDir = "#{cfg.buildDir}/lib/Debug";
        cfg.binDir = "#{cfg.buildDir}/bin/Debug";
        cpp.setCMakeGenerator("Xcode");
    end

end

end # Rakish
