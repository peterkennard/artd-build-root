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

task :javaLibs => [] do

    # super hack for now should be gradleized for version control.
	Git.cloneIfAvailable('git.didi.co:/home/didi/Pool_1/third-party-jars', "#{myDir}/third-party-jars" );

	artdLibs=[
		'artd-util',
		'artd-vecmath',
		'artd-bml-base',
		'artd-bml-interpreter',
		'artd-bml-generator',
		'artd-bml-net',
		'artd-bml-servlet',
		'artd-net',
		'artd-uiscene',
	];

	artdLibs.each do |lib|
		localDir = "#{myDir}/artdlib-java/#{lib}";
		remoteDir = "git.livingwork.com:/home/git/artd/#{lib}.git";
		if(Git.cloneIfAvailable(remoteDir, localDir))
            # setup remote branch
            remoteDir = "git.livingwork.com:/home/didi/Pool_1/lib/artd/#{lib}.git";
            FileUtils.cd localDir do
               begin
                   system("git remote add z_artd -f -m master #{remoteDir}");
               rescue
               end
            end
        end
	end
end


task :setup => [:javaLibs, :libCppSetup, :testSetup ] do
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

task :build => [ :includes ] do
    system("CMake --build build --config DEBUG");
end

Rakish.Project(
    :includes=>[Rakish::CppProjectModule, Rakish::GitModule ],
	:name 		=> "artd-lib",
    :dependsUponOpt => subdirs
) do

    export task :cleanAll => sourceSubdir do |t|
        FileUtils.rm_rf(buildDir);  # remove recursive
    end

    task :runConfigs do
        if(targetPlatform =~ /MacOS/)
            FileUtils.mkdir_p ("#{buildDir}/artdlib.xcodeproj/xcshareddata/xcschemes");
            FileUtils.cp_r( "#{projectDir}/build-scripts/xcodeproj/xcshareddata/xcschemes/.", "#{buildDir}/artdlib.xcodeproj/xcshareddata/xcschemes");
        end
    end

    task :projectFiles do
        FileUtils.mkdir_p("./build")
        FileUtils.cd("./build") do
            cmd = "#{cmakeCommand} -G \"#{cMakeGenerator}\" -DWEBGPU_BACKEND=DAWN"
            cmd += " ..";
            system(cmd);
        end
    end

    export task :genProject => [ :projectFiles, :runConfigs ] do
    end

    setupCppConfig :targetType =>'NONE' do |cfg|
    end

end # end project artd-lib

task :nativeLibs => [ :vendorLibs, :autogen, :genProject, :build ] do
end

end # Rakish
