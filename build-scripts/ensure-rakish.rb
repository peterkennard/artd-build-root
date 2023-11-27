myDir = File.dirname(File.expand_path(__FILE__));

if (ARGV.length > 0 && ARGV[0] === "__recursing__")

	$recursing = true;
	if(ARGV.length == 1)
		task :__recursing__ => [:default]
	else
		task :__recursing__
	end
	task :ensureRakish do
	end
    require "#{myDir}/artd-rakish/lib/rakish";

else
    begin
        unless File.file?("#{myDir}/artd-rakish/lib/rakish.rb")
            puts("forcing download of \"#{myDir}/artd-rakish\".")
            raise LoadError; # force it to download
        end

        require "#{myDir}/artd-rakish/rakish";

    rescue LoadError => e
        useSSH = File.exist?("#{ENV['HOME']}/66A46A08-2C23-49AE-95C0-69CE20B326A3.txt");
#        system("rm -fr \"#{myDir}/artd-rakish"")
        puts " downloading artd-rakish build utility"
        localDir = "#{myDir}/artd-rakish";
        if(useSSH)
            system("git clone git@github.com:peterkennard/artd-rakish.git \"#{localDir}\"");
        else
            system("git clone https://github.com/peterkennard/artd-rakish.git \"#{localDir}\"");
        end

        require "#{myDir}/artd-rakish/rakish";
        exec "rake __recursing__ #{ARGV.join(" ")}"
    end
end

