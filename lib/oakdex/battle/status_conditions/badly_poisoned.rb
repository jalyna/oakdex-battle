module Oakdex
  class Battle
    module StatusConditions
      # Represents BadlyPoisoned status condition
      class BadlyPoisoned < NonVolatile
        def initialize(pokemon)
          super
          @turn_count = 0
        end

        def after_turn(turn)
          return if pokemon.fainted?
          turn.battle.add_to_log('damage_by_badly_poisoned',
                                 pokemon.trainer.name,
                                 pokemon.name, hp_by_turn)
          pokemon.change_hp_by(hp_by_turn)
          @turn_count += 1
        end

        def after_switched_out(_battle)
          @turn_count = 0
        end

        private

        def hp_by_turn
          [-(pokemon.hp * percent).to_i, -1].min
        end

        def percent
          ([@turn_count.to_f, 15].min + 1) / 16.0
        end
      end
    end
  end
end
