module Nanoc2::Filters
  class ERB < Nanoc2::Filter

    identifiers :erb

    def run(content)
      require 'erb'

      # Create context
      context = ::Nanoc2::Extra::Context.new(assigns)

      # Get result
      erb = ::ERB.new(content)
      erb.filename = filename
      erb.result(context.get_binding)
    end

  end
end
