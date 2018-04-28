require 'spec_helper'

describe Oakdex::Battle::StatusConditions::Paralysis do
  let(:trainer) { double(:trainer, name: 'Trainer') }
  let(:current_hp) { 20 }
  let(:pokemon) do
    double(:pokemon, hp: 25, trainer: trainer, name: 'Pokemon',
                     current_hp: current_hp)
  end
  let(:battle) { double(:battle) }
  subject { described_class.new(pokemon) }

  before do
    allow(battle).to receive(:add_to_log)
  end

  describe '#stat_modifier' do
    it { expect(subject.stat_modifier(:def)).to eq(1.0) }
    it { expect(subject.stat_modifier(:speed)).to eq(0.5) }
  end

  describe '#prevents_move?' do
    let(:move_execution) do
      double(:move_execution, battle: battle, pokemon: pokemon)
    end
    let(:rand_number) { 50 }
    before do
      allow(subject).to receive(:rand).with(1..100).and_return(rand_number)
    end

    it { expect(subject).not_to be_prevents_move(move_execution) }

    context 'less than 25' do
      let(:rand_number) { 20 }
      it { expect(subject).to be_prevents_move(move_execution) }

      it 'adds to log' do
        expect(battle).to receive(:add_to_log)
          .with('paralysed', pokemon.trainer.name, pokemon.name)
        subject.prevents_move?(move_execution)
      end
    end
  end
end
