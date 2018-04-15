$LOAD_PATH << File.expand_path('../lib', __FILE__)
require 'oakdex/battle/version'

Gem::Specification.new do |s|
  s.name        = 'oakdex-battle'
  s.version     = Oakdex::Battle::VERSION
  s.summary     = 'Pokémon Battle Engine in Ruby'
  s.description = 'Pokémon Battle Engine Gen 7 Gem, based on oakdex-pokedex'
  s.authors     = ['Jalyna Schroeder']
  s.email       = 'jalyna.schroeder@gmail.com'
  s.files       = Dir.glob('lib/**/**') + %w[README.md]
  s.homepage    = 'http://github.com/jalyna/oakdex-battle'
  s.license     = 'MIT'
  s.add_runtime_dependency 'oakdex-pokedex', '>= 0.2.2'
end
