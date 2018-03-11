require 'spec_helper'

describe Oakdex::Battle::Pokemon do
  describe '.create' do
    let(:species_name) { 'Bulbasaur' }
    let(:options) { { level: 10 } }
    let(:exp) { 50 }
    let(:hp) { double(:hp) }
    let(:pokemon) { double(:pokemon) }
    let(:ability) { double(:ability) }
    let(:nature) { double(:nature) }
    let(:gender) { 'female' }
    let(:ability_name) { 'Soundproof' }
    let(:move_type) { double(:move_type, pp: 44) }
    let(:move) { double(:move) }
    let(:species) do
      double(:species,
             leveling_rate: 'leveling_rate',
             gender_ratios: {
               'male' => 25.5,
               'female' => 74.5
             },
             abilities: [
               {
                 'name' => ability_name
               },
               {
                 'name' => 'Bla',
                 'hidden' => true
               },
               {
                 'name' => 'Blub',
                 'mega' => true
               }
             ],
             base_stats: {
               'hp' => 123
             },
             learnset: [
               {
                 'move' => 'Move1',
                 'level' => 3
               },
               {
                 'move' => 'Move2',
                 'level' => 50
               },
               {
                 'move' => 'Move3'
               }
             ]
            )
    end
    let(:ev) do
      {
        hp: 0,
        atk: 0,
        def: 0,
        sp_atk: 0,
        sp_def: 0,
        speed: 0
      }
    end
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
    let(:attributes) do
      {
        exp: exp,
        gender: gender,
        ability: ability,
        nature: nature,
        hp: hp,
        iv: iv,
        ev: ev,
        moves: [move]
      }
    end

    before do
      allow(Oakdex::Pokedex::Pokemon).to receive(:find)
        .with(species_name).and_return(species)
      allow(Oakdex::Pokedex::Ability).to receive(:find)
        .with(ability_name).and_return(ability)
      allow(Oakdex::Pokedex::Move).to receive(:find)
        .with('Move1').and_return(move_type)
      allow(Oakdex::Battle::Move).to receive(:new)
        .with(move_type, move_type.pp, move_type.pp).and_return(move)
      allow(Oakdex::Battle::PokemonStat).to receive(:exp_by_level)
        .with(species.leveling_rate, options[:level]).and_return(exp)
      allow(Oakdex::Pokedex::Nature).to receive(:all)
        .and_return('Nature' => nature)
      allow_any_instance_of(Oakdex::Battle::PokemonFactory)
        .to receive(:rand).with(1..1000).and_return(500)
      allow_any_instance_of(Oakdex::Battle::PokemonFactory)
        .to receive(:rand).with(0..31).and_return(10)
      allow(Oakdex::Battle::PokemonStat).to receive(:level_by_exp)
        .with(species.leveling_rate, exp).and_return(options[:level])
      allow(Oakdex::Battle::PokemonStat).to receive(:initial_stat)
        .with(:hp,
              level: options[:level],
              iv: iv,
              ev: ev,
              base_stats: species.base_stats,
              nature: nature
             )
        .and_return(hp)
    end

    it 'creates pokemon with auto-generated attributes' do
      expect(described_class).to receive(:new).with(
        species,
        attributes
      ).and_return(pokemon)
      expect(described_class.create(species_name, options)).to eq(pokemon)
    end

    context 'data given' do
      let(:iv) do
        {
          hp: 10,
          atk: 10,
          def: 10,
          sp_atk: 12,
          sp_def: 30,
          speed: 10
        }
      end
      let(:ev) do
        {
          hp: 33,
          atk: 34,
          def: 0,
          sp_atk: 120,
          sp_def: 0,
          speed: 0
        }
      end
      let(:gender) { 'male' }
      let(:hp) { 17 }

      let(:options) do
        {
          exp: exp,
          gender: 'male',
          ability: 'Something',
          nature: 'MyNature',
          hp: hp,
          iv: iv,
          ev: ev,
          moves: [
            ['MyMove', 20, 30]
          ]
        }
      end

      before do
        allow(Oakdex::Pokedex::Move).to receive(:find)
          .with('MyMove').and_return(move_type)
        allow(Oakdex::Battle::Move).to receive(:new)
          .with(move_type, 20, 30).and_return(move)
      end

      it 'creates pokemon by given attributes' do
        expect(described_class).to receive(:new).with(
          species,
          attributes
        ).and_return(pokemon)
        expect(described_class.create(species_name, options)).to eq(pokemon)
      end
    end
  end
end
