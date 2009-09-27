# encoding: utf-8

module Nanoc3

  # A Nanoc3::Site is the in-memory representation of a nanoc site. It holds
  # references to the following site data:
  #
  # * +items+ is a list of Nanoc3::Item instances representing items
  # * +layouts+ is a list of Nanoc3::Layout instances representing layouts
  # * +code_snippets+ is list of Nanoc3::CodeSnippet instance representing
  #   custom site code
  #
  # In addition, each site has a +config+ hash which stores the site
  # configuration. This configuration hash can have the following keys:
  #
  # +output_dir+:: The directory to which compiled items will be written. This
  #                path is relative to the current working directory, but can
  #                also be an absolute path.
  #
  # +data_sources+:: A list of data sources for this site. See below for
  #                  documentation on the structure of this list. By default,
  #                  there is only one data source of the filesystem  type
  #                  mounted at /.
  #
  # +index_filenames+:: A list of filenames that will be stripped off full
  #                     item paths to create cleaner URLs (for example,
  #                     '/about/' will be used instead of
  #                     '/about/index.html'). The default value should be okay
  #                     in most cases.
  #
  # The list of data sources consists of hashes with the following keys:
  #
  # +:type+:: The type of data source, i.e. its identifier. 
  #
  # +:items_root+:: The prefix that should be given to all items returned by
  #                 the #items method (comparable to mount points for
  #                 filesystems in Unix-ish OSes).
  #
  # +:layouts_root+:: The prefix that should be given to all layouts returned
  #                   by the #layouts method (comparable to mount points for
  #                   filesystems in Unix-ish OSes).
  #
  # +:config+:: A hash containing the configuration for this data source. This
  #             is especially useful for online data sources; for example, a
  #             Twitter data source would need the username of the account
  #             from which to fetch tweets.
  #
  # A site also has several helper classes:
  #
  # * +data_source+ is a Nanoc3::DataSource subclass instance used for loading
  #   site data.
  # * +compiler+ is a Nanoc3::Compiler instance that compiles item
  #   representations.
  #
  # The physical representation of a Nanoc3::Site is usually a directory that
  # contains a configuration file, site data, a rakefile, a rules file, etc.
  # The way site data is stored depends on the data source.
  class Site

    # The default configuration for a data source. A data source's
    # configuration overrides these options.
    DEFAULT_DATA_SOURCE_CONFIG = {
      :type         => 'filesystem_compact',
      :items_root   => '/',
      :layouts_root => '/',
      :config       => {}
    }

    # The default configuration for a site. A site's configuration overrides
    # these options: when a Nanoc3::Site is created with a configuration that
    # lacks some options, the default value will be taken from
    # +DEFAULT_CONFIG+.
    DEFAULT_CONFIG = {
      :output_dir      => 'output',
      :data_sources    => [ {} ],
      :index_filenames => [ 'index.html' ]
    }

    # The site configuration.
    attr_reader :config

    # The timestamp when the site configuration was last modified.
    attr_reader :config_mtime

    # The timestamp when the rules were last modified.
    attr_reader :rules_mtime

    # The code block that will be executed after all data is loaded but before
    # the site is compiled.
    attr_accessor :preprocessor

    # Creates a Nanoc3::Site object for the site specified by the given
    # +dir_or_config_hash+ argument.
    #
    # @param [Hash, String] dir_or_config_hash If a string, contains the path
    #   to the site directory; if a hash, contains the site configuration.
    def initialize(dir_or_config_hash)
      build_config(dir_or_config_hash)

      @code_snippets_loaded = false
      @items_loaded         = false
      @layouts_loaded       = false
    end

    # Returns the compiler for this site. Will create a new compiler if none
    # exists yet.
    def compiler
      @compiler ||= Compiler.new(self)
    end

    # Returns the data sources for this site. Will create a new data source if
    # none exists yet. Raises Nanoc3::Errors::UnknownDataSource if the site
    # configuration specifies an unknown data source.
    def data_sources
      @data_sources ||= begin
        @config[:data_sources].map do |data_source_hash|
          # Get data source class
          data_source_class = Nanoc3::DataSource.named(data_source_hash[:type])
          raise Nanoc3::Errors::UnknownDataSource.new(data_source_hash[:type]) if data_source_class.nil?

          # Create data source
          data_source_class.new(
            self,
            data_source_hash[:items_root],
            data_source_hash[:layouts_root],
            data_source_hash[:config] || {}
          )
        end
      end
    end

    # Loads the site data. This will query the Nanoc3::DataSource associated
    # with the site and fetch all site data. The site data is cached, so
    # calling this method will not have any effect the second time, unless
    # +force+ is true.
    #
    # @param [Boolean] force If true, will force load the site data even if it
    #   has been loaded before, to circumvent caching issues.
    def load_data(force=false)
      # Don't load data twice
      return if instance_variable_defined?(:@data_loaded) && @data_loaded && !force

      # Load all data
      data_sources.each { |ds| ds.use }
      load_code_snippets(force)
      load_rules
      load_items
      load_layouts
      data_sources.each { |ds| ds.unuse }

      # Preprocess
      setup_child_parent_links
      Nanoc3::PreprocessorContext.new(self).instance_eval(&preprocessor) unless preprocessor.nil?
      link_everything_to_site
      setup_child_parent_links
      build_reps
      route_reps

      # Done
      @data_loaded = true
    end

    # Returns this site's code snippets. Raises an exception if data hasn't been loaded yet.
    def code_snippets
      raise Nanoc3::Errors::DataNotYetAvailable.new('Code snippets', false) unless @code_snippets_loaded
      @code_snippets
    end

    # Returns this site's items. Raises an exception if data hasn't been loaded yet.
    def items
      raise Nanoc3::Errors::DataNotYetAvailable.new('Items', true) unless @items_loaded
      @items
    end

    # Returns this site's layouts. Raises an exception if data hasn't been loaded yet.
    def layouts
      raise Nanoc3::Errors::DataNotYetAvailable.new('Layouts', true) unless @layouts_loaded
      @layouts
    end

  private

    # Returns the Nanoc3::CompilerDSL that should be used for this site.
    def dsl
      @dsl ||= Nanoc3::CompilerDSL.new(self)
    end

    # Loads this site's code and executes it.
    def load_code_snippets(force=false)
      # Don't load code snippets twice
      return if @code_snippets_loaded and !force

      # Get code snippets
      @code_snippets = data_sources.map { |ds| ds.code_snippets }.flatten

      # Execute code snippets
      @code_snippets.each { |cs| cs.load }

      @code_snippets_loaded = true
    end

    # Loads this site's rules.
    def load_rules
      # Find rules file
      rules_filename = [ 'Rules', 'rules', 'Rules.rb', 'rules.rb' ].find { |f| File.file?(f) }
      raise Nanoc3::Errors::NoRulesFileFound.new if rules_filename.nil?

      # Get rule data
      @rules       = File.read(rules_filename)
      @rules_mtime = File.stat(rules_filename).mtime

      # Load DSL
      dsl.instance_eval(@rules)
    end

    # Loads this site's items, sets up item child-parent relationships and
    # builds each item's list of item representations.
    def load_items
      @items = []
      data_sources.each do |ds|
        items_in_ds = ds.items
        items_in_ds.each { |i| i.identifier = File.join(ds.items_root, i.identifier) }
        @items += items_in_ds
      end

      @items_loaded = true
    end

    # Loads this site's layouts.
    def load_layouts
      @layouts = []
      data_sources.each do |ds|
        layouts_in_ds = ds.layouts
        layouts_in_ds.each { |i| i.identifier = File.join(ds.layouts_root, i.identifier) }
        @layouts += layouts_in_ds
      end

      @layouts_loaded = true
    end

    # Links items, layouts and code snippets to the site.
    def link_everything_to_site
      @items.each         { |i|  i.site  = self }
      @layouts.each       { |l|  l.site  = self }
      @code_snippets.each { |cs| cs.site = self }
    end

    # Fills each item's parent reference and children array with the
    # appropriate items.
    def setup_child_parent_links
      # Clear all links
      @items.each do |item|
        item.parent = nil
        item.children = []
      end

      @items.each do |item|
        # Get parent
        parent_identifier = item.identifier.sub(/[^\/]+\/$/, '')
        parent = @items.find { |p| p.identifier == parent_identifier }
        next if parent.nil? or item.identifier == '/'

        # Link
        item.parent = parent
        parent.children << item
      end
    end

    # Creates the representations of all items as defined by the compilation
    # rules.
    def build_reps
      @items.each do |item|
        # Find matching rules
        matching_rules = self.compiler.item_compilation_rules.select { |r| r.applicable_to?(item) }
        raise Nanoc3::Errors::NoMatchingCompilationRuleFound.new(rep) if matching_rules.empty?

        # Create reps
        rep_names = matching_rules.map { |r| r.rep_name }.uniq
        rep_names.each do |rep_name|
          item.reps << ItemRep.new(item, rep_name)
        end
      end
    end

    # Determines the paths of all item representations.
    def route_reps
      reps = @items.map { |i| i.reps }.flatten
      reps.each do |rep|
        # Find matching rule
        rule = self.compiler.routing_rule_for(rep)
        raise Nanoc3::Errors::NoMatchingRoutingRuleFound.new(rep) if rule.nil?

        # Get basic path by applying matching rule
        basic_path = rule.apply_to(rep)
        next if basic_path.nil?

        # Get raw path by prepending output directory
        rep.raw_path = self.config[:output_dir] + basic_path

        # Get normal path by stripping index filename
        rep.path = basic_path
        self.config[:index_filenames].each do |index_filename|
          if rep.path[-index_filename.length..-1] == index_filename
            # Strip and stop
            rep.path = rep.path[0..-index_filename.length-1]
            break
          end
        end
      end
    end

    # Builds the configuration hash based on the given argument. Also see
    # #initialize for details.
    def build_config(dir_or_config_hash)
      if dir_or_config_hash.is_a? String
        # Read config from config.yaml in given dir
        config_path = File.join(dir_or_config_hash, 'config.yaml')
        @config = DEFAULT_CONFIG.merge(YAML.load_file(config_path).symbolize_keys)
        @config[:data_sources].map! { |ds| ds.symbolize_keys }
        @config_mtime = File.stat(config_path).mtime
      else
        # Use passed config hash
        @config = DEFAULT_CONFIG.merge(dir_or_config_hash)
        @config_mtime = nil
      end

      # Merge data sources with default data source config
      @config[:data_sources].map! { |ds| DEFAULT_DATA_SOURCE_CONFIG.merge(ds) }
    end

  end

end
