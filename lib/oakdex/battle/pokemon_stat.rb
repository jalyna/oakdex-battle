module Oakdex
  class Battle
    # Calculates Pokemon Stats
    class PokemonStat
      STAGE_MULTIPLIERS = {
        -6 => Rational(2, 8),
        -5 => Rational(2, 7),
        -4 => Rational(2, 6),
        -3 => Rational(2, 5),
        -2 => Rational(2, 4),
        -1 => Rational(2, 3),
        0 => Rational(2, 2),
        1 => Rational(3, 2),
        2 => Rational(4, 2),
        3 => Rational(5, 2),
        4 => Rational(6, 2),
        5 => Rational(7, 2),
        6 => Rational(8, 2)
      }

      STAGE_MULTIPLIERS_CRITICAL_HIT = {
        0 => Rational(1, 24),
        1 => Rational(1, 8),
        2 => Rational(1, 2),
        3 => Rational(1, 1)
      }

      STAGE_MULTIPLIERS_ACC_EVA = {
        -6 => Rational(3, 9),
        -5 => Rational(3, 8),
        -4 => Rational(3, 7),
        -3 => Rational(3, 6),
        -2 => Rational(3, 5),
        -1 => Rational(3, 4),
        0 => Rational(3, 3),
        1 => Rational(4, 3),
        2 => Rational(5, 3),
        3 => Rational(6, 3),
        4 => Rational(7, 3),
        5 => Rational(8, 3),
        6 => Rational(9, 3)
      }

      class << self
        def initial_stat(stat, options = {})
          first_part = initial_stat_first_part(stat, options)
          (
            if stat == :hp
              first_part + options[:level] + 10
            elsif stat.to_s == options[:nature].increased_stat
              (first_part + 5) * 1.1
            elsif stat.to_s == options[:nature].decreased_stat
              (first_part + 5) * 0.9
            else
              first_part + 5
            end
          ).to_i
        end

        def exp_by_level(leveling_rate, level)
          case leveling_rate
          when 'Fast' then ((4.0 * level**3) / 5).to_i
          when 'Slow' then ((5.0 * level**3) / 4).to_i
          when 'Medium Slow' then medium_slow_exp(level)
          when 'Fluctuating' then fluctuating_exp(level)
          else level**3
          end
        end

        def level_by_exp(leveling_rate, exp)
          level = 2
          level += 1 while exp_by_level(leveling_rate, level) <= exp
          level - 1
        end

        private

        def medium_slow_exp(level)
          (
            ((6.0 / 5) * level**3) - 15 * level**2 + (100 * level) - 140
          ).to_i
        end

        def fluctuating_exp(level)
          (
          if level <= 15
            level**3 * ((((level + 1) / 3.0) + 24) / 50)
          elsif level <= 36
            level**3 * ((level + 14) / 50.0)
          else
            level**3 * (((level / 2.0) + 32) / 50)
          end
          ).to_i
        end

        def initial_stat_first_part(stat, options = {})
          (
            (
              2.0 *
              options[:base_stats][stat.to_s] +
              options[:iv][stat] +
              (options[:ev][stat] / 4)
            ) * options[:level]
          ) / 100
        end
      end
    end
  end
end
