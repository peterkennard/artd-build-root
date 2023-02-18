require 'rakish'
require 'rakish/CppProjects.rb'
require 'json'

module Rakish

  class ProjectBase
  end

  ## stuff to be moced into CppProjects later when done
  module CTools
    class TargetConfig

      # currently does not handle user added libraries outside of project
      # caches result so don't call until compile and autogen are done.
      def getOrderedLibs

        unless(@orderedLibs_)
          olibs=[];
          getOrderedLinkrefs.each do|ref|
            olibs << ref[:libs] if ref[:libs];
          end
          @orderedLibs_ = olibs.flatten;
        end
        @orderedLibs_;
      end
    end

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

  module WasmCppTools

    class WasmTools
      include CTools

      # extension for pre linked object files
      # for consumers of CTools toolchain
      def objExt
        '.bc'
      end
      # extension for static library files
      # for consumers of CTools toolchain
      def libExt
        '.a'
      end
      # extension for dynamic library files
      # for consumers of CTools toolchain
      def dllExt
        '' # not supported
      end
      # extension for executable files
      # for consumers of CTools toolchain
      def exeExt
        '.html'
      end

      # extension for "export list" files
      # for consumers of CTools toolchain
      def exportsExt
        '.jsexports'
      end

      EmccPath = Util.findInBinPath('emcc')
      # EmccPath = Util.findInBinPath('clang-em')
      EmarPath = Util.findInBinPath('emar')

      def initialize
        @compileForSuffix = {};

        addCompileAction('.cpp', @@compileCPPAction);
        addCompileAction('.c', @@compileCAction);
      end

      # will format and cache into the config the /I and /D and other constant
      # compiler flags for the specific configuration and cache it in the configuration
      def getFormattedGccFlags(cfig)

        unless(cfl = cfig.getMy(:gccFlags_))
          # if not cached build command line string
          cfl = "";

          if(false)
            cfig.cflags.each do |cf|
              cfl += (' ' + cf)
            end
          end

          # format include paths
          cfig.includePaths.each do |dir|
            cfl += " -I \"#{dir}\"";
          end

          #  "ARTD_PLATFORMTYPE=#{@platformType}",
          cfl += " -D\"ARTD_PLATFORMBITS=32\" -D\"ARTD_DEBUGTYPE=Debug\"";
          # "ARTD_LINKAGETYPE=#{@linkType}"

          # format CPP macro defs
          cfig.cppDefines.each do |k,v|
            cfl += " -D\"#{k}#{v ? '='+v : ''}\""
          end
          # log.debug("cppflags are \"#{cfl}\"");
          cfig.set(:gccFlags_,cfl)
        end
        cfl
      end


      def addCompileAction(suff,action)
        @compileForSuffix[suff] = action;
      end

      def writeCompileCommand(dir, srcfile, outfile, cmdline, tail)

        cmdfile = "#{outfile.pathmap('%X')}#{srcfile.pathmap('%x')}.command"


#        unless File.exists(cmdfile)

#          cmdline += " -D__EMSCRIPTEN__ -D__GNUC__=4 ";
          cmdline += tail;

          File.open(cmdfile,"w") do |f|
            f.puts(" { \"directory\": \"#{dir}\"," );
            f.puts("   \"command\": #{cmdline.to_json}," );
            f.puts("   \"file\": \"#{srcfile}\",");
            f.puts("   \"output\": \"#{outfile}\" }");
#        end
        end
#        compile_commands.json
      end

      @@compileCPPAction = lambda do |t,args|
        t.config.ctools.doCompileCpp(t)
      end
      @@compileCAction = @@compileCPPAction;

      def doCompileCpp(t)

        cppFile = t.source;
        objFile = t.name;
        cfig = t.config;
        # depname = "#{objFile.pathmap('%X')}#{cppFile.pathmap('%x')}.d";
        depname = objFile.pathmap('%X.d');

        lang = cppFile.end_with?('.c','.C') ? '-x c' : '-x c++ -std=c++14';

        cmdline = "\"#{EmccPath}\" -O3 -s USE_PTHREADS=1 #{lang} -MT\"#{depname}\" -MMD -MP -MF \"#{depname}\" -Wall -pedantic -c ";

        cmdline += " -o \"#{objFile}\"";

        tail = getFormattedGccFlags(cfig);
        tail += " \"#{cppFile}\"";

        # log.debug("\n\t#{cmdline}");
        log.info cppFile.pathmap('%f');

        # CLion compile database support
        writeCompileCommand(File.expand_path('.'),cppFile,objFile,cmdline,tail);

        cmdline += tail;
        IO.popen(cmdline) do |output|
          while line = output.gets do
            log.info line.strip!
          end
        end


        included = Rakish::FileSet.new

        File.open(depname) do |file|
          file.each_line do |line|
            line.strip!
            if line.end_with?(':')
              line.sub!(':','');
              # line = line[0...(line.length-1)];
              included << line
            end
          end
        end

        depfile = depname.ext('.raked');
        updateDependsFile(t,depfile,included);

      end

      @@buildLibAction = lambda do |t,args|
        t.config.ctools.doBuildLib(t)
      end
      def doBuildLib(t)

        cfg = t.config;
        outpath = t.name;

        log.info("Creating wasm library #{File.basename(outpath)}");
        cmdline = "\"#{EmarPath}\" rcuv \"#{outpath}\"";

        # object files
        objs=[]
        objs << t.createArgs[:userobjs];
        objs.flatten.each do |obj|
          obj = obj.to_s
          next unless obj.pathmap('%x') == objExt
          cmdline += " \"#{obj}\"";
        end

        # log.debug("\n cmdline = #{cmdline}\n");
        FileUtils.cp( cfg.exportsFile, outpath.pathmap("%X#{exportsExt}")) if(cfg.exportsFile);
        FileUtils.cp( cfg.exportedScript, outpath.pathmap("%X.js")) if(cfg.exportedScript);
        execLogged(cmdline);
      end

      def getOuputExportsPath(baseName)
        File.expand_path("lib#{baseName}#{exportsExt}");
      end

      def getOuputJScriptPath(baseName)
        File.expand_path("lib#{baseName}.js");
      end

      # real bodge for now need to clean this up somehow.
      def loadLinkref(libdir,project,cfgName)
        ref={};

        type = project.currentBuildConfig.targetType;
        case type
        when 'LIB','DLL' # other types of targets DO NOT export anything

          cd libdir, :verbose=>false do
            cfg = project.currentBuildConfig;
            ref[:libs] = [ File.expand_path("lib#{cfg.targetName}#{libExt}")];
            efile = getOuputExportsPath(cfg.targetName);
            ref[:exports] = efile if cfg.exportsFile;
            ref[:jscripts] = cfg.exportedScript if cfg.exportedScript;
          end
        end
        ref
      end

      # add libraries and consolidated jsexports list to link
      def resolveAndAddLibs(cfg)

        cmdline = "";

        # consolidate all exports into one exports list file
        exported=[];
        if(cfg.exportsFile)
          eval("exported << #{readFileToString(cfg.exportsFile)}");
        end

        cfg.getOrderedLinkrefs.flatten.each do |ref|
          if(ref[:exports])
            eval("exported << #{readFileToString(ref[:exports])}");
          end
        end

        exported.flatten!
        unless(exported.empty?)
          exportsTemp = "#{cfg.configuredObjDir}/jsexportsTemp.txt";
          File.open(exportsTemp,'w') do |f|
            f.puts("#{exported}\n");
          end
          cmdline += " -s \"EXPORTED_FUNCTIONS=@#{exportsTemp}\"";
        end

        # defines C functions in wasm to be exported to javascript in browser
        # # add library search paths
        eachof cfg.libpaths do |lpath|
           log.debug("libpath:\"#{lpath}\"");
        end

        cmdline += " \"-L#{cfg.nativeLibDir}\"";

        # add libraries to command line
        # testPrefix = "#{cfg.nativeLibDir}/lib";

        # add exported libraries from dependencies ( all we support at present )
        # note order the built libs are provided least dependent to most
        # user provided libs must be manually ordered
        #
        # TODO: remove redundancies as several dependencies might use the same lib
        # TODO: ned to keep order sorted so LAST occurrance of each lib remains.
        #

        cfg.getOrderedLibs.each do |lib|
          if(File.path_is_absolute?(lib))
          #   if(lib.start_with?(testPrefix))
          #     lib = lib.slice(testPrefix.length, lib.length - testPrefix.length);
          #     cmdline += " \"-l#{lib.pathmap('%X')}\"";
          #     next
          #   end
          #   log.debug("warning: library #{lib} not in search paths absolute path specified");
             cmdline += " \"#{lib}\""; # note no -l for absolute path

             # system("\"#{EmarPath}\" x \"#{lib}\"");

          else
            cmdline += " \"-l#{lib}\"";
          end
        end

        # log.debug("cmdline \"#{cmdline}\"")
        { :cmdline=>cmdline, :jscripts=>cfg.getOrderedJScripts() }
      end

      @@linkDllAction = lambda do |t,args|
        t.config.ctools.doLinkDll(t)
      end
      def doLinkDll(t)

        cfg = t.config;
        outpath = t.name;

        # writeLinkref(cfg,cfg.targetBase,outpath);
        #
        # log.info("linking shared lib #{outpath}");
        #
        # cmdline = "\"#{GppPath}\" -g -pthread -shared -shared-libgcc -Wl,-E,--no-allow-shlib-undefined,-soname,\"#{outpath}\" -o \"#{outpath}\"";
        #
        # # object files
        # objs=[]
        # objs << t.sources[:userobjs];
        # objs.flatten.each do |obj|
        #   obj = obj.to_s
        #   next unless obj.pathmap('%x') == '.o'
        #   cmdline += " \"#{obj}\"";
        # end
        #
        # cmdline += resolveAndAddLibs(cfg);
        #
        # # log.debug("\n cmdline = #{cmdline}\n");
        # system(cmdline);
      end

      @@linkAppAction = lambda do |t,args|
        t.config.ctools.doLinkApp(t)
      end
      def doLinkApp(t)

        cfg = t.config;
        outpath = t.name;

        log.info("linking wasm application \"#{outpath}\""); # .pathmap('%X')}\"");


        cmdline = "\"#{EmccPath}\"";

        # multithreading things
        # cmdline += " -pthread -s USE_PTHREADS=1 ";

        # -s DEMANGLE_SUPPORT=1
        # -shared-libgcc

        # TODO - had to put the FETCH flag in here because it lost it somehow when the lflags

        cmdline += " -O3 -s FETCH=1 -s FULL_ES3=1 -s \"USE_GLFW=3\" -s WASM=1 -g -s ERROR_ON_UNDEFINED_SYMBOLS=0 -Wl"; # - E,--no-allow-shlib-undefined";

        # libs and exports go after objs
        resolved = resolveAndAddLibs(cfg);

        # build the html file from template and scripts from libraries
        if(cfg.htmlTemplate)

log.debug("html template is: #{cfg.htmlTemplate}");

          template = nil;
          scripts = resolved[:jscripts]
          if(!scripts.empty?)
            template = "#{cfg.configuredObjDir()}/template-temp.html"
            # aaaack copy the whole block ? twice ?
            _InsertedScript_ = "\n" + File.new(scripts[0], "r").read;
            # yes it can't be toooo big as it has to be in ruby memory :)
            # log.debug("from #{cfg.template}to insert is #{_InsertedScript_}");
            File.open(template,"w") do |outfile|
              rubyPP(cfg.htmlTemplate,outfile,binding);
            end
          else
            template = cfg.htmlTemplate;
          end
          # --shell-file <path> defines html template file to be used in genrating the HTML
          cmdline += " --shell-file \"#{template}\"";

        end

        cmdline += " #{cfg.lflags}" if(cfg.lflags);

        cmdline += " -o \"#{outpath}\"";

        # object files
        objs=[]
        objs << t.createArgs[:userobjs];
        objs.flatten.each do |obj|
          obj = obj.to_s
          next unless obj.pathmap('%x') == objExt
          cmdline += " \"#{obj}\"";
        end

        cmdline += resolved[:cmdline];

        # log.debug("\n cmdline = #{cmdline}\n");
        system(cmdline);

      end

      # for consumers of CTools toolchain
      def getCompileActionForSuffix(suff)
        @compileForSuffix[suff]
      end

      # for consumers of CTools toolchain
      def initCompileTask(cfg)
        ensureDirectoryTask(cfg.configuredObjDir);
        cfg.project.addCleanFiles("#{cfg.configuredObjDir}/*#{objExt()}",
                                  "#{cfg.configuredObjDir}/*.d"
        );
        Rake::Task.define_task :compile => [:includes,
                                            cfg.configuredObjDir,
                                            :depends]
      end

      def appendCommands(comma, dep, f)
        files = FileList.new("#{dep.configuredObjDir}/*.command");
        didOne = false
        files.each do |cmd|
          f.puts(',') if(didOne)
          txt = File.new(cmd).read
          f.print(txt)
          didOne = true;
        end
        f.puts(',') if(comma && didOne)
      end
      def createClionDatabase(cfg)
        # "compile_commands.json"

        tempfile = "#{cfg.configuredObjDir}/compile_commands.json";
        outfile= "#{cfg.projectDir}/compile_commands.json";

        File.open(tempfile,'w') do |f|
          f.puts('[');
          cfg.allDependencies().each do |dep|
            appendCommands(true, dep, f);
          end
          appendCommands(false, cfg.project, f);
          f.puts("\n]");
        end

        if(textFilesDiffer(tempfile,outfile))
          log.info("updating compile_commands.json");
          FileUtils.cp(tempfile,outfile);
        end

      end


      @@resolveLinkAction_ = lambda do |t,args|
        cfg = t.config;
        doLink = t.createArgs[:linkTask];

        cfg.ctools.createClionDatabase(cfg);

        unless doLink.needed?
          deps=[]
          cfg.getOrderedLibs.each do |lib|
            if(File.path_is_absolute?(lib))
              deps << lib;
            end
          end
          cfg.getOrderedJScripts.each do |js|
            deps << js;
          end
          doLink.enhance(deps) unless(doLink.needed?); # add libraries as dependencies
        end

      end

      class WasmLinkConfig < TargetConfig
        def initialize(pnt, cfgName, tools)
          super(pnt,cfgName,tools);
          @emldflags=[];
        end

        attr_reader :htmlTemplate
        def htmlTemplate=(template)
          @htmlTemplate = File.expand_path(template);
        end
        attr_reader :exportsFile
        def exportsFile=(filePath)
          @exportsFile = File.expand_path(filePath);
        end
        attr_reader :exportedScript
        # TODO should take arrays ??
        def exportedScript=(filePath)
          @exportedScript = File.expand_path(filePath);
        end
        attr_accessor :lflags

        # currently does not handle user added libraries outside of project
        # caches result so don't call until compile and autogen are done.
        def getOrderedJScripts
          unless(@orderedJScripts_)
            jscripts=[];
            getOrderedLinkrefs.each do|ref|
              jscripts << ref[:jscripts] if ref[:jscripts]
            end
            @orderedJScripts_ = jscripts.flatten;
          end
          @orderedJScripts_;
        end
      end

      # to be overridden by specific toolchains for link target configuration
      def createLinkConfig(parent,configName)
        WasmLinkConfig.new(parent,configName,self);
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

        task :build =>  [ cmakeLists ];
        task :compile => [ cmakeLists ];
        task :rebuild => [ :clean, :build ]

      end
      # for consumers of CTools toolchain
      def createLinkTask(objs,cfg)

        case(cfg.targetType)
        when 'APP'

          targetBase = "#{cfg.binDir()}/#{cfg.targetName}";
          targetName = "#{targetBase}.html";

          depends =[];
          depends << cfg.htmlTemplate if(cfg.htmlTemplate)
          depends << cfg.exportsFile if(cfg.exportsFile)

          doLink = Rake::FileTask.define_task targetName => depends, :$@=> { :userobjs=>objs }, &@@linkAppAction;

          cfg.project.addCleanFiles("#{doLink.name}","#{targetBase}.wasm","#{targetBase}.js","#{targetBase}.wast");

        when 'LIB','DLL'

          # for the time being a DLL is a static library as WebAssembly doen't support DLLs

          depends =[];
          depends << cfg.exportsFile if(cfg.exportsFile)
          depends << cfg.exportedScript if(cfg.exportedScript)

          targetName = "#{cfg.nativeLibDir()}/lib#{cfg.targetName}#{libExt}";
          doLink = Rake::FileTask.define_task targetName => depends, :$@=> { :userobjs=>objs }, &@@buildLibAction;

        # when 'DLL'
        #   ##  targetName = "#{cfg.nativeLibDir()}/#{cfg.configName}/lib#{cfg.targetName}.so";
        #   ##  doLink = Rake::FileTask.define_task targetName => [], :$@=> { :userobjs=>objs }, &@@linkDllAction;

        else
          log.debug("unsupported target type #{cfg.targetType}");
          return(false);
        end

        doLink.config = cfg;
        doLink.enhance(objs);

        cfg.project.addCleanFiles(targetName);

        tsk = task :clean do |t|
          cfg = t.config;
          FileList.new("#{cfg.configuredObjDir}/*.command").each do |f|
            FileUtils.rm(f);
          end
        end
        tsk.config = cfg

        # create a "setup" task to resolve everything after compiling, generating code, etc and set up the link.
        tsk = task "#{cfg.targetName}.#{cfg.targetType}.resolve", :$@=>{ :linkTask=>doLink },  &@@resolveLinkAction_;
        tsk.config = cfg;

        defineCLionTasks(cfg);


        { :setupTasks=>tsk, :linkTask=>doLink } # note this returns a hash !!
      end # end method

    end # end class

    def self.getConfiguredTools(configName,args={})
      return(WasmTools.new());
    end

  end

end
