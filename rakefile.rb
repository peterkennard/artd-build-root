myDir = File.dirname(__FILE__);
require "#{myDir}/build-options.rb"

require "rakish/GitModule"

module Rakish

myDir = File.dirname(__FILE__);
cfg = BuildConfig("root");

task :libCppSetup => [] do
	Git.clone("git.livingwork.com:/home/artd/newartd/artdlib-cpp", "#{myDir}/artdlib-cpp");
end

task :setup => [:libCppSetup] do
	puts "setup complete."
end

subdirs = [
    "./artdlib-cpp",
    "./third-party"
];


if(cfg.targetPlatform =~ /MacOS/ )
    task :build => [ :includes ] do
        system("CMake --build build --config DEBUG");
    end
end


Rakish.Project(
    :includes=>[Rakish::CppProjectModule, Rakish::GitModule ],
	:name 		=> "artd-lib",
	:id         => "371FD2F5-ED71-0114-8F52-D889C786B495",
	:dependsUpon => subdirs,
    :dependsUponOpt => [ './artdlib-test' ]
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
