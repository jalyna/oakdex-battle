require 'forwardable'

module Oakdex
  class Battle
    # Represents a pokemon that is in battle
    class InBattlePokemon
      extend Forwardable

      def_delegators :@pokemon, :current_hp, :moves_with_pp
      def_delegators :@side, :battle

      attr_reader :pokemon, :position, :side

      def initialize(pokemon, side, position = 0)
        @pokemon = pokemon
        @side = side
        @position = position
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
              move: move,
              target: [target.side, target.position]
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

      # TODO: user
      # TODO: all_users
      # TODO: all_adjacent
      # TODO: adjacent_foes_all
      # TODO: all_except_user
      # TODO: all_foes
      # TODO: all
      # TODO: user_and_random_adjacent_foe
      def available_targets(move)
        case move.target
        when 'user' then [self]
        when 'target_adjacent_user_single' then adjacent_users
        when 'target_adjacent_single'
          adjacent_foes + adjacent_users
        when 'target_user_or_adjacent_user'
          [self] + adjacent_users
        else adjacent_foes
        end
      end

      def target_adjacent_single
        adjacent_foes + adjacent_users
      end

      def adjacent_foes
        other_side.in_battle_pokemon.select do |ibp|
          ibp.position.between?(position - 1, position + 1)
        end
      end

      def adjacent_users
        (@side.in_battle_pokemon - [self]).select do |ibp|
          ibp.position.between?(position - 1, position + 1)
        end
      end

      def other_side
        other_sides.first
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
