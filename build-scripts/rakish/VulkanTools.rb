myPath = File.dirname(File.expand_path(__FILE__));
require "rakish/Rakish.rb"

module Rakish

  module VulkanTools

    CompileShader_ = Util::findInBinPath("glslc");

    class << self
        def compileShader(src,dest,opts={})
            system("\"#{CompileShader_}\" \"#{src}\" -o \"#{dest}\"");
        end

        def createShaderTasks(*files)
            opts = (Hash === files.last) ? files.pop : {}
            destDir = opts[:destDir];
			if(destDir)
                FileUtils.mkdir_p(destDir)
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
                    compileShader(src,t.name);
                end
                tasks << task;
            end
            tasks
        end
    end

    def vkt
        Rakish::VulkanTools
    end

  end

end # rakish
