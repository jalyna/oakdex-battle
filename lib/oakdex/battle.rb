require 'oakdex/pokedex'

require 'oakdex/battle/pokemon'
require 'oakdex/battle/trainer'
require 'oakdex/battle/action'
require 'oakdex/battle/damage'
require 'oakdex/battle/turn'
require 'oakdex/battle/valid_action_service'

module Oakdex
  # Namespace that handles Battles
  class Battle
    attr_reader :log, :actions, :team1, :team2

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
      valid_action_service.valid_actions_for(trainer)
    end

    def add_action(trainer, action)
      return false unless valid_actions_for(trainer).include?(action)
      @actions << Action.new(trainer, action)
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

    def remove_from_arena(_trainer, pokemon)
      @sides = @sides.map do |side|
        side.map do |trainer_data|
          [
            trainer_data[0],
            trainer_data[1].select { |p| p != pokemon }
          ]
        end
      end
    end

    def add_to_arena(trainer, pokemon)
      @sides = @sides.map do |side|
        side.map do |trainer_data|
          if trainer_data[0] == trainer
            [
              trainer_data[0],
              trainer_data[1] + [pokemon]
            ]
          else
            trainer_data
          end
        end
      end
    end

    private

    def valid_action_service
      @valid_action_service ||= ValidActionService.new(self)
    end

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
      turn = Turn.new(self, @actions)
      turn.execute
      finish_turn
    end

    def trainers
      @team1 + @team2
    end

    def finish_turn
      @log << @current_log
      @current_log = []
      @actions = []
    end
  end
end
