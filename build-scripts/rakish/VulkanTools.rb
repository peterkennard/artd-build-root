myPath = File.dirname(File.expand_path(__FILE__));
require "rakish/Rakish.rb"

module Rakish

  module VulkanTools
	include Rakish::Logger
	include Rakish::Util

    CompileShader_ = Util::findInBinPath("glslc");

    def self.compileShader(src,dest,opts={})
        system("\"#{CompileShader_}\" \"#{src}\" -o \"#{dest}\"");
    end

    def createShaderTasks(*files)
        opts = (Hash === files.last) ? files.pop : {}
        destDir = opts[:destDir];
        if(destDir)
            # FileUtils.mkdir_p(destDir)
            ensureDirectoryTask(destDir);
        else
            destDir = '.';
        end

        files = FileSet.new(files); # recursively expand wildcards.
        destDir = File.expand_path(destDir);
        tasks = [];
        files.each do |src|
            dest = File.basename(src);
            dest = "#{dest.gsub(/\./,'_')}.spv";
            dest = File.join(destDir,dest);
            task = file dest => [ destDir, src ] do |t|
                VulkanTools::compileShader(src,t.name);
            end
            tasks << task;
        end
        tasks
    end

    def vkt
        return self #Rakish::VulkanTools
    end

  end

end # rakish
