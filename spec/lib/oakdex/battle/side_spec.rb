require 'spec_helper'

describe Oakdex::Battle::Side do
  let(:pokemon_per_side) { 1 }
  let(:battle) { double(:battle, pokemon_per_side: pokemon_per_side) }
  let(:pokemon1) { double(:pokemon) }
  let(:pokemon2) { double(:pokemon) }
  let(:pokemon3) { double(:pokemon) }
  let(:pokemon4) { double(:pokemon) }
  let(:pokemon5) { double(:pokemon) }
  let(:team1) { [pokemon1, pokemon3] }
  let(:team2) { [pokemon2] }
  let(:trainer1) { double(:trainer, team: team1) }
  let(:trainer2) { double(:trainer, team: team2) }
  let(:trainers) { [trainer1, trainer2] }
  subject { described_class.new(battle, trainers) }

  describe '#next_position' do
    let(:active_in_battle_pokemon1) { double(:active_in_battle_pokemon, position: 0) }
    let(:active_in_battle_pokemon_list1) { [] }
    let(:trainers) { [trainer1] }
    before do
      allow(trainer1).to receive(:active_in_battle_pokemon)
        .and_return(active_in_battle_pokemon_list1)
    end

    it { expect(subject.next_position).to eq(0) }

    context 'pokemon in battle' do
      let(:active_in_battle_pokemon_list1) { [active_in_battle_pokemon1] }
      it { expect(subject.next_position).to be_nil }

      context '2 pokemon in battle' do
        let(:pokemon_per_side) { 2 }
        it { expect(subject.next_position).to eq(1) }
      end
    end
  end

  describe '#send_to_battle' do
    let(:pokemon_per_side) { 2 }
    it 'sends first pokemon to battle' do
      expect(trainer1).to receive(:send_to_battle)
        .with(pokemon1, subject)
      expect(trainer2).to receive(:send_to_battle)
        .with(pokemon2, subject)
      subject.send_to_battle
    end

    context '1 trainer' do
      let(:team1) { [pokemon1, pokemon3, pokemon4] }
      let(:team2) { [pokemon2, pokemon5] }
      let(:trainers) { [trainer1] }

      it 'sends first two pokemon to battle' do
        expect(trainer1).to receive(:send_to_battle)
          .with(pokemon1, subject)
        expect(trainer1).to receive(:send_to_battle)
          .with(pokemon3, subject)
        subject.send_to_battle
      end

      context 'two trainer per side' do
        let(:trainers) { [trainer1, trainer2] }

        it 'sends first two pokemon to battle' do
          expect(trainer1).to receive(:send_to_battle)
            .with(pokemon1, subject)
          expect(trainer2).to receive(:send_to_battle)
            .with(pokemon2, subject)
          subject.send_to_battle
        end
      end

      context 'not enough pokemon' do
        let(:team1) { [pokemon1] }

        it 'sends first two pokemon to battle' do
          expect(trainer1).to receive(:send_to_battle)
            .with(pokemon1, subject)
          expect(trainer1).not_to receive(:send_to_battle)
            .with(nil, subject)
          subject.send_to_battle
        end
      end
    end
  end

  describe '#remove_fainted' do
    it 'removes fainted of each trainer' do
      expect(trainer1).to receive(:remove_fainted)
      expect(trainer2).to receive(:remove_fainted)
      subject.remove_fainted
    end
  end

  describe '#trainer_on_side?' do
    let(:trainer3) { double(:trainer) }
    it { expect(subject).to be_trainer_on_side(trainer1) }
    it { expect(subject).to be_trainer_on_side(trainer2) }
    it { expect(subject).not_to be_trainer_on_side(trainer3) }
  end

  describe '#active_in_battle_pokemon' do
    let(:active_in_battle_pokemon1) { double(:active_in_battle_pokemon) }
    let(:active_in_battle_pokemon2) { double(:active_in_battle_pokemon) }

    before do
      allow(trainer1).to receive(:active_in_battle_pokemon)
        .and_return([active_in_battle_pokemon1])
      allow(trainer2).to receive(:active_in_battle_pokemon)
        .and_return([active_in_battle_pokemon2])
    end

    it 'returns battle pokemon' do
      expect(subject.active_in_battle_pokemon)
        .to eq([active_in_battle_pokemon1, active_in_battle_pokemon2])
    end
  end

  describe '#fainted?' do
    let(:fainted1) { false }
    let(:fainted2) { false }

    before do
      allow(trainer1).to receive(:fainted?).and_return(fainted1)
      allow(trainer2).to receive(:fainted?).and_return(fainted2)
    end

    it { expect(subject).not_to be_fainted }

    context 'trainer1 fainted' do
      let(:fainted1) { true }
      it { expect(subject).not_to be_fainted }

      context 'trainer2 fainted' do
        let(:fainted2) { true }
        it { expect(subject).to be_fainted }
      end
    end
  end

  describe '#pokemon_in_battle?' do
    let(:active_in_battle_pokemon1) { double(:active_in_battle_pokemon, position: 0) }
    let(:active_in_battle_pokemon_list1) { [active_in_battle_pokemon1] }
    let(:trainers) { [trainer1] }
    before do
      allow(trainer1).to receive(:active_in_battle_pokemon)
        .and_return(active_in_battle_pokemon_list1)
    end

    it { expect(subject).to be_pokemon_in_battle(0) }
    it { expect(subject).not_to be_pokemon_in_battle(1) }
  end

  describe '#pokemon_left?' do
    let(:active_in_battle_pokemon1) { double(:active_in_battle_pokemon, position: 0) }
    let(:active_in_battle_pokemon_list1) { [active_in_battle_pokemon1] }
    let(:trainers) { [trainer1] }
    before do
      allow(trainer1).to receive(:active_in_battle_pokemon)
        .and_return(active_in_battle_pokemon_list1)
    end

    it { expect(subject).to be_pokemon_left }

    context 'no pokemon' do
      let(:active_in_battle_pokemon_list1) { [] }
      it { expect(subject).not_to be_pokemon_left }
    end
  end
end
