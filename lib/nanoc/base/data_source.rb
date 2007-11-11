Nanoc.load_file('base', 'plugin.rb')

module Nanoc
  class DataSource < Plugin

    def initialize(site)
      @site = site
    end

    # Attributes

    class << self
      attr_accessor :_name
    end

    def self.name(name=nil)
      if name.nil?
        self._name
      else
        self._name = name
        $nanoc_extras_manager.register_data_source(name, self)
      end
    end

    # Preparation

    def up
    end

    def down
    end

    def setup
    end

    # Loading data

    def pages
      $stderr.puts 'ERROR: DataSource#pages must be overridden'
      exit(1)
    end

    def page_defaults
      $stderr.puts 'ERROR: DataSource#page_defaults must be overridden'
      exit(1)
    end

    def layouts
      $stderr.puts 'ERROR: DataSource#layouts must be overridden'
      exit(1)
    end

    def templates
      $stderr.puts 'ERROR: DataSource#templates must be overridden'
      exit(1)
    end

    # Creating data

    def create_page(name, template_name)
      $stderr.puts 'ERROR: DataSource#create_page must be overridden'
      exit(1)
    end

    def create_layout(name)
      $stderr.puts 'ERROR: DataSource#create_layout must be overridden'
      exit(1)
    end

    def create_template(name)
      $stderr.puts 'ERROR: DataSource#create_template must be overridden'
      exit(1)
    end

  end
end