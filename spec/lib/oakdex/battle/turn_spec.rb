require 'spec_helper'

describe Oakdex::Battle::Turn do
  let(:speed1) { 20 }
  let(:speed2) { 10 }
  let(:target1) { double(:target, current_hp: 6) }
  let(:target2) { double(:target, current_hp: 6) }
  let(:target_list1) { [target1] }
  let(:target_list2) { [target2] }
  let(:pokemon1) { double(:pokemon, current_hp: 6, speed: speed1) }
  let(:pokemon2) { double(:pokemon, current_hp: 6, speed: speed2) }
  let(:battle) { double(:battle) }
  let(:priority1) { 1 }
  let(:priority2) { 0 }
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
      let(:target1) { double(:target, current_hp: 0) }

      it 'executes actions' do
        expect(action1).not_to receive(:execute)
        expect(action2).to receive(:execute).with(subject).ordered
        subject.execute
      end
    end

    context 'pokemon is fainted' do
      let(:pokemon1) { double(:pokemon, current_hp: 0, speed: speed1) }

      it 'executes actions' do
        expect(action1).not_to receive(:execute)
        expect(action2).to receive(:execute).with(subject).ordered
        subject.execute
      end
    end
  end
end
