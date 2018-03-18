require 'oakdex/pokedex'

require 'oakdex/battle/pokemon'
require 'oakdex/battle/trainer'
require 'oakdex/battle/action'
require 'oakdex/battle/damage'
require 'oakdex/battle/turn'

module Oakdex
  # Namespace that handles Battles
  class Battle
    attr_reader :log

    def initialize(team1, team2, options = {})
      @team1 = team1.is_a?(Array) ? team1 : [team1]
      @team2 = team2.is_a?(Array) ? team2 : [team2]
      @options = options
      @sides = []
      @log = []
      @current_log = []
      @actions = []
    end

    def arena
      { sides: @sides }
    end

    def valid_actions_for(trainer)
      valid_actions = pokemon_in_battle(trainer).flat_map do |pokemon|
        valid_moves_for(trainer, pokemon)
      end

      valid_actions.select do |action|
        if action[:action] == 'move'
          !@actions.any? { |a| a[1][:pokemon] == action[:pokemon] }
        else
          true
        end
      end
    end

    def add_action(trainer, action)
      return false unless valid_actions_for(trainer).include?(action)
      @actions << [trainer, action]
      true
    end

    def simulate_action(trainer)
      valid_actions = valid_actions_for(trainer)
      return false if valid_actions.empty?
      add_action(trainer, valid_actions_for(trainer).sample)
      true
    end

    def continue
      return start if @sides.empty?
      return false if trainers.any? { |t| !valid_actions_for(t).empty? }
      execute_actions
      true
    end

    def finished?
      !winner.nil?
    end

    def winner
      return if teams_with_no_pokemon_left.empty?
      ([@team1, @team2] - teams_with_no_pokemon_left).flatten(1)
    end

    def add_to_log(*args)
      @current_log << args.to_a
    end

    def remove_fainted
      @sides = @sides.map do |side|
        side.map do |trainer_data|
          [
            trainer_data[0],
            trainer_data[1].select { |p| !p.current_hp.zero? }
          ]
        end
      end
    end

    private

    def teams_with_no_pokemon_left
      [@team1, @team2].select do |team|
        team.all? do |trainer|
          trainer.team.all? do |pokemon|
            pokemon.current_hp <= 0
          end
        end
      end
    end

    def start
      @sides = [@team1, @team2].map do |team|
        team.map do |trainer|
          add_to_log 'sends_to_battle', trainer.name, trainer.team.first.name
          [trainer, [trainer.team.first]]
        end
      end
      finish_turn
      true
    end

    def execute_actions
      turn = Turn.new(self, @actions.map { |a| Action.new(*a) })
      turn.execute
      finish_turn
    end

    def trainers
      @team1 + @team2
    end

    def pokemon_in_battle(trainer)
      @sides.each do |side|
        side.each do |trainer_data|
          return trainer_data[1] if trainer_data.first == trainer
        end
      end
      []
    end

    def valid_moves_for(trainer, pokemon)
      if pokemon.moves.all? { |m| m.pp.zero? }
        return struggle_move(trainer, pokemon)
      end
      pokemon.moves.map do |move|
        next if move.pp.zero?
        available_targets_for_move(trainer, pokemon, move).map do |target|
          {
            action: 'move',
            pokemon: pokemon,
            move: move.name,
            target: target
          }
        end
      end.compact.flatten(1)
    end

    def struggle_move(trainer, pokemon)
      move = struggle_move_instance
      available_targets_for_move(trainer, pokemon, move).map do |target|
        {
          action: 'move',
          pokemon: pokemon,
          move: move.name,
          target: target
        }
      end
    end

    def struggle_move_instance
      @struggle_move ||= begin
        move_type = Oakdex::Pokedex::Move.find('Struggle')
        Oakdex::Battle::Move.new(move_type, move_type.pp, move_type.pp)
      end
      @struggle_move.pp = 1
      @struggle_move
    end

    def available_targets_for_move(trainer, _pokemon, _move)
      # target, all_adjacent_foes, all_foes, user, anyone_but_user,
      # user_and_adjacent_ally, user_and_allies, adjacent_ally,
      # all_adjacent, everyone, target_foe
      other_sides(trainer).map do |side|
        side.map { |trainer_data| trainer_data[1] }
      end.flatten(2)
    end

    def other_sides(trainer)
      @sides.select do |side|
        !side.any? { |trainer_data| trainer_data.first == trainer }
      end
    end

    def finish_turn
      @log << @current_log
      @current_log = []
      @actions = []
    end
  end
end
