require 'test/helper'

class Nanoc::DataSources::FilesystemTest < MiniTest::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  # Test preparation

  def test_setup
    in_dir %w{ tmp } do
      # Create site
      create_site('site')

      in_dir %w{ site } do
        # Get site
        site = Nanoc::Site.new(YAML.load_file('config.yaml'))

        # Remove files to make sure they are recreated
        FileUtils.rm_rf('assets')
        FileUtils.rm_rf('asset_defaults.yaml')
        FileUtils.rm_rf('content')
        FileUtils.rm_rf('page_defaults.yaml')
        FileUtils.rm_rf('meta.yaml')
        FileUtils.rm_rf('layouts/default')
        FileUtils.rm_rf('lib/default.rb')

        # Mock VCS
        vcs = mock
        vcs.expects(:add).times(4) # One time for each directory
        site.data_source.vcs = vcs

        # Recreate files
        site.data_source.loading { site.data_source.setup {} }

        # Ensure essential files have been recreated
        assert(File.directory?('assets/'))
        assert(File.directory?('content/'))
        assert(File.directory?('layouts/'))
        assert(File.directory?('lib/'))

        # Ensure no non-essential files have been recreated
        assert(!File.file?('asset_defaults.yaml'))
        assert(!File.file?('content/content.html'))
        assert(!File.file?('content/content.yaml'))
        assert(!File.directory?('layouts/default/'))
        assert(!File.file?('meta.yaml'))
        assert(!File.file?('page_defaults.yaml'))
        assert(!File.file?('lib/default.rb'))
      end
    end
  end

  def test_destroy
    with_temp_site do |site|
      # Mock VCS
      vcs = mock
      vcs.expects(:remove).times(6) # One time for each directory
      site.data_source.vcs = vcs

      # Destroy
      site.data_source.destroy
     end
  end

  def test_update
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil)

    # Set expectations
    data_source.expects(:update_page_defaults)
    data_source.expects(:update_pages)

    # update
    data_source.update
  end

  def test_update_page_defaults
    in_dir %w{ tmp } do
      # Build outdated page defaults
      File.open('meta.yaml', 'w') { |io| }

      # Get data source
      data_source = Nanoc::DataSources::Filesystem.new(nil)

      # Mock VCS
      vcs = mock
      vcs.expects(:move).with('meta.yaml', 'page_defaults.yaml')
      data_source.vcs = vcs

      # Update page defaults
      data_source.instance_eval { update_page_defaults }
    end
  end

  def test_update_pages
    in_dir %w{ tmp } do
      # Build some pages (outdated and up-to-date)
      FileUtils.mkdir_p('content')
      FileUtils.mkdir_p('content/foo')
      FileUtils.mkdir_p('content/foo/bar')
      File.open('content/index.erb',        'w') { |io| }
      File.open('content/meta.yaml',        'w') { |io| }
      File.open('content/foo/index.haml',   'w') { |io| }
      File.open('content/foo/meta.yaml',    'w') { |io| }
      File.open('content/foo/bar/bar.haml', 'w') { |io| }
      File.open('content/foo/bar/bar.yaml', 'w') { |io| }

      # Update
      data_source = Nanoc::DataSources::Filesystem.new(nil)
      data_source.instance_eval { update_pages }

      # Check old files
      assert(!File.file?('content/index.erb'))
      assert(!File.file?('content/meta.yaml'))
      assert(!File.file?('content/foo/index.haml'))
      assert(!File.file?('content/foo/meta.yaml'))

      # Check new files
      assert(File.file?('content/content.erb'))
      assert(File.file?('content/content.yaml'))
      assert(File.file?('content/foo/foo.haml'))
      assert(File.file?('content/foo/foo.yaml'))
      assert(File.file?('content/foo/bar/bar.haml'))
      assert(File.file?('content/foo/bar/bar.yaml'))
    end
  end

  # Test pages

  def test_pages
    with_temp_site do |site|
      assert_equal([ 'Home' ], site.pages.map { |page| page.attribute_named(:title) })
    end
  end

  def test_save_page
    with_temp_site do |site|
      # Check pages
      assert_equal(1, site.pages.size)
      old_page = site.pages[0]

      # Create page
      new_page = Nanoc::Page.new('Hello, I am a noob.', { :foo => 'bar' }, '/noob/')
      site.data_source.save_page(new_page)
      site.load_data(true)

      # Check pages
      assert_equal(2, site.pages.size)

      # Update page
      old_page.attributes = { :xyzzy => 'abba' }
      site.data_source.save_page(old_page)
      site.load_data(true)

      # Check pages
      assert_equal(2, site.pages.size)
      assert(site.pages.any? { |p| p.attribute_named(:xyzzy) == 'abba' })
    end
  end

  def test_move_page
    # TODO implement
  end

  def test_delete_page
    # TODO implement
  end

  # Test assets

  def test_assets
    with_temp_site do |site|
      # Create asset with extension
      FileUtils.mkdir_p('assets/foo')
      File.open('assets/foo/foo.yaml', 'w') do |io|
        io.write("filters: []\n")
        io.write("extension: newfooext\n")
      end
      File.open('assets/foo/foo.fooext', 'w') do |io|
        io.write('Lorem ipsum dolor sit amet...')
      end

      # Create asset without extension
      FileUtils.mkdir_p('assets/bar')
      File.open('assets/bar/bar.yaml', 'w') do |io|
        io.write("filters: []\n")
      end
      File.open('assets/bar/bar.barext', 'w') do |io|
        io.write("Lorem ipsum dolor sit amet...")
      end

      # Reload data
      site.load_data(true)

      # Check assets
      assert_equal(2, site.assets.size)
      assert(site.assets.any? { |a| a.attribute_named(:extension) == 'newfooext' })
      assert(site.assets.any? { |a| a.attribute_named(:extension) == 'barext' })
    end
  end

  def test_save_asset
    # TODO implement
  end

  def test_move_asset
    # TODO implement
  end

  def test_delete_asset
    # TODO implement
  end

  # Test page defaults

  def test_page_defaults
    with_temp_site do |site|
      assert_equal('html', site.page_defaults.attributes[:extension])
    end
  end

  def test_save_page_defaults
    with_temp_site do |site|
      # Get page defaults
      page_defaults = site.page_defaults

      # Update page defaults
      page_defaults.attributes[:extension] = 'php' # eww, php! :D
      site.data_source.save_page_defaults(page_defaults)
      site.load_data(true)

      # Check page defaults
      assert_equal('php', site.page_defaults.attributes[:extension])
    end
  end

  # Test asset defaults

  def test_asset_defaults
    with_temp_site do |site|
      assert_equal([], site.asset_defaults.attributes[:filters])
    end
  end

  def test_save_asset_defaults
    with_temp_site do |site|
      # Get asset defaults
      asset_defaults = site.asset_defaults

      # Update asset defaults
      asset_defaults.attributes[:foo] = 'bar'
      site.data_source.save_asset_defaults(asset_defaults)
      site.load_data(true)

      # Check asset defaults
      assert_equal('bar', site.asset_defaults.attributes[:foo])
    end
  end

  # Test layouts

  def test_layouts
    with_temp_site do |site|
      layout = site.layouts[0]

      assert_equal('/default/', layout.path)
      assert_equal('erb', layout.attribute_named(:filter))
      assert(layout.content.include?('<%= @page.title %></title>'))
    end
  end

  def test_save_layout
    # TODO implement
  end

  def test_move_layout
    # TODO implement
  end

  def test_delete_layout
    # TODO implement
  end

  # Test code

  def test_code
    with_temp_site do |site|
      assert_match(/# All files in the 'lib' directory will be loaded/, site.code.data)
    end
  end

  def test_save_code
    # TODO implement
  end

  # Test private methods

  def test_meta_filenames
    # TODO implement
  end

  def test_content_filename_for_dir_with_one_content_file
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/bar/baz')
    File.open('tmp/foo/bar/baz/baz.html', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'tmp/foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('tmp/foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_two_content_files
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/bar/baz')
    File.open('tmp/foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.xhtml', 'w') { |io| io.write('test') }

    # Check content filename
    assert_raises(RuntimeError) do
      assert_equal(
        'tmp/foo/bar/baz/baz.html',
        data_source.instance_eval do
          content_filename_for_dir('tmp/foo/bar/baz')
        end
      )
    end
  end

  def test_content_filename_for_dir_with_one_content_and_one_meta_file
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/bar/baz')
    File.open('tmp/foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.yaml', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'tmp/foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('tmp/foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_one_content_and_many_meta_files
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/bar/baz')
    File.open('tmp/foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.yaml', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/foo.yaml', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/zzz.yaml', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'tmp/foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('tmp/foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_one_content_file_and_rejected_files
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/bar/baz')
    File.open('tmp/foo/bar/baz/baz.html', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.html~', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.html.orig', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.html.rej', 'w') { |io| io.write('test') }
    File.open('tmp/foo/bar/baz/baz.html.bak', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'tmp/foo/bar/baz/baz.html',
      data_source.instance_eval do
        content_filename_for_dir('tmp/foo/bar/baz')
      end
    )
  end

  def test_content_filename_for_dir_with_one_index_content_file
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/bar/baz')
    File.open('tmp/foo/bar/baz/index.html', 'w') { |io| io.write('test') }

    # Check content filename
    assert_equal(
      'tmp/foo/bar/baz/index.html',
      data_source.instance_eval do
        content_filename_for_dir('tmp/foo/bar/baz')
      end
    )
  end

  # Miscellaneous

  def test_meta_filenames_error
    # TODO implement
  end

  def test_content_filename_for_dir_error
    # TODO implement
  end

  def test_content_filename_for_dir_index_error
    # Create data source
    data_source = Nanoc::DataSources::Filesystem.new(nil)

    # Build directory
    FileUtils.mkdir_p('tmp/foo/index')
    File.open('tmp/foo/index/index.html', 'w') { |io| io.write('test') }

    # Check
    assert_equal(
      'tmp/foo/index/index.html',
      data_source.instance_eval { content_filename_for_dir('tmp/foo/index') }
    )
  end

  def test_compile_site_with_file_object
    with_site_fixture 'site_with_file_object' do |site|
      site.compiler.run

      assert(File.file?('output/index.html'))
      assert_equal(1, Dir[File.join('output', '*')].size)
      assert(File.read('output/index.html').include?("This page was last modified at #{File.new('content/content.erb').mtime}."))
    end
  end

  def test_compile_site_with_backup_files
    with_site_fixture 'site_with_backup_files' do |site|
      File.open('content/content.txt~', 'w')          { |io| }
      File.open('layouts/default/default.erb~', 'w')  { |io| }
      File.open('layouts/default/default.yaml~', 'w') { |io| }

      site.compiler.run
      site.compiler.run

      FileUtils.rm_rf 'content/content.txt~'          if File.exist?('content/content.txt~')
      FileUtils.rm_rf 'layouts/default/default.erb~'  if File.exist?('layouts/default/default.erb~')
      FileUtils.rm_rf 'layouts/default/default.yaml~' if File.exist?('layouts/default/default.yaml~')
    end
  end

  def test_compile_site_with_new_layout_structure
    with_site_fixture 'site_with_new_layout_structure' do |site|
      site.compiler.run
      site.compiler.run

      assert(File.file?('output/index.html'))
      assert_equal(1, Dir[File.join('output', '*')].size)
      assert(File.read('output/index.html').include?('<div class="supercool">Blah blah blah this is a page blah blah blah.</div>'))
    end
  end

  def test_compile_huge_site
    with_temp_site do |site|
      # Create a lot of pages
      count = Process.getrlimit(Process::RLIMIT_NOFILE)[0] + 5
      count.times do |i|
        FileUtils.mkdir("content/#{i}")
        File.open("content/#{i}/#{i}.html", 'w') { |io| io << "This is page #{i}." }
        File.open("content/#{i}/#{i}.yaml", 'w') { |io| io << "title: Page #{i}"   }
      end

      # Load and compile site
      site = Nanoc::Site.new(YAML.load_file('config.yaml'))
      site.compiler.run
    end
  end

end
