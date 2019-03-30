require 'oakdex/pokemon'

require 'oakdex/battle/in_battle_pokemon'
require 'oakdex/battle/trainer'
require 'oakdex/battle/move_execution'
require 'oakdex/battle/action'
require 'oakdex/battle/damage'
require 'oakdex/battle/turn'
require 'oakdex/battle/valid_action_service'
require 'oakdex/battle/side'
require 'oakdex/battle/active_in_battle_pokemon'

module Oakdex
  # Represents battle, with has n turns and m sides
  class Battle
    attr_reader :log, :actions, :team1, :team2,
                :sides, :current_log

    def initialize(team1, team2, options = {})
      @team1 = team1.is_a?(Array) ? team1 : [team1]
      @team2 = team2.is_a?(Array) ? team2 : [team2]
      @options = options
      @sides = []
      @log = []
      @current_log = []
      @actions = []
      @turns = []
      @sides = [@team1, @team2].map do |team|
        Side.new(self, team)
      end
    end

    def pokemon_per_side
      @options[:pokemon_per_side] || @team1.size
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
      add_action(trainer, valid_actions.sample)
    end

    def continue
      return start if @log.empty?
      return false unless trainers.all? { |t| valid_actions_for(t).empty? }
      execute_actions
      true
    end

    def finished?
      !fainted_sides.empty?
    end

    def winner
      return if fainted_sides.empty?
      (sides - fainted_sides).flat_map(&:trainers)
    end

    def add_to_log(*args)
      @current_log << args.to_a
    end

    def remove_fainted
      sides.each(&:remove_fainted)
    end

    def side_by_id(id)
      sides.find { |s| s.id == id }
    end

    def trainers
      sides.flat_map(&:trainers)
    end

    def pokemon_by_id(id)
      trainers.each do |trainer|
        trainer.team.each do |p|
          return p if p.id == id
        end
      end

      nil
    end

    private

    def valid_action_service
      @valid_action_service ||= ValidActionService.new(self)
    end

    def fainted_sides
      sides.select(&:fainted?)
    end

    def start
      sides.each(&:send_to_battle)
      finish_turn
      true
    end

    def execute_actions
      @turns << Turn.new(self, @actions).tap(&:execute)
      finish_turn
    end

    def finish_turn
      @log << @current_log
      @current_log = []
      @actions = []
    end
  end
end
