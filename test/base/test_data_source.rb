require 'helper'

class Nanoc::DataSourceTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_loading
    # Create data source
    data_source = Nanoc::DataSource.new(nil)
    data_source.expects(:up).times(1)
    data_source.expects(:down).times(1)

    # Test nested loading
    assert_equal(0, data_source.instance_eval { @references })
    data_source.loading do
      assert_equal(1, data_source.instance_eval { @references })
      data_source.loading do
        assert_equal(2, data_source.instance_eval { @references })
      end
      assert_equal(1, data_source.instance_eval { @references })
    end
    assert_equal(0, data_source.instance_eval { @references })
  end

  def test_not_implemented
    # Create data source
    data_source = Nanoc::DataSource.new(nil)

    # Test optional methods
    assert_nothing_raised { data_source.up }
    assert_nothing_raised { data_source.down }
    assert_nothing_raised { data_source.update }

    # Test required methods - general
    assert_raise(NotImplementedError) { data_source.setup }
    assert_raise(NotImplementedError) { data_source.destroy }

    # Test required methods - pages
    assert_raise(NotImplementedError) { data_source.pages }
    assert_raise(NotImplementedError) { data_source.save_page(nil) }
    assert_raise(NotImplementedError) { data_source.move_page(nil, nil) }
    assert_raise(NotImplementedError) { data_source.delete_page(nil) }

    # Test required methods - page defaults
    assert_raise(NotImplementedError) { data_source.page_defaults }
    assert_raise(NotImplementedError) { data_source.save_page_defaults(nil) }

    # Test required methods - assets
    assert_raise(NotImplementedError) { data_source.assets }
    assert_raise(NotImplementedError) { data_source.save_asset(nil) }
    assert_raise(NotImplementedError) { data_source.move_asset(nil, nil) }
    assert_raise(NotImplementedError) { data_source.delete_asset(nil) }

    # Test required methods - asset defaults
    assert_raise(NotImplementedError) { data_source.asset_defaults }
    assert_raise(NotImplementedError) { data_source.save_asset_defaults(nil) }

    # Test required methods - layouts
    assert_raise(NotImplementedError) { data_source.layouts }
    assert_raise(NotImplementedError) { data_source.save_layout(nil) }
    assert_raise(NotImplementedError) { data_source.move_layout(nil, nil) }
    assert_raise(NotImplementedError) { data_source.delete_layout(nil) }

    # Test required methods - code
    assert_raise(NotImplementedError) { data_source.code }
    assert_raise(NotImplementedError) { data_source.save_code(nil) }
  end

end
