module Oakdex
  class Battle
    # Creates Pokemon instance and prefills attributes
    class PokemonFactory
      REQUIRED_ATTRIBUTES = %i[exp gender ability nature hp iv ev moves]
      OPTIONAL_ATTRIBUTES = %i[
        original_trainer
        wild
        item_id
        amie
      ]

      class << self
        def create(species, options = {})
          factory = new(species, options)
          attributes = Hash[(REQUIRED_ATTRIBUTES + OPTIONAL_ATTRIBUTES).map do |attr|
            [attr, factory.send(attr)]
          end]
          Pokemon.new(species, attributes)
        end
      end

      def initialize(species, options = {})
        @species = species
        @options = options
      end

      private

      def original_trainer
        @options[:original_trainer]
      end

      def wild
        @options[:wild]
      end

      def item_id
        @options[:item_id]
      end

      def amie
        @options[:amie]
      end

      def moves
        if @options[:moves]
          @options[:moves].map do |move_data|
            Move.new(
              Oakdex::Pokedex::Move.find!(move_data[0]),
              move_data[1],
              move_data[2]
            )
          end
        else
          (generate_available_moves + additional_moves).take(4)
        end
      end

      def generate_available_moves
        available_moves.sample(4).map do |move_name|
          move_type = Oakdex::Pokedex::Move.find!(move_name)
          Move.new(move_type, move_type.pp, move_type.pp)
        end
      end

      def additional_moves
        return [] unless @options[:additional_moves]
        @options[:additional_moves].map do |move_name|
          move_type = Oakdex::Pokedex::Move.find!(move_name)
          Move.new(move_type, move_type.pp, move_type.pp)
        end
      end

      def available_moves
        @species.learnset.map do |m|
          m['move'] if m['level'] && m['level'] <= level
        end.compact
      end

      def ability
        if @options['ability']
          Oakdex::Pokedex::Ability.find!(@options['ability'])
        else
          Oakdex::Pokedex::Ability.find!(abilities.sample['name'])
        end
      end

      def abilities
        @species.abilities.select { |a| !a['hidden'] && !a['mega'] }
      end

      def exp
        @options[:exp] || PokemonStat.exp_by_level(
          @species.leveling_rate,
          @options[:level]
        )
      end

      def level
        PokemonStat.level_by_exp(@species.leveling_rate, exp)
      end

      def hp
        return @options[:hp] if @options[:hp]
        PokemonStat.initial_stat(:hp,
                                 level: level,
                                 iv: iv,
                                 ev: ev,
                                 base_stats: @species.base_stats,
                                 nature: nature
                                )
      end

      def iv
        return @options[:iv] if @options[:iv]
        @iv ||= Hash[Pokemon::BATTLE_STATS.map do |stat|
          [stat, rand(0..31)]
        end]
      end

      def ev
        return @options[:ev] if @options[:ev]
        @ev ||= Hash[Pokemon::BATTLE_STATS.map do |stat|
          [stat, 0]
        end]
      end

      def gender
        return @options[:gender] if @options[:gender]
        return 'neuter' unless @species.gender_ratios
        calculate_gender
      end

      def calculate_gender
        if rand(1..1000) <= @species.gender_ratios['male'] * 10
          'male'
        else
          'female'
        end
      end

      def nature(options = {})
        @nature ||= if options[:nature]
                      Oakdex::Pokedex::Nature.find!(options[:nature])
                    else
                      Oakdex::Pokedex::Nature.all.values.sample
                    end
      end
    end
  end
end
