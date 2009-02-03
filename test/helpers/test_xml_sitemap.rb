require 'test/helper'

class Nanoc::Helpers::XMLSitemapTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc::Helpers::XMLSitemap

  def test_xml_sitemap
    if_have 'builder' do
      # Create pages
      @pages = [ mock, mock, mock ]

      # Create page 0
      @pages[0].expects(:is_hidden).returns(false)
      @pages[0].expects(:path).returns('/foo/')
      @pages[0].expects(:mtime).returns(nil)
      @pages[0].expects(:changefreq).returns(nil)
      @pages[0].expects(:priority).returns(nil)

      # Create page 1
      @pages[1].expects(:is_hidden).returns(true)

      # Create page 2
      @pages[2].expects(:is_hidden).returns(false)
      @pages[2].expects(:path).returns('/baz/')
      @pages[2].expects(:mtime).times(2).returns(Time.parse('12/07/2004'))
      @pages[2].expects(:changefreq).times(2).returns('daily')
      @pages[2].expects(:priority).times(2).returns(0.5)

      # Create sitemap page
      @page = mock
      @page.expects(:base_url).times(2).returns('http://example.com')

      # Check
      assert_nothing_raised do
        xml_sitemap
      end
    end
  ensure
    @pages = nil
    @page = nil
  end

end
