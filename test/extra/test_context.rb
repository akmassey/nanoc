require 'test/helper'

class Nanoc2::Extra::ContextTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_context
    # Create context
    context = Nanoc2::Extra::Context.new({ :foo => 'bar', :baz => 'quux' })

    # Ensure correct evaluation
    assert_equal('bar', eval("@foo", context.get_binding))
  end

end
