require 'forwardable'

module Oakdex
  class Battle
    # Represents one Action. One turn has many actions.
    class Action
      RECALL_PRIORITY = 7
      ITEM_PRIORITY = 6

      extend Forwardable

      def_delegators :@turn, :battle

      attr_reader :trainer, :damage
      attr_accessor :turn

      def initialize(trainer, attributes)
        @trainer = trainer
        @attributes = attributes
      end

      def priority
        move&.priority || (recall? ? RECALL_PRIORITY : ITEM_PRIORITY)
      end

      def pokemon
        return pokemon_by_team_position if item?
        recall? ? pokemon_by_position : battle.pokemon_by_id(pokemon_id)
      end

      def pokemon_id
        move? ? @attributes[:pokemon] : nil
      end

      def pokemon_position
        recall? ? @attributes[:pokemon] : nil
      end

      def target
        recall? ? battle.pokemon_by_id(@attributes[:target]) : targets
      end

      def target_id
        recall? ? @attributes[:target] : nil
      end

      def type
        @attributes[:action]
      end

      def move
        return unless @attributes[:move]
        @move ||= pokemon.moves.find { |m| m.name == @attributes[:move] }
        @move ||= Oakdex::Pokemon::Move.create(@attributes[:move])
      end

      def hitting_probability
        ((move.accuracy / 100.0) * (pokemon.accuracy / target.evasion)) * 1000
      end

      def hitting?
        @hitting = rand(1..1000) <= hitting_probability ? 1 : 0
        @hitting == 1
      end

      def execute
        return execute_growth if growth?
        return execute_recall if recall?
        return execute_use_item if item?
        targets.each { |t| MoveExecution.new(self, t).execute }
      end

      def item_id
        @attributes[:item_id]
      end

      private

      def targets
        target_list.map do |target|
          side = battle.side_by_id(target[0])
          target_by_position(side, target[1])
        end.compact
      end

      def target_list
        list = @attributes[:target]
        return [] if (list || []).empty?
        list = [list] unless list[0].is_a?(Array)
        list
      end

      def recall?
        type == 'recall'
      end

      def move?
        type == 'move'
      end

      def item?
        type == 'use_item_on_pokemon'
      end

      def growth?
        type == 'growth_event'
      end

      def pokemon_by_position
        trainer.active_in_battle_pokemon
          .find { |ibp| ibp.position == @attributes[:pokemon] }&.pokemon
      end

      def pokemon_by_team_position
        trainer.team[@attributes[:pokemon_team_pos]]
      end

      def target_by_position(side, position)
        side.active_in_battle_pokemon
          .find { |ibp| ibp.position == position }&.pokemon
      end

      def side
        battle.sides.find { |s| s.trainer_on_side?(trainer) }
      end

      def execute_recall
        add_recalls_log
        if pokemon
          trainer.remove_from_battle(pokemon, side)
          trainer.send_to_battle(target, side)
        else
          trainer.send_to_battle(target, side)
        end
      end

      def item_actions
        @attributes[:item_actions]
      end

      def execute_growth
        trainer.growth_event.execute(@attributes[:option])
        while trainer.growth_event? && trainer.growth_event.read_only?
          e = trainer.growth_event
          add_log e.message
          e.execute
        end
      end

      def execute_use_item
        add_log 'uses_item_on_pokemon', trainer.name, pokemon.name, item_id
        consumed = pokemon.use_item(item_id, in_battle: true)
        trainer.consume_item(item_id) if consumed
        action_id = 0
        while pokemon.growth_event? do
          event = pokemon.growth_event
          if event.read_only?
            add_log trainer.name, pokemon.name, event.message
            event.execute
          else
            raise 'Invalid Item Usage' unless item_actions[action_id]
            event.execute(item_actions[action_id])
            action_id += 1
          end
        end
      end

      def add_log(*args)
        battle.add_to_log(*args)
      end

      def add_recalls_log
        if pokemon
          add_log 'recalls', trainer.name, pokemon.name, target.name
        else
          add_log 'recalls_for_fainted', trainer.name, target.name
        end
      end
    end
  end
end
