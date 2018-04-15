require 'forwardable'
require 'oakdex/battle/pokemon_stat'
require 'oakdex/battle/move'
require 'oakdex/battle/pokemon_factory'
require 'oakdex/battle/status_conditions'

module Oakdex
  class Battle
    # Represents detailed pokemon instance
    class Pokemon
      extend Forwardable

      BATTLE_STATS = %i[hp atk def sp_atk sp_def speed]
      OTHER_STATS = %i[accuracy evasion critical_hit]
      STATUS_CONDITIONS = {
        'poison' => StatusConditions::Poison,
        'burn' => StatusConditions::Burn,
        'freeze' => StatusConditions::Freeze,
        'paralysis' => StatusConditions::Paralysis,
        'badly_poisoned' => StatusConditions::BadlyPoisoned,
        'sleep' => StatusConditions::Sleep
      }

      def_delegators :@species, :types

      attr_accessor :trainer

      def self.create(species_name, options = {})
        species = Oakdex::Pokedex::Pokemon.find!(species_name)
        Oakdex::Battle::PokemonFactory.create(species, options)
      end

      def initialize(species, attributes = {})
        @species = species
        @attributes = attributes
        @attributes[:status_conditions] ||= []
        reset_stats
      end

      def name
        @species.names['en']
      end

      def moves
        @attributes[:moves]
      end

      def current_hp
        @attributes[:hp]
      end

      def status_conditions
        @attributes[:status_conditions]
      end

      def moves_with_pp
        moves.select { |m| m.pp > 0 }
      end

      def change_hp_by(hp_change)
        @attributes[:hp] = if hp_change < 0
                             [@attributes[:hp] + hp_change, 0].max
                           else
                             [@attributes[:hp] + hp_change, hp].min
                           end
      end

      def change_pp_by(move_name, pp_change)
        move = moves.find { |m| m.name == move_name }
        return unless move
        move.pp = if pp_change < 0
                    [move.pp + pp_change, 0].max
                  else
                    [move.pp + pp_change, move.max_pp].min
                  end
      end

      def change_stat_by(stat, change_by)
        modifiers = stage_multipliers(stat)
        stat_before = @stat_modifiers[stat]
        min_value = modifiers.keys.first
        max_value = modifiers.keys.last
        @stat_modifiers[stat] = if change_by < 0
                                  [stat_before + change_by, min_value].max
                                else
                                  [stat_before + change_by, max_value].min
                                end
        stat_before != @stat_modifiers[stat]
      end

      def add_status_condition(condition_name)
        @attributes[:status_conditions] << status_condition(condition_name)
      end

      def remove_status_condition(condition)
        @attributes[:status_conditions] = @attributes[:status_conditions]
          .reject { |s| s == condition }
      end

      def reset_stats
        @stat_modifiers = (BATTLE_STATS + OTHER_STATS - %i[hp]).map do |stat|
          [stat, 0]
        end.to_h
      end

      def level
        PokemonStat.level_by_exp(@species.leveling_rate, @attributes[:exp])
      end

      def accuracy
        stage(:accuracy)
      end

      def evasion
        stage(:evasion)
      end

      def critical_hit_prob
        stage(:critical_hit)
      end

      BATTLE_STATS.each do |stat|
        define_method stat do
          (initial_stat(stat) * stage(stat)).to_i
        end
      end

      private

      def status_condition(condition_name)
        STATUS_CONDITIONS[condition_name].new(self)
      end

      def stage(stat)
        multipliers = stage_multipliers(stat)
        multipliers[@stat_modifiers[stat] || 0]
      end

      def initial_stat(stat)
        PokemonStat.initial_stat(stat,
                                 level:      level,
                                 nature:     @attributes[:nature],
                                 iv:         @attributes[:iv],
                                 ev:         @attributes[:ev],
                                 base_stats: @species.base_stats
                                )
      end

      def stage_multipliers(stat)
        case stat
        when :evasion, :accuracy
          PokemonStat::STAGE_MULTIPLIERS_ACC_EVA
        when :critical_hit
          PokemonStat::STAGE_MULTIPLIERS_CRITICAL_HIT
        else
          PokemonStat::STAGE_MULTIPLIERS
        end
      end
    end
  end
end
