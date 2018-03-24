require 'forwardable'

module Oakdex
  class Battle
    # Generates all valid actions within the battle
    class ValidActionService
      extend Forwardable

      def_delegators :@battle, :actions, :sides

      def initialize(battle)
        @battle = battle
      end

      def valid_actions_for(trainer)
        return [] if sides.empty?
        return [] if no_battle_pokemon?(trainer)
        valid_move_actions_for(trainer) + valid_recall_actions_for(trainer)
      end

      private

      def valid_move_actions_for(trainer)
        trainer.in_battle_pokemon.flat_map(&:valid_move_actions)
      end

      def valid_recall_actions_for(trainer)
        trainer.left_pokemon_in_team.flat_map do |pokemon|
          pokemon_per_trainer.times.map do |position|
            recall_action(trainer.in_battle_pokemon[position],
                          pokemon)
          end.compact
        end
      end

      def recall_action(in_battle_pokemon, target)
        return if in_battle_pokemon && in_battle_pokemon.action_added?
        return if recall_action_for?(target)
        {
          action: 'recall',
          pokemon: in_battle_pokemon&.pokemon,
          target: target
        }
      end

      def pokemon_per_trainer
        sides.first.trainers.size
      end

      def recall_action_for?(target)
        actions.any? do |action|
          action.type == 'recall' && action.target == target
        end
      end

      def no_battle_pokemon?(trainer)
        other_sides(trainer).all? { |s| s.in_battle_pokemon.empty? }
      end

      def other_sides(trainer)
        sides.select { |s| !s.trainer_on_side?(trainer) }
      end
    end
  end
end
