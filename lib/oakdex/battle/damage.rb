require 'forwardable'

module Oakdex
  class Battle
    # Calculates damage
    class Damage
      extend Forwardable

      def_delegators :@action, :move, :pokemon, :target

      def initialize(turn, action)
        @turn = turn
        @action = action
      end

      def damage
        (simple_damage * modifier).to_i
      end

      def critical?
        @critical ||= rand(1..1000) <= pokemon.critical_hit_prob * 1000 ? 1 : 0
        @critical == 1
      end

      def effective?
        type_modifier > 1.0
      end

      def ineffective?
        type_modifier < 1.0
      end

      private

      def modifier
        target_modifier * weather_modifier * critical_hit_modifier *
          random_modifier * stab_modifier * type_modifier *
          burn_modifier * status_condition_modifier * other_modifiers
      end

      def status_condition_modifier
        pokemon.status_conditions.reduce(1.0) do |modifier, condition|
          modifier * condition.damage_modifier(@action)
        end
      end

      def target_modifier
        1.0 # TODO: 0.75 if move has more than one target
      end

      def weather_modifier
        1.0 # TODO: 1.5 water at rain or fire at harsh sunlight, 0.5 vice versa
      end

      def critical_hit_modifier
        if critical?
          1.5
        else
          1.0
        end
      end

      def random_modifier
        @random_modifier ||= rand(850..1000) / 1000.0
      end

      def stab_modifier
        pokemon.types.include?(move.type_id) ? 1.5 : 1.0
      end

      def type_modifier
        target.types.reduce(1.0) do |factor, type|
          factor * move.type.effectivness[type]
        end
      end

      def burn_modifier
        1.0 # TODO: 0.5 if attack is burning and physical move
      end

      def other_modifiers
        1.0 # TODO: See other https://bulbapedia.bulbagarden.net/wiki/Damage
      end

      def def_and_atk
        if move.category == 'special'
          (pokemon.sp_atk.to_f / target.sp_def.to_f)
        else
          (pokemon.atk.to_f / target.def.to_f)
        end
      end

      def simple_damage
        (((2 * pokemon.level) / 5.0 + 2) * move.power * def_and_atk) / 50 + 2
      end
    end
  end
end
