require 'spec_helper'

describe Oakdex::Battle::Action do
  let(:pokemon) do
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
end
