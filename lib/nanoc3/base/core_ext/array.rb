# encoding: utf-8

module Nanoc3::ArrayExtensions

  # Returns a new array where all items' keys are recursively converted to symbols by calling #symbolize_keys.
  def symbolize_keys
    inject([]) do |array, element|
      array + [ element.respond_to?(:symbolize_keys) ? element.symbolize_keys : element ]
    end
  end

  # Returns a new array where all items' keys are recursively converted to strings by calling #stringify_keys.
  def stringify_keys
    inject([]) do |array, element|
      array + [ element.respond_to?(:stringify_keys) ? element.stringify_keys : element ]
    end
  end

end

class Array
  include Nanoc3::ArrayExtensions
end
