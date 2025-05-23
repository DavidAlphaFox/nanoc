# frozen_string_literal: true

require 'nanoc/core'
require 'diff/lcs'
require 'diff/lcs/hunk'
require 'logger'

begin
  require 'cri'
rescue LoadError => e
  $stderr.puts e
  $stderr.puts "If you are using a Gemfile, make sure that the Gemfile contains Nanoc ('gem \"nanoc\"')."
  exit 1
end

module Nanoc
  # @api private
  module CLI
    FORCE_COLOR_ENABLED = :enabled
    FORCE_COLOR_DISABLED = :disabled

    class << self
      attr_accessor :force_color

      # true if debug output is enabled, false if not
      attr_accessor :debug

      attr_accessor :verbosity

      def debug? = debug
    end

    # Set default singleton attributes
    self.force_color = nil
    self.debug = false
    self.verbosity = 0

    # Wraps `$stdout` and `$stderr` in appropriate cleaning streams.
    #
    # @return [void]
    def self.setup_cleaning_streams
      $stdout = wrap_in_cleaning_stream($stdout)
      $stderr = wrap_in_cleaning_stream($stderr)
    end

    # Wraps the given stream in a cleaning stream. The cleaning streams will
    # have the proper stream cleaners configured.
    #
    # @param [IO] io The stream to wrap
    #
    # @return [::Nanoc::CLI::CleaningStream]
    def self.wrap_in_cleaning_stream(io)
      cio = ::Nanoc::CLI::CleaningStream.new(io)

      unless enable_utf8?(io)
        cio.add_stream_cleaner(Nanoc::CLI::StreamCleaners::UTF8)
      end

      cio
    end

    # @return [Boolean] true if UTF-8 support is present, false if not
    def self.enable_utf8?(io)
      return true unless io.tty?

      %w[LC_ALL LC_CTYPE LANG].any? { |e| ENV.fetch(e, nil) =~ /UTF/i }
    end

    # @return [Boolean] true if color support is present, false if not
    def self.enable_ansi_colors?(io)
      case force_color
      when FORCE_COLOR_ENABLED
        true
      when FORCE_COLOR_DISABLED
        false
      else
        io.tty? && !ENV.key?('NO_COLOR')
      end
    end

    # Invokes the Nanoc command-line tool with the given arguments.
    #
    # @param [Array<String>] args An array of command-line arguments
    #
    # @return [void]
    def self.run(args)
      Nanoc::CLI::ErrorHandler.handle_while do
        setup
        root_command.run(args)
      end
    end

    # @return [Cri::Command] The root command, i.e. the command-line tool itself
    def self.root_command
      @root_command
    end

    # Adds the given command to the collection of available commands.
    #
    # @param [Cri::Command] cmd The command to add
    #
    # @return [void]
    def self.add_command(cmd)
      root_command.add_command(cmd)
    end

    # Schedules the given block to be executed after the CLI has been set up.
    #
    # @return [void]
    def self.after_setup(&block)
      # TODO: decide what should happen if the CLI is already set up
      add_after_setup_proc(block)
    end

    # Makes the command-line interface ready for use.
    #
    # @return [void]
    def self.setup
      Nanoc::CLI.setup_cleaning_streams
      setup_commands
      load_custom_commands
      after_setup_procs.each(&:call)
    end

    # Sets up the root command and base subcommands.
    #
    # @return [void]
    def self.setup_commands
      # Reinit
      @root_command = nil

      # Add root command
      filename = __dir__ + '/cli/commands/nanoc.rb'
      @root_command = Cri::Command.load_file(filename, infer_name: true)

      # Add help command
      help_cmd = Cri::Command.new_basic_help
      add_command(help_cmd)

      # Add other commands
      cmd_filenames = Dir[__dir__ + '/cli/commands/*.rb']
      cmd_filenames.each do |cmd_filename|
        basename = File.basename(cmd_filename, '.rb')

        next if basename == 'nanoc'

        cmd = Cri::Command.load_file(cmd_filename, infer_name: true)
        add_command(cmd)
      end

      if defined?(Bundler)
        # Discover external commands through Bundler
        begin
          Bundler.require(:nanoc)
        rescue Bundler::GemfileNotFound
          # When running Nanoc with Bundler being defined but
          # no gemfile being present (rubygems automatically loads
          # Bundler when executing from command line), don't crash.
        end
      end
    end

    # Loads site-specific commands.
    #
    # @return [void]
    def self.load_custom_commands
      if Nanoc::Core::SiteLoader.cwd_is_nanoc_site?
        config = Nanoc::Core::ConfigLoader.new.new_from_cwd
        config[:commands_dirs].each do |path|
          load_commands_at(File.expand_path(path))
        end
      end
    end

    def self.load_commands_at(path)
      recursive_contents_of(path).each do |filename|
        # Create command
        command = Cri::Command.load_file(filename, infer_name: true)

        # Get supercommand
        pieces = filename.gsub(/^#{path}\/|\.rb$/, '').split('/')
        pieces = pieces[0, pieces.size - 1] || []
        root = Nanoc::CLI.root_command
        supercommand = pieces.reduce(root) do |cmd, piece|
          cmd&.command_named(piece)
        end

        # Add to supercommand
        if supercommand.nil?
          raise "Cannot load command at #{filename} because its supercommand cannot be found"
        end

        supercommand.add_command(command)
      end
    end

    # @return [Array] The directory contents
    def self.recursive_contents_of(path)
      return [] unless File.directory?(path)

      files, dirs = *Dir[path + '/*'].sort.partition { |e| File.file?(e) }
      dirs.each { |d| files.concat recursive_contents_of(d) }
      files
    end

    def self.after_setup_procs
      @after_setup_procs || []
    end

    def self.add_after_setup_proc(proc)
      @after_setup_procs ||= []
      @after_setup_procs << proc
    end
  end
end

inflector_class = Class.new(Zeitwerk::Inflector) do
  def camelize(basename, abspath)
    case basename
    when 'version', 'cli', 'utf8'
      basename.upcase
    when 'ansi_string_colorizer'
      'ANSIStringColorizer'
    else
      super
    end
  end
end

loader = Zeitwerk::Loader.new
loader.inflector = inflector_class.new
loader.push_dir(__dir__ + '/..')
loader.ignore(__dir__ + '/../nanoc-cli.rb')
loader.ignore(__dir__ + '/cli/commands')
loader.setup
loader.eager_load
