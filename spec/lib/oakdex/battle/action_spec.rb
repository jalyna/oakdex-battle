require 'spec_helper'

describe Oakdex::Battle::Action do
  let(:pokemon1_accuracy) { 1.0 }
  let(:pokemon3_evasion) { 1.0 }
  let(:pokemon1) do
    double(:pokemon, accuracy: pokemon1_accuracy,
                     name: 'Pokemon1')
  end
  let(:pokemon2) { double(:pokemon, name: 'Pokemon2') }
  let(:pokemon3) do
    double(:pokemon, evasion: pokemon3_evasion,
                     name: 'Pokemon3', trainer: trainer2)
  end
  let(:side1) { double(:side) }
  let(:in_battle_pokemon_list2) { [in_battle_pokemon2] }
  let(:side2) { double(:side, in_battle_pokemon: in_battle_pokemon_list2) }
  let(:move1_accuracy) { 100 }
  let(:move1) do
    double(:move, name: 'Cool Move', priority: 0,
                  accuracy: move1_accuracy)
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
  let(:move_attributes) do
    {
      action: 'move',
      pokemon: pokemon1,
      move: move1,
      target: [side2, in_battle_pokemon2.position]
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
    it { expect(subject.target).to eq(pokemon3) }

    context 'no in battle pokemon' do
      let(:in_battle_pokemon_list2) { [] }
      it { expect(subject.target).to be_nil }
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

  describe '#hitting_probability' do
    it { expect(subject.hitting_probability).to eq(1000) }

    context 'move accuracy is less than 100' do
      let(:move1_accuracy) { 80 }
      it { expect(subject.hitting_probability).to eq(800) }
    end

    context 'pokemon accuracy is less than 1' do
      let(:pokemon1_accuracy) { 0.8 }
      it { expect(subject.hitting_probability).to eq(800) }
    end

    context 'target evasion is less than 1' do
      let(:pokemon3_evasion) { 0.8 }
      it { expect(subject.hitting_probability).to eq(1250) }
    end
  end

  describe '#hitting?' do
    let(:rand_number) { 500 }
    before do
      allow(subject).to receive(:rand).with(1..1000).and_return(rand_number)
    end

    it { expect(subject).to be_hitting }

    context 'not hitting' do
      let(:rand_number) { 1001 }
      it { expect(subject).not_to be_hitting }
    end
  end

  describe '#execute' do
    let(:battle) { double(:battle, sides: [side1, side2]) }
    let(:turn) { double(:turn, battle: battle) }
    let(:hitting) { true }
    let(:damage_points) { 4 }
    let(:pokemon3_hp) { 10 }
    let(:damage) { double(:damage, damage: damage_points) }

    before do
      allow(battle).to receive(:add_to_log)
      allow(battle).to receive(:remove_fainted)
      allow(side1).to receive(:trainer_on_side?)
        .with(trainer1).and_return(true)
      allow(trainer1).to receive(:remove_from_battle)
        .with(pokemon1, side1)
      allow(trainer1).to receive(:send_to_battle)
        .with(pokemon2, side1)
      allow(subject).to receive(:hitting?).and_return(hitting)
      allow(Oakdex::Battle::Damage).to receive(:new)
        .with(turn, subject).and_return(damage)
      allow(pokemon1).to receive(:change_pp_by)
        .with(move1.name, -1)
      allow(pokemon3).to receive(:change_hp_by)
        .with(-damage_points)
      allow(pokemon3).to receive(:current_hp).and_return(pokemon3_hp)
    end

    it 'reduces pp' do
      expect(pokemon1).to receive(:change_pp_by)
        .with(move1.name, -1)
      subject.execute(turn)
    end

    it 'reduces hp' do
      expect(pokemon3).to receive(:change_hp_by)
        .with(-damage_points)
      subject.execute(turn)
    end

    it 'adds log' do
      expect(battle).to receive(:add_to_log)
        .with('uses_move', trainer1.name, pokemon1.name, move1.name)
      expect(battle).to receive(:add_to_log)
        .with('received_damage', trainer2.name, pokemon3.name,
              move1.name, damage_points)
      subject.execute(turn)
    end

    it 'removes fainted' do
      expect(battle).to receive(:remove_fainted)
      subject.execute(turn)
    end

    context 'damage is 0' do
      let(:damage_points) { 0 }

      it 'adds log' do
        expect(battle).to receive(:add_to_log)
          .with('received_no_damage', trainer2.name,
                pokemon3.name, move1.name)
        subject.execute(turn)
      end
    end

    context 'pokemon fainted' do
      let(:pokemon3_hp) { 0 }

      it 'adds log' do
        expect(battle).to receive(:add_to_log)
          .with('target_fainted', trainer2.name, pokemon3.name)
        subject.execute(turn)
      end
    end

    context 'not hitting' do
      let(:hitting) { false }

      it 'adds log' do
        expect(battle).to receive(:add_to_log)
          .with('move_does_not_hit', trainer1.name,
                pokemon1.name, move1.name)
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
