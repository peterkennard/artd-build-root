myDir = File.dirname(__FILE__);
require "#{myDir}/../build-options.rb"
require "rakish/GitModule";

module Rakish

    stubs = [
        'oss-zlib',
        'oss-jextract',
        'oss-libpng',
        'oss-glm',

     #  './oss-glfw',
     #   './oss-stb',
     #  './tinyobjloader',
     #  './google-dawn',
     #  'freetype'
    ];

    dependsList=[];

    unless inSetupTask()

        dependsList = stubs;
        cfg = BuildConfig("root");

        log.debug("depends #{dependsList}");
    end

	Rakish.Project( :dependsUpon =>dependsList,
                    :includes    => [Rakish::GitModule],
	                :name 		 => "native-libs"
	) do

	    export task :setup do
            useSSH = File.exists?("#{ENV['HOME']}/66A46A08-2C23-49AE-95C0-69CE20B326A3.txt");
            stubs.each do |stub|
                localDir = "#{projectDir}/#{stub}";
                if(useSSH)
                    git.clone( "git@github.com:peterkennard/#{stub}-stub.git", localDir )
                else
  	                git.clone("https://github.com/peterkennard/#{stub}-stub.git", localDir);

                end
            end
	    end
	end

end # emd Rakish