# encoding: utf-8

module Nanoc3::CLI::Commands

  class Debug < Cri::Command

    def name
      'debug'
    end

    def aliases
      []
    end

    def short_desc
      'show debug information for this site'
    end

    def long_desc
      'Show information about all items, item representations and layouts ' \
      'in the current site.'
    end

    def usage
      "nanoc3 debug"
    end

    def option_definitions
      []
    end

    def run(options, arguments)
      # Make sure we are in a nanoc site directory
      print "Loading site data... "
      @base.require_site
      @base.site.load_data
      puts "done"
      puts

      # Get data
      items   = @base.site.items
      reps    = items.map { |i| i.reps }.flatten
      layouts = @base.site.layouts

      # Get dependency tracker
      # FIXME clean this up
      dependency_tracker = @base.site.compiler.send(:dependency_tracker)
      dependency_tracker.load_graph

      # Print items
      puts '=== Items'
      puts
      row = 0
      items.sort_by { |i| i.identifier }.each do |item|
        puts "item #{item.identifier}:"

        # Print item dependencies
        puts "  dependencies:"
        predecessors = dependency_tracker.direct_predecessors_of(item).sort_by { |i| i.identifier }
        predecessors.each do |pred|
          puts "    #{pred.identifier}"
        end
        puts "    (nothing)" if predecessors.empty?

        # Print item representations
        puts "  representations:"
        item.reps.sort_by { |r| r.name.to_s }.each do |rep|
          puts "    #{rep.name} -> #{rep.raw_path || '(not written)'}"
        end

        # Done
        puts
      end
      puts

      # Print layouts
      puts '=== Layouts'
      puts
      layouts.each do |layout|
        puts "layout #{layout.identifier}"
      end
    end

  end

end
