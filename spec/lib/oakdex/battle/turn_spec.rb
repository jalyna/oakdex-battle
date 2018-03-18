require 'spec_helper'

describe Oakdex::Battle::Turn do
  let(:pokemon1) do
    Oakdex::Battle::Pokemon.create('Pikachu',
                                   level: 3,
                                   moves: [['Thunder Shock', 30, 30]]
                                  )
  end
  let(:pokemon2) do
    Oakdex::Battle::Pokemon.create('Bulbasaur',
                                   level: 3,
                                   moves: [['Tackle', 35, 35]]
                                  )
  end
  let(:trainer1) { Oakdex::Battle::Trainer.new('Ash', [pokemon1]) }
  let(:trainer2) { Oakdex::Battle::Trainer.new('Misty', [pokemon2]) }
  let(:attributes1) do
    {
      action: 'move',
      pokemon: pokemon1,
      target: pokemon2,
      move: 'Thunder Shock'
    }
  end
  let(:attributes2) do
    {
      action: 'move',
      pokemon: pokemon2,
      target: pokemon1,
      move: 'Tackle'
    }
  end
  let(:action1) { Oakdex::Battle::Action.new(trainer1, attributes1) }
  let(:action2) { Oakdex::Battle::Action.new(trainer2, attributes2) }
  let(:battle) { Oakdex::Battle.new(trainer1, trainer2) }

  subject { described_class.new(battle, [action1, action2]) }

  describe '#execute' do
    let(:move1_prio) { 1 }
    let(:move2_prio) { 0 }
    let(:pokemon1_speed) { 100 }
    let(:pokemon2_speed) { 100 }

    before do
      allow(pokemon1).to receive(:speed).and_return(pokemon1_speed)
      allow(pokemon2).to receive(:speed).and_return(pokemon2_speed)
      allow(pokemon1.moves.first).to receive(:priority).and_return(move1_prio)
      allow(pokemon2.moves.first).to receive(:priority).and_return(move2_prio)
    end

    it 'does actions in correct order' do
      expect(action1).to receive(:execute)
        .with(subject)
        .ordered
      expect(action2).to receive(:execute)
        .with(subject)
        .ordered
      subject.execute
    end

    context 'pokemon fainted' do
      before do
        allow(pokemon1).to receive(:current_hp).and_return(0)
      end

      it 'does actions in correct order' do
        expect(action1).not_to receive(:execute)
        expect(action2).not_to receive(:execute)
        subject.execute
      end
    end

    context 'move 2 has higher prio' do
      let(:move2_prio) { 2 }

      it 'does actions in correct order' do
        expect(action2).to receive(:execute)
          .with(subject)
          .ordered
        expect(action1).to receive(:execute)
          .with(subject)
          .ordered
        subject.execute
      end
    end

    context 'same prio' do
      let(:move1_prio) { 0 }
      let(:pokemon2_speed) { 110 }

      it 'does actions in correct order' do
        expect(action2).to receive(:execute)
          .with(subject)
          .ordered
        expect(action1).to receive(:execute)
          .with(subject)
          .ordered
        subject.execute
      end
    end

    context 'second pokemon' do
      let(:pokemon3) do
        Oakdex::Battle::Pokemon.create('Charmander',
                                       level: 3,
                                       moves: [['Tackle', 35, 35]]
                                      )
      end
      let(:trainer2) do
        Oakdex::Battle::Trainer.new('Misty',
                                    [pokemon2, pokemon3])
      end
      let(:attributes2) do
        {
          action: 'recall',
          pokemon: pokemon2,
          target: pokemon3
        }
      end

      it 'does actions in correct order' do
        expect(action2).to receive(:execute)
          .with(subject)
          .ordered
        expect(action1).to receive(:execute)
          .with(subject)
          .ordered
        subject.execute
      end
    end
  end
end
