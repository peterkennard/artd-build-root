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
        system("git clone https://github.com/peterkennard/artd-rakish.git \"#{myDir}/artd-rakish\"");

        require "#{myDir}/artd-rakish/rakish";

        system "git config --global --replace-all core.autocrlf true";
        exec "rake __recursing__ #{ARGV.join(" ")}"
    end
end

