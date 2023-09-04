myDir = File.dirname(__FILE__);

if (ARGV.length > 0 && ARGV[0] === "__recursing__")

	$recursing = true;
	if(ARGV.length == 1)
		task :__recursing__ => [:default]
	else
		task :__recursing__
	end
	task :ensureRakish do
    end
    require "#{myDir}/artd-rakish/rakish";

else
    begin
        unless File.file?("#{myDir}/artd-rakish/lib/rakish.rb")
            # puts("forcing load error !!!")
            raise LoadError; # force it to download
        end
        require "#{myDir}/artd-rakish/rakish";

    rescue LoadError => e

        system("rm -fr \"#{myDir}/artd-rakish\"")
        puts "downloading artd-rakish build utility"
        localDir = "#{myDir}/artd-rakish";
        system("git clone https://github.com/peterkennard/artd-rakish.git \"#{localDir}\"");
		FileUtils.cd localDir do
            begin
                system("git remote add z_didi -f -m master git.livingwork.com:/home/didi/libs/artd/artd-rakish.git");
            rescue
            end
        end

        system("git clone  \"#{myDir}/artd-rakish\"");

        require "#{myDir}/artd-rakish/rakish";

        exec "rake __recursing__ #{ARGV.join(" ")}"
    end
end

