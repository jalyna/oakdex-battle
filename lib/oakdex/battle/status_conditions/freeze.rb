module Oakdex
  class Battle
    module StatusConditions
      # Represents Freeze status condition
      class Freeze < NonVolatile
        def prevents_move?(move_execution)
          move_execution
            .battle
            .add_to_log('frozen',
                        move_execution.pokemon.trainer.name,
                        move_execution.pokemon.name)
          true
        end

        def after_received_damage(move_execution)
          return unless move_execution.move.type_id == 'fire'
          defrost(move_execution.battle)
        end

        def before_turn(turn)
          return unless rand(1..100) <= 20
          defrost(turn.battle)
        end

        private

        def defrost(battle)
          pokemon.remove_status_condition(self)
          battle.add_to_log('defrosts',
                            pokemon.trainer.name,
                            pokemon.name)
        end
      end
    end
  end
end
