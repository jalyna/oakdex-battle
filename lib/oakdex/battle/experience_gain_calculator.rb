module Oakdex
  class Battle
    # Calculates the experience a pokemon gains after a defeat
    # https://bulbapedia.bulbagarden.net/wiki/Experience#Experience_gain_in_battle
    class ExperienceGainCalculator
      def self.calculate(fainted, winner, options = {})
        new(fainted, winner, options).calculate
      end

      def initialize(fainted, winner, options = {})
        @options = options
        @fainted = fainted
        @winner = winner
      end

      def calculate
        (flat? ? flat_formula : scaled_formula).to_i
      end

      private

      def flat?
        @options[:flat]
      end

      def scaled_formula
        (
          ((a * b * l) / (5 * s))
          * ((2 * l + 10)**2.5 / (l + lp + 10)**2.5) + 1
        ) * t * e * p
      end

      def flat_formula
        (a * t * b * e * l * p * f * v) / (7 * s)
      end

      def a
        @fainted.wild? ? 1.0 : 1.5
      end

      def b
        @fainted.species.base_exp_yield
      end

      def l
        @fainted.level
      end

      def lp
        @winner.level
      end

      def e
        @winner.item_id == 'Lucky Egg' ? 1.5 : 1.0
      end

      def p
        # TODO: Integrate Point Power
        1
      end

      def f
        @winner.amie_level(:affection) >= 2 ? 1.2 : 1.0
      end

      def t
        @winner.traded? ? 1.5 : 1.0
      end

      def s
        @options[:winner_using_exp_share] ? 2 : 1
      end

      def v
        # TODO: 1.2 if the winning Pokemon is at or past
        # the level where it would be able to evolve,
        # but it has not
        1
      end
    end
  end
end
