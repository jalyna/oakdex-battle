require 'spec_helper'

describe Oakdex::Battle::InBattlePokemon do
  let(:actions) { [] }
  let(:hp_zero) { false }
  let(:current_hp) { double(:current_hp, zero?: hp_zero) }
  let(:moves_with_pp) { double(:moves_with_pp) }
  let(:pokemon) do
    double(:pokemon,
           current_hp: current_hp,
           moves_with_pp: moves_with_pp)
  end
  let(:side) { double(:side, battle: battle) }
  let(:side2) { double(:side, battle: battle) }
  let(:sides) { [side, side2] }
  let(:battle) { double(:battle) }
  subject { described_class.new(pokemon, side) }

  before do
    allow(battle).to receive(:sides).and_return(sides)
    allow(battle).to receive(:actions).and_return(actions)
  end

  describe '#pokemon' do
    it { expect(subject.pokemon).to eq(pokemon) }
  end

  %i[current_hp moves_with_pp].each do |field|
    describe "##{field}" do
      it {
        expect(subject.public_send(field))
        .to eq(pokemon.public_send(field))
      }
    end
  end

  describe '#fainted?' do
    it { expect(subject).not_to be_fainted }

    context 'zero hp' do
      let(:hp_zero) { true }
      it { expect(subject).to be_fainted }
    end
  end

  describe '#action_added?' do
    let(:pokemon2) { double(:pokemon) }
    it { expect(subject).not_to be_action_added }

    context 'action exist' do
      let(:action1) { double(:action, pokemon: pokemon) }
      let(:actions) { [action1] }
      it { expect(subject).to be_action_added }

      context 'for other pokemon' do
        let(:action1) { double(:action, pokemon: pokemon2) }
        it { expect(subject).not_to be_action_added }
      end
    end
  end

  describe '#valid_move_actions' do
    let(:action_added) { false }
    let(:move1) { double(:move, name: 'Cool Move') }
    let(:moves_with_pp) { [move1] }
    let(:pokemon2) { double(:pokemon) }
    let(:in_battle_pokemon2) do
      double(:in_battle_pokemon, pokemon: pokemon2)
    end

    before do
      allow(side2).to receive(:in_battle_pokemon) do
        [in_battle_pokemon2]
      end
      allow(subject).to receive(:action_added?).and_return(action_added)
    end

    it 'returns all movies that have enough pp' do
      expect(subject.valid_move_actions).to eq([
                                                 {
                                                   action: 'move',
                                                   pokemon: pokemon,
                                                   move: move1.name,
                                                   target: pokemon2
                                                 }
                                               ])
    end

    context 'no moves' do
      let(:moves_with_pp) { [] }

      it 'returns struggle' do
        expect(subject.valid_move_actions).to eq([
                                                   {
                                                     action: 'move',
                                                     pokemon: pokemon,
                                                     move: 'Struggle',
                                                     target: pokemon2
                                                   }
                                                 ])
      end
    end

    context 'existing move for this pokemon' do
      let(:action_added) { true }
      it { expect(subject.valid_move_actions).to be_empty }
    end
  end
end
