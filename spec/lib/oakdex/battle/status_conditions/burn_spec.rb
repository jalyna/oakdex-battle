require 'spec_helper'

describe Oakdex::Battle::StatusConditions::Burn do
  let(:trainer) { double(:trainer, name: 'Trainer') }
  let(:current_hp) { 32 }
  let(:pokemon) do
    double(:pokemon, hp: 32, trainer: trainer, name: 'Pokemon',
                     current_hp: current_hp,
                     fainted?: current_hp.zero?)
  end
  let(:battle) { double(:battle) }
  let(:move_category) { 'special' }
  let(:move) { double(:move, category: move_category) }
  let(:turn) { double(:turn, battle: battle) }
  let(:move_execution) do
    double(:move_execution, battle: battle, pokemon: pokemon,
                            move: move)
  end

  subject { described_class.new(pokemon) }

  before do
    allow(battle).to receive(:add_to_log)
    allow(pokemon).to receive(:change_hp_by)
    allow(battle).to receive(:remove_fainted)
  end

  describe '#after_turn' do
    it 'adds log' do
      expect(battle).to receive(:add_to_log)
        .with('damage_by_burn', trainer.name, pokemon.name, -2)
      subject.after_turn(turn)
    end

    it 'reduces hp by 1/16' do
      expect(pokemon).to receive(:change_hp_by).with(-2)
      subject.after_turn(turn)
    end

    context 'fainted' do
      let(:current_hp) { 0 }

      it 'does not add log' do
        expect(battle).not_to receive(:add_to_log)
          .with('damage_by_burn', trainer.name, pokemon.name, -2)
        subject.after_turn(turn)
      end
    end
  end

  describe '#damage_modifier' do
    it { expect(subject.damage_modifier(move_execution)).to eq(1.0) }

    context 'physical' do
      let(:move_category) { 'physical' }
      it { expect(subject.damage_modifier(move_execution)).to eq(0.5) }
    end
  end

  describe '#after_fainted' do
    it 'removes status condition' do
      expect(pokemon).to receive(:remove_status_condition).with(subject)
      subject.after_fainted(battle)
    end
  end
end
