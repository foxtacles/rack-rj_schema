$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new 'rack-rj_schema', '0.1.0' do |s|
  s.licenses = %w[MIT]
  s.summary = "Rack middleware for RequestObject/ViewModel JSON schema validations"
  s.description = "Rack middleware for RequestObject/ViewModel JSON schema validations"
  s.authors = ['Christian Semmler']
  s.email = ['mail@csemmler.com']
  s.homepage = 'https://github.com/software-partner/rack-rj-schema'
  s.files = %w[
    Rakefile
  ] + Dir['lib/**/*']
  s.add_dependency 'rack'
  s.add_dependency 'rj_schema'
  s.add_dependency 'activesupport'
  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-byebug'
end
