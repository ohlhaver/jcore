# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{jcore}
  s.version = "1.0.2"
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ram Singla"]
  s.date = %q{2009-08-31}
  s.description = %q{JCore is web data extraction library.}
  s.email = %q{ram.singla@gmail.com}
  s.extra_rdoc_files = ["README.markdown"]
  s.files = [ 
    "README.markdown", 
    "VERSION.yml", 
    "lib/jcore.rb", 
    "lib/clean.rb",
    "lib/distance.rb",
    "lib/extracter.rb",
    "lib/keyword.rb",
    "lib/learner.rb",
    "lib/pattern.rb",
    "lib/template.rb",
    "lib/token.rb",
    "lib/tokenizer.rb",
    "lib/xpath.rb",
    "lib/clean/AGENCIES",
    "lib/clean/EN.STOPWORDS",
    "lib/clean/DE.STOPWORDS",
    "lib/keywords/EN.STOPWORDS",
    "lib/keywords/DE.STOPWORDS" 
  ]
  s.has_rdoc = true
  s.homepage = %q{https://github.com/ohlhaver/jcore}
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{JCore is web data extraction library.}
  
  dependencies = { 
    'hpricot' => '= 0.6.164', 
    'htmlentities' => '>= 4.1.0', 
    'multibyte' => '>=0.1.1',
    'ruby-stemmer' => '>=0.5.3'
  }
  
  if s.respond_to?(:specification_version) && 
    Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0')
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
    dependencies.each_pair do |gg, vv|
      s.add_runtime_dependency(gg, vv)
    end
  else
    dependencies.each_pair do |gg, vv|
      s.add_dependency(gg, vv)
    end
  end
end

