require 'forwardable'

module Oakdex
  class Battle
    # Represents a pokemon that is in battle
    class InBattlePokemon
      extend Forwardable

      def_delegators :@pokemon, :current_hp, :moves_with_pp
      def_delegators :@side, :battle

      attr_reader :pokemon

      def initialize(pokemon, side)
        @pokemon = pokemon
        @side = side
        @position = 0
      end

      def fainted?
        current_hp.zero?
      end

      def action_added?
        actions.any? { |a| a.pokemon == pokemon }
      end

      def valid_move_actions
        return [] if action_added?
        moves = moves_with_pp
        moves = [struggle_move] if moves_with_pp.empty?
        moves.flat_map do |move|
          available_targets(move).map do |target|
            {
              action: 'move',
              pokemon: pokemon,
              move: move.name,
              target: target
            }
          end
        end
      end

      private

      def struggle_move
        @struggle_move ||= begin
          move_type = Oakdex::Pokedex::Move.find('Struggle')
          Oakdex::Battle::Move.new(move_type, move_type.pp, move_type.pp)
        end
      end

      def available_targets(_move)
        other_sides.flat_map(&:in_battle_pokemon).map(&:pokemon)
      end

      def other_sides
        battle.sides - [@side]
      end

      def actions
        battle.actions
      end
    end
  end
end
