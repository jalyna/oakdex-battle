require 'spec_helper'

describe Oakdex::Battle do
  let(:pokemon1) do
    Oakdex::Battle::Pokemon.create('Pikachu',
                                   level: 3,
                                   moves: [['Thunder Shock', 30, 30]]
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
