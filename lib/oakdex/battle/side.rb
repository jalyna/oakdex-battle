require 'forwardable'

module Oakdex
  class Battle
    # Represents a side in an active battle, has n trainers
    class Side
      extend Forwardable

      def_delegators :@battle, :add_to_log

      attr_reader :trainers, :battle

      def initialize(battle, trainers)
        @battle = battle
        @trainers = trainers
      end

      def send_to_battle
        @trainers.map do |trainer|
          trainer.send_to_battle(trainer.team.first, self)
        end
      end

      def remove_fainted
        @trainers.each(&:remove_fainted)
      end

      def trainer_on_side?(trainer)
        @trainers.include?(trainer)
      end

      def in_battle_pokemon
        @trainers.map(&:in_battle_pokemon).flatten(1)
      end

      def fainted?
        @trainers.all?(&:fainted?)
      end
    end
  end
end
