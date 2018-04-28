require 'spec_helper'

describe Oakdex::Battle::Damage do
  let(:level1) { 3 }
  let(:level2) { 3 }
  let(:pokemon1) do
    Oakdex::Battle::Pokemon.create('Pikachu',
                                   level: level1,
                                   moves: [['Thunder Shock', 30, 30]]
                                  )
  end
  let(:pokemon2) do
    Oakdex::Battle::Pokemon.create('Bulbasaur',
                                   level: level2,
                                   moves: [['Tackle', 35, 35]]
                                  )
  end
  let(:in_battle_pokemon1) do
    double(:in_battle_pokemon,
           pokemon: pokemon1, position: 0)
  end
  let(:in_battle_pokemon2) do
    double(:in_battle_pokemon,
           pokemon: pokemon2, position: 0)
  end
  let(:side1) { double(:side, in_battle_pokemon: [in_battle_pokemon1]) }
  let(:side2) { double(:side, in_battle_pokemon: [in_battle_pokemon2]) }
  let(:trainer1) { Oakdex::Battle::Trainer.new('Ash', [pokemon1]) }
  let(:trainer2) { Oakdex::Battle::Trainer.new('Misty', [pokemon2]) }
  let(:attributes1) do
    {
      action: 'move',
      pokemon: pokemon1,
      target: [side2, 0],
      move: pokemon1.moves.first
    }
  end
  let(:attributes2) do
    {
      action: 'move',
      pokemon: pokemon2,
      target: [side1, 0],
      move: pokemon2.moves.first
    }
  end
  let(:action1) { Oakdex::Battle::Action.new(trainer1, attributes1) }
  let(:action2) { Oakdex::Battle::Action.new(trainer2, attributes2) }
  let(:battle) { Oakdex::Battle.new(trainer1, trainer2) }
  let(:turn) { Oakdex::Battle::Turn.new(battle, [action1, action2]) }
  let(:def_val) { 20 }
  let(:sp_def) { 30 }
  let(:atk) { 30 }
  let(:sp_atk) { 20 }
  let(:base_power) { 60 }
  let(:category) { 'physical' }
  let(:critical_hit_prob) { 0 }
  let(:random) { 1000 }
  let(:move_type) { 'Fire' }
  let(:pokemon1_types) { ['Normal'] }
  let(:pokemon2_types) { ['Normal'] }
  let(:move_execution1) do
    double(:move_execution,
           action: action1, target: pokemon2, move: pokemon1.moves.first,
           pokemon: pokemon1)
  end

  subject { described_class.new(turn, move_execution1) }

  before do
    allow(pokemon2).to receive(:def).and_return(def_val)
    allow(pokemon2).to receive(:sp_def).and_return(sp_def)
    allow(pokemon1).to receive(:atk).and_return(atk)
    allow(pokemon1).to receive(:sp_atk).and_return(sp_atk)
    allow(pokemon1).to receive(:types).and_return(pokemon1_types)
    allow(pokemon2).to receive(:types).and_return(pokemon2_types)
    allow(pokemon1.moves.first).to receive(:category).and_return(category)
    allow(pokemon1.moves.first).to receive(:power).and_return(base_power)
    allow(pokemon1.moves.first).to receive(:type).and_return(move_type)
    allow(pokemon1).to receive(:critical_hit_prob).and_return(critical_hit_prob)
    allow(subject).to receive(:rand).with(1..1000).and_return(2)
    allow(subject).to receive(:rand).with(850..1000).and_return(random)
  end

  describe '#damage' do
    it { expect(subject.damage).to eq(7) }

    context 'status condition' do
      let(:condition) { double(:condition) }
      before do
        allow(pokemon1).to receive(:status_conditions)
          .and_return([condition])
        allow(condition).to receive(:damage_modifier)
          .with(move_execution1)
          .and_return(0.5)
      end

      it { expect(subject.damage).to eq(3) }
    end

    context 'higher level' do
      let(:level1) { 8 }
      it { expect(subject.damage).to eq(11) }
    end

    context 'higher atk' do
      let(:atk) { 50 }
      it { expect(subject.damage).to eq(11) }
    end

    context 'higher def' do
      let(:def_val) { 50 }
      it { expect(subject.damage).to eq(4) }
    end

    context 'higher base_power' do
      let(:base_power) { 120 }
      it { expect(subject.damage).to eq(13) }
    end

    context 'special attack' do
      let(:category) { 'special' }
      it { expect(subject.damage).to eq(4) }
    end

    context 'critical hit' do
      let(:critical_hit_prob) { 1 }
      it { expect(subject.damage).to eq(11) }
    end

    context 'random factor' do
      let(:random) { 900 }
      it { expect(subject.damage).to eq(6) }
    end

    context 'same type as move' do
      let(:pokemon1_types) { %w[Normal Fire] }
      it { expect(subject.damage).to eq(11) }
    end

    context 'target is grass type' do
      let(:pokemon2_types) { %w[Normal Grass] }
      it { expect(subject.damage).to eq(15) }
    end

    context 'target is fire type' do
      let(:pokemon2_types) { %w[Fire] }
      it { expect(subject.damage).to eq(3) }
    end
  end

  describe '#critical?' do
    it { expect(subject).not_to be_critical }

    context 'critical hit' do
      let(:critical_hit_prob) { 1 }
      it { expect(subject).to be_critical }
    end
  end

  describe '#effective?' do
    it { expect(subject).not_to be_effective }

    context 'target is grass type' do
      let(:pokemon2_types) { %w[Normal Grass] }
      it { expect(subject).to be_effective }
    end
  end

  describe '#ineffective?' do
    it { expect(subject).not_to be_ineffective }

    context 'target is fire type' do
      let(:pokemon2_types) { %w[Normal Fire] }
      it { expect(subject).to be_ineffective }
    end
  end
end
