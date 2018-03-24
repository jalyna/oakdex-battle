module Oakdex
  class Battle
    # Represents a Pokemon Trainer. Owns Pokemon and has a name
    class Trainer
      attr_reader :name, :team, :in_battle_pokemon

      def initialize(name, team)
        @name = name
        team.each { |p| p.trainer = self }
        @team = team
        @in_battle_pokemon = []
      end

      def fainted?
        @team.all? { |p| p.current_hp.zero? }
      end

      def send_to_battle(pokemon, side)
        @in_battle_pokemon << InBattlePokemon.new(pokemon,
                                                  side, side.next_position)
        side.add_to_log 'sends_to_battle', name, pokemon.name
      end

      def remove_from_battle(pokemon, side)
        @in_battle_pokemon = @in_battle_pokemon.select do |ibp|
          ibp.pokemon != pokemon
        end
        side.add_to_log 'removes_from_battle', name, pokemon.name
      end

      def remove_fainted
        @in_battle_pokemon = @in_battle_pokemon.reject(&:fainted?)
      end

      def left_pokemon_in_team
        @team.select { |p| !p.current_hp.zero? } -
          @in_battle_pokemon.map(&:pokemon)
      end
    end
  end
end
