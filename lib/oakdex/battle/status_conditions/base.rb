module Oakdex
  class Battle
    module StatusConditions
      # Represents Abstract Class Base
      class Base
        attr_reader :pokemon

        def initialize(pokemon)
          @pokemon = pokemon
        end

        def after_turn(turn); end

        def after_fainted(battle); end

        def after_switched_out(battle); end

        def stat_modifier(_stat)
          1.0
        end

        def damage_modifier(_move_execution)
          1.0
        end

        def prevents_move?(_move_execution)
          false
        end
      end
    end
  end
end
