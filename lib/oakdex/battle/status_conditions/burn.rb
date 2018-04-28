module Oakdex
  class Battle
    module StatusConditions
      # Represents Burn status condition
      class Burn < Base
        def after_turn(turn)
          return if pokemon.current_hp.zero?
          turn.battle.add_to_log('damage_by_burn',
                                 pokemon.trainer.name,
                                 pokemon.name, hp_by_turn)
          pokemon.change_hp_by(hp_by_turn)
        end

        def damage_modifier(move_execution)
          move_execution.move.category == 'physical' ? 0.5 : super
        end

        def after_fainted(_battle)
          pokemon.remove_status_condition(self)
        end

        private

        def hp_by_turn
          [-(pokemon.hp / 16).to_i, -1].min
        end
      end
    end
  end
end
