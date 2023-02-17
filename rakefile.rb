myDir = File.dirname(__FILE__);
require "#{myDir}/ensure-rakish.rb"

require "rakish/GitModule"

module Rakish

task :didiBase => [] do
end

task :ossLibs => [:didiBase] do
	Git.clone('git.didi.co:/home/didi/Pool_1/lib/oss.git', "#{myDir}/didi/lib/oss");
	Git.clone('git.didi.co:/home/didi/Pool_1/third-party-projects.git', "#{myDir}/didi/third-party-projects");
end

task :didiResearch => [:didiBase, :ossLibs] do
	Git.clone('git.didi.co:/home/didi/Pool_1/didi-research.git', "#{myDir}/didi/didi-research");
end

task :setup => [] do
	puts "setup complete."
end

end
