require 'forwardable'
require 'oakdex/battle/status_conditions'
require 'securerandom'

module Oakdex
  class Battle
    # Represents detailed pokemon instance that is part of a Trainer's Team
    class InBattlePokemon
      extend Forwardable

      OTHER_STATS = %i[accuracy evasion critical_hit]
      ALL_STATS = Oakdex::Pokemon::BATTLE_STATS + OTHER_STATS
      STATUS_CONDITIONS = {
        'poison' => StatusConditions::Poison,
        'burn' => StatusConditions::Burn,
        'freeze' => StatusConditions::Freeze,
        'paralysis' => StatusConditions::Paralysis,
        'badly_poisoned' => StatusConditions::BadlyPoisoned,
        'sleep' => StatusConditions::Sleep
      }

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

      def_delegators :@pokemon, :types, :trainer, :trainer=,
                     :name, :moves, :moves_with_pp, :change_hp_by,
                     :change_pp_by, :level, :fainted?, :usable_item?,
                     :use_item, :growth_event?, :growth_event, :grow_from_battle

      attr_reader :status_conditions, :pokemon

      def initialize(pokemon, options = {})
        @pokemon = pokemon
        @status_conditions = options[:status_conditions] || []
        if @pokemon.primary_status_condition
          add_status_condition(@pokemon.primary_status_condition)
        end
        @pokemon.enable_battle_mode
        reset_stats
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
        @status_conditions << status_condition(condition_name)
        @pokemon.primary_status_condition = condition_name
      end

      def remove_status_condition(condition)
        @status_conditions = @status_conditions.reject { |s| s == condition }
        @pokemon.primary_status_condition = nil if @status_conditions.empty?
      end

      def reset_stats
        @stat_modifiers = (ALL_STATS - %i[hp]).map do |stat|
          [stat, 0]
        end.to_h
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

      def id
        @id ||= SecureRandom.uuid
      end

      Oakdex::Pokemon::BATTLE_STATS.each do |stat|
        define_method stat do
          (@pokemon.public_send(stat) * stage(stat) *
            status_condition_modifier(stat)).to_i
        end
      end

      def to_h
        {
          id: id,
          pokemon: @pokemon.for_game
        }
      end

      private

      def status_condition_modifier(stat)
        status_conditions.reduce(1.0) do |modifier, condition|
          condition.stat_modifier(stat) * modifier
        end
      end

      def status_condition(condition_name)
        STATUS_CONDITIONS[condition_name].new(self)
      end

      def stage(stat)
        multipliers = stage_multipliers(stat)
        multipliers[@stat_modifiers[stat] || 0]
      end

      def stage_multipliers(stat)
        case stat
        when :evasion, :accuracy
          STAGE_MULTIPLIERS_ACC_EVA
        when :critical_hit
          STAGE_MULTIPLIERS_CRITICAL_HIT
        else
          STAGE_MULTIPLIERS
        end
      end
    end
  end
end
