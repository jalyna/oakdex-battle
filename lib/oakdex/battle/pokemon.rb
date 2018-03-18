require 'forwardable'
require 'oakdex/battle/pokemon_stat'
require 'oakdex/battle/move'
require 'oakdex/battle/pokemon_factory'

module Oakdex
  class Battle
    # Represents detailed pokemon instance
    class Pokemon
      extend Forwardable

      BATTLE_STATS = %i[hp atk def sp_atk sp_def speed]

      def_delegators :@species, :types

      attr_accessor :trainer

      def self.create(species_name, options = {})
        species = Oakdex::Pokedex::Pokemon.find!(species_name)
        Oakdex::Battle::PokemonFactory.create(species, options)
      end

      def initialize(species, attributes = {})
        @species = species
        @attributes = attributes
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

      def level
        PokemonStat.level_by_exp(@species.leveling_rate, @attributes[:exp])
      end

      def accuracy
        1.0 # TODO: add stages
      end

      def evasion
        1.0 # TODO: add stages
      end

      def critical_hit_prob
        Rational(1, 16) # TODO: add stages
      end

      BATTLE_STATS.each do |stat|
        define_method stat do
          PokemonStat.initial_stat(stat,
                                   level:      level,
                                   nature:     @attributes[:nature],
                                   iv:         @attributes[:iv],
                                   ev:         @attributes[:ev],
                                   base_stats: @species.base_stats
                                  )
        end
      end
    end
  end
end
