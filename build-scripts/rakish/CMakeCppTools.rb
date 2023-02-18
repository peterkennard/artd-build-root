require 'rakish'
require 'rakish/CppProjects.rb'
require 'json'

module Rakish

  class ProjectBase
  end

  ## stuff to be moced into CppProjects later when done
  module CTools

    class TargetConfig

      # does not handle user added libraries outside of project
      # caches result so don't call until autogen and includes are done.
      def getOrderedLibs()

        unless(@orderedLibs_)
          olibs=[]
          olibs << libs;
          olibs = olibs.flatten;

          deps = project.dependencies;
          if(deps)
              deps.reverse_each do |dep|
                if(defined? dep.outputsNativeLibrary)
                  if(dep.outputsNativeLibrary)
                    if(dep.nativeLibDir)
                       olibs << dep.myName;
                    end
                  end
                end
              end
          end
          @orderedLibs_ = olibs;
        end
        @orderedLibs_;
      end # getOrderedLibs

    def getExportedLibs
      olibs=[]
      if(thirdPartyLibs)
        thirdPartyLibs.flatten.each do |tpl|
          tpl = File.expand_path(tpl);
          olibs << tpl;
          next;
        end
      end
      olibs

    end

    end # TargetConfig


    # def createCompileTasks(files,cfg)
    #   # format object files name
    #
    #   mapstr = "#{cfg.configuredObjDir()}/%f#{objExt()}";
    #
    #   objs=FileList[];
    #   files.each do |source|
    #     obj = source.pathmap(mapstr);
    #     task = createCompileTask(source,obj,cfg);
    #     objs << obj if task;  # will be the same as task.name
    #   end
    #   objs
    # end

  end

  module CppProjectModule
  end

  module CppProjectConfig
    attr_accessor  :cmakeCommand

    def cmakeCommand
      @cmakeCommand||="cmake";
    end

  end

  module CMakeCppTools

    class CMakeTools
      include CTools

      task :cmakeClean      => [];
      task :cmakeGen        => [:includes];

      # extension for pre linked object files
      # for consumers of CTools toolchain
      def objExt
        '.cpp'
      end
      # extension for static library files
      # for consumers of CTools toolchain
      def libExt
        '.lib'
      end
      # extension for dynamic library files
      # for consumers of CTools toolchain
      def dllExt
        '.dll'
      end
      # extension for executable files
      # for consumers of CTools toolchain
      def exeExt
        '.exe'
      end

      def initialize
        @compileForSuffix = {};

        addCompileAction('.cpp', @@compileCPPAction);
        addCompileAction('.c', @@compileCAction);
      end

	  @@cMakeDoNothingAction_ = lambda do |t,args|
		# log.debug("attempting to compile #{t.source} into\n    #{t}\n    in #{File.expand_path('.')}");
	  end

      def addCompileAction(suff,action)
         @@cMakeDoNothingAction_;
      end

      @@compileCPPAction = lambda do |t,args|
         @@cMakeDoNothingAction_;
         # @@doNothingAction_;
      end
      @@compileCAction = @@compileCPPAction;

      @@linkDllAction = lambda do |t,args|
         @@cMakeDoNothingAction_;
         # @@doNothingAction_;
      end

      @@linkAppAction = lambda do |t,args|
         @@cMakeDoNothingAction_;
         # @@doNothingAction_;
      end

      # for consumers of CTools toolchain
      def getCompileActionForSuffix(suff)
         @@cMakeDoNothingAction_;
         # @@doNothingAction_;
      end

      @@resolveLinkAction_ = lambda do |t,args|
      end

      class CMakeTargetConfig < TargetConfig
        attr_accessor  :cmakeExport
      end

      def cmakeExport
          @cmakeCommand
      end

      # to be overridden by specific toolchains for link target configuration
      def createLinkConfig(parent,configName)
        CMakeTargetConfig.new(parent,configName,self);
      end

      def defineCLionTasks(cfg)

        cmakeBuildDir = "#{cfg.projectDir}/cmake-build-debug";

        if(Dir.exists?(cmakeBuildDir))
            unless(File.exists?("#{cmakeBuildDir}/removeToForceCleanOnBuild.txt"))
                # log.debug("forcing cleanAll !!!");
                namespace(':') do
                    itask = task :includes;
                    itask.prerequisites.insert(0,:cleanAll);
                end
                system("echo blah blah blah > \"#{cmakeBuildDir}/removeToForceCleanOnBuild.txt\"" );
            end
        end

        # updateCLion = task :updateCLionMake do |t|
          # cfg = t.config;
          # makefilePath = "#{cfg.projectDir}/cmake-build-debug/CMakeFiles/Makefile2";
          # if(File.exists?(makefilePath) )
          # unless(system("grep __rakish_inserted__  \"#{makefilePath}\" > /dev/null"))
              # system("printf  \"\\n# __rakish_inserted__\\ninclude ../clionmake.mk\\n\" >> \"#{makefilePath}\"");
          # end
          # end
        # end

        # updateCLion.config = cfg;

        # only update IDE if files differ
        listname = "#{cfg.projectDir}/CMakeLists.txt";

        cmakeLists = file "#{cfg.projectObjDir}/CMakeLists.generated" => [ "#{cfg.projectFile}"] do |t|

          FileUtils.mkdir_p(File.dirname(t.name));

          cfg = t.config;

          File.open(t.name,'w') do |f|

            f.puts "# this file generated by rakish project \"#{cfg.projectName}\" edits will be lost"
            f.puts ''
            f.puts 'cmake_minimum_required(VERSION 3.12)'
            f.puts "project(#{cfg.projectName})"
            f.puts ''

            f.puts "include_directories("
            cfg.includePaths.each do |path|
              f.puts "        \"#{getRelativePath(path,cfg.projectDir)}\""
            end
            f.puts '    )'
            f.puts ''

            f.puts 'add_custom_target(build ALL rake build WORKING_DIRECTORY ./.'
            f.puts '       SOURCES'
            cfg.getSourceFiles.each do |src|
              f.puts "       \"#{getRelativePath(src,cfg.projectDir)}\""
            end
            f.puts '    )'
            f.puts ''

            f.puts 'set_property(DIRECTORY PROPERTY ADDITIONAL_MAKE_CLEAN_FILES'
            f.puts '"removeToForceCleanOnBuild.txt" )'
            f.puts ''
          end

          if(textFilesDiffer(t.name,listname))
            log.info("updating CMakeLists.txt");
            FileUtils.cp(t.name,listname);
          end

        end
        cmakeLists.config = cfg;
        unless File.exists?(listname)
          FileUtils.rm_f cmakeLists.name; # force rebuild
        end

        # task :build =>  [ cmakeLists ];
        # task :compile => [ cmakeLists ];
        # task :rebuild => [ :clean, :build ]
      end

    def generateCMakeExports(objs,cfg,t)

        project = cfg.project;
        cmakeName = project.myName;

        File.open("#{t.name}",'w') do |f|
            f.puts("# file generated by \"#{cfg.projectFile}\"");
            f.puts("\ncmake_minimum_required (VERSION 3.8)");

            f.puts("\nproject (\"#{cmakeName}\")")

            if(cfg.cmakeExport)

                case(cfg.targetType)
                    when 'APP'
                        f.puts("\nadd_executable(\"#{cmakeName}\"");
                    when 'LIB'
                        f.puts("\nadd_library(\"#{cmakeName}\" STATIC");
                    when 'DLL'
                        f.puts("\nadd_library(\"#{cmakeName}\" SHARED");
                end

                f.puts("     IMPORTED GLOBAL)");

                libs = cfg.getExportedLibs()

                if(cfg.targetPlatform =~ /Windows/)
                    if(libs.length > 0)
                          f.puts("");
                          libs.each do |lib|
                              if(lib.end_with?(cfg.dllExt()))
                                  f.puts("set_property( TARGET \"#{cmakeName}\" PROPERTY IMPORTED_LOCATION ")
                                  f.puts("        \"#{lib}\")");
                                  f.puts("");
                              elsif(lib.end_with?(cfg.libExt()))
                                  f.puts("set_property( TARGET \"#{cmakeName}\" PROPERTY IMPORTED_IMPLIB ")
                                  f.puts("        \"#{lib}\")");
                                  f.puts("");
                              end
                          end
                     end
                elsif(cfg.targetPlatform =~ /MacOS/ )
                     if(libs.length > 0)
                       f.puts("");
                       libs.each do |lib|
                           if(lib.end_with?(cfg.dllExt()) || lib.end_with?(cfg.libExt()))
                               f.puts("set_property( TARGET \"#{cmakeName}\" PROPERTY IMPORTED_LOCATION ")
                               f.puts("        \"#{lib}\")");
                               f.puts("");
                           end
                       end
                    end
                end
            end
        end # end File.open
    end

    # for consumers of CTools toolchain
    # TODO: this is a hack for making CMake files as everything needs to be resolved to
    def generateCMakeBuild(objs,cfg,t)

        project = cfg.project;
        sources = cfg.getSourceFiles();
        cmakeName = project.myName;
        projectDir = project.projectDir;

        libs = cfg.getOrderedLibs();

        File.open("#{t.name}",'w') do |f|

            f.puts("# file generated by \"#{cfg.projectFile}\"");
            f.puts("\ncmake_minimum_required (VERSION 3.8)");

            f.puts("\nproject (\"#{cmakeName}\")")

            f.puts("\nfile(GLOB_RECURSE includes \"*.h\")")

            case(cfg.targetType)
                when 'APP'
                        atype = "";
                        if(cfg.appType =~ /window/i)
                            atype = "WIN32";
                        end
                    f.puts("\nadd_executable(\"#{cmakeName}\" #{atype}");
                when 'LIB'
                    f.puts("\nadd_library(\"#{cmakeName}\" STATIC");
                when 'DLL'
                    f.puts("\nadd_library(\"#{cmakeName}\" SHARED");
            end

            sources.each do |src|
                src = getRelativePath(src,projectDir);
                f.puts("    \"#{src}\"");
            end
            f.puts("    ${includes}")

            f.puts(")");
            f.puts("");

            f.puts("if (CMAKE_VERSION VERSION_GREATER 3.12)");
                f.puts("    set_property(TARGET \"#{cmakeName}\" PROPERTY CXX_STANDARD 20)")
            f.puts("endif()");
            f.puts("");
            f.puts("target_include_directories(\"#{cmakeName}\" BEFORE PUBLIC \".\" \"#{getRelativePath(cfg.buildIncludeDir(),projectDir)}\")" )

            defines = cfg.cppDefines();
            if(defines.length)
                f.puts("");
                f.puts("target_compile_definitions( \"#{cmakeName}\" PRIVATE \n");
                 cfg.cppDefines.each do |k,v|
                     f.puts("        \"-D#{k}#{v ? '='+v : ''}\"");
                 end
                 f.puts("    )");
             end

            if(libs.length > 0)
                 f.puts("");
                 f.puts("target_link_libraries(\"#{cmakeName}\" PUBLIC")
                 libs.each do |lib|
                     f.puts("        \"#{lib}\"");
                 end
                 f.puts("    )");
            end
        end # end File.open
    end

      def createLinkTask(objs,cfg,project)

          myFile = File.expand_path(__FILE__);
          genTasks=[];
log.debug("#########  createLinkTask #{cfg.projectDir}/CMakeBuild.raked")
          genTask = file "#{cfg.projectDir}/CMakeExports.raked" => [myFile , cfg.projectFile ] do |t|
               cfg = t.config;
               generateCMakeExports(objs,cfg,t);
          end
          genTask.config = cfg;
          genTasks << genTask;

          genTask = file "#{cfg.projectDir}/CMakeBuild.raked" => [ myFile, cfg.projectFile ] do |t|
               cfg = t.config;
               generateCMakeBuild(objs,cfg,t);
          end
          genTask.config = cfg;
          genTasks << genTask;

          project.export task :cmakeGen=>[genTasks] do
          end
          nil # hack so caller in CppProject doesn't try to actually compile and link

      end

    end # end CMakeTools class

    def self.getConfiguredTools(configName,args={})
      return(CMakeTools.new());
    end

  end

end
