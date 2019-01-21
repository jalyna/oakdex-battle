require 'spec_helper'

describe Oakdex::Battle::Turn do
  let(:speed1) { 20 }
  let(:speed2) { 10 }
  let(:target1) { double(:target, current_hp: 6, fainted?: false) }
  let(:target2) { double(:target, current_hp: 6, fainted?: false) }
  let(:target_list1) { [target1] }
  let(:target_list2) { [target2] }
  let(:pokemon1) { double(:pokemon, current_hp: 6, speed: speed1, fainted?: false) }
  let(:pokemon2) { double(:pokemon, current_hp: 6, speed: speed2, fainted?: false) }
  let(:battle) { double(:battle) }
  let(:priority1) { 1 }
  let(:priority2) { 0 }
  let(:status_conditions) { [] }
  let(:active_in_battle_pokemon1) do
    double(:active_in_battle_pokemon1, pokemon: pokemon1)
  end
  let(:side1) { double(:side1, active_in_battle_pokemon: [active_in_battle_pokemon1]) }
  let(:action1) do
    double(:action, priority: priority1,
                    target: target_list1, pokemon: pokemon1)
  end
  let(:action2) do
    double(:action, priority: priority2,
                    target: target_list2, pokemon: pokemon2)
  end
  let(:actions) { [action1, action2] }
  subject { described_class.new(battle, actions) }

  before do
    allow(battle).to receive(:remove_fainted)
    allow(battle).to receive(:sides).and_return([side1])
    allow(pokemon1).to receive(:status_conditions)
      .and_return(status_conditions)
  end

  describe '#execute' do
    it 'executes actions' do
      expect(action1).to receive(:execute).with(subject).ordered
      expect(action2).to receive(:execute).with(subject).ordered
      subject.execute
    end

    context 'same priority' do
      let(:priority1) { 0 }

      it 'executes actions' do
        expect(action1).to receive(:execute).with(subject).ordered
        expect(action2).to receive(:execute).with(subject).ordered
        subject.execute
      end
    end

    context 'target is fainted' do
      let(:target1) { double(:target, fainted?: true) }

      it 'executes actions' do
        expect(action1).not_to receive(:execute)
        expect(action2).to receive(:execute).with(subject).ordered
        subject.execute
      end
    end

    context 'pokemon is fainted' do
      let(:pokemon1) { double(:pokemon, fainted?: true, speed: speed1) }

      it 'executes actions' do
        expect(action1).not_to receive(:execute)
        expect(action2).to receive(:execute).with(subject).ordered
        subject.execute
      end
    end

    context 'with status conditions' do
      let(:status_condition) { double(:status_condition) }
      let(:status_conditions) { [status_condition] }
      before do
        allow(action1).to receive(:execute).with(subject)
        allow(action2).to receive(:execute).with(subject)
      end

      it 'executes status_condition on after_turn' do
        allow(status_condition).to receive(:before_turn).with(subject)
        expect(status_condition).to receive(:after_turn).with(subject)
        expect(battle).to receive(:remove_fainted)
        subject.execute
      end

      it 'executes status_condition on before_turn' do
        allow(status_condition).to receive(:after_turn).with(subject)
        expect(status_condition).to receive(:before_turn).with(subject)
        expect(battle).to receive(:remove_fainted)
        subject.execute
      end
    end
  end
end
