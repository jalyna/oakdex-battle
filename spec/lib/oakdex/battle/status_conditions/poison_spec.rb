require 'spec_helper'

describe Oakdex::Battle::StatusConditions::Poison do
  let(:trainer) { double(:trainer, name: 'Trainer') }
  let(:current_hp) { 20 }
  let(:pokemon) do
    double(:pokemon, hp: 25, trainer: trainer, name: 'Pokemon',
                     current_hp: current_hp)
  end
  let(:battle) { double(:battle) }
  let(:turn) { double(:turn, battle: battle) }
  subject { described_class.new(pokemon) }

  before do
    allow(battle).to receive(:add_to_log)
    allow(pokemon).to receive(:change_hp_by)
    allow(battle).to receive(:remove_fainted)
  end

  describe '#after_turn' do
    it 'adds log' do
      expect(battle).to receive(:add_to_log)
        .with('damage_by_poison', trainer.name, pokemon.name, -3)
      subject.after_turn(turn)
    end

    it 'reduces hp by 1/8' do
      expect(pokemon).to receive(:change_hp_by).with(-3)
      subject.after_turn(turn)
    end

    context 'fainted' do
      let(:current_hp) { 0 }

      it 'does not add log' do
        expect(battle).not_to receive(:add_to_log)
          .with('damage_by_poison', trainer.name, pokemon.name, -3)
        subject.after_turn(turn)
      end
    end
  end

  describe '#after_fainted' do
    it 'removes status condition' do
      expect(pokemon).to receive(:remove_status_condition).with(subject)
      subject.after_fainted(battle)
    end
  end
end
