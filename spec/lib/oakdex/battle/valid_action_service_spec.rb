require 'spec_helper'

describe Oakdex::Battle::ValidActionService do
  let(:next_position1) { 0 }
  let(:pokemon1) { double(:pokemon) }
  let(:pokemon2) { double(:pokemon) }
  let(:valid_move) { double(:valid_move) }
  let(:action_added) { false }
  let(:actions) { [] }
  let(:active_in_battle_pokemon1) do
    double(:active_in_battle_pokemon,
           position: 0,
           valid_move_actions: [valid_move],
           pokemon: pokemon1,
           action_added?: action_added)
  end
  let(:active_in_battle_pokemon2) do
    double(:active_in_battle_pokemon)
  end
  let(:left_pokemon_in_team) { [] }
  let(:active_in_battle_pokemon_list) { [active_in_battle_pokemon1] }
  let(:active_in_battle_pokemon_list2) { [active_in_battle_pokemon2] }
  let(:team_pokemon1_pokemon) { double(:team_pokemon1_pokemon) }
  let(:team_pokemon1) { double(:team_pokemon1, pokemon: team_pokemon1_pokemon) }
  let(:team_pokemon2) { double(:team_pokemon2) }
  let(:items) { [] }
  let(:trainer1) do
    double(:trainer,
           active_in_battle_pokemon: active_in_battle_pokemon_list,
           left_pokemon_in_team: left_pokemon_in_team,
           team: [team_pokemon1, team_pokemon2],
           items: items)
  end
  let(:side1) do
    double(:side,
           next_position: next_position1,
           trainers: [trainer1],
           active_in_battle_pokemon: active_in_battle_pokemon_list)
  end
  let(:side2) { double(:side, active_in_battle_pokemon: active_in_battle_pokemon_list2) }
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
          pokemon: active_in_battle_pokemon1.position,
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
        let(:action1) { double(:action, type: 'recall', target: pokemon2, trainer: trainer1) }
        let(:actions) { [action1] }
        it { expect(subject.valid_actions_for(trainer1)).to eq([valid_move]) }
      end

      context 'no in battle pokemon on other side' do
        let(:active_in_battle_pokemon_list2) { [] }
        it { expect(subject.valid_actions_for(trainer1)).to eq([]) }
      end

      context 'in battle pokemon fainted' do
        let(:active_in_battle_pokemon_list) { [] }
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

      context 'items available' do
        let(:items) { ['Potion'] }
        let(:growth_event) { double(:growth_event, read_only?: true, execute: nil) }

        before do
          allow(team_pokemon1).to receive(:usable_item?)
            .with('Potion', in_battle: true)
            .and_return(true)
          allow(team_pokemon2).to receive(:usable_item?)
            .with('Potion', in_battle: true)
            .and_return(false)
          allow(team_pokemon1_pokemon).to receive(:dup)
            .and_return(team_pokemon1_pokemon)
          allow(team_pokemon1_pokemon).to receive(:use_item)
            .with('Potion', in_battle: true)
            .and_return(true)
          allow(team_pokemon1_pokemon).to receive(:growth_event)
            .and_return(growth_event)
        end

        it 'shows item action' do
          valid_actions = subject.valid_actions_for(trainer1)
          expect(valid_actions.size).to eq(3)
          expect(valid_actions[-1])
            .to eq({
              action: 'use_item_on_pokemon',
              pokemon_team_pos: 0,
              item_id: 'Potion',
              item_actions: []
            })
        end

        context 'item actions present' do
          before do
            allow(growth_event).to receive(:possible_actions)
              .and_return(['a', 'b'])
            allow(growth_event).to receive(:read_only?)
              .and_return(false, false, false, true, false, true)
          end

          it 'shows multiple item actions' do
            valid_actions = subject.valid_actions_for(trainer1)
            expect(valid_actions.size).to eq(4)
            expect(valid_actions[-2..-1])
              .to eq([{
                action: 'use_item_on_pokemon',
                pokemon_team_pos: 0,
                item_id: 'Potion',
                item_actions: ['a']
              },
              {
                action: 'use_item_on_pokemon',
                pokemon_team_pos: 0,
                item_id: 'Potion',
                item_actions: ['b']
              }])
          end
        end
      end
    end
  end
end
