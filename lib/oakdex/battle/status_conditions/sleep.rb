module Oakdex
  class Battle
    module StatusConditions
      # Represents Sleep status condition
      class Sleep < NonVolatile
        def initialize(pokemon)
          super
          @turn_count = 0
          @max_turn_count = rand(1..3)
        end

        def after_turn(turn)
          wake_up(turn.battle) if @turn_count >= @max_turn_count
          @turn_count += 1
        end

        def prevents_move?(move_execution)
          move_execution
            .battle
            .add_to_log('sleeping',
                        pokemon.trainer.name,
                        pokemon.name)
          true
        end

        private

        def wake_up(battle)
          pokemon.remove_status_condition(self)
          battle.add_to_log('wake_up',
                            pokemon.trainer.name,
                            pokemon.name)
        end
      end
    end
  end
end
