myPath = File.dirname(File.expand_path(__FILE__));
require "rakish/Rakish.rb"

module Rakish

  module VulkanTools

    CompileShader_ = Util::findInBinPath("glslc");

    class << self
        def compileShader(src,dest,opts={})
            system("\"#{CompileShader_}\" \"#{src}\" -o \"#{dest}\"");
        end
    end

    def vkt
        Rakish::VulkanTools
    end

  end

end # rakish
