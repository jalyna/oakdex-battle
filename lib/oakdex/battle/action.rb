require 'forwardable'

module Oakdex
  class Battle
    # Represents one Action. One turn has many actions.
    class Action
      extend Forwardable

      def_delegators :@turn, :battle

      attr_reader :trainer, :damage

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

      def hitting?
        @hitting = rand(1..1000) <= hitting_probability ? 1 : 0
        @hitting == 1
      end

      def execute(turn)
        @turn = turn
        pokemon.change_pp_by(move.name, -1)
        if hitting?
          add_uses_move_log
          @damage = Damage.new(@turn, self)
          if @damage.damage > 0
            add_received_damage_log
            target.change_hp_by(-@damage.damage)
            add_target_fainted_log if target.current_hp.zero?
          else
            add_received_no_damage_log
          end
        else
          add_move_does_not_hit_log
        end
      end

      private

      def add_log(*args)
        battle.add_to_log(*args)
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
