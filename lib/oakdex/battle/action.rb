require 'forwardable'

module Oakdex
  class Battle
    # Represents one Action. One turn has many actions.
    class Action
      RECALL_PRIORITY = 6

      extend Forwardable

      def_delegators :@turn, :battle

      attr_reader :trainer, :damage, :turn

      def initialize(trainer, attributes)
        @trainer = trainer
        @attributes = attributes
      end

      def priority
        move&.priority || RECALL_PRIORITY
      end

      def pokemon
        recall? ? pokemon_by_position : @attributes[:pokemon]
      end

      def pokemon_position
        recall? ? @attributes[:pokemon] : nil
      end

      def target
        recall? ? @attributes[:target] : targets
      end

      def type
        @attributes[:action]
      end

      def move
        @attributes[:move]
      end

      def hitting_probability
        ((move.accuracy / 100.0) * (pokemon.accuracy / target.evasion)) * 1000
      end

      def hitting?
        @hitting = rand(1..1000) <= hitting_probability ? 1 : 0
        @hitting == 1
      end

      def execute(turn)
        @turn = turn
        return execute_recall if type == 'recall'
        targets.each { |t| MoveExecution.new(self, t).execute }
      end

      private

      def targets
        target_list.map do |target|
          target_by_position(target[0], target[1])
        end.compact
      end

      def target_list
        list = @attributes[:target]
        reutrn [] if list.empty?
        list = [list] unless list[0].is_a?(Array)
        list
      end

      def recall?
        type == 'recall'
      end

      def pokemon_by_position
        trainer.active_in_battle_pokemon
          .find { |ibp| ibp.position == @attributes[:pokemon] }&.pokemon
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
