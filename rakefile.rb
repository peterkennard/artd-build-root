myDir = File.dirname(__FILE__);
require "#{myDir}/build-options.rb"

Git = Rakish::Git;


task :buildTools => [] do


    ret = `which brew`;
    unless(ret =~ /\/bin\/brew/ )
        Rakish.log.error( "\n##### homebrew is required to run this build");
        puts( "\nTo install: \n");
        puts( "Launch Terminal.");
        puts( "Write the following command:");
        puts( "/bin/zsh -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\" → hit return.");
        puts( "Now, enter your Mac password. Hit the return key on your keyboard to continue.\n\n\n");

        Rakish.log.error( "\n##### Exiting");

        exit(0);
    end

    ret = `which python3`;
    unless(ret =~ /homebrew\/bin\/python3/ )
        system('brew install python3')
    end

    ret = `which pip`;
    unless(ret =~ /bin\/pip/ )
        system('python3 -m ensurepip --updradeip --upgrade')
    end

    ret = `which conan`;
    unless(ret =~ /bin\/conan/ )
        system('pip install conan==1.95.0')
    end

    ret = `which cmake`;
    unless(ret =~ /homebrew\/bin\/conan/ )
        system('brew install cmake')
    end

end

task :nativeLibs => [ :buildTools ]do
    FileUtils.cd "./third-party" do
        system("rake setup");
    end
    FileUtils.cd "./native-libs" do
        system("rake setup");
    end
end

task :setup => [:buildTools, :nativeLibs] do
	puts "setup complete."
end

task :resources => [] do
end


subdirs=[]

# TODO: make some sort of "ignoreDependencies" or isSetupTask function
unless Rakish.inSetupTask()

    subdirs = [
        './native-libs',
        './third-party',
    ];
end

Rakish.Project(
    :includes=>[Rakish::CppProjectModule, Rakish::GitModule ],
	:name 		=> "artd-root",
    :dependsUponOpt => subdirs
) do

    export task :cleanAll => sourceSubdir do |t|
        FileUtils.rm_rf(buildDir);  # remove recursive
    end

    task :runConfigs do
        if(targetPlatform =~ /MacOS/)
            FileUtils.mkdir_p ("#{buildDir}/#{projectName}.xcodeproj/xcshareddata/xcschemes");
            FileUtils.cp_r( "#{projectDir}/build-scripts/xcodeproj/xcshareddata/xcschemes/.", "#{buildDir}/#{projectName}.xcodeproj/xcshareddata/xcschemes");
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

unless Rakish.inSetupTask()
    task :vendorLibs;
    task :nativeLibs => [ :vendorLibs, :autogen, :genProject, :build ] do
    end
end






# # You can disable password authentication with -o PasswordAuthentication=no. Full command would be:
# # ssh -nT -o PasswordAuthentication=no <host>  # n no stdout output, T no tty input.
# # GIT_SSH_COMMAND=ssh -o PasswordAuthentication=no'
#
# # task :testSetup => [ :thirdPartySetup, :libCppSetup ] do
# #     if(Git.cloneIfAvailable("git.livingwork.com:/home/artd/newartd/artdlib-test", "#{myDir}/artdlib-test"))
# #         cd "#{myDir}/artdlib-test" do
# #             system("rake setup");
# #         end
# # 	end
# # end
