require 'spec_helper'

describe Oakdex::Battle::Trainer do
  let(:name) { double(:name) }
  let(:current_hp1) { 10 }
  let(:current_hp2) { 12 }
  let(:pok1) { double(:pok1, "trainer=": nil) }
  let(:pok2) { double(:pok2, "trainer=": nil) }
  let(:pokemon1) do
    double(:pokemon,
           name: 'Pok1',
           current_hp: current_hp1,
           fainted?: current_hp1 == 0)
  end
  let(:pokemon2) do
    double(:pokemon,
           current_hp: current_hp2,
           fainted?: current_hp2 == 0)
  end
  let(:team) { [pokemon1, pokemon2] }
  let(:items) { ['Potion', 'Potion', 'Calcium'] }
  let(:side) { double(:side, next_position: 0, add_to_log: nil) }
  let(:trainer2) { double(:trainer2) }
  let(:side2) { double(:side2, next_position: 0, add_to_log: nil, trainers: [trainer2]) }
  let(:fainted) { false }
  let(:battle) { double(:battle, sides: [side, side2]) }
  let(:active_in_battle_pokemon) do
    double(:active_in_battle_pokemon, fainted?: fainted,
                               pokemon: pokemon1,
                               battle: battle)
  end

  let(:options) { {} }
  subject { described_class.new(name, [pok1, pok2], items, options) }

  before do
    allow(Oakdex::Battle::InBattlePokemon).to receive(:new).with(pok1).and_return(pokemon1)
    allow(Oakdex::Battle::InBattlePokemon).to receive(:new).with(pok2).and_return(pokemon2)
    allow(side).to receive(:trainer_on_side?).with(subject).and_return(true)
    subject.side = side
    allow(trainer2).to receive(:side).and_return(side2)
  end

  describe '#name' do
    it { expect(subject.name).to eq(name) }
  end

  describe '#team' do
    it { expect(subject.team).to eq(team) }
  end

  describe '#items' do
    it { expect(subject.items).to eq(items) }
  end

  describe '#consume_item' do
    it 'deletes first occurence' do
      subject.consume_item('Potion')
      expect(subject.items).to eq(['Potion', 'Calcium'])
    end
  end

  describe '#active_in_battle_pokemon' do
    it { expect(subject.active_in_battle_pokemon).to eq([]) }
  end

  describe '#fainted?' do
    it { expect(subject).not_to be_fainted }

    context 'pokemon hp 1 is zero' do
      let(:current_hp1) { 0 }
      it { expect(subject).not_to be_fainted }

      context 'pokemon hp 2 is zero' do
        let(:current_hp2) { 0 }
        it { expect(subject).to be_fainted }
      end
    end
  end

  describe '#send_to_battle' do
    let(:position) { 0 }

    before do
      allow(Oakdex::Battle::ActiveInBattlePokemon).to receive(:new)
        .with(pokemon1, side, position).and_return(active_in_battle_pokemon)
      allow(side).to receive(:add_to_log)
        .with('sends_to_battle', name, pokemon1.name)
      allow(side).to receive(:next_position).and_return(position)
    end

    it 'sends pokemon to battle' do
      subject.send_to_battle(pokemon1, side)
      expect(subject.active_in_battle_pokemon).to eq([active_in_battle_pokemon])
    end

    it 'adds to logs' do
      expect(side).to receive(:add_to_log)
        .with('sends_to_battle', name, pokemon1.name)
      subject.send_to_battle(pokemon1, side)
    end
  end

  describe '#remove_from_battle' do
    let(:position) { 0 }
    let(:status_condition) { double(:status_condition) }

    before do
      allow(Oakdex::Battle::ActiveInBattlePokemon).to receive(:new)
        .with(pokemon1, side, position).and_return(active_in_battle_pokemon)
      allow(side).to receive(:add_to_log)
        .with('sends_to_battle', name, pokemon1.name)
      allow(side).to receive(:add_to_log)
        .with('removes_from_battle', name, pokemon1.name)
      allow(side).to receive(:next_position).and_return(position)
      allow(pokemon1).to receive(:reset_stats)
      allow(pokemon1).to receive(:status_conditions)
        .and_return([status_condition])
      allow(status_condition).to receive(:after_switched_out)
        .with(battle)
      subject.send_to_battle(pokemon1, side)
    end

    it 'removes pokemon from battle' do
      expect(status_condition).to receive(:after_switched_out)
        .with(battle)
      subject.remove_from_battle(pokemon1, side)
      expect(subject.active_in_battle_pokemon).to eq([])
    end

    it 'adds to logs' do
      expect(side).to receive(:add_to_log)
        .with('removes_from_battle', name, pokemon1.name)
      subject.remove_from_battle(pokemon1, side)
    end

    it 'reset stats' do
      expect(pokemon1).to receive(:reset_stats)
      subject.remove_from_battle(pokemon1, side)
    end
  end

  describe '#remove_fainted' do
    let(:position) { 0 }
    let(:status_condition) { double(:status_condition) }
    before do
      allow(Oakdex::Battle::ActiveInBattlePokemon).to receive(:new)
        .with(pokemon1, side, position).and_return(active_in_battle_pokemon)
      allow(side).to receive(:add_to_log)
        .with('sends_to_battle', name, pokemon1.name)
      allow(side).to receive(:next_position).and_return(position)
      allow(pokemon1).to receive(:status_conditions)
        .and_return([status_condition])
      subject.send_to_battle(pokemon1, side)
    end

    it 'does nothing' do
      expect(battle).not_to receive(:add_to_log)
      subject.remove_fainted
      expect(subject.active_in_battle_pokemon).to eq([active_in_battle_pokemon])
    end

    context 'pokemon fainted' do
      let(:fainted) { true }
      before do
        allow(side2).to receive(:trainer_on_side?).with(subject).and_return(false)
      end

      it 'removes fainted' do
        expect(battle).to receive(:add_to_log)
          .with('pokemon_fainted', name, pokemon1.name)
        expect(status_condition).to receive(:after_fainted).with(battle)
        expect(trainer2).to receive(:grow).with(active_in_battle_pokemon)
        subject.remove_fainted
        expect(subject.active_in_battle_pokemon).to eq([])
      end
    end
  end

  describe '#left_pokemon_in_team' do
    let(:position) { 0 }

    it { expect(subject.left_pokemon_in_team).to eq(team) }

    context 'pokemon1 hp is zero' do
      let(:current_hp1) { 0 }
      it { expect(subject.left_pokemon_in_team).to eq([pokemon2]) }
    end

    context 'has in battle pokemon' do
      before do
        allow(Oakdex::Battle::ActiveInBattlePokemon).to receive(:new)
          .with(pokemon1, side, position).and_return(active_in_battle_pokemon)
        allow(side).to receive(:add_to_log)
          .with('sends_to_battle', name, pokemon1.name)
        allow(side).to receive(:next_position).and_return(position)
        subject.send_to_battle(pokemon1, side)
      end

      it { expect(subject.left_pokemon_in_team).to eq([pokemon2]) }
    end
  end

  describe 'growth events' do
    let(:growth_event) { nil }

    before do
      allow(pokemon1).to receive(:growth_event).and_return(growth_event)
      allow(pokemon1).to receive(:growth_event?).and_return(!growth_event.nil?)
      allow(pokemon2).to receive(:growth_event).and_return(nil)
    end

    describe '#growth_event?' do
      it { expect(subject).not_to be_growth_event }

      context 'with growth event' do
        let(:growth_event) { double(:growth_event) }
        it { expect(subject).to be_growth_event }
      end
    end

    describe '#growth_event' do
      it { expect(subject.growth_event).to be_nil }

      context 'with growth event' do
        let(:growth_event) { double(:growth_event) }
        it { expect(subject.growth_event).to eq(growth_event) }
      end
    end

    describe '#remove_growth_event' do
      it 'does nothing' do
        expect(pokemon1).not_to receive(:remove_growth_event)
        subject.remove_growth_event
      end

      context 'with growth event' do
        let(:growth_event) { double(:growth_event) }
        it 'removes the pokemons growth event' do
          expect(pokemon1).to receive(:remove_growth_event)
          subject.remove_growth_event
        end
      end
    end
  end

  describe '#grow' do
    let(:defeated_pokemon) { double(:defeated_pokemon) }
    let(:defeated) { double(:defeated, pokemon: double(:pok, pokemon: defeated_pokemon)) }

    before do
      subject.send_to_battle(pokemon1, side)
      allow(side).to receive(:battle).and_return(battle)
    end

    it 'nothing happens by default' do
      expect(pokemon1).not_to receive(:grow_from_battle)
      subject.grow(defeated)
    end

    context 'when enable_grow' do
      let(:options) { { enable_grow: true } }
      let(:read_only) { true }
      let(:growth_event) do
        double(:growth_event, read_only?: read_only,
          message: 'test',
          possible_actions: ['a', 'b'])
      end

      it 'pokemon grows' do
        expect(pokemon1).to receive(:grow_from_battle).with(defeated_pokemon)
        expect(battle).to receive(:add_to_log).with('test')
        expect(growth_event).to receive(:execute)
        allow(pokemon1).to receive(:growth_event?).and_return(true, false)
        allow(pokemon1).to receive(:growth_event).and_return(growth_event)
        subject.grow(defeated)
      end

      context 'with exp share' do
        let(:options) { { enable_grow: true, using_exp_share: true } }

        it 'team pokemon grows too' do
          expect(pokemon1).to receive(:grow_from_battle).with(defeated_pokemon)
          expect(pokemon2).to receive(:grow_from_battle).with(defeated_pokemon)
          expect(battle).to receive(:add_to_log).with('test')
          expect(growth_event).to receive(:execute)
          allow(pokemon1).to receive(:growth_event?).and_return(false)
          allow(pokemon2).to receive(:growth_event?).and_return(true, false)
          allow(pokemon2).to receive(:growth_event).and_return(growth_event)
          subject.grow(defeated)
        end
      end

      context 'not read only' do
        let(:read_only) { false }
        it 'pokemon grows' do
          expect(pokemon1).to receive(:grow_from_battle).with(defeated_pokemon)
          expect(battle).to receive(:add_to_log)
            .with('choice_for', subject.name, 'test', 'a,b')
          expect(growth_event).not_to receive(:execute)
          allow(pokemon1).to receive(:growth_event?).and_return(true, true, false)
          allow(pokemon1).to receive(:growth_event).and_return(growth_event)
          subject.grow(defeated)
        end
      end
    end
  end
end
