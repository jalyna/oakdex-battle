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
  let(:side) { double(:side1, battle: battle) }
  let(:side2) { double(:side2, battle: battle) }
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

  describe '#position' do
    it { expect(subject.position).to eq(0) }
    context 'position given' do
      subject { described_class.new(pokemon, side, 1) }
      it { expect(subject.position).to eq(1) }
    end
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
    let(:target) { 'target_adjacent_single' }
    let(:move1) { double(:move, name: 'Cool Move', target: target) }
    let(:moves_with_pp) { [move1] }
    let(:pokemon2) { double(:pokemon) }
    let(:in_battle_pokemon2) do
      double(:in_battle_pokemon, pokemon: pokemon2, side: side2,
                                 position: 0)
    end
    let(:in_battle_pokemon3) do
      double(:in_battle_pokemon, side: side2, position: 1)
    end
    let(:in_battle_pokemon4) do
      double(:in_battle_pokemon, side: side2, position: 2)
    end
    let(:in_battle_pokemon5) do
      double(:in_battle_pokemon, side: side, position: 0)
    end
    let(:in_battle_pokemon6) do
      double(:in_battle_pokemon, side: side, position: 1)
    end
    let(:in_battle_pokemon7) do
      double(:in_battle_pokemon, side: side, position: 2)
    end

    before do
      allow(side2).to receive(:in_battle_pokemon) do
        [in_battle_pokemon2]
      end
      allow(side).to receive(:in_battle_pokemon) do
        [subject]
      end
      allow(subject).to receive(:action_added?).and_return(action_added)
    end

    it 'returns all moves that have enough pp' do
      expect(subject.valid_move_actions).to eq([
                                                 {
                                                   action: 'move',
                                                   pokemon: pokemon,
                                                   move: move1,
                                                   target: [side2, 0]
                                                 }
                                               ])
    end

    context '3 vs. 3' do
      before do
        allow(side2).to receive(:in_battle_pokemon) do
          [in_battle_pokemon2, in_battle_pokemon3, in_battle_pokemon4]
        end
        allow(side).to receive(:in_battle_pokemon) do
          [subject, in_battle_pokemon6, in_battle_pokemon7]
        end
      end

      it 'returns targets' do
        expect(subject.valid_move_actions.map { |m| m[:target] })
          .to eq([[side2, 0], [side2, 1], [side, 1]])
      end

      context 'target_adjacent_user_single' do
        let(:target) { 'target_adjacent_user_single' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[side, 1]])
        end
      end

      context 'target_user_or_adjacent_user' do
        let(:target) { 'target_user_or_adjacent_user' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[side, 0], [side, 1]])
        end
      end

      context 'user' do
        let(:target) { 'user' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[side, 0]])
        end
      end
    end

    context 'no moves' do
      let(:moves_with_pp) { [] }
      let(:struggle_move) do
        double(:struggle_move,
               target: 'target_adjacent_single')
      end
      before do
        allow(Oakdex::Battle::Move).to receive(:new)
          .and_return(struggle_move)
      end

      it 'returns struggle' do
        expect(subject.valid_move_actions).to eq([
                                                   {
                                                     action: 'move',
                                                     pokemon: pokemon,
                                                     move: struggle_move,
                                                     target: [side2, 0]
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
