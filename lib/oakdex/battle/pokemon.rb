require 'oakdex/battle/pokemon_stat'
require 'oakdex/battle/move'
require 'oakdex/battle/pokemon_factory'

module Oakdex
  class Battle
    # Represents detailed pokemon instance
    class Pokemon
      BATTLE_STATS = %i[hp atk def sp_atk sp_def speed]

      def self.create(species_name, options = {})
        species = Oakdex::Pokedex::Pokemon.find!(species_name)
        Oakdex::Battle::PokemonFactory.create(species, options)
      end

      def initialize(species, attributes = {})
        @species = species
        @attributes = attributes
      end
    end
  end
end
