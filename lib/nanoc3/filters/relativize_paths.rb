module Nanoc3::Filters
  class RelativizePaths < Nanoc3::Filter

    require 'nanoc3/helpers/link_to'
    include Nanoc3::Helpers::LinkTo

    def run(content, params={})
      type = params[:type] || :html

      case type
      when :html
        content.gsub(/(src|href)=(['"]?)(\/.+?)\2([ >])/) do
          $1 + '=' + $2 + relative_path_to($3) + $2 + $4
        end
      when :css
        content.gsub(/url\((['"]?)(\/.+?)\1\)/) do
          'url(' + $1 + relative_path_to($2) + $1 + ')'
        end
      end
    end

  end
end
