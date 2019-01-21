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
        return [] if no_battle_pokemon?(trainer) && own_battle_pokemon?(trainer)
        valid_move_actions_for(trainer) + valid_recall_actions_for(trainer)
      end

      private

      def valid_move_actions_for(trainer)
        trainer.active_in_battle_pokemon.flat_map(&:valid_move_actions)
      end

      def valid_recall_actions_for(trainer)
        trainer.left_pokemon_in_team.flat_map do |pokemon|
          pokemon_per_trainer.times.map do |position|
            recall_action(trainer,
                          trainer.active_in_battle_pokemon[position],
                          pokemon)
          end.compact
        end
      end

      def recall_action(trainer, active_ibp, target)
        return if !recall_action_valid?(trainer, active_ibp, target) ||
                  recall_action_for?(target)
        {
          action: 'recall',
          pokemon: active_ibp&.position || side(trainer).next_position,
          target: target
        }
      end

      def recall_action_valid?(trainer, active_in_battle_pokemon, _target)
        if active_in_battle_pokemon
          !active_in_battle_pokemon.action_added?
        else
          next_position = side(trainer).next_position
          next_position && !recall_action_for_position?(next_position)
        end
      end

      def pokemon_per_trainer
        sides.first.trainers.size
      end

      def recall_action_for?(target)
        actions.any? do |action|
          action.type == 'recall' && action.target == target
        end
      end

      def recall_action_for_position?(position)
        actions.any? do |action|
          action.type == 'recall' && action.pokemon_position == position
        end
      end

      def no_battle_pokemon?(trainer)
        other_sides(trainer).all? { |s| s.active_in_battle_pokemon.empty? }
      end

      def own_battle_pokemon?(trainer)
        !side(trainer).active_in_battle_pokemon.empty?
      end

      def other_sides(trainer)
        sides.select { |s| !s.trainer_on_side?(trainer) }
      end

      def side(trainer)
        sides.find { |s| s.trainer_on_side?(trainer) }
      end
    end
  end
end
