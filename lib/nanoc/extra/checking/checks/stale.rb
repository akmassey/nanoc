# encoding: utf-8

module Nanoc::Extra::Checking::Checks

  class Stale < ::Nanoc::Extra::Checking::Check

    identifier :stale

    def run
      require 'set'

      item_rep_paths = Set.new(@site.items.collect { |i| i.reps }.flatten.collect { |r| r.raw_path })

      self.output_filenames.each do |f|
        next if self.pruner.filename_excluded?(f)
        if !item_rep_paths.include?(f)
          self.add_issue(
            "file without matching item",
            :subject  => f)
        end
      end
    end

    protected

    def pruner
      exclude_config = @site.config.fetch(:prune, {}).fetch(:exclude, [])
      @pruner ||= Nanoc::Extra::Pruner.new(@site, :exclude => exclude_config)
    end

  end

end
