require 'spec_helper'

describe Oakdex::Battle::Pokemon do
  let(:species) { Oakdex::Pokedex::Pokemon.find('Pikachu') }
  let(:iv) do
    {
      hp: 10,
      atk: 10,
      def: 10,
      sp_atk: 10,
      sp_def: 10,
      speed: 10
    }
  end
  let(:ev) do
    {
      hp: 10,
      atk: 10,
      def: 10,
      sp_atk: 10,
      sp_def: 10,
      speed: 10
    }
  end
  let(:move) do
    Oakdex::Battle::Move.new(
      Oakdex::Pokedex::Move.find('Thunder Shock'), 30, 40
    )
  end
  let(:additional_attributes) { {} }
  let(:attributes) do
    {
      exp: 100,
      gender: 'female',
      ability: Oakdex::Pokedex::Ability.find('Static'),
      nature: Oakdex::Pokedex::Nature.find('Bashful'),
      hp: 12,
      iv: iv,
      ev: ev,
      moves: [move]
    }.merge(additional_attributes)
  end
  subject { described_class.new(species, attributes) }

  describe '.create' do
    let(:species_name) { 'Bulbasaur' }
    let(:options) { { level: 10 } }
    let(:pokemon) { double(:pokemon) }
    let(:species) { double(:species) }

    before do
      allow(Oakdex::Pokedex::Pokemon).to receive(:find!)
        .with(species_name).and_return(species)
      allow(Oakdex::Battle::PokemonFactory).to receive(:create)
        .with(species, options).and_return(pokemon)
    end

    it 'creates pokemon with auto-generated attributes' do
      expect(described_class.create(species_name, options)).to eq(pokemon)
    end
  end

  describe '#name' do
    it { expect(subject.name).to eq('Pikachu') }
  end

  describe '#species' do
    it { expect(subject.species).to eq(species) }
  end

  describe '#moves' do
    it { expect(subject.moves).to eq([move]) }
  end

  describe '#gender' do
    it { expect(subject.gender).to eq('female') }
  end

  describe '#current_hp' do
    it { expect(subject.current_hp).to eq(12) }
  end

  describe '#level' do
    it { expect(subject.level).to eq(4) }
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

  describe '#accuracy' do
    it { expect(subject.accuracy).to eq(1) }
  end

  describe '#evasion' do
    it { expect(subject.evasion).to eq(1) }
  end

  describe '#critical_hit_prob' do
    it { expect(subject.critical_hit_prob).to eq(Rational(1, 24)) }
  end

  describe '#moves_with_pp' do
    it { expect(subject.moves_with_pp).to eq([move]) }

    context 'no pp' do
      let(:move) do
        Oakdex::Battle::Move.new(
          Oakdex::Pokedex::Move.find('Thunder Shock'), 0, 40
        )
      end

      it { expect(subject.moves_with_pp).to eq([]) }
    end
  end

  describe '#change_hp_by' do
    let(:change_by) { -2 }
    before { subject.change_hp_by(change_by) }

    it { expect(subject.current_hp).to eq(10) }

    context 'hp under 0' do
      let(:change_by) { -30 }
      it { expect(subject.current_hp).to eq(0) }
    end

    context 'positive' do
      let(:change_by) { 2 }
      it { expect(subject.current_hp).to eq(14) }
    end

    context 'more than max' do
      let(:change_by) { 200 }
      it { expect(subject.current_hp).to eq(17) }
    end
  end

  describe '#reset_stats' do
    let(:initial_stat) { 100 }
    before do
      subject.change_stat_by(:atk, 2)
      subject.change_stat_by(:def, -3)
      subject.change_stat_by(:evasion, 3)
      allow(Oakdex::Battle::PokemonStat).to receive(:initial_stat)
        .with(:atk, anything).and_return(initial_stat)
      allow(Oakdex::Battle::PokemonStat).to receive(:initial_stat)
        .with(:def, anything).and_return(initial_stat)
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
      allow(Oakdex::Battle::PokemonStat).to receive(:initial_stat)
        .with(stat, anything).and_return(initial_stat)
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
        Oakdex::Battle::PokemonStat::STAGE_MULTIPLIERS[-2]).to_i)
      }

      context 'accuracy' do
        let(:stat) { :accuracy }

        it {
          expect(subject.accuracy)
            .to eq(Oakdex::Battle::PokemonStat::STAGE_MULTIPLIERS_ACC_EVA[-2])
        }
      end

      context 'evasion' do
        let(:stat) { :evasion }

        it {
          expect(subject.evasion)
            .to eq(Oakdex::Battle::PokemonStat::STAGE_MULTIPLIERS_ACC_EVA[-2])
        }
      end

      context 'critical_hit' do
        let(:stat) { :critical_hit }
        let(:change_by) { 1 }

        it {
          expect(subject.critical_hit_prob)
            .to eq(Oakdex::Battle::PokemonStat::
              STAGE_MULTIPLIERS_CRITICAL_HIT[1])
        }
      end
    end
  end

  describe '#add_status_condition' do
    let(:condition) { 'poison' }
    let(:condition_class) { ::Oakdex::Battle::StatusConditions::Poison }
    let(:status_condition) { double(:status_condition) }

    before do
      allow(condition_class).to receive(:new)
        .with(subject).and_return(status_condition)
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
      subject.add_status_condition(condition)
    end

    it 'removes condition' do
      expect(subject.status_conditions).to eq([status_condition])
      subject.remove_status_condition(status_condition)
      expect(subject.status_conditions).to be_empty
    end
  end

  describe '#change_pp_by' do
    let(:change_by) { -1 }
    let(:move_name) { 'Thunder Shock' }
    before { subject.change_pp_by(move_name, change_by) }

    it { expect(move.pp).to eq(29) }

    context 'pp under 0' do
      let(:change_by) { -40 }
      it { expect(move.pp).to eq(0) }
    end

    context 'positive' do
      let(:change_by) { 1 }
      it { expect(move.pp).to eq(31) }
    end

    context 'more than max' do
      let(:change_by) { 200 }
      it { expect(move.pp).to eq(40) }
    end

    context 'unknown move' do
      let(:move_name) { 'Struggle' }
      it { expect(move.pp).to eq(30) }
    end
  end

  %i[types].each do |field|
    describe "##{field}" do
      it {
        expect(subject.public_send(field))
        .to eq(species.public_send(field))
      }
    end
  end

  describe '#wild?' do
    it { expect(subject).not_to be_wild }

    context 'wild' do
      let(:additional_attributes) { { wild: true } }
      it { expect(subject).to be_wild }
    end
  end

  describe '#original_trainer' do
    it { expect(subject.original_trainer).to be_nil }

    context 'original trainer given' do
      let(:additional_attributes) { { original_trainer: 'Name of Trainer' } }
      it { expect(subject.original_trainer).to eq('Name of Trainer') }
    end
  end

  describe '#traded?' do
    it { expect(subject).not_to be_traded }

    context 'trainer given' do
      let!(:trainer) { Oakdex::Battle::Trainer.new('Awesome Trainer', [subject]) }
      it { expect(subject).not_to be_traded }

      context 'original trainer given' do
        let(:additional_attributes) { { original_trainer: 'Name of Trainer' } }
        it { expect(subject).to be_traded }

        context 'ot is same as trainer' do
          let(:additional_attributes) { { original_trainer: 'Awesome Trainer' } }
          it { expect(subject).not_to be_traded }
        end
      end
    end
  end

  describe '#item_id' do
    it { expect(subject.item_id).to be_nil }

    context 'item given' do
      let(:additional_attributes) { { item_id: 'Name of Item' } }
      it { expect(subject.item_id).to eq('Name of Item') }
    end
  end

  describe '#amie' do
    it { expect(subject.amie).to eq({
      affection: 0,
      fullness: 0,
      enjoyment: 0
    }) }

    context 'amie given' do
      let(:additional_attributes) { { amie: {
        affection: 1,
        fullness: 2,
        enjoyment: 3
      } } }
      it { expect(subject.amie).to eq({
        affection: 1,
        fullness: 2,
        enjoyment: 3
      }) }
    end
  end

  describe '#amie_level' do
    it { expect(subject.amie_level(:affection)).to eq(0) }

    context 'amie given' do
      let(:additional_attributes) { { amie: {
        affection: 201
      } } }
      it { expect(subject.amie_level(:affection)).to eq(4) }
    end
  end
end
