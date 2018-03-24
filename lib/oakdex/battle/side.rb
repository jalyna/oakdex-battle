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

      def next_position
        left_position.first
      end

      def send_to_battle
        @trainers.map do |trainer|
          battle.pokemon_per_side.times do |i|
            break unless trainer.team[i]
            trainer.send_to_battle(trainer.team[i], self)
          end
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

      private

      def left_position
        all_position - taken_positions
      end

      def taken_positions
        in_battle_pokemon.map(&:position).sort
      end

      def all_position
        battle.pokemon_per_side.times.to_a
      end
    end
  end
end
