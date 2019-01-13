require 'spec_helper'

describe Oakdex::Battle::Breeding do
  let(:pokemon1) { Oakdex::Battle::Pokemon.create('Ditto', level: 10) }
  let(:pokemon2) { Oakdex::Battle::Pokemon.create('Pikachu', level: 20, gender: 'male') }

  describe '.compatible?' do
    it { expect(described_class).to be_compatible(pokemon1, pokemon2) }

    context 'both dittos' do
      let(:pokemon2) { Oakdex::Battle::Pokemon.create('Ditto', level: 20) }
      it { expect(described_class).not_to be_compatible(pokemon1, pokemon2) }
    end

    context 'neutral' do
      let(:pokemon2) { Oakdex::Battle::Pokemon.create('Rotom', level: 20) }
      it { expect(described_class).to be_compatible(pokemon1, pokemon2) }

      context 'both neutral and same species but not ditto' do
        let(:pokemon1) { Oakdex::Battle::Pokemon.create('Rotom', level: 10) }
        it { expect(described_class).not_to be_compatible(pokemon1, pokemon2) }
      end

      context 'one neutral and same egg group but not ditto' do
        let(:pokemon1) { Oakdex::Battle::Pokemon.create('Chandelure', level: 10, gender: 'female') }
        it { expect(described_class).not_to be_compatible(pokemon1, pokemon2) }
      end
    end

    context 'same egg group' do
      let(:pokemon1) { Oakdex::Battle::Pokemon.create('Pachirisu', level: 10, gender: 'female') }
      it { expect(described_class).to be_compatible(pokemon1, pokemon2) }

      context 'both female' do
        let(:pokemon1) { Oakdex::Battle::Pokemon.create('Pachirisu', level: 10, gender: 'female') }
        let(:pokemon2) { Oakdex::Battle::Pokemon.create('Pikachu', level: 20, gender: 'female') }
        it { expect(described_class).not_to be_compatible(pokemon1, pokemon2) }
      end

      context 'both male' do
        let(:pokemon1) { Oakdex::Battle::Pokemon.create('Pachirisu', level: 10, gender: 'male') }
        let(:pokemon2) { Oakdex::Battle::Pokemon.create('Pikachu', level: 20, gender: 'male') }
        it { expect(described_class).not_to be_compatible(pokemon1, pokemon2) }
      end
    end

    context 'different egg group' do
      let(:pokemon1) { Oakdex::Battle::Pokemon.create('Bulbasaur', level: 10, gender: 'female') }
      it { expect(described_class).not_to be_compatible(pokemon1, pokemon2) }
    end

    context 'same egg group but undiscovered' do
      let(:pokemon1) { Oakdex::Battle::Pokemon.create('Pichu', level: 10, gender: 'female') }
      let(:pokemon2) { Oakdex::Battle::Pokemon.create('Pichu', level: 10, gender: 'male') }
      it { expect(described_class).not_to be_compatible(pokemon1, pokemon2) }
    end

    context 'both Pikachus' do
      let(:pokemon1) { Oakdex::Battle::Pokemon.create('Pikachu', level: 20, gender: 'female') }
      let(:pokemon2) { Oakdex::Battle::Pokemon.create('Pikachu', level: 20, gender: 'male') }
      it { expect(described_class).to be_compatible(pokemon1, pokemon2) }

      context 'both female' do
        let(:pokemon1) { Oakdex::Battle::Pokemon.create('Pikachu', level: 20, gender: 'female') }
        let(:pokemon2) { Oakdex::Battle::Pokemon.create('Pikachu', level: 20, gender: 'female') }
        it { expect(described_class).not_to be_compatible(pokemon1, pokemon2) }
      end

      context 'both male' do
        let(:pokemon1) { Oakdex::Battle::Pokemon.create('Pikachu', level: 20, gender: 'male') }
        let(:pokemon2) { Oakdex::Battle::Pokemon.create('Pikachu', level: 20, gender: 'male') }
        it { expect(described_class).not_to be_compatible(pokemon1, pokemon2) }
      end
    end
  end

  describe '.chance_in_percentage' do
    it { expect(described_class.chance_in_percentage(pokemon1, pokemon2)).to eq(20) }

    context 'not compatible' do
      let(:pokemon1) { Oakdex::Battle::Pokemon.create('Bulbasaur', level: 10, gender: 'female') }
      it { expect(described_class.chance_in_percentage(pokemon1, pokemon2)).to eq(0) }
    end

    context 'same species' do
      let(:pokemon1) { Oakdex::Battle::Pokemon.create('Pikachu', level: 20, gender: 'female') }
      let(:pokemon2) { Oakdex::Battle::Pokemon.create('Pikachu', level: 20, gender: 'male') }
      it { expect(described_class.chance_in_percentage(pokemon1, pokemon2)).to eq(50) }
    end
  end

  describe '.breed' do
    let(:child) { described_class.breed(pokemon1, pokemon2) }

    it { expect(child.level).to eq(1) }
    it('has species from non ditto') { expect(child.name).to eq('Pichu') }
    it { expect(child.moves.map(&:name)).to match_array(['Thunder Shock', 'Charm']) }

    context 'same egg group' do
      let(:pokemon1) { Oakdex::Battle::Pokemon.create('Pachirisu', level: 10, gender: 'female') }
      it('has species from female') { expect(child.name).to eq('Pachirisu') }
    end

    context 'parent with egg moves' do
      let(:parent_moves) do
        [
          ['Reversal', 10, 10],
          ['Wish', 10, 10]
        ]
      end
      let(:pokemon1) { Oakdex::Battle::Pokemon.create('Ditto', level: 10) }
      let(:pokemon2) { Oakdex::Battle::Pokemon.create('Pikachu', level: 20, gender: 'male', moves: parent_moves) }

      it {
        expect(child.moves.map(&:name)).to match_array([
                                                         'Thunder Shock',
                                                         'Charm',
                                                         'Reversal',
                                                         'Wish'
                                                       ])
      }
    end
  end
end
