# encoding: utf-8

class Nanoc::Extra::Checking::Checks::HTMLTest < Nanoc::TestCase

  def test_run_ok
    if_have 'w3c_validators' do
      with_site do |site|
        # Create files
        FileUtils.mkdir_p('output')
        File.open('output/blah.html', 'w') { |io| io.write('<!DOCTYPE html><html><head><meta charset="utf-8"><title>Hello</title></head><body><h1>Hi!</h1></body>') }
        File.open('output/style.css', 'w') { |io| io.write('h1 { coxlor: rxed; }') }

        # Run check
        check = Nanoc::Extra::Checking::Checks::HTML.new(site)
        check.run

        # Check
        assert check.issues.empty?
      end
    end
  end

  def test_run_error
    if_have 'w3c_validators' do
      with_site do |site|
        # Create files
        FileUtils.mkdir_p('output')
        File.open('output/blah.html', 'w') { |io| io.write('<h2>Hi!</h1>') }
        File.open('output/style.css', 'w') { |io| io.write('h1 { coxlor: rxed; }') }

        # Run check
        check = Nanoc::Extra::Checking::Checks::HTML.new(site)
        check.run

        # Check
        refute check.issues.empty?
      end
    end
  end

end

