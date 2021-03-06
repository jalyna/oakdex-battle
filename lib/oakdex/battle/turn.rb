require 'forwardable'

module Oakdex
  class Battle
    # Represents one Turn within the battle
    class Turn
      extend Forwardable

      def_delegators :@battle, :sides
      attr_reader :battle

      def initialize(battle, actions)
        @battle = battle
        @actions = actions
      end

      def execute
        execute_status_conditions(:before_turn)

        @actions.each { |a| a.turn = self }
        ordered_actions.each do |action|
          next unless valid_target?(action)
          next if action.pokemon && action.pokemon.fainted?
          action.execute
        end

        execute_status_conditions(:after_turn)
      end

      private

      def execute_status_conditions(method)
        status_conditions.each do |status_condition|
          status_condition.public_send(method, self)
        end
        battle.remove_fainted
      end

      def status_conditions
        sides.flat_map(&:active_in_battle_pokemon)
          .map(&:pokemon)
          .flat_map(&:status_conditions)
      end

      def valid_target?(action)
        targets = action.target.is_a?(Array) ? action.target : [action.target]
        targets.all? do |target|
          !target.nil? && !target.fainted?
        end
      end

      def ordered_actions
        @ordered_actions ||= @actions.sort { |a, b| compare_actions(a, b) }
      end

      def compare_actions(a, b)
        a_prio = a.priority
        b_prio = b.priority
        if a_prio == b_prio && a_prio < 6
          if a.pokemon.speed == b.pokemon.speed
            [1, -1].sample
          else
            b.pokemon.speed <=> a.pokemon.speed
          end
        else
          b_prio <=> a_prio
        end
      end
    end
  end
end
