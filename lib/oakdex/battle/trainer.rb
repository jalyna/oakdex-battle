module Oakdex
  class Battle
    # Represents a Pokemon Trainer. Owns Pokemon and has a name
    class Trainer
      attr_reader :name, :team, :active_in_battle_pokemon, :items

      def initialize(name, pokemon, items = [], options = {})
        @name = name
        pokemon.each { |p| p.trainer = self }
        @team = pokemon.map { |p| Oakdex::Battle::InBattlePokemon.new(p) }
        @active_in_battle_pokemon = []
        @items = items
        @options = options
      end

      def fainted?
        @team.all?(&:fainted?)
      end

      def growth_event?
        !growth_events.empty?
      end

      def growth_event
        growth_events.first
      end

      def remove_growth_event
        remove_growth_event = growth_event
        return unless remove_growth_event
        team.each do |pok|
          next unless pok.growth_event == remove_growth_event
          pok.remove_growth_event
        end
      end

      def consume_item(item_id)
        first_index = @items.index(item_id)
        @items.delete_at(first_index)
      end

      def send_to_battle(pokemon, side)
        @active_in_battle_pokemon << ActiveInBattlePokemon.new(
          pokemon,
          side, side.next_position)
        side.add_to_log 'sends_to_battle', name, pokemon.name
      end

      def remove_from_battle(pokemon, side)
        ibp_to_remove = @active_in_battle_pokemon
          .find { |ibp| ibp.pokemon == pokemon }
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
          other_side_gains(ibp)
        end
        @active_in_battle_pokemon = @active_in_battle_pokemon.reject(&:fainted?)
      end

      def left_pokemon_in_team
        @team.select { |p| !p.fainted? } -
          @active_in_battle_pokemon.map(&:pokemon)
      end

      def grow(defeated_pokemon)
        return unless @options[:enable_grow]
        active_in_battle_pokemon.each do |ibp|
          next if ibp.fainted?
          ibp.pokemon.grow_from_battle(defeated_pokemon.pokemon.pokemon)
          while ibp.pokemon.growth_event? && ibp.pokemon.growth_event.read_only?
            ibp.battle.add_to_log(ibp.pokemon.growth_event.message)
            ibp.pokemon.growth_event.execute
          end
          if ibp.pokemon.growth_event?
            ibp.battle.add_to_log(
              'choice_for',
              name,
              ibp.pokemon.growth_event.message,
              ibp.pokemon.growth_event.possible_actions.join(',')
            )
          end
        end
      end

      private

      def other_side_gains(ibp)
        winner_sides = ibp.battle.sides - ibp.battle.sides.select { |s| s.trainer_on_side?(self) }
        winner_sides.each do |side|
          side.trainers.each do |trainer|
            trainer.grow(ibp)
          end
        end
      end

      def growth_events
        team.map do |pok|
          pok.growth_event
        end.compact
      end
    end
  end
end
