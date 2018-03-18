require 'spec_helper'

describe Oakdex::Battle::Action do
  let(:pokemon) do
    Oakdex::Battle::Pokemon.create('Pikachu',
                                   level: 3,
                                   hp: 6,
                                   moves: [['Thunder Shock', 30, 30]]
                                  )
  end
  let(:pokemon2) do
    Oakdex::Battle::Pokemon.create('Bulbasaur',
                                   level: 3,
                                   hp: 6,
                                   moves: [['Tackle', 35, 35]]
                                  )
  end
  let(:trainer) { Oakdex::Battle::Trainer.new('Ash', [pokemon]) }
  let(:attributes) do
    {
      action: 'move',
      pokemon: pokemon,
      target: pokemon2,
      move: 'Thunder Shock'
    }
  end
  subject { described_class.new(trainer, attributes) }

  describe '#pokemon' do
    it { expect(subject.pokemon).to eq(pokemon) }
  end

  describe '#target' do
    it { expect(subject.target).to eq(pokemon2) }
  end

  describe '#move' do
    it { expect(subject.move).to eq(pokemon.moves.first) }
  end

  describe '#trainer' do
    it { expect(subject.trainer).to eq(trainer) }
  end

  describe '#hitting_probability' do
    it { expect(subject.hitting_probability).to eq(1000) }

    context 'move accuracy is less than 100' do
      before do
        allow(subject.move).to receive(:accuracy).and_return(80)
      end
      it { expect(subject.hitting_probability).to eq(800) }
    end

    context 'pokemon accuracy is less than 1' do
      before do
        allow(subject.pokemon).to receive(:accuracy).and_return(0.8)
      end
      it { expect(subject.hitting_probability).to eq(800) }
    end

    context 'target evasion is less than 1' do
      before do
        allow(subject.target).to receive(:evasion).and_return(0.8)
      end
      it { expect(subject.hitting_probability).to eq(1250) }
    end
  end

  describe '#hitting?' do
    let(:rand_number) { 500 }

    before do
      allow(subject).to receive(:rand).with(1..1000).and_return(rand_number)
    end

    it { expect(subject).to be_hitting }

    context 'not hitting' do
      let(:rand_number) { 1001 }
      it { expect(subject).not_to be_hitting }
    end
  end

  describe '#execute' do
    let(:attributes2) do
      {
        action: 'move',
        pokemon: pokemon2,
        target: pokemon,
        move: 'Tackle'
      }
    end
    let(:trainer2) { Oakdex::Battle::Trainer.new('Misty', [pokemon2]) }
    let(:action2) { Oakdex::Battle::Action.new(trainer2, attributes2) }
    let(:battle) { Oakdex::Battle.new(trainer, trainer2) }
    let(:turn) { Oakdex::Battle::Turn.new(battle, [subject, action2]) }
    let(:log) { [] }
    let(:hitting) { true }
    let(:damage) { double(:damage, damage: 3) }

    before do
      allow(subject).to receive(:hitting?).and_return(hitting)
      allow(battle).to receive(:add_to_log) do |*args|
        log << args.to_a
      end
      allow(Oakdex::Battle::Damage).to receive(:new)
        .with(turn, subject).and_return(damage)
    end

    it 'adds correct logs' do
      subject.execute(turn)
      expect(log)
        .to eq([
                 ['uses_move', 'Ash', 'Pikachu', 'Thunder Shock'],
                 ['received_damage', 'Misty', 'Bulbasaur',
                  'Thunder Shock', damage.damage]
               ])
    end

    it 'sets damage object' do
      subject.execute(turn)
      expect(subject.damage).to eq(damage)
    end

    it 'reduces target hp' do
      expect(pokemon2).to receive(:change_hp_by).with(-damage.damage)
      subject.execute(turn)
    end

    context 'target faints' do
      let(:damage) { double(:damage, damage: 8) }
      it 'adds correct logs' do
        subject.execute(turn)
        expect(log)
          .to eq([
                   ['uses_move', 'Ash', 'Pikachu', 'Thunder Shock'],
                   ['received_damage', 'Misty', 'Bulbasaur',
                    'Thunder Shock', damage.damage],
                   %w[target_fainted Misty Bulbasaur]
                 ])
      end
    end

    context 'no damage' do
      let(:damage) { double(:damage, damage: 0) }

      it 'adds correct logs' do
        subject.execute(turn)
        expect(log)
          .to eq([
                   ['uses_move', 'Ash', 'Pikachu', 'Thunder Shock'],
                   ['received_no_damage', 'Misty', 'Bulbasaur',
                    'Thunder Shock']
                 ])
      end

      it 'sets damage object' do
        subject.execute(turn)
        expect(subject.damage).to eq(damage)
      end
    end

    context 'not hitting' do
      let(:hitting) { false }

      it 'adds correct logs' do
        subject.execute(turn)
        expect(log)
          .to eq([['move_does_not_hit', 'Ash', 'Pikachu', 'Thunder Shock']])
      end

      it 'does not set damage object' do
        subject.execute(turn)
        expect(subject.damage).to be_nil
      end
    end
  end
end
