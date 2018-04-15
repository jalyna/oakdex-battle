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
      end
    end
  end
end
