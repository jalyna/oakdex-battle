module Oakdex
  class Battle
    # Represents one Action. One turn has many actions.
    class Action
      attr_reader :trainer

      def initialize(trainer, attributes)
        @trainer = trainer
        @attributes = attributes
      end

      def pokemon
        @attributes[:pokemon]
      end

      def target
        @attributes[:target]
      end

      def move
        pokemon.moves.find { |m| m.name == @attributes[:move] }
      end

      def hitting_probability
        ((move.accuracy / 100.0) * (pokemon.accuracy / target.evasion)) * 1000
      end
    end
  end
end
