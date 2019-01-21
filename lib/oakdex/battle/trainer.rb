module Oakdex
  class Battle
    # Represents a Pokemon Trainer. Owns Pokemon and has a name
    class Trainer
      attr_reader :name, :team, :active_in_battle_pokemon

      def initialize(name, pokemon)
        @name = name
        pokemon.each { |p| p.trainer = self }
        @team = pokemon.map { |p| Oakdex::Battle::InBattlePokemon.new(p) }
        @active_in_battle_pokemon = []
      end

      def fainted?
        @team.all? { |p| p.current_hp.zero? }
      end

      def send_to_battle(pokemon, side)
        @active_in_battle_pokemon << ActiveInBattlePokemon.new(pokemon,
                                                  side, side.next_position)
        side.add_to_log 'sends_to_battle', name, pokemon.name
      end

      def remove_from_battle(pokemon, side)
        ibp_to_remove = @active_in_battle_pokemon.find { |ibp| ibp.pokemon == pokemon }
        pokemon.reset_stats
        pokemon.status_conditions.each do |s|
          s.after_switched_out(ibp_to_remove.battle)
        end
        @active_in_battle_pokemon -= [ibp_to_remove]
        side.add_to_log 'removes_from_battle', name, pokemon.name
      end

      def remove_fainted
        @active_in_battle_pokemon.each do |ibp|
          next unless ibp.fainted?
          ibp.battle.add_to_log('pokemon_fainted', name, ibp.pokemon.name)
          ibp.pokemon.status_conditions
            .each { |s| s.after_fainted(ibp.battle) }
        end
        @active_in_battle_pokemon = @active_in_battle_pokemon.reject(&:fainted?)
      end

      def left_pokemon_in_team
        @team.select { |p| !p.current_hp.zero? } -
          @active_in_battle_pokemon.map(&:pokemon)
      end
    end
  end
end
