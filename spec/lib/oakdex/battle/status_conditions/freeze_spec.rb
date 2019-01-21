require 'spec_helper'

describe Oakdex::Battle::StatusConditions::Freeze do
  let(:trainer) { double(:trainer, name: 'Trainer') }
  let(:current_hp) { 20 }
  let(:pokemon) do
    double(:pokemon, hp: 25, trainer: trainer, name: 'Pokemon',
                     current_hp: current_hp)
  end
  let(:move_type) { 'normal' }
  let(:move) do
    double(:move, type_id: move_type)
  end
  let(:battle) { double(:battle) }
  let(:turn) { double(:turn, battle: battle) }
  subject { described_class.new(pokemon) }

  before do
    allow(battle).to receive(:add_to_log)
  end

  describe '#after_received_damage' do
    before do
      allow(pokemon).to receive(:remove_status_condition)
        .with(subject)
    end

    let(:move_execution) do
      double(:move_execution, battle: battle, move: move)
    end

    it 'does nothing' do
      expect(pokemon).not_to receive(:remove_status_condition)
          .with(subject)
      subject.after_received_damage(move_execution)
    end

    context 'fire move' do
      let(:move_type) { 'fire' }

      it 'defrosts' do
        expect(pokemon).to receive(:remove_status_condition)
          .with(subject)
        subject.after_received_damage(move_execution)
      end

      it 'adds to log' do
        expect(battle).to receive(:add_to_log)
          .with('defrosts', pokemon.trainer.name, pokemon.name)
        subject.after_received_damage(move_execution)
      end
    end
  end

  describe '#prevents_move?' do
    let(:move_execution) do
      double(:move_execution, battle: battle, pokemon: pokemon)
    end
    it { expect(subject).to be_prevents_move(move_execution) }

    it 'adds to log' do
      expect(battle).to receive(:add_to_log)
        .with('frozen', pokemon.trainer.name, pokemon.name)
      subject.prevents_move?(move_execution)
    end
  end

  describe '#before_turn' do
    let(:rand_number) { 50 }
    before do
      allow(subject).to receive(:rand).with(1..100).and_return(rand_number)
      allow(pokemon).to receive(:remove_status_condition).with(subject)
    end

    it 'does nothing' do
      expect(battle).not_to receive(:add_to_log)
      expect(pokemon).not_to receive(:remove_status_condition)
        .with(subject)
      subject.before_turn(turn)
    end

    context '20 percent chance' do
      let(:rand_number) { 18 }

      it 'adds to log' do
        expect(battle).to receive(:add_to_log)
          .with('defrosts', pokemon.trainer.name, pokemon.name)
        subject.before_turn(turn)
      end

      it 'removes status condition' do
        expect(pokemon).to receive(:remove_status_condition)
          .with(subject)
        subject.before_turn(turn)
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
