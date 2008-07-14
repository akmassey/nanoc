require 'helper'

class Nanoc::CLI::CreateSiteCommandTest < Test::Unit::TestCase

  def setup    ; global_setup    ; end
  def teardown ; global_teardown ; end

  def test_create_site_with_existing_name
    in_dir %w{ tmp } do
      assert_nothing_raised()   { Nanoc::CLI::Base.new.run([ 'create_site', 'foo' ]) }
      assert_raise(SystemExit)  { Nanoc::CLI::Base.new.run([ 'create_site', 'foo' ]) }
    end
  end

end
