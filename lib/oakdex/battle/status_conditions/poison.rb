module Oakdex
  class Battle
    module StatusConditions
      # Represents Poison status condition
      class Poison < Base
        def after_turn(turn)
          return if pokemon.current_hp.zero?
          turn.battle.add_to_log('damage_by_poison',
                                 pokemon.trainer.name,
                                 pokemon.name, hp_by_turn)
          pokemon.change_hp_by(hp_by_turn)
        end

        def after_fainted(_battle)
          pokemon.remove_status_condition(self)
        end

        private

        def hp_by_turn
          [-(pokemon.hp / 8).to_i, -1].min
        end
      end
    end
  end
end
