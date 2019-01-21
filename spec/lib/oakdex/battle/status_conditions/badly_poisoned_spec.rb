require 'spec_helper'

describe Oakdex::Battle::StatusConditions::BadlyPoisoned do
  let(:trainer) { double(:trainer, name: 'Trainer') }
  let(:current_hp) { 20 }
  let(:pokemon) do
    double(:pokemon, hp: 25, trainer: trainer, name: 'Pokemon',
                     current_hp: current_hp,
                     fainted?: current_hp.zero?)
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
        .with('damage_by_badly_poisoned', trainer.name, pokemon.name, -1)
      subject.after_turn(turn)
    end

    it 'reduces hp by 1/16 but it increases' do
      expect(pokemon).to receive(:change_hp_by).with(-1)
      subject.after_turn(turn)
      expect(pokemon).to receive(:change_hp_by).with(-3)
      subject.after_turn(turn)
      expect(pokemon).to receive(:change_hp_by).with(-4)
      subject.after_turn(turn)
      expect(pokemon).to receive(:change_hp_by).with(-6)
      subject.after_turn(turn)
    end

    context 'fainted' do
      let(:current_hp) { 0 }

      it 'does not add log' do
        expect(battle).not_to receive(:add_to_log)
          .with('damage_by_badly_poisoned', trainer.name, pokemon.name, -3)
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

  describe '#after_switched_out' do
    before do
      subject.after_turn(turn)
      subject.after_turn(turn)
      subject.after_turn(turn)
      subject.after_turn(turn)
    end

    it 'resets counter' do
      subject.after_switched_out(battle)
      expect(pokemon).to receive(:change_hp_by).with(-1)
      subject.after_turn(turn)
    end
  end
end
