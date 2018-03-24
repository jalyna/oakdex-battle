require 'spec_helper'

describe Oakdex::Battle do
  let(:trainer1) { double(:trainer) }
  let(:trainer2) { double(:trainer) }
  let(:options) { {} }
  let(:team1) { [trainer1] }
  let(:team2) { [trainer2] }
  let(:action) { double(:action) }
  let(:valid_action) { double(:valid_action) }
  let(:valid_actions) { [valid_action] }
  let(:valid_action_service) { double(:valid_action_service) }
  subject { described_class.new(team1, team2, options) }

  before do
    allow(Oakdex::Battle::ValidActionService).to receive(:new)
      .with(subject).and_return(valid_action_service)
    allow(valid_action_service).to receive(:valid_actions_for)
      .with(trainer1).and_return(valid_actions)
  end

  describe '#arena' do
    it { expect(subject.arena).to eq(sides: []) }
  end

  describe '#valid_actions_for' do
    it { expect(subject.valid_actions_for(trainer1)).to eq(valid_actions) }
  end

  describe '#add_action' do
    before do
      allow(Oakdex::Battle::Action).to receive(:new)
        .with(trainer1, valid_action).and_return(action)
    end

    it 'adds action' do
      expect(subject.add_action(trainer1, valid_action)).to be(true)
      expect(subject.actions).to eq([action])
    end

    context 'invalid action' do
      let(:invalid_action) { double(:invalid_action) }

      it 'does not add action' do
        expect(subject.add_action(trainer1, invalid_action)).to be(false)
        expect(subject.actions).to be_empty
      end
    end
  end

  describe '#simulate_action' do
    it 'adds action' do
      expect(subject).to receive(:add_action)
        .with(trainer1, valid_action)
      subject.simulate_action(trainer1)
    end

    context 'no actions' do
      let(:valid_actions) { [] }
      it 'does not add action' do
        expect(subject).not_to receive(:add_action)
        expect(subject.simulate_action(trainer1)).to be(false)
      end
    end
  end

  describe '#continue' do
    pending
  end

  describe '#finished?' do
    pending
  end

  describe '#winner?' do
    pending
  end

  describe '#add_to_log' do
    pending
  end

  describe '#remove_fainted' do
    pending
  end
end
