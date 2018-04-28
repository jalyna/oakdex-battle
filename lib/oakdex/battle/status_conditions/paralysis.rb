module Oakdex
  class Battle
    module StatusConditions
      # Represents Paralysis status condition
      class Paralysis < Base
        def stat_modifier(stat)
          return 0.5 if stat == :speed
          super
        end

        def prevents_move?(move_execution)
          if rand(1..100) <= 25
            move_execution
              .battle
              .add_to_log('paralysed',
                          move_execution.pokemon.trainer.name,
                          move_execution.pokemon.name)
            true
          else
            false
          end
        end
      end
    end
  end
end
