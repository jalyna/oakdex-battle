require 'spec_helper'

describe Oakdex::Battle::ValidActionService do
  let(:next_position1) { 0 }
  let(:pokemon1) { double(:pokemon) }
  let(:pokemon2) { double(:pokemon) }
  let(:valid_move) { double(:valid_move) }
  let(:action_added) { false }
  let(:actions) { [] }
  let(:in_battle_pokemon1) do
    double(:in_battle_pokemon,
           position: 0,
           valid_move_actions: [valid_move],
           pokemon: pokemon1,
           action_added?: action_added)
  end
  let(:in_battle_pokemon2) do
    double(:in_battle_pokemon)
  end
  let(:left_pokemon_in_team) { [] }
  let(:in_battle_pokemon_list) { [in_battle_pokemon1] }
  let(:in_battle_pokemon_list2) { [in_battle_pokemon2] }
  let(:trainer1) do
    double(:trainer,
           in_battle_pokemon: in_battle_pokemon_list,
           left_pokemon_in_team: left_pokemon_in_team)
  end
  let(:side1) do
    double(:side,
           next_position: next_position1,
           trainers: [trainer1],
           in_battle_pokemon: in_battle_pokemon_list)
  end
  let(:side2) { double(:side, in_battle_pokemon: in_battle_pokemon_list2) }
  let(:battle) { double(:battle, sides: [side1, side2], actions: actions) }
  subject { described_class.new(battle) }

  before do
    allow(side1).to receive(:trainer_on_side?).with(trainer1).and_return(true)
    allow(side2).to receive(:trainer_on_side?).with(trainer1).and_return(false)
  end

  describe '#valid_actions_for' do
    it 'shows move action' do
      expect(subject.valid_actions_for(trainer1)).to eq([valid_move])
    end

    context 'more than one pokemon' do
      let(:left_pokemon_in_team) { [pokemon2] }
      let(:recall_action) do
        {
          action: 'recall',
          pokemon: in_battle_pokemon1.position,
          target: pokemon2
        }
      end

      it 'shows move and recall action' do
        expect(subject.valid_actions_for(trainer1))
          .to eq([valid_move, recall_action])
      end

      context 'action added' do
        let(:action_added) { true }
        it { expect(subject.valid_actions_for(trainer1)).to eq([valid_move]) }
      end

      context 'recall action added' do
        let(:action1) { double(:action, type: 'recall', target: pokemon2) }
        let(:actions) { [action1] }
        it { expect(subject.valid_actions_for(trainer1)).to eq([valid_move]) }
      end

      context 'no in battle pokemon on other side' do
        let(:in_battle_pokemon_list2) { [] }
        it { expect(subject.valid_actions_for(trainer1)).to eq([]) }
      end

      context 'in battle pokemon fainted' do
        let(:in_battle_pokemon_list) { [] }
        let(:recall_action2) do
          {
            action: 'recall',
            pokemon: 0,
            target: pokemon2
          }
        end

        it 'recall action' do
          expect(subject.valid_actions_for(trainer1)).to eq([recall_action2])
        end
      end
    end
  end
end
