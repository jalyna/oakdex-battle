module Oakdex
  class Battle
    # Represents one Turn within the battle
    class Turn
      attr_reader :battle

      def initialize(battle, actions)
        @battle = battle
        @actions = actions
      end

      def execute
        ordered_actions.each do |action|
          next unless valid_target?(action)
          next if action.pokemon && action.pokemon.current_hp.zero?
          action.execute(self)
        end
      end

      private

      def valid_target?(action)
        targets = action.target.is_a?(Array) ? action.target : [action.target]
        targets.all? do |target|
          !target.nil? && !target.current_hp.zero?
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
