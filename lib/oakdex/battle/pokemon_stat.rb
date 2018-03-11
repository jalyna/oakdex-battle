module Oakdex
  class Battle
    # Calculates Pokemon Stats
    class PokemonStat
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
