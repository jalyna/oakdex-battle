require 'spec_helper'

describe Oakdex::Battle::ValidActionService do
  let(:pokemon1) { double(:pokemon) }
  let(:pokemon2) { double(:pokemon) }
  let(:valid_move) { double(:valid_move) }
  let(:action_added) { false }
  let(:actions) { [] }
  let(:in_battle_pokemon1) do
    double(:in_battle_pokemon,
           valid_move_actions: [valid_move],
           pokemon: pokemon1,
           action_added?: action_added)
  end
  let(:left_pokemon_in_team) { [] }
  let(:in_battle_pokemon_list) { [in_battle_pokemon1] }
  let(:trainer1) do
    double(:trainer,
           in_battle_pokemon: in_battle_pokemon_list,
           left_pokemon_in_team: left_pokemon_in_team)
  end
  let(:side1) { double(:side, trainers: [trainer1]) }
  let(:side2) { double(:side) }
  let(:battle) { double(:battle, sides: [side1, side2], actions: actions) }
  subject { described_class.new(battle) }

  describe '#valid_actions_for' do
    it 'shows move action' do
      expect(subject.valid_actions_for(trainer1)).to eq([valid_move])
    end

    context 'more than one pokemon' do
      let(:left_pokemon_in_team) { [pokemon2] }
      let(:recall_action) do
        {
          action: 'recall',
          pokemon: pokemon1,
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

      context 'in battle pokemon fainted' do
        let(:in_battle_pokemon_list) { [] }
        let(:recall_action2) do
          {
            action: 'recall',
            pokemon: nil,
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
