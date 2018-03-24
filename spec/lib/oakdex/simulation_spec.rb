require 'spec_helper'

describe 'Battle simulation' do
  let(:pokemon1) do
    Oakdex::Battle::Pokemon.create('Pikachu', level: 5)
  end
  let(:pokemon2) do
    Oakdex::Battle::Pokemon.create('Bulbasaur', level: 5)
  end
  let(:pokemon3) do
    Oakdex::Battle::Pokemon.create('Squirtle', level: 5)
  end
  let(:pokemon4) do
    Oakdex::Battle::Pokemon.create('Pidgey', level: 4)
  end
  let(:trainer1) do
    Oakdex::Battle::Trainer.new('Ash', [pokemon1, pokemon2])
  end
  let(:trainer2) do
    Oakdex::Battle::Trainer.new('Misty', [pokemon3, pokemon4])
  end
  let(:team1) { [trainer1] }
  let(:team2) { [trainer2] }
  let(:battle) do
    Oakdex::Battle.new(team1, team2)
  end

  10.times do |i|
    it "executes battle simulation #{i}" do
      battle.continue

      until battle.finished?
        battle.simulate_action(trainer1)
        battle.simulate_action(trainer2)
        battle.continue
      end

      battle.log.each do |log|
        puts log.inspect
      end

      puts "WINNER: #{battle.winner.map(&:name)}" if battle.winner

      expect(battle.log).not_to be_empty
      expect(battle).to be_finished
    end
  end
end
