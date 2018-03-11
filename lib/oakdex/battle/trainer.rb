module Oakdex
  class Battle
    # Represents a Pokemon Trainer. Owns Pokemon and has a name
    class Trainer
      attr_reader :name, :team

      def initialize(name, team)
        @name = name
        @team = team
      end
    end
  end
end
