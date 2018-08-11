require 'spec_helper'

describe Oakdex::Battle::StatusConditions::Sleep do
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
  end

  describe '#prevents_move?' do
    let(:move_execution) do
      double(:move_execution, battle: battle, pokemon: pokemon)
    end
    it { expect(subject).to be_prevents_move(move_execution) }

    it 'adds to log' do
      expect(battle).to receive(:add_to_log)
        .with('sleeping', pokemon.trainer.name, pokemon.name)
      subject.prevents_move?(move_execution)
    end
  end

  describe '#after_turn' do
    let(:turns_asleep) { 1 }
    before do
      subject.instance_variable_set(:@max_turn_count, turns_asleep)
      allow(pokemon).to receive(:remove_status_condition).with(subject)
    end

    it 'does nothing' do
      expect(battle).not_to receive(:add_to_log)
      expect(pokemon).not_to receive(:remove_status_condition)
        .with(subject)
      subject.after_turn(turn)
    end

    context 'second turn' do
      before do
        subject.after_turn(turn)
      end

      it 'adds to log' do
        expect(battle).to receive(:add_to_log)
          .with('wake_up', pokemon.trainer.name, pokemon.name)
        subject.after_turn(turn)
      end

      it 'removes status condition' do
        expect(pokemon).to receive(:remove_status_condition)
          .with(subject)
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
