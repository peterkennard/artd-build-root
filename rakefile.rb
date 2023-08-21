myDir = File.dirname(__FILE__);
require "#{myDir}/build-options.rb"

require "rakish/GitModule"

module Rakish

myDir = File.dirname(__FILE__);
cfg = BuildConfig("root");

# You can disable password authentication with -o PasswordAuthentication=no. Full command would be:
# ssh -nT -o PasswordAuthentication=no <host>  # n no stdout output, T no tty input.
# GIT_SSH_COMMAND=ssh -o PasswordAuthentication=no'

task :libCppSetup => [] do
	Git.clone("https://github.com/peterkennard/artdlib-cpp.git", "#{myDir}/artdlib-cpp");
	cd "#{myDir}/artdlib-cpp" do
		system("rake setup");
	end
    # this just for importing old stuff
	Git.cloneIfAvailable("git.livingwork.com:/home/git/artdlib-cpp-new", "#{myDir}/artdlib-cpp-new");
end

task :thirdPartySetup do
    Git.clone("https://github.com/peterkennard/third-party.git", "#{myDir}/third-party");
	cd "#{myDir}/third-party" do
		system("rake setup");
	end
end

task :testSetup => [ :thirdPartySetup, :libCppSetup ] do
    if(Git.cloneIfAvailable("git.livingwork.com:/home/artd/newartd/artdlib-test", "#{myDir}/artdlib-test"))
        cd "#{myDir}/artdlib-test" do
            system("rake setup");
        end
	end
end

task :setup => [:libCppSetup, :testSetup ] do
	puts "setup complete."
end

subdirs=[]

# TODO: make some sort of "ignoreDependencies" or isSetupTask function
unless inSetupTask()
    subdirs = [
        './artdlib-cpp',
        './third-party',
        './artdlib-test'
    ];
end

if(cfg.targetPlatform =~ /MacOS/ )
    task :build => [ :includes ] do
        system("CMake --build build --config DEBUG");
    end
end

Rakish.Project(
    :includes=>[Rakish::CppProjectModule, Rakish::GitModule ],
	:name 		=> "artd-lib",
    :dependsUponOpt => subdirs
) do

    export task :cleanAll => sourceSubdir do |t|
        FileUtils.rm_rf(buildDir);  # remove recursive
    end

    export task :genProject do
        FileUtils.mkdir_p("./build")
        FileUtils.cd("./build") do
            cmd = "#{cmakeCommand} -G \"#{cMakeGenerator}\""
            cmd += " ..";
            system(cmd);
        end
    end

    setupCppConfig :targetType =>'NONE' do |cfg|
    end

end # end project artd-lib

task :nativeLibs => [ :vendorLibs, :autogen, :genProject, :build ] do
end

end # Rakish
