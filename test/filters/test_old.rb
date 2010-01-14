require 'test/helper'

class Nanoc2::Filters::OldTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_filter
    assert_raises(Nanoc2::Error) do
      # Create site
      site = mock

      # Create page
      page = mock
      page.expects(:site).returns(site)

      # Create page rep
      page_rep = mock
      page_rep.expects(:is_a?).with(Nanoc2::PageRep).returns(true)
      page_rep.expects(:page).returns(page)

      # Get filter
      filter = ::Nanoc2::Filters::Old.new(page_rep)

      # Run filter
      result = filter.run("blah")
    end
  end

end
