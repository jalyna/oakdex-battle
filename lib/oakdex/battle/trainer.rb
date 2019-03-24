module Oakdex
  class Battle
    # Represents a Pokemon Trainer. Owns Pokemon and has a name
    class Trainer
      attr_reader :name, :team, :active_in_battle_pokemon, :items
      attr_accessor :side

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
        pokemon = team.find { |p| p.growth_event == remove_growth_event }
        pokemon.remove_growth_event
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
          execute_grow_for_pokemon(ibp.pokemon, defeated_pokemon)
        end
        grow_team_pokemon(defeated_pokemon)
      end

      private

      def battle
        side.battle
      end

      def grow_team_pokemon(defeated_pokemon)
        return unless @options[:using_exp_share]
        exclude_pokemon = active_in_battle_pokemon.map(&:pokemon)

        (team - exclude_pokemon).each do |pok|
          next if pok.fainted?
          execute_grow_for_pokemon(pok, defeated_pokemon)
        end
      end

      def execute_grow_for_pokemon(bp, defeated_pokemon)
        bp.grow_from_battle(defeated_pokemon.pokemon.pokemon)
        execute_read_only_events(bp)
        return unless bp.growth_event?
        add_choice_to_log(bp)
      end

      def execute_read_only_events(bp)
        while bp.growth_event? && bp.growth_event.read_only?
          battle.add_to_log(bp.growth_event.message)
          bp.growth_event.execute
        end
      end

      def add_choice_to_log(bp)
        battle.add_to_log(
          'choice_for',
          name,
          bp.growth_event.message,
          bp.growth_event.possible_actions.join(',')
        )
      end

      def other_side_gains(ibp)
        winner_sides = ibp.battle.sides - side_of_trainer(ibp.battle.sides)
        winner_sides.each do |side|
          side.trainers.each do |trainer|
            trainer.grow(ibp)
          end
        end
      end

      def side_of_trainer(sides)
        sides.select { |s| s.trainer_on_side?(self) }
      end

      def growth_events
        team.map(&:growth_event).compact
      end
    end
  end
end
