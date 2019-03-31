require 'spec_helper'

describe Oakdex::Battle::InBattlePokemon do
  let(:primary_status_condition) { nil }
  let(:pokemon) do
    double(:pokemon,
           hp: 17,
           atk: 9,
           def: 7,
           sp_atk: 9,
           sp_def: 8,
           speed: 12,
           primary_status_condition: primary_status_condition,
           enable_battle_mode: nil,
           to_h: { some: { hash: 'values' } }
          )
  end

  subject { described_class.new(pokemon) }

  it 'enables pokemon battle mode' do
    expect(pokemon).to receive(:enable_battle_mode)
    subject
  end

  %w[
    types
    trainer
    trainer=
    name
    moves
    moves_with_pp
    change_hp_by
    change_pp_by
    level
    fainted?
    grow_from_battle
  ].each do |method|
    describe "##{method}" do
      it 'is forwarded from pokemon' do
        value = double(:value)
        expect(pokemon).to receive(:"#{method}").and_return(value)
        expect(subject.public_send(method)).to eq(value)
      end
    end
  end

  describe '#to_h' do
    it { expect(subject.to_h).to eq({ id: subject.id, pokemon: pokemon.to_h }) }
  end

  describe '#accuracy' do
    it { expect(subject.accuracy).to eq(1) }
  end

  describe '#evasion' do
    it { expect(subject.evasion).to eq(1) }
  end

  describe '#critical_hit_prob' do
    it { expect(subject.critical_hit_prob).to eq(Rational(1, 24)) }
  end

  describe '#id' do
    before do
      allow(SecureRandom).to receive(:uuid).and_return('random_id')
    end

    it { expect(subject.id).to eq('random_id') }
  end

  describe '#hp' do
    it { expect(subject.hp).to eq(17) }
  end

  describe '#atk' do
    it { expect(subject.atk).to eq(9) }
  end

  describe '#def' do
    it { expect(subject.def).to eq(7) }
  end

  describe '#sp_atk' do
    it { expect(subject.sp_atk).to eq(9) }
  end

  describe '#sp_def' do
    it { expect(subject.sp_def).to eq(8) }
  end

  describe '#speed' do
    it { expect(subject.speed).to eq(12) }

    context 'status condition given' do
      let(:condition) { double(:condition) }
      before do
        allow(subject).to receive(:status_conditions)
          .and_return([condition])
        allow(condition).to receive(:stat_modifier).with(:speed)
          .and_return(1.5)
      end

      it { expect(subject.speed).to eq(12 * 1.5) }
    end
  end

  describe '#reset_stats' do
    let(:initial_stat) { 100 }
    before do
      subject.change_stat_by(:atk, 2)
      subject.change_stat_by(:def, -3)
      subject.change_stat_by(:evasion, 3)
      allow(pokemon).to receive(:atk).and_return(initial_stat)
      allow(pokemon).to receive(:def).and_return(initial_stat)
    end

    it 'resets stats' do
      subject.reset_stats
      expect(subject.atk).to eq(initial_stat)
      expect(subject.atk).to eq(initial_stat)
      expect(subject.evasion).to eq(Rational(1, 1))
    end
  end

  describe '#change_stat_by' do
    let(:change_by) { -2 }
    let(:stat) { :atk }
    let(:initial_stat) { 100 }
    before do
      allow(pokemon).to receive(stat).and_return(initial_stat)
    end

    it 'returns true when value was changed' do
      expect(subject.change_stat_by(stat, change_by)).to be(true)
    end

    context 'stat is at minimum' do
      let(:change_by) { -6 }
      before { subject.change_stat_by(stat, change_by) }
      it 'returns false when value was changed' do
        expect(subject.change_stat_by(stat, change_by)).to be(false)
      end
    end

    context 'stat changed' do
      before { subject.change_stat_by(stat, change_by) }
      it {
        expect(subject.atk).to eq((initial_stat *
        Oakdex::Battle::InBattlePokemon::STAGE_MULTIPLIERS[-2]).to_i)
      }

      context 'accuracy' do
        let(:stat) { :accuracy }

        it {
          expect(subject.accuracy)
            .to eq(Oakdex::Battle::InBattlePokemon::STAGE_MULTIPLIERS_ACC_EVA[-2])
        }
      end

      context 'evasion' do
        let(:stat) { :evasion }

        it {
          expect(subject.evasion)
            .to eq(Oakdex::Battle::InBattlePokemon::STAGE_MULTIPLIERS_ACC_EVA[-2])
        }
      end

      context 'critical_hit' do
        let(:stat) { :critical_hit }
        let(:change_by) { 1 }

        it {
          expect(subject.critical_hit_prob)
            .to eq(Oakdex::Battle::InBattlePokemon::
              STAGE_MULTIPLIERS_CRITICAL_HIT[1])
        }
      end
    end
  end

  context 'pokemon has primary status condition' do
    let(:primary_status_condition) { 'poison' }
    let(:condition_class) { ::Oakdex::Battle::StatusConditions::Poison }
    let(:status_condition) { double(:status_condition) }

    before do
      allow(condition_class).to receive(:new).and_return(status_condition)
      expect(pokemon).to receive(:primary_status_condition=).with('poison')
    end

    it { expect(subject.status_conditions).to eq([status_condition]) }
  end

  describe '#add_status_condition' do
    let(:condition) { 'poison' }
    let(:condition_class) { ::Oakdex::Battle::StatusConditions::Poison }
    let(:status_condition) { double(:status_condition) }

    before do
      allow(condition_class).to receive(:new)
        .with(subject).and_return(status_condition)
      expect(pokemon).to receive(:primary_status_condition=).with(condition)
      subject.add_status_condition(condition)
    end

    it { expect(subject.status_conditions).to eq([status_condition]) }

    context 'burn' do
      let(:condition) { 'burn' }
      let(:condition_class) { ::Oakdex::Battle::StatusConditions::Burn }
      it { expect(subject.status_conditions).to eq([status_condition]) }
    end

    context 'freeze' do
      let(:condition) { 'freeze' }
      let(:condition_class) { ::Oakdex::Battle::StatusConditions::Freeze }
      it { expect(subject.status_conditions).to eq([status_condition]) }
    end

    context 'paralysis' do
      let(:condition) { 'paralysis' }
      let(:condition_class) { ::Oakdex::Battle::StatusConditions::Paralysis }
      it { expect(subject.status_conditions).to eq([status_condition]) }
    end

    context 'badly_poisoned' do
      let(:condition) { 'badly_poisoned' }
      let(:condition_class) do
        ::Oakdex::Battle::StatusConditions::BadlyPoisoned
      end
      it { expect(subject.status_conditions).to eq([status_condition]) }
    end

    context 'sleep' do
      let(:condition) { 'sleep' }
      let(:condition_class) { ::Oakdex::Battle::StatusConditions::Sleep }
      it { expect(subject.status_conditions).to eq([status_condition]) }
    end
  end

  describe '#remove_status_condition' do
    let(:condition) { 'poison' }
    let(:condition_class) { ::Oakdex::Battle::StatusConditions::Poison }
    let(:status_condition) { double(:status_condition) }

    before do
      allow(condition_class).to receive(:new)
        .with(subject).and_return(status_condition)
      allow(pokemon).to receive(:primary_status_condition=).with(condition)
      subject.add_status_condition(condition)
    end

    it 'removes condition' do
      expect(subject.status_conditions).to eq([status_condition])
      expect(pokemon).to receive(:primary_status_condition=).with(nil)
      subject.remove_status_condition(status_condition)
      expect(subject.status_conditions).to be_empty
    end
  end
end
