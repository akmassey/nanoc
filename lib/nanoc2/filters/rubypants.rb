module Nanoc2::Filters
  class SmartyPants < Nanoc2::Filter

    identifiers :rubypants

    def run(content)
      require 'rubypants'

      # Get result
      ::RubyPants.new(content).to_html
    end

  end
end
