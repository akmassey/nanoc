require 'nanoc3/package'

namespace :doc do

  desc 'Build the RDoc documentation'
  task :rdoc do
    # Clean
    FileUtils.rm_r 'doc' if File.exist?('doc')

    # Build
    rdoc_files   = Nanoc3::Package.instance.gem_spec.extra_rdoc_files + [ 'lib' ]
    rdoc_options = Nanoc3::Package.instance.gem_spec.rdoc_options
    system *[ 'rdoc', rdoc_files, rdoc_options ].flatten
  end

  desc 'Build the YARD documentation'
  task :yardoc do
    # Clean
    FileUtils.rm_r 'doc' if File.exist?('doc')

    # Get options
    yardoc_files   = Dir.glob('lib/nanoc3/base/**/*.rb') +
                     Dir.glob('lib/nanoc3/data_sources/**/*.rb') +
                     Dir.glob('lib/nanoc3/extra/**/*.rb') +
                     Dir.glob('lib/nanoc3/helpers/**/*.rb')
    yardoc_options = [
      '--verbose',
      '--readme', 'README'
    ]

    # Build
    system *[ 'yardoc', yardoc_files, yardoc_options ].flatten
  end

end

desc 'Alias for doc:rdoc'
task :doc => [ :'doc:rdoc' ]
