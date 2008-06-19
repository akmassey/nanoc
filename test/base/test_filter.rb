require 'helper'

class Nanoc::FilterTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_initialize_with_page_rep
    # Create site
    site = mock

    # Create page
    page = mock
    page_proxy = Nanoc::Proxy.new(page)
    page.expects(:to_proxy).times(2).returns(page_proxy)
    page.expects(:site).returns(site)
    page.expects(:attribute_named).times(2).with(:foo).returns('page attr foo')

    # Create page rep
    page_rep = mock
    page_rep_proxy = Nanoc::Proxy.new(page_rep)
    page_rep.expects(:to_proxy).times(2).returns(page_rep_proxy)
    page_rep.expects(:is_a?).with(Nanoc::PageRep).returns(true)
    page_rep.expects(:page).returns(page)
    page_rep.expects(:attribute_named).times(2).with(:foo).returns('page rep attr foo')

    # Create filter
    filter = Nanoc::Filter.new(page_rep)

    # Test objects
    assert_equal('page attr foo',     filter.instance_eval { @obj.to_proxy.foo })
    assert_equal('page rep attr foo', filter.instance_eval { @obj_rep.to_proxy.foo })

    # Test page
    assert_equal('page attr foo',     filter.instance_eval { @page.to_proxy.foo })
    assert_equal('page rep attr foo', filter.instance_eval { @page_rep.to_proxy.foo })

    # Test asset
    assert_equal(nil,                 filter.instance_eval { @asset })
    assert_equal(nil,                 filter.instance_eval { @asset_rep })
  end

  def test_initialize_with_asset_rep
    # Create site
    site = mock

    # Create asset
    asset = mock
    asset_proxy = Nanoc::Proxy.new(asset)
    asset.expects(:to_proxy).times(2).returns(asset_proxy)
    asset.expects(:site).returns(site)
    asset.expects(:attribute_named).times(2).with(:foo).returns('asset attr foo')

    # Create asset rep
    asset_rep = mock
    asset_rep_proxy = Nanoc::Proxy.new(asset_rep)
    asset_rep.expects(:to_proxy).times(2).returns(asset_rep_proxy)
    asset_rep.expects(:is_a?).with(Nanoc::PageRep).returns(false)
    asset_rep.expects(:asset).returns(asset)
    asset_rep.expects(:attribute_named).times(2).with(:foo).returns('asset rep attr foo')

    # Create filter
    filter = Nanoc::Filter.new(asset_rep)

    # Test objects
    assert_equal('asset attr foo',      filter.instance_eval { @obj.to_proxy.foo })
    assert_equal('asset rep attr foo',  filter.instance_eval { @obj_rep.to_proxy.foo })

    # Test page
    assert_equal(nil,                   filter.instance_eval { @page })
    assert_equal(nil,                   filter.instance_eval { @page_rep })

    # Test asset
    assert_equal('asset attr foo',      filter.instance_eval { @asset.to_proxy.foo })
    assert_equal('asset rep attr foo',  filter.instance_eval { @asset_rep.to_proxy.foo })
  end

  def test_assigns
    # Create site
    site = mock

    # Create page
    page_rep = mock
    page = mock
    page_proxy = Nanoc::Proxy.new(page)
    page.expects(:to_proxy).returns(page_proxy)

    # Create asset
    asset = mock
    asset_proxy = mock
    asset.expects(:site).returns(site)
    asset.expects(:to_proxy).times(2).returns(asset_proxy)

    # Create asset rep
    asset_rep = mock
    asset_rep_proxy = mock
    asset_rep.expects(:is_a?).with(Nanoc::PageRep).returns(false)
    asset_rep.expects(:asset).returns(asset)
    asset_rep.expects(:to_proxy).returns(asset_rep_proxy)

    # Create layout
    layout = mock
    layout_proxy = Nanoc::Proxy.new(layout)
    layout.expects(:to_proxy).returns(layout_proxy)

    # Create site
    site.expects(:assets).returns([ asset ])
    site.expects(:pages).returns([ page ])
    site.expects(:layouts).returns([ layout ])
    site.expects(:config).returns({ :xxx => 'yyy' })

    # Create filter
    filter = Nanoc::Filter.new(asset_rep, { :foo => 'bar' })

    # Check normal assigns
    assert_equal(nil,               filter.assigns[:page])
    assert_equal(nil,               filter.assigns[:page_rep])
    assert_equal(asset_proxy,       filter.assigns[:asset])
    assert_equal(asset_rep_proxy,   filter.assigns[:asset_rep])
    assert_equal([ page_proxy ],    filter.assigns[:pages])
    assert_equal([ asset_proxy ],   filter.assigns[:assets])
    assert_equal([ layout_proxy ],  filter.assigns[:layouts])
    assert_equal({ :xxx => 'yyy' }, filter.assigns[:config])

    # Check other assigns
    assert_equal('bar', filter.assigns[:foo])
  end

  def test_run
    # Create site
    site = mock

    # Create asset
    asset = mock
    asset_proxy = Nanoc::Proxy.new(asset)
    asset.expects(:site).returns(site)

    # Create asset rep
    asset_rep = mock
    asset_rep_proxy = Nanoc::Proxy.new(asset_rep)
    asset_rep.expects(:is_a?).with(Nanoc::PageRep).returns(false)
    asset_rep.expects(:asset).returns(asset)

    # Create filter
    filter = Nanoc::Filter.new(asset_rep)

    # Make sure an error is raised
    assert_raise(NotImplementedError) do
      filter.run(nil)
    end
  end

  def test_extensions
    # Create site
    site = mock

    # Create asset
    asset = mock
    asset_proxy = Nanoc::Proxy.new(asset)
    asset.expects(:site).returns(site)

    # Create asset rep
    asset_rep = mock
    asset_rep_proxy = Nanoc::Proxy.new(asset_rep)
    asset_rep.expects(:is_a?).with(Nanoc::PageRep).returns(false)
    asset_rep.expects(:asset).returns(asset)

    # Create filter
    filter = Nanoc::Filter.new(asset_rep)

    # Update extension
    filter.class.class_eval { extension :foo }

    # Check
    assert_equal(:foo, filter.class.class_eval { extension })
    assert_equal([ :foo ], filter.class.class_eval { extensions })

    # Update extension
    filter.class.class_eval { extensions :foo, :bar }

    # Check
    assert_equal([ :foo, :bar ], filter.class.class_eval { extensions })
  end

end
