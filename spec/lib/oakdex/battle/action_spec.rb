require 'spec_helper'

describe Oakdex::Battle::Action do
  let(:pokemon1) { double(:pokemon, name: 'Pokemon1', id: 'p1', moves: [move1]) }
  let(:pokemon2) { double(:pokemon, name: 'Pokemon2', id: 'p2') }
  let(:pokemon3) do
    double(:pokemon, name: 'Pokemon3',
                     trainer: trainer2, id: 'p3')
  end
  let(:pokemon4) do
    double(:pokemon, name: 'Pokemon4',
                     trainer: trainer2, id: 'p4')
  end
  let(:side1) { double(:side, id: 'side1') }
  let(:active_in_battle_pokemon_list2) { [active_in_battle_pokemon2] }
  let(:side2) { double(:side, id: 'side2', active_in_battle_pokemon: active_in_battle_pokemon_list2) }
  let(:move1) do
    double(:move, name: 'Cool Move', priority: 0)
  end
  let(:active_in_battle_pokemon_list1) { [active_in_battle_pokemon1] }
  let(:trainer2) do
    double(:trainer,
           name: 'Trainer2')
  end
  let(:team_pokemon1) { double(:team_pokemon1, name: 'TeamPokemon1') }
  let(:trainer1) do
    double(:trainer,
           team: [team_pokemon1],
           active_in_battle_pokemon: active_in_battle_pokemon_list1,
           name: 'Trainer1')
  end
  let(:active_in_battle_pokemon1) do
    double(:active_in_battle_pokemon,
           position: 0, pokemon: pokemon1)
  end
  let(:active_in_battle_pokemon2) do
    double(:active_in_battle_pokemon,
           position: 0, pokemon: pokemon3)
  end
  let(:active_in_battle_pokemon3) do
    double(:active_in_battle_pokemon,
           position: 1, pokemon: pokemon4)
  end
  let(:targets) { [side2.id, active_in_battle_pokemon2.position] }
  let(:move_attributes) do
    {
      'action' => 'move',
      'pokemon' => pokemon1.id,
      'move' => move1.name,
      'target' => targets
    }
  end
  let(:recall_attributes) do
    {
      'action' => 'recall',
      'pokemon' => active_in_battle_pokemon1.position,
      'target' => pokemon2.id
    }
  end
  let(:item_next_actions) { [] }
  let(:use_item_on_pokemon_attributes) do
    {
      'action' => 'use_item_on_pokemon',
      'pokemon_team_pos' => 0,
      'item_id' => 'Potion',
      'item_actions' => item_next_actions
    }
  end
  let(:growth_attributes) do
    {
      'action' => 'growth_event',
      'option' => 'a'
    }
  end
  let(:battle) { double(:battle, sides: [side1, side2]) }
  let(:turn) { double(:turn, battle: battle) }
  let(:attributes) { move_attributes }
  before do
    allow(battle).to receive(:side_by_id).with(side1.id).and_return(side1)
    allow(battle).to receive(:side_by_id).with(side2.id).and_return(side2)
    allow(battle).to receive(:pokemon_by_id).with(pokemon1.id).and_return(pokemon1)
    allow(battle).to receive(:pokemon_by_id).with(pokemon2.id).and_return(pokemon2)
    allow(battle).to receive(:pokemon_by_id).with(pokemon3.id).and_return(pokemon3)
    allow(battle).to receive(:pokemon_by_id).with(pokemon4.id).and_return(pokemon4)
  end
  subject { described_class.new(trainer1, attributes) }

  describe '#priority' do
    before { subject.turn = turn }

    it 'returns moves priority' do
      expect(subject.priority).to eq(move1.priority)
    end

    context 'recall action' do
      let(:attributes) { recall_attributes }
      it 'returns 7' do
        expect(subject.priority).to eq(7)
      end
    end

    context 'use_item_on_pokemon action' do
      let(:attributes) { use_item_on_pokemon_attributes }
      it 'returns 6' do
        expect(subject.priority).to eq(6)
      end
    end
  end

  describe '#pokemon_id' do
    it { expect(subject.pokemon_id).to eq(pokemon1.id) }

    context 'recall action' do
      let(:attributes) { recall_attributes }
      it { expect(subject.pokemon_id).to be_nil }
    end
  end

  describe '#target_id' do
    it { expect(subject.target_id).to be_nil }

    context 'recall action' do
      let(:attributes) { recall_attributes }
      it { expect(subject.target_id).to eq(pokemon2.id) }
    end
  end

  describe '#pokemon' do
    before { subject.turn = turn }

    it { expect(subject.pokemon).to eq(pokemon1) }

    context 'recall action' do
      let(:attributes) { recall_attributes }
      it { expect(subject.pokemon).to eq(pokemon1) }

      context 'no in battle pokemon' do
        let(:active_in_battle_pokemon_list1) { [] }
        it { expect(subject.pokemon).to be_nil }
      end
    end

    context 'use_item_on_pokemon action' do
      let(:attributes) { use_item_on_pokemon_attributes }
      it { expect(subject.pokemon).to eq(team_pokemon1) }
    end
  end

  describe '#target' do
    before { subject.turn = turn }

    it { expect(subject.target).to eq([pokemon3]) }

    context 'no in battle pokemon' do
      let(:active_in_battle_pokemon_list2) { [] }
      it { expect(subject.target).to be_empty }
    end

    context 'recall action' do
      let(:attributes) { recall_attributes }
      it { expect(subject.target).to eq(pokemon2) }
    end
  end

  describe '#type' do
    it { expect(subject.type).to eq('move') }

    context 'recall action' do
      let(:attributes) { recall_attributes }
      it { expect(subject.type).to eq('recall') }
    end
  end

  describe '#move' do
    before { subject.turn = turn }

    it { expect(subject.move).to eq(move1) }

    context 'recall action' do
      let(:attributes) { recall_attributes }
      it { expect(subject.move).to be_nil }
    end
  end

  describe '#execute' do
    let(:move_execution) { double(:move_execution) }
    let(:move_execution2) { double(:move_execution2) }

    before do
      allow(battle).to receive(:add_to_log)
      allow(side1).to receive(:trainer_on_side?)
        .with(trainer1).and_return(true)
      allow(trainer1).to receive(:remove_from_battle)
        .with(pokemon1, side1)
      allow(trainer1).to receive(:send_to_battle)
        .with(pokemon2, side1)
      subject.turn = turn
    end

    it 'executes move execution' do
      allow(Oakdex::Battle::MoveExecution).to receive(:new)
        .with(subject, pokemon3).and_return(move_execution)
      expect(move_execution).to receive(:execute)
      subject.execute
    end

    context 'multiple targets' do
      let(:active_in_battle_pokemon_list2) { [active_in_battle_pokemon2, active_in_battle_pokemon3] }
      let(:targets) do
        [
          [side2.id, active_in_battle_pokemon2.position],
          [side2.id, active_in_battle_pokemon3.position]
        ]
      end

      it 'executes move execution' do
        allow(Oakdex::Battle::MoveExecution).to receive(:new)
          .with(subject, pokemon3).and_return(move_execution)
        allow(Oakdex::Battle::MoveExecution).to receive(:new)
          .with(subject, pokemon4).and_return(move_execution2)
        expect(move_execution).to receive(:execute)
        expect(move_execution2).to receive(:execute)
        subject.execute
      end
    end

    context 'growth action' do
      let(:attributes) { growth_attributes }
      let(:growth_event) { double(:growth_event) }
      let(:growth_event2) { double(:growth_event2, read_only?: true, message: 'yuppie') }

      before do
        allow(trainer1).to receive(:growth_event).and_return(growth_event, growth_event2)
        allow(trainer1).to receive(:growth_event?).and_return(true, false)
      end

      it 'passes option to growth event and executes it' do
        expect(growth_event).to receive(:execute).with('a')
        expect(growth_event2).to receive(:execute)
        expect(battle).to receive(:add_to_log).with('yuppie')
        subject.execute
      end
    end

    context 'use_item_on_pokemon action' do
      let(:attributes) { use_item_on_pokemon_attributes }
      let(:consumed) { true }
      let(:growth_event) do
        double(:growth_event, read_only?: true, execute: nil, message: 'foobar')
      end

      before do
        expect(team_pokemon1).to receive(:use_item)
          .with('Potion', in_battle: true)
          .and_return(consumed)
        allow(trainer1).to receive(:consume_item).with('Potion')
        allow(team_pokemon1).to receive(:growth_event?).and_return(true, false)
        allow(team_pokemon1).to receive(:growth_event).and_return(growth_event)
      end

      it 'adds log' do
        expect(battle).to receive(:add_to_log)
          .with('uses_item_on_pokemon', trainer1.name, team_pokemon1.name, 'Potion')
        expect(battle).to receive(:add_to_log)
          .with(trainer1.name, team_pokemon1.name, 'foobar')
        subject.execute
      end

      it 'executes growth event' do
        expect(growth_event).to receive(:execute)
        subject.execute
      end

      context 'when not read only' do
        before do
          allow(team_pokemon1).to receive(:growth_event?).and_return(true, true, false)
          allow(growth_event).to receive(:read_only?).and_return(false, true)
        end
        let(:item_next_actions) { ['my_action'] }

        it 'executes growth event' do
          expect(growth_event).to receive(:execute).with('my_action')
          expect(growth_event).to receive(:execute).with(no_args)
          subject.execute
        end
      end
    end

    context 'recall action' do
      let(:attributes) { recall_attributes }

      it 'adds log' do
        expect(battle).to receive(:add_to_log)
          .with('recalls', trainer1.name, pokemon1.name, pokemon2.name)
        subject.execute
      end

      it 'switches pokemon' do
        expect(trainer1).to receive(:remove_from_battle)
          .with(pokemon1, side1)
        expect(trainer1).to receive(:send_to_battle)
          .with(pokemon2, side1)
        subject.execute
      end

      context 'no pokemon in battle' do
        let(:active_in_battle_pokemon_list1) { [] }

        it 'adds log' do
          expect(battle).to receive(:add_to_log)
            .with('recalls_for_fainted', trainer1.name, pokemon2.name)
          subject.execute
        end

        it 'recalls pokemon' do
          expect(trainer1).not_to receive(:remove_from_battle)
            .with(pokemon1, side1)
          expect(trainer1).to receive(:send_to_battle)
            .with(pokemon2, side1)
          subject.execute
        end
      end
    end
  end
end
