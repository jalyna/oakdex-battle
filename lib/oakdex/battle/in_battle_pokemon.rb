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
          targets_in_battle(move).map do |target|
            {
              action: 'move',
              pokemon: pokemon,
              move: move,
              target: target
            }
          end
        end
      end

      private

      def targets_in_battle(move)
        available_targets(move).map do |targets|
          if targets.last.is_a?(Array)
            targets if targets_in_battle?(targets)
          elsif target_in_battle?(targets)
            targets
          end
        end.compact.reject(&:empty?)
      end

      def targets_in_battle?(targets)
        targets.any? { |target| target[0].pokemon_in_battle?(target[1]) }
      end

      def target_in_battle?(target)
        target[0].pokemon_in_battle?(target[1]) ||
          (!target[0].pokemon_left? && target[1] == 0)
      end

      def struggle_move
        @struggle_move ||= Oakdex::Pokemon::Move.create('Struggle')
      end

      def available_targets(move)
        with_target(move) || multiple_targets_adjacent(move) ||
          multiple_targets(move) || []
      end

      def multiple_targets(move)
        case move.target
        when 'all_users' then [all_users]
        when 'all_except_user' then [all_targets - [self_target]]
        when 'all' then [all_targets]
        when 'all_foes' then [all_foes]
        end
      end

      def multiple_targets_adjacent(move)
        case move.target
        when 'all_adjacent' then [adjacent]
        when 'adjacent_foes_all' then [adjacent_foes]
        end
      end

      def with_target(move)
        case move.target
        when 'user', 'user_and_random_adjacent_foe' then [self_target]
        when 'target_adjacent_user_single' then adjacent_users
        when 'target_adjacent_single' then adjacent
        when 'target_user_or_adjacent_user'
          [self_target] + adjacent_users
        end
      end

      def all_targets
        all_foes + all_users
      end

      def target_adjacent_single
        adjacent_foes + adjacent_users
      end

      def adjacent
        adjacent_foes + adjacent_users
      end

      def self_target
        [@side, position]
      end

      def adjacent_foes
        [
          [other_side, position - 1],
          [other_side, position],
          [other_side, position + 1]
        ].select { |t| t[1] >= 0 && t[1] < pokemon_per_side }
      end

      def adjacent_users
        [
          [@side, position - 1],
          [@side, position + 1]
        ].select { |t| t[1] >= 0 && t[1] < pokemon_per_side }
      end

      def all_users
        pokemon_per_side.times.map { |i| [@side, i] }
      end

      def all_foes
        pokemon_per_side.times.map { |i| [other_side, i] }
      end

      def pokemon_per_side
        battle.pokemon_per_side
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
