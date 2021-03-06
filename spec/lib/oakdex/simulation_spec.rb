require 'spec_helper'

describe 'Battle simulation' do
  let(:pokemon1) do
    Oakdex::Pokemon.create('Pikachu', level: 5,
                                              moves: [
                                                ['Nuzzle', 30, 30],
                                                ['Blue Flare', 10, 10],
                                                ['Ice Fang', 10, 10],
                                                ['Hypnosis', 10, 10]
                                              ])
  end
  let(:pokemon2) do
    Oakdex::Pokemon.create('Bulbasaur',
                                   level: 5,
                                   moves: [
                                     ['Aromatherapy', 30, 30],
                                     ['Gravity', 2, 2],
                                     ['Poison Gas', 10, 10],
                                     ['Toxic', 10, 10]
                                   ]
                                  )
  end
  let(:pokemon3) do
    Oakdex::Pokemon.create('Squirtle', level: 5)
  end
  let(:pokemon4) do
    Oakdex::Pokemon.create('Pidgey', level: 4)
  end
  let(:pokemon5) do
    Oakdex::Pokemon.create('Charmander', level: 3)
  end
  let(:pokemon6) do
    Oakdex::Pokemon.create('Caterpie', level: 3)
  end
  let(:pokemon7) do
    Oakdex::Pokemon.create('Chikorita', level: 3)
  end
  let(:pokemon8) do
    Oakdex::Pokemon.create('Spearow', level: 3)
  end
  let(:pokemon9) do
    Oakdex::Pokemon.create('Pidgey', level: 3)
  end
  let(:items2) do
    ['Potion', 'Elixir', 'Ether']
  end
  let(:items1) do
    ['Potion', 'Potion', 'Revive', 'Soda Pop', 'Ether']
  end
  let(:trainer1) do
    Oakdex::Battle::Trainer.new('Ash', [pokemon1, pokemon2], items1, enable_grow: true, using_exp_share: true)
  end
  let(:trainer2) do
    Oakdex::Battle::Trainer.new('Misty', [pokemon3, pokemon4], items2)
  end
  let(:team1) { [trainer1] }
  let(:team2) { [trainer2] }
  let(:battle) { Oakdex::Battle.new(team1, team2) }

  context '1 Trainer vs. 1 Trainer' do
    context '1 vs. 1' do
      5.times do |i|
        it "executes battle simulation #{i}" do
          battle.continue

          until battle.finished?
            puts "UUU #{battle.valid_actions_for(trainer1)}"
            battle.simulate_action(trainer1)
            battle.simulate_action(trainer2)
            battle.continue
            puts battle.log.last.inspect
          end

          puts "WINNER: #{battle.winner.map(&:name)}" if battle.winner

          expect(battle.log).not_to be_empty
          expect(battle).to be_finished

          expect(battle.to_h).to eq({
            finished: true,
            pokemon_per_side: 1,
            sides: battle.sides.map(&:to_h)
          })
        end
      end
    end

    context '2 vs. 2' do
      let(:trainer1) do
        Oakdex::Battle::Trainer.new('Ash', [pokemon1, pokemon2,
                                            pokemon5, pokemon6], items1)
      end
      let(:trainer2) do
        Oakdex::Battle::Trainer.new('Misty', [pokemon3, pokemon4,
                                              pokemon7, pokemon8], items2)
      end
      let(:battle) { Oakdex::Battle.new(team1, team2, pokemon_per_side: 2) }

      5.times do |i|
        it "executes battle simulation #{i}" do
          battle.continue

          until battle.finished?
            battle.simulate_action(trainer1)
            battle.simulate_action(trainer1)
            battle.simulate_action(trainer2)
            battle.simulate_action(trainer2)
            battle.continue
            puts battle.log.last.inspect
          end

          puts "WINNER: #{battle.winner.map(&:name)}" if battle.winner

          expect(battle.log).not_to be_empty
          expect(battle).to be_finished
        end
      end
    end

    context '3 vs. 3' do
      let(:trainer1) do
        Oakdex::Battle::Trainer.new('Ash', [pokemon1, pokemon2,
                                            pokemon5, pokemon6], items1)
      end
      let(:trainer2) do
        Oakdex::Battle::Trainer.new('Misty', [pokemon3, pokemon4,
                                              pokemon7, pokemon8], items2)
      end
      let(:battle) { Oakdex::Battle.new(team1, team2, pokemon_per_side: 3) }

      5.times do |i|
        it "executes battle simulation #{i}" do
          battle.continue

          until battle.finished?
            battle.simulate_action(trainer1)
            battle.simulate_action(trainer1)
            battle.simulate_action(trainer1)
            battle.simulate_action(trainer2)
            battle.simulate_action(trainer2)
            battle.simulate_action(trainer2)
            battle.continue
            puts battle.log.last.inspect
          end

          puts "WINNER: #{battle.winner.map(&:name)}" if battle.winner

          expect(battle.log).not_to be_empty
          expect(battle).to be_finished
        end
      end
    end
  end

  context '2 vs. 2 with two trainers on each side' do
    let(:trainer3) do
      Oakdex::Battle::Trainer.new('Brock', [pokemon5, pokemon6], items1)
    end
    let(:trainer4) do
      Oakdex::Battle::Trainer.new('Erika', [pokemon7, pokemon8, pokemon9], items2)
    end
    let(:team1) { [trainer1, trainer3] }
    let(:team2) { [trainer2, trainer4] }

    5.times do |i|
      it "executes battle simulation #{i}" do
        battle.continue

        until battle.finished?
          battle.simulate_action(trainer1)
          battle.simulate_action(trainer2)
          battle.simulate_action(trainer3)
          battle.simulate_action(trainer4)
          battle.continue
          puts battle.log.last.inspect
        end

        puts "WINNER: #{battle.winner.map(&:name)}" if battle.winner

        expect(battle.log).not_to be_empty
        expect(battle).to be_finished
      end
    end
  end
end
