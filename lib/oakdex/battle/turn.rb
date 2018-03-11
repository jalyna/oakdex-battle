module Oakdex
  class Battle
    # Represents one Turn within the battle
    class Turn
      def initialize(battle, actions)
        @battle = battle
        @actions = actions
      end

      def execute
        ordered_actions.each do |action|
          execute_action(action)
        end
      end

      private

      def execute_action(action)
        if hitting?(action)
          @battle.add_to_log 'uses_move', action.trainer.name,
                             action.pokemon.name, action.move.name
          # TODO do damage
        else
          @battle.add_to_log 'move_does_not_hit', action.trainer.name,
                             action.pokemon.name, action.move.name
        end
      end

      def hitting?(action)
        rand(1..1000) <= action.hitting_probability
      end

      def ordered_actions
        @ordered_actions ||= @actions.sort { |a, b| compare_actions(a, b) }
      end

      def compare_actions(a, b)
        a_prio = a.move.priority
        b_prio = b.move.priority
        if a_prio == b_prio
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
