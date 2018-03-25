require 'spec_helper'

describe Oakdex::Battle::Action do
  let(:pokemon1) { double(:pokemon, name: 'Pokemon1') }
  let(:pokemon2) { double(:pokemon, name: 'Pokemon2') }
  let(:pokemon3) do
    double(:pokemon, name: 'Pokemon3',
                     trainer: trainer2)
  end
  let(:pokemon4) do
    double(:pokemon, name: 'Pokemon4',
                     trainer: trainer2)
  end
  let(:side1) { double(:side) }
  let(:in_battle_pokemon_list2) { [in_battle_pokemon2] }
  let(:side2) { double(:side, in_battle_pokemon: in_battle_pokemon_list2) }
  let(:move1) do
    double(:move, name: 'Cool Move', priority: 0)
  end
  let(:in_battle_pokemon_list1) { [in_battle_pokemon1] }
  let(:trainer2) do
    double(:trainer,
           name: 'Trainer2')
  end
  let(:trainer1) do
    double(:trainer,
           in_battle_pokemon: in_battle_pokemon_list1,
           name: 'Trainer1')
  end
  let(:in_battle_pokemon1) do
    double(:in_battle_pokemon,
           position: 0, pokemon: pokemon1)
  end
  let(:in_battle_pokemon2) do
    double(:in_battle_pokemon,
           position: 0, pokemon: pokemon3)
  end
  let(:in_battle_pokemon3) do
    double(:in_battle_pokemon,
           position: 1, pokemon: pokemon4)
  end
  let(:targets) { [side2, in_battle_pokemon2.position] }
  let(:move_attributes) do
    {
      action: 'move',
      pokemon: pokemon1,
      move: move1,
      target: targets
    }
  end
  let(:recall_attributes) do
    {
      action: 'recall',
      pokemon: in_battle_pokemon1.position,
      target: pokemon2
    }
  end
  let(:attributes) { move_attributes }
  subject { described_class.new(trainer1, attributes) }

  describe '#priority' do
    it 'returns moves priority' do
      expect(subject.priority).to eq(move1.priority)
    end

    context 'recall action' do
      let(:attributes) { recall_attributes }
      it 'returns 6' do
        expect(subject.priority).to eq(6)
      end
    end
  end

  describe '#pokemon' do
    it { expect(subject.pokemon).to eq(pokemon1) }

    context 'recall action' do
      let(:attributes) { recall_attributes }
      it { expect(subject.pokemon).to eq(pokemon1) }

      context 'no in battle pokemon' do
        let(:in_battle_pokemon_list1) { [] }
        it { expect(subject.pokemon).to be_nil }
      end
    end
  end

  describe '#target' do
    it { expect(subject.target).to eq([pokemon3]) }

    context 'no in battle pokemon' do
      let(:in_battle_pokemon_list2) { [] }
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
    it { expect(subject.move).to eq(move1) }

    context 'recall action' do
      let(:attributes) { recall_attributes }
      it { expect(subject.move).to be_nil }
    end
  end

  describe '#execute' do
    let(:battle) { double(:battle, sides: [side1, side2]) }
    let(:turn) { double(:turn, battle: battle) }
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
    end

    it 'executes move execution' do
      allow(Oakdex::Battle::MoveExecution).to receive(:new)
        .with(subject, pokemon3).and_return(move_execution)
      expect(move_execution).to receive(:execute)
      subject.execute(turn)
    end

    context 'multiple targets' do
      let(:in_battle_pokemon_list2) { [in_battle_pokemon2, in_battle_pokemon3] }
      let(:targets) do
        [
          [side2, in_battle_pokemon2.position],
          [side2, in_battle_pokemon3.position]
        ]
      end

      it 'executes move execution' do
        allow(Oakdex::Battle::MoveExecution).to receive(:new)
          .with(subject, pokemon3).and_return(move_execution)
        allow(Oakdex::Battle::MoveExecution).to receive(:new)
          .with(subject, pokemon4).and_return(move_execution2)
        expect(move_execution).to receive(:execute)
        expect(move_execution2).to receive(:execute)
        subject.execute(turn)
      end
    end

    context 'recall action' do
      let(:attributes) { recall_attributes }

      it 'adds log' do
        expect(battle).to receive(:add_to_log)
          .with('recalls', trainer1.name, pokemon1.name, pokemon2.name)
        subject.execute(turn)
      end

      it 'switches pokemon' do
        expect(trainer1).to receive(:remove_from_battle)
          .with(pokemon1, side1)
        expect(trainer1).to receive(:send_to_battle)
          .with(pokemon2, side1)
        subject.execute(turn)
      end

      context 'no pokemon in battle' do
        let(:in_battle_pokemon_list1) { [] }

        it 'adds log' do
          expect(battle).to receive(:add_to_log)
            .with('recalls_for_fainted', trainer1.name, pokemon2.name)
          subject.execute(turn)
        end

        it 'recalls pokemon' do
          expect(trainer1).not_to receive(:remove_from_battle)
            .with(pokemon1, side1)
          expect(trainer1).to receive(:send_to_battle)
            .with(pokemon2, side1)
          subject.execute(turn)
        end
      end
    end
  end
end
