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
    let(:hitting_probability1) { 500 }
    let(:hitting_probability2) { 500 }
    let(:hitting_rand1) { 500 }
    let(:hitting_rand2) { 500 }

    before do
      allow(pokemon1).to receive(:speed).and_return(pokemon1_speed)
      allow(pokemon2).to receive(:speed).and_return(pokemon2_speed)
      allow(pokemon1.moves.first).to receive(:priority).and_return(move1_prio)
      allow(pokemon2.moves.first).to receive(:priority).and_return(move2_prio)
      allow(action1).to receive(:hitting_probability)
        .and_return(hitting_probability1)
      allow(action2).to receive(:hitting_probability)
        .and_return(hitting_probability2)
      allow(subject).to receive(:rand).with(1..1000).and_return(hitting_rand1)
      allow(subject).to receive(:rand).with(1..1000).and_return(hitting_rand2)
    end

    it 'adds to logs' do
      expect(battle).to receive(:add_to_log)
        .with('uses_move', 'Ash', 'Pikachu', 'Thunder Shock')
        .ordered
      expect(battle).to receive(:add_to_log)
        .with('uses_move', 'Misty', 'Bulbasaur', 'Tackle')
        .ordered
      subject.execute
    end

    context 'move 1 is not hitting' do
      let(:hitting_probability1) { 400 }

      it 'adds to logs' do
        expect(battle).to receive(:add_to_log)
          .with('move_does_not_hit', 'Ash', 'Pikachu', 'Thunder Shock')
          .ordered
        expect(battle).to receive(:add_to_log)
          .with('uses_move', 'Misty', 'Bulbasaur', 'Tackle')
          .ordered
        subject.execute
      end
    end

    context 'move 2 has higher prio' do
      let(:move2_prio) { 2 }

      it 'adds to logs' do
        expect(battle).to receive(:add_to_log)
          .with('uses_move', 'Misty', 'Bulbasaur', 'Tackle')
          .ordered
        expect(battle).to receive(:add_to_log)
          .with('uses_move', 'Ash', 'Pikachu', 'Thunder Shock')
          .ordered
        subject.execute
      end
    end

    context 'same prio' do
      let(:move1_prio) { 0 }
      let(:pokemon2_speed) { 110 }

      it 'adds to logs' do
        expect(battle).to receive(:add_to_log)
          .with('uses_move', 'Misty', 'Bulbasaur', 'Tackle')
          .ordered
        expect(battle).to receive(:add_to_log)
          .with('uses_move', 'Ash', 'Pikachu', 'Thunder Shock')
          .ordered
        subject.execute
      end
    end
  end
end
