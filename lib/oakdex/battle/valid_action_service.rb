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
        valid_move_actions_for(trainer) +
          valid_recall_actions_for(trainer) +
          valid_item_actions_for(trainer)
      end

      private

      def valid_move_actions_for(trainer)
        trainer.active_in_battle_pokemon.flat_map(&:valid_move_actions)
      end

      def valid_item_actions_for(trainer)
        return [] if actions.select { |a| a.trainer == trainer }.size >= pokemon_per_trainer
        trainer.items.flat_map do |item_id|
          trainer.team.flat_map.with_index do |pokemon, i|
            next if actions.any? { |a| a.item_id == item_id }
            next unless pokemon.usable_item?(item_id, in_battle: true)
            possible_item_actions(pokemon, item_id).map do |item_actions|
              {
                action: 'use_item_on_pokemon',
                pokemon_team_pos: i,
                item_id: item_id,
                item_actions: item_actions
              }
            end
          end.compact
        end - actions
      end

      def possible_item_actions(battle_pokemon, item_id, prevActions = [])
        dup_pokemon = battle_pokemon.pokemon.dup
        dup_pokemon.use_item(item_id, in_battle: true)
        e = dup_pokemon.growth_event
        return [[]] if !e || e.read_only?
        prevActions.each do |a|
          e.execute(a)
          e = dup_pokemon.growth_event
        end
        return [prevActions] if e.read_only?
        e.possible_actions.flat_map do |a|
          r = possible_item_actions(battle_pokemon, item_id, prevActions + [a])
          r
        end
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
