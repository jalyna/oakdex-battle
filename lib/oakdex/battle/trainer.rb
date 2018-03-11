module Oakdex
  class Battle
    # Represents a Pokemon Trainer. Owns Pokemon and has a name
    class Trainer
      def initialize(name, pokemon_team)
        @name = name
        @team = pokemon_team
      end
    end
  end
end
