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
      Oakdex::Pokedex::Move.find('Thunder Shock'), 30, 30
    )
  end
  let(:attributes) do
    {
      exp: 100,
      gender: 'female',
      ability: Oakdex::Pokedex::Ability.find('Static'),
      nature: Oakdex::Pokedex::Nature.find('Bashful'),
      hp: 20,
      iv: iv,
      ev: ev,
      moves: [move]
    }
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

  describe '#moves' do
    it { expect(subject.moves).to eq([move]) }
  end

  describe '#current_hp' do
    it { expect(subject.current_hp).to eq(20) }
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
  end

  describe '#accuracy' do
    it { expect(subject.accuracy).to eq(1) }
  end

  describe '#evasion' do
    it { expect(subject.evasion).to eq(1) }
  end

  describe '#critical_hit_prob' do
    it { expect(subject.critical_hit_prob).to eq(Rational(1, 16)) }
  end

  %i[types].each do |field|
    describe "##{field}" do
      it {
        expect(subject.public_send(field))
        .to eq(species.public_send(field))
      }
    end
  end
end