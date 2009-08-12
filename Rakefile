namespace :specs  do

  desc 'Execute all specs'
  task :all do
    file = "#{File.dirname(__FILE__)}/specs/*_spec.rb"
    Kernel.system( "spec -c --format=specdoc #{file}" )
  end

end