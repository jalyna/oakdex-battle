require 'spec_helper'

describe Oakdex::Battle::Trainer do
  let(:name) { double(:name) }
  let(:current_hp1) { 10 }
  let(:current_hp2) { 12 }
  let(:pokemon1) do
    double(:pokemon,
           "trainer=": nil,
           name: 'Pok1',
           current_hp: current_hp1)
  end
  let(:pokemon2) do
    double(:pokemon,
           "trainer=": nil,
           current_hp: current_hp2)
  end
  let(:team) { [pokemon1, pokemon2] }
  let(:side) { double(:side) }
  let(:fainted) { false }
  let(:battle) { double(:battle) }
  let(:active_in_battle_pokemon) do
    double(:active_in_battle_pokemon, fainted?: fainted,
                               pokemon: pokemon1,
                               battle: battle)
  end
  subject { described_class.new(name, team) }

  describe '#name' do
    it { expect(subject.name).to eq(name) }
  end

  describe '#team' do
    it { expect(subject.team).to eq(team) }
  end

  describe '#active_in_battle_pokemon' do
    it { expect(subject.active_in_battle_pokemon).to eq([]) }
  end

  describe '#fainted?' do
    it { expect(subject).not_to be_fainted }

    context 'pokemon hp 1 is zero' do
      let(:current_hp1) { 0 }
      it { expect(subject).not_to be_fainted }

      context 'pokemon hp 2 is zero' do
        let(:current_hp2) { 0 }
        it { expect(subject).to be_fainted }
      end
    end
  end

  describe '#send_to_battle' do
    let(:position) { 0 }

    before do
      allow(Oakdex::Battle::ActiveInBattlePokemon).to receive(:new)
        .with(pokemon1, side, position).and_return(active_in_battle_pokemon)
      allow(side).to receive(:add_to_log)
        .with('sends_to_battle', name, pokemon1.name)
      allow(side).to receive(:next_position).and_return(position)
    end

    it 'sends pokemon to battle' do
      subject.send_to_battle(pokemon1, side)
      expect(subject.active_in_battle_pokemon).to eq([active_in_battle_pokemon])
    end

    it 'adds to logs' do
      expect(side).to receive(:add_to_log)
        .with('sends_to_battle', name, pokemon1.name)
      subject.send_to_battle(pokemon1, side)
    end
  end

  describe '#remove_from_battle' do
    let(:position) { 0 }
    let(:status_condition) { double(:status_condition) }

    before do
      allow(Oakdex::Battle::ActiveInBattlePokemon).to receive(:new)
        .with(pokemon1, side, position).and_return(active_in_battle_pokemon)
      allow(side).to receive(:add_to_log)
        .with('sends_to_battle', name, pokemon1.name)
      allow(side).to receive(:add_to_log)
        .with('removes_from_battle', name, pokemon1.name)
      allow(side).to receive(:next_position).and_return(position)
      allow(pokemon1).to receive(:reset_stats)
      allow(pokemon1).to receive(:status_conditions)
        .and_return([status_condition])
      allow(status_condition).to receive(:after_switched_out)
        .with(battle)
      subject.send_to_battle(pokemon1, side)
    end

    it 'removes pokemon from battle' do
      expect(status_condition).to receive(:after_switched_out)
        .with(battle)
      subject.remove_from_battle(pokemon1, side)
      expect(subject.active_in_battle_pokemon).to eq([])
    end

    it 'adds to logs' do
      expect(side).to receive(:add_to_log)
        .with('removes_from_battle', name, pokemon1.name)
      subject.remove_from_battle(pokemon1, side)
    end

    it 'reset stats' do
      expect(pokemon1).to receive(:reset_stats)
      subject.remove_from_battle(pokemon1, side)
    end
  end

  describe '#remove_fainted' do
    let(:position) { 0 }
    let(:status_condition) { double(:status_condition) }
    before do
      allow(Oakdex::Battle::ActiveInBattlePokemon).to receive(:new)
        .with(pokemon1, side, position).and_return(active_in_battle_pokemon)
      allow(side).to receive(:add_to_log)
        .with('sends_to_battle', name, pokemon1.name)
      allow(side).to receive(:next_position).and_return(position)
      allow(pokemon1).to receive(:status_conditions)
        .and_return([status_condition])
      subject.send_to_battle(pokemon1, side)
    end

    it 'does nothing' do
      expect(battle).not_to receive(:add_to_log)
      subject.remove_fainted
      expect(subject.active_in_battle_pokemon).to eq([active_in_battle_pokemon])
    end

    context 'pokemon fainted' do
      let(:fainted) { true }

      it 'removes fainted' do
        expect(battle).to receive(:add_to_log)
          .with('pokemon_fainted', name, pokemon1.name)
        expect(status_condition).to receive(:after_fainted).with(battle)
        subject.remove_fainted
        expect(subject.active_in_battle_pokemon).to eq([])
      end
    end
  end

  describe '#left_pokemon_in_team' do
    let(:position) { 0 }

    it { expect(subject.left_pokemon_in_team).to eq(team) }

    context 'pokemon1 hp is zero' do
      let(:current_hp1) { 0 }
      it { expect(subject.left_pokemon_in_team).to eq([pokemon2]) }
    end

    context 'has in battle pokemon' do
      before do
        allow(Oakdex::Battle::ActiveInBattlePokemon).to receive(:new)
          .with(pokemon1, side, position).and_return(active_in_battle_pokemon)
        allow(side).to receive(:add_to_log)
          .with('sends_to_battle', name, pokemon1.name)
        allow(side).to receive(:next_position).and_return(position)
        subject.send_to_battle(pokemon1, side)
      end

      it { expect(subject.left_pokemon_in_team).to eq([pokemon2]) }
    end
  end
end
