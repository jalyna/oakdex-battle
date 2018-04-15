require 'forwardable'

module Oakdex
  class Battle
    # Represents one Action. One turn has many actions.
    class MoveExecution
      RECALL_PRIORITY = 6

      extend Forwardable

      def_delegators :@action, :battle, :turn, :pokemon,
                     :move, :trainer

      attr_reader :action, :target

      def initialize(action, target)
        @action = action
        @target = target
      end

      def hitting_probability
        ((move.accuracy / 100.0) * (pokemon.accuracy / target.evasion)) * 1000
      end

      def hitting?
        @hitting = rand(1..1000) <= hitting_probability ? 1 : 0
        @hitting == 1
      end

      def execute
        pokemon.change_pp_by(move.name, -1)
        if hitting?
          add_uses_move_log
          execute_damage
          execute_stat_modifiers
        else
          add_move_does_not_hit_log
        end

        battle.remove_fainted
      end

      private

      def execute_stat_modifiers
        return if move.stat_modifiers.empty?
        move.stat_modifiers.each do |stat_modifier|
          modifier_target = stat_modifier['affects_user'] ? pokemon : target
          stat = stat_modifier['stat']
          stat = random_stat if stat == 'random'
          if modifier_target.change_stat_by(stat.to_sym,
                                            stat_modifier['change_by'])
            add_changes_stat_log(modifier_target, stat,
                                 stat_modifier['change_by'])
          else
            add_changes_no_stat_log(modifier_target, stat,
                                    stat_modifier['change_by'])
          end
        end
      end

      def execute_damage
        return if move.power.zero?
        @damage = Damage.new(turn, self)
        if @damage.damage > 0
          add_received_damage_log
          target.change_hp_by(-@damage.damage)
          add_target_fainted_log if target.current_hp.zero?
        else
          add_received_no_damage_log
        end
      end

      def random_stat
        (Pokemon::BATTLE_STATS + Pokemon::OTHER_STATS).sample
      end

      def add_log(*args)
        battle.add_to_log(*args)
      end

      def add_changes_stat_log(target, stat, change_by)
        add_log 'changes_stat', target.trainer.name, target.name,
                stat, change_by
      end

      def add_changes_no_stat_log(target, stat, change_by)
        add_log 'changes_no_stat', target.trainer.name, target.name,
                stat, change_by
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