module Oakdex
  class Battle
    # Pokemon Breeding
    class Breeding
      class << self
        def compatible?(pokemon1, pokemon2)
          new(pokemon1, pokemon2).compatible?
        end

        def chance_in_percentage(pokemon1, pokemon2)
          new(pokemon1, pokemon2).chance_in_percentage
        end

        def breed(pokemon1, pokemon2)
          new(pokemon1, pokemon2).child
        end
      end

      def initialize(pokemon1, pokemon2)
        @female = pokemon1.gender == 'female' ? pokemon1 : pokemon2
        @male = ([pokemon1, pokemon2] - [@female]).first
      end

      def compatible?
        (opposite_gender? && same_egg_group? && !any_undiscovered?) ||
          (exactly_one_is_ditto? && non_ditto_is_discovered?)
      end

      def chance_in_percentage
        return 0 unless compatible?
        return 50 if same_species?
        20
      end

      def child
        return unless compatible?
        Oakdex::Battle::Pokemon.create(child_species.name, level: 1)
      end

      private

      def child_species
        lowest_in_evolutionary_chain(non_ditto_or_female.species)
      end

      def lowest_in_evolutionary_chain(species)
        # TODO: take incenses into account
        lowest_species = species
        while lowest_species.evolution_from
          lowest_species = Oakdex::Pokedex::Pokemon
            .find!(lowest_species.evolution_from)
        end
        lowest_species
      end

      def exactly_one_is_ditto?
        (@female.name == 'Ditto') ^ (@male.name == 'Ditto')
      end

      def non_ditto_is_discovered?
        !non_ditto.species.egg_groups.include?('Undiscovered')
      end

      def non_ditto
        return unless exactly_one_is_ditto?
        @female.name == 'Ditto' ? @male : @female
      end

      def non_ditto_or_female
        non_ditto || @female
      end

      def opposite_gender?
        @female.gender == 'female' && @male.gender == 'male'
      end

      def same_egg_group?
        !(@female.species.egg_groups & @male.species.egg_groups).empty?
      end

      def any_undiscovered?
        (@female.species.egg_groups + @male.species.egg_groups)
          .include?('Undiscovered')
      end

      def same_species?
        @female.name == @male.name
      end
    end
  end
end
