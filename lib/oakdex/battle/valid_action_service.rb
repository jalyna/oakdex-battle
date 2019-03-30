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
        return [] if no_actions_for?(trainer)
        growth_events = growth_event_actions(trainer)
        return growth_events unless growth_events.empty?
        valid_move_actions_for(trainer) +
          valid_recall_actions_for(trainer) +
          valid_item_actions_for(trainer)
      end

      private

      def actions_for_trainer(trainer)
        actions.select { |a| a.trainer == trainer }
      end

      def no_actions_for?(trainer)
        growth_events = growth_event_actions(trainer)
        sides.empty? ||
          (no_battle_pokemon?(trainer) && growth_events.empty?) ||
          (other_is_growing?(trainer) && growth_events.empty?) ||
          added_growth_action_already?(trainer)
      end

      def added_growth_action_already?(trainer)
        growth_events = growth_event_actions(trainer)

        !growth_events.empty? && !actions_for_trainer(trainer).empty?
      end

      def growth_event_actions(trainer)
        while trainer.growth_event? && trainer.growth_event.read_only?
          @battle.add_to_log(trainer.growth_event.message)
          trainer.growth_event.execute
        end

        if trainer.growth_event?
          trainer.growth_event.possible_actions.map do |option|
            {
              action: 'growth_event',
              option: option
            }
          end
        else
          []
        end
      end

      def other_is_growing?(trainer)
        other_trainers = sides.flat_map(&:trainers) - [trainer]
        other_trainers.any? do |t|
          t.growth_event? && !t.growth_event.read_only?
        end
      end

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
          target: target.id
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
          action.type == 'recall' && action.target_id == target.id
        end
      end

      def recall_action_for_position?(position)
        actions.any? do |action|
          action.type == 'recall' && action.pokemon_position == position
        end
      end

      def no_battle_pokemon?(trainer)
        other_sides(trainer).all? { |s| s.active_in_battle_pokemon.empty? } &&
          own_battle_pokemon?(trainer)
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
