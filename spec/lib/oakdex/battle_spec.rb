require 'spec_helper'

describe Oakdex::Battle do
  let(:move_1_pp) { 30 }
  let(:pokemon1) do
    Oakdex::Battle::Pokemon.create('Pikachu',
                                   level: 3,
                                   moves: [['Thunder Shock', move_1_pp, 30]]
                                  )
  end
  let(:pokemon2) do
    Oakdex::Battle::Pokemon.create('Charmander',
                                   level: 3,
                                   moves: [['Tackle', 35, 35]]
                                  )
  end
  let(:trainer1) { Oakdex::Battle::Trainer.new('Ash', [pokemon1]) }
  let(:trainer2) { Oakdex::Battle::Trainer.new('Misty', [pokemon2]) }
  subject { described_class.new(trainer1, trainer2) }

  describe '#arena' do
    it { expect(subject.arena).to eq(sides: []) }
  end

  describe '#log' do
    it { expect(subject.log).to eq([]) }
  end

  describe '#valid_actions_for' do
    it { expect(subject.valid_actions_for(trainer1)).to eq([]) }
    it { expect(subject.valid_actions_for(trainer2)).to eq([]) }
  end

  describe '#add_action' do
    it { expect(subject.add_action(trainer1, {})).to be(false) }
  end

  describe '#continue' do
    it { expect(subject.continue).to be(true) }
  end

  describe '#finished?' do
    it { expect(subject).not_to be_finished }
  end

  describe '#winner' do
    it { expect(subject.winner).to be_nil }
  end

  context 'one side has no healthy pokemon' do
    let(:pokemon2) do
      Oakdex::Battle::Pokemon.create('Charmander',
                                     level: 3,
                                     hp: 0,
                                     moves: [['Tackle', 35, 35]]
                                    )
    end

    describe '#finished?' do
      it { expect(subject).to be_finished }
    end

    describe '#winner' do
      it { expect(subject.winner).to eq([trainer1]) }
    end
  end

  context 'trainer1 has a second pokemon' do
    let(:pokemon3) do
      Oakdex::Battle::Pokemon.create('Pidgey',
                                     level: 3,
                                     moves: [['Quick Attack', 30, 30]]
                                    )
    end
    let(:trainer1) { Oakdex::Battle::Trainer.new('Ash', [pokemon1, pokemon3]) }

    context 'started' do
      before { subject.continue }

      describe '#arena' do
        it 'adds current pokemon to arena' do
          expect(subject.arena).to eq(
            sides: [
              [[trainer1, [pokemon1]]],
              [[trainer2, [pokemon2]]]
            ]
          )
        end
      end

      context 'first action added recall' do
        before do
          subject.add_action(trainer1,
                             action: 'recall',
                             pokemon: pokemon1,
                             target: pokemon3
                            )
        end

        describe '#valid_actions_for' do
          it 'shows valid actions for trainer1' do
            expect(subject.valid_actions_for(trainer1)).to eq([])
          end
        end
      end

      context 'first action added move' do
        before do
          subject.add_action(trainer1,
                             action: 'move',
                             pokemon: pokemon1,
                             move: 'Thunder Shock',
                             target: pokemon2
                            )
        end

        describe '#valid_actions_for' do
          it 'shows valid actions for trainer1' do
            expect(subject.valid_actions_for(trainer1)).to eq([])
          end
        end
      end

      describe '#valid_actions_for' do
        it 'shows valid actions for trainer1' do
          expect(subject.valid_actions_for(trainer1))
          .to eq([
                   {
                     action: 'move',
                     pokemon: pokemon1,
                     move: 'Thunder Shock',
                     target: pokemon2
                   },
                   {
                     action: 'recall',
                     pokemon: pokemon1,
                     target: pokemon3
                   }
                 ])
        end

        context 'pokemon1 fainted' do
          before do
            allow(pokemon1).to receive(:current_hp).and_return(0)
          end

          it 'removes pokemon2' do
            subject.remove_fainted
            expect(subject.valid_actions_for(trainer1))
            .to eq([
                     {
                       action: 'recall',
                       pokemon: nil,
                       target: pokemon3
                     }
                   ])
          end
        end
      end
    end
  end

  context 'started' do
    before { subject.continue }

    describe '#remove_from_arena' do
      it 'removes pokemon' do
        subject.remove_from_arena(trainer1, pokemon1)
        expect(subject.arena).to eq(
          sides: [
            [[trainer1, []]],
            [[trainer2, [pokemon2]]]
          ]
        )
      end
    end

    describe '#add_to_arena' do
      let(:pokemon3) { double(:pokemon) }
      it 'adds pokemon' do
        subject.add_to_arena(trainer1, pokemon3)
        expect(subject.arena).to eq(
          sides: [
            [[trainer1, [pokemon1, pokemon3]]],
            [[trainer2, [pokemon2]]]
          ]
        )
      end
    end

    describe '#remove_fainted' do
      it 'removes none' do
        subject.remove_fainted
        expect(subject.arena).to eq(
          sides: [
            [[trainer1, [pokemon1]]],
            [[trainer2, [pokemon2]]]
          ]
        )
      end

      context 'pokemon2 fainted' do
        before do
          allow(pokemon2).to receive(:current_hp).and_return(0)
        end

        it 'removes pokemon2' do
          subject.remove_fainted
          expect(subject.arena).to eq(
            sides: [
              [[trainer1, [pokemon1]]],
              [[trainer2, []]]
            ]
          )
        end
      end
    end

    describe '#arena' do
      it 'adds current pokemon to arena' do
        expect(subject.arena).to eq(
          sides: [
            [[trainer1, [pokemon1]]],
            [[trainer2, [pokemon2]]]
          ]
        )
      end
    end

    describe '#log' do
      it 'adds log' do
        expect(subject.log).to eq([[
                                    %w[sends_to_battle Ash Pikachu],
                                    %w[sends_to_battle Misty Charmander]
                                  ]])
      end
    end

    describe '#valid_actions_for' do
      it 'shows valid actions for trainer1' do
        expect(subject.valid_actions_for(trainer1))
        .to eq([
                 {
                   action: 'move',
                   pokemon: pokemon1,
                   move: 'Thunder Shock',
                   target: pokemon2
                 }
               ])
      end

      context 'no pp left' do
        let(:move_1_pp) { 0 }
        it 'shows valid actions for trainer1' do
          expect(subject.valid_actions_for(trainer1))
          .to eq([
                   {
                     action: 'move',
                     pokemon: pokemon1,
                     move: 'Struggle',
                     target: pokemon2
                   }
                 ])
        end
      end

      it 'shows valid actions for trainer2' do
        expect(subject.valid_actions_for(trainer2))
        .to eq([
                 {
                   action: 'move',
                   pokemon: pokemon2,
                   move: 'Tackle',
                   target: pokemon1
                 }
               ])
      end
    end

    describe '#add_action' do
      it 'adds valid one' do
        expect(subject.add_action(trainer1,
                                  action: 'move',
                                  pokemon: pokemon1,
                                  move: 'Thunder Shock',
                                  target: pokemon2
                                 )).to be(true)
      end

      it 'does not add invalid one' do
        expect(subject.add_action(trainer1,
                                  action: 'move',
                                  pokemon: pokemon1,
                                  move: 'Thunder Storm',
                                  target: pokemon2
                                 )).to be(false)
      end
    end

    describe '#continue' do
      it { expect(subject.continue).to be(false) }
    end

    context 'first action added' do
      before do
        subject.add_action(trainer1,
                           action: 'move',
                           pokemon: pokemon1,
                           move: 'Thunder Shock',
                           target: pokemon2
                          )
      end

      describe '#valid_actions_for' do
        it 'shows valid actions for trainer1' do
          expect(subject.valid_actions_for(trainer1)).to eq([])
        end

        it 'shows valid actions for trainer2' do
          expect(subject.valid_actions_for(trainer2))
          .to eq([
                   {
                     action: 'move',
                     pokemon: pokemon2,
                     move: 'Tackle',
                     target: pokemon1
                   }
                 ])
        end
      end

      describe '#continue' do
        it { expect(subject.continue).to be(false) }
      end

      describe '#simulate_action' do
        it 'simulates action' do
          expect(subject.simulate_action(trainer2)).to be(true)
        end
      end

      context 'second action added' do
        before do
          subject.add_action(trainer2,
                             action: 'move',
                             pokemon: pokemon2,
                             move: 'Tackle',
                             target: pokemon1
                            )
        end

        describe '#valid_actions_for' do
          it 'shows valid actions for trainer1' do
            expect(subject.valid_actions_for(trainer1)).to eq([])
          end

          it 'shows valid actions for trainer2' do
            expect(subject.valid_actions_for(trainer2)).to eq([])
          end
        end

        describe '#continue' do
          it { expect(subject.continue).to be(true) }
        end

        context 'continued' do
          before { subject.continue }

          describe '#log' do
            xit { expect(subject.log.size).to eq(2) }
          end
        end
      end
    end
  end
end
