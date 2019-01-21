module Oakdex
  class Battle
    module StatusConditions
      # Represents Poison status condition
      class Poison < NonVolatile
        def after_turn(turn)
          return if pokemon.fainted?
          turn.battle.add_to_log('damage_by_poison',
                                 pokemon.trainer.name,
                                 pokemon.name, hp_by_turn)
          pokemon.change_hp_by(hp_by_turn)
        end

        private

        def hp_by_turn
          [-(pokemon.hp / 8).to_i, -1].min
        end
      end
    end
  end
end
