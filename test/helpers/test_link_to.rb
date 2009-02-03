require 'test/helper'

class Nanoc::Helpers::LinkToTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  include Nanoc::Helpers::LinkTo

  def test_link_to_with_path
    # Check
    assert_equal(
      '<a href="/foo/">Foo</a>',
      link_to('Foo', '/foo/')
    )
  end

  def test_link_to_with_rep
    # Create rep
    rep = mock
    rep.expects(:path).returns('/bar/')

    # Check
    assert_equal(
      '<a href="/bar/">Bar</a>',
      link_to('Bar', rep)
    )
  end

  def test_link_to_with_attributes
    # Check
    assert_equal(
      '<a title="Dis mai foo!" href="/foo/">Foo</a>',
      link_to('Foo', '/foo/', :title => 'Dis mai foo!')
    )
  end

  def test_link_to_escape
    # Check
    assert_equal(
      '<a title="Foo &amp; Bar" href="/foo/">Foo &amp; Bar</a>',
      link_to('Foo &amp; Bar', '/foo/', :title => 'Foo & Bar')
    )
  end

  def test_link_to_unless_current_current
    # Create page
    @page_rep = mock
    @page_rep.expects(:path).at_least_once.returns('/foo/')

    # Check
    assert_equal(
      '<span class="active" title="You\'re here.">Bar</span>',
      link_to_unless_current('Bar', @page_rep)
    )
  ensure
    @page = nil
  end

  def test_link_to_unless_current_not_current
    # Create page
    @page_rep = mock
    @page_rep.expects(:path).at_least_once.returns('/foo/')

    # Check
    assert_equal(
      '<a href="/abc/xyz/">Bar</a>',
      link_to_unless_current('Bar', '/abc/xyz/')
    )
  end

end
