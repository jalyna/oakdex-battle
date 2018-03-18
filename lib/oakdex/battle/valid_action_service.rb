require 'forwardable'

module Oakdex
  class Battle
    # Generates all valid actions within the battle
    class ValidActionService
      extend Forwardable

      def_delegators :@battle, :actions

      def initialize(battle)
        @battle = battle
      end

      def valid_actions_for(trainer)
        valid_moves_for(trainer) + valid_recall_actions_for(trainer)
      end

      private

      def valid_moves_for(trainer)
        pokemon_in_battle(trainer).flat_map do |pokemon|
          valid_moves_for_pokemon(trainer, pokemon)
        end
      end

      def valid_moves_for_pokemon(trainer, pokemon)
        return [] unless actions_for(trainer, pokemon).empty?
        moves = pokemon.moves_with_pp
        moves = [struggle_move] if moves.empty?
        moves.map do |move|
          available_targets_for_move(trainer, pokemon, move).map do |target|
            move_action(move, pokemon, target)
          end
        end.compact.flatten(1)
      end

      def struggle_move
        @struggle_move ||= begin
          move_type = Oakdex::Pokedex::Move.find('Struggle')
          Oakdex::Battle::Move.new(move_type, move_type.pp, move_type.pp)
        end
      end

      def available_targets_for_move(trainer, _pokemon, _move)
        other_sides(trainer).map do |side|
          side.map { |trainer_data| trainer_data[1] }
        end.flatten(2)
      end

      def valid_recall_actions_for(trainer)
        return [] if sides.empty?
        left_pokemon_in_team_for(trainer).flat_map do |pokemon|
          pokemon_per_trainer.times.map do |position|
            recall_action(trainer, pokemon_in_battle(trainer)[position],
                          pokemon)
          end.compact
        end
      end

      def move_action(move, pokemon, target)
        {
          action: 'move',
          pokemon: pokemon,
          move: move.name,
          target: target
        }
      end

      def recall_action(trainer, pokemon, target)
        return if pokemon && !actions_for(trainer, pokemon).empty?
        {
          action: 'recall',
          pokemon: pokemon,
          target: target
        }
      end

      def left_pokemon_in_team_for(trainer)
        (trainer.team - pokemon_in_battle(trainer)).select do |p|
          !p.current_hp.zero?
        end
      end

      def pokemon_in_battle(trainer)
        sides.each do |side|
          side.each do |trainer_data|
            return trainer_data[1] if trainer_data.first == trainer
          end
        end
        []
      end

      def other_sides(trainer)
        sides.select do |side|
          !side.any? { |trainer_data| trainer_data.first == trainer }
        end
      end

      def pokemon_per_trainer
        @battle.team1.size
      end

      def sides
        @battle.arena[:sides]
      end

      def actions_of(trainer)
        actions.select { |a| a.trainer == trainer }
      end

      def actions_for(trainer, pokemon)
        actions_of(trainer).select { |a| a.pokemon == pokemon }
      end
    end
  end
end
