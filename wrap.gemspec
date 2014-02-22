## wrap.gemspec
#

Gem::Specification::new do |spec|
  spec.name = "wrap"
  spec.version = "1.5.2"
  spec.platform = Gem::Platform::RUBY
  spec.summary = "wrap"
  spec.description = "non-sucking :before and :after filters for any ruby class"
  spec.license = "same as ruby's"

  spec.files =
["README",
 "Rakefile",
 "lib",
 "lib/wrap.rb",
 "test",
 "test/testing.rb",
 "test/wrap_test.rb",
 "wrap.gemspec"]

  spec.executables = []
  
  spec.require_path = "lib"

  spec.test_files = nil

  
    spec.add_dependency(*["map", " >= 4.7.1"])
  

  spec.extensions.push(*[])

  spec.rubyforge_project = "codeforpeople"
  spec.author = "Ara T. Howard"
  spec.email = "ara.t.howard@gmail.com"
  spec.homepage = "https://github.com/ahoward/wrap"
end
