myDir = File.dirname(File.expand_path(__FILE__));
require "#{myDir}/../build-options.rb";
require "rakish/GitModule";

module Rakish

dependsList = [];

cfg = BuildConfig("root");


artdLibs = [
    'artd-lib-logger',
    'artd-jlib-base',
    'artd-lib-vecmath',
    'artd-jlib-thread',
    'artd-jlib-io',
    'artd-jlib-net',
    'artd-jlib-util',
    'artd-gpu-engine'
];


unless inSetupTask()
    artdLibs.each do |lib|
        dependsList << "./#{lib}"
    end
end

Rakish.Project(
    :includes    => [Rakish::GitModule],
	:name 		 => "native-libs",
    :dependsUponOpt => dependsList
) do

    export task :setup => [] do
        useSSH = File.exists?("#{ENV['HOME']}/66A46A08-2C23-49AE-95C0-69CE20B326A3.txt");

        artdLibs.each do |lib|

            localDir = "#{projectDir}/#{lib}"
    	    if(useSSH)  # all are writable here and we have access to didi pool repository
    	        git.clone("git@github.com:peterkennard/#{lib}.git", localDir);
#                remoteDir = "git.livingwork.com:/home/git/github/#{lib}.git";
    	        remoteDir = "git.livingwork.com:/home/artd/pooldev/#{lib}.git";
                begin
                    system("git remote add pool_artd -f -m main #{remoteDir}");
                rescue
                end
    	    else
    	        git.clone("https://github.com/peterkennard/#{lib}.git", localDir);
      	    end
        end
    end

end

end # Rakish
