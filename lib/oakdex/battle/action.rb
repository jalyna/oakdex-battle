require 'forwardable'

module Oakdex
  class Battle
    # Represents one Action. One turn has many actions.
    class Action
      RECALL_PRIORITY = 6

      extend Forwardable

      def_delegators :@turn, :battle

      attr_reader :trainer, :damage

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
        recall? ? @attributes[:target] : target_by_position
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
        pokemon.change_pp_by(move.name, -1)
        if hitting?
          add_uses_move_log
          execute_damage
        else
          add_move_does_not_hit_log
        end

        battle.remove_fainted
      end

      private

      def recall?
        type == 'recall'
      end

      def pokemon_by_position
        trainer.in_battle_pokemon
          .find { |ibp| ibp.position == @attributes[:pokemon] }&.pokemon
      end

      def target_by_position
        @attributes[:target][0].in_battle_pokemon
          .find { |ibp| ibp.position == @attributes[:target][1] }&.pokemon
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

      def execute_damage
        @damage = Damage.new(@turn, self)
        if @damage.damage > 0
          add_received_damage_log
          target.change_hp_by(-@damage.damage)
          add_target_fainted_log if target.current_hp.zero?
        else
          add_received_no_damage_log
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

      def add_uses_move_log
        add_log 'uses_move', trainer.name, pokemon.name, move.name
      end

      def add_move_does_not_hit_log
        add_log 'move_does_not_hit', trainer.name, pokemon.name, move.name
      end

      def add_target_fainted_log
        add_log 'target_fainted', target.trainer.name, target.name
      end

      def add_received_damage_log
        add_log 'received_damage', target.trainer.name, target.name,
                move.name, @damage.damage
      end

      def add_received_no_damage_log
        add_log 'received_no_damage', target.trainer.name, target.name,
                move.name
      end
    end
  end
end
