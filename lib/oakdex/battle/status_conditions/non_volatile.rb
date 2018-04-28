module Oakdex
  class Battle
    module StatusConditions
      # Represents Abstract Class Base NonVolatile
      class NonVolatile < Base
        def after_fainted(_battle)
          pokemon.remove_status_condition(self)
        end
      end
    end
  end
end
