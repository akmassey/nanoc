# encoding: utf-8

module Nanoc3::Helpers

  # Provides functionality for “capturing” content in one place and reusing
  # this content elsewhere.
  #
  # For example, suppose you want the sidebar of your site to contain a short
  # summary of the item. You could put the summary in the meta file, but
  # that’s not possible when the summary contains eRuby. You could also put
  # the sidebar inside the actual item, but that’s not very pretty. Instead,
  # you write the summary on the item itself, but capture it, and print it in
  # the sidebar layout.
  #
  # This helper has been tested with ERB and Haml. Other filters may not work
  # correctly.
  #
  # @example Capturing content into a `content_for_summary` attribute
  #
  #   <% content_for :summary do %>
  #     <p>On this item, nanoc is introduced, blah blah.</p>
  #   <% end %>
  #
  # @example Showing captured content in a sidebar
  #
  #   <div id="sidebar">
  #     <h3>Summary</h3>
  #     <%= content_for(@item, :summary) || '(no summary)' %>
  #   </div>
  #
  # @example Showing captured content in a sidebar the old, deprecated way (do not use or I will become very angry)
  #
  #   <div id="sidebar">
  #     <h3>Summary</h3>
  #     <%= @item[:content_for_summary] || '(no summary)' %>
  #   </div>
  module Capturing

    # @overload content_for(name, &block)
    #
    #   Captures the content inside the block and stores it so that it can be
    #   referenced later on. The same method, {#content_for}, is used for
    #   getting the captured content as well as setting it. When capturing,
    #   the content of the block itself will not be outputted.
    #
    #   For backwards compatibility, it is also possible to fetch the captured
    #   content by getting the contents of the attribute named `content_for_`
    #   followed by the given name. This way of accessing captures is
    #   deprecated.
    #
    #   @param [Symbol, String] name The base name of the attribute into which
    #     the content should be stored
    #
    #   @return [void]
    #
    # @overload content_for(item, name)
    #
    #   Fetches the capture with the given name from the given item and
    #   returns it. The captured content will not be outputted.
    #
    #   @param [Nanoc3::Item] item The item for which to get the capture
    #
    #   @param [Symbol, String] name The name of the capture to fetch
    #
    #   @return [String] The stored captured content
    def content_for(*args, &block)
      # Initialize
      @_Nanoc3_Helpers_Capturing_captures ||= {}
      @_Nanoc3_Helpers_Capturing_captures[@item.identifier] ||= {}

      if block_given? # Set content
        # Get args
        if args.size != 1
          raise ArgumentError, "expected 1 argument (the name of the capture) but got #{args.size} instead"
        end
        name = args[0]

        # Capture and store
        content = capture(&block)
        @item["content_for_#{name}".to_sym] = content # FIXME don’t do this
        @_Nanoc3_Helpers_Capturing_captures[@item.identifier][name.to_sym] = content
      else # Get content
        # Get args
        if args.size != 2
          raise ArgumentError, "expected 2 arguments (the item and the name of the capture) but got #{args.size} instead"
        end
        item = args[0]
        name = args[1]

        # Get content
        @_Nanoc3_Helpers_Capturing_captures[item.identifier][name]
      end
    end

    # Evaluates the given block and returns its contents. The contents of the
    # block is not outputted.
    #
    # @return [String] The captured result
    def capture(&block)
      # Get erbout so far
      erbout = eval('_erbout', block.binding)
      erbout_length = erbout.length

      # Execute block
      block.call

      # Get new piece of erbout
      erbout_addition = erbout[erbout_length..-1]

      # Remove addition
      erbout[erbout_length..-1] = ''

      # Done
      erbout_addition
    end

  end

end
