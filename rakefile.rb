myDir = File.dirname(__FILE__);
require "#{myDir}/build-options.rb"

require "rakish/GitModule"

module Rakish

myDir = File.dirname(__FILE__);
cfg = BuildConfig("root");

task :libCppSetup => [] do
	Git.clone("https://github.com/peterkennard/artdlib-cpp.git", "#{myDir}/artdlib-cpp");
	cd "#{myDir}/artdlib-cpp" do
		system("rake setup");
	end
# this just for importing old stuff
	Git.clone("git.livingwork.com:/home/git/artdlib-cpp-new", "#{myDir}/artdlib-cpp-new");
end

task :thirdPartySetup do
    Git.clone("git.livingwork.com:/home/artd/newartd/third-party.git", "#{myDir}/third-party");
	cd "#{myDir}/third-party" do
		system("rake setup");
	end
end

task :testSetup => [ :thirdPartySetup, :libCppSetup ] do
    Git.clone("git.livingwork.com:/home/artd/newartd/artdlib-test", "#{myDir}/artdlib-test");
	cd "#{myDir}/artdlib-test" do
		system("rake setup");
	end
end

task :setup => [:libCppSetup, :testSetup ] do
	puts "setup complete."
end

subdirs=[]
unless (ARGV.length > 0 && (ARGV[0] =~ /setup/))
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
	:id         => "371FD2F5-ED71-0114-8F52-D889C786B495",
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

end # Rakish
