namespace :specs  do

  desc 'Execute all specs'
  task :all do
    file = "#{File.dirname(__FILE__)}/specs/*_spec.rb"
    Kernel.system( "spec -c --format=specdoc #{file}" )
  end

end

namespace :learn do
  
  desc 'Learn all templates'
  task :all do
    sources = Dir["#{File.dirname(__FILE__)}/data/labeled_stories/*.html"].inject([]) do |s, file| 
      source = File.basename(file).split('_').first
      s << source
    end
    sources.uniq!
    sources.each do |source| 
      next unless source
      puts "Learning Source: #{source}"
      Kernel.system( "#{File.dirname(__FILE__)}/script/learn -s #{source}")
    end
  end
end