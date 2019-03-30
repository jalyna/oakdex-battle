require 'spec_helper'

describe Oakdex::Battle do
  let(:pok1) { double(:pokemon, id: 'ab') }
  let(:pok2) { double(:pokemon, id: 'cd') }
  let(:trainer1) { double(:trainer, growth_event?: false, name: 'Trainer1', team: [pok1]) }
  let(:trainer2) { double(:trainer, growth_event?: false, name: 'Trainer2', team: [pok2]) }
  let(:trainer3) { double(:trainer) }
  let(:options) { {} }
  let(:team1) { [trainer1] }
  let(:team2) { [trainer2] }
  let(:action) { double(:action) }
  let(:valid_action) { double(:valid_action) }
  let(:valid_actions) { [valid_action] }
  let(:valid_action_service) { double(:valid_action_service) }

  before do
    allow(trainer1).to receive(:side=)
    allow(trainer2).to receive(:side=)
    allow(trainer3).to receive(:side=)
    allow(Oakdex::Battle::ValidActionService).to receive(:new)
      .with(subject).and_return(valid_action_service)
    allow(valid_action_service).to receive(:valid_actions_for)
      .with(trainer1).and_return(valid_actions)
  end

  subject { described_class.new(team1, team2, options) }

  describe '#sides' do
    it { expect(subject.sides.size).to eq(2) }
    it { expect(subject.sides.first.trainers).to eq([trainer1]) }
    it { expect(subject.sides.last.trainers).to eq([trainer2]) }
  end

  describe '#pokemon_per_side' do
    it { expect(subject.pokemon_per_side).to eq(1) }

    context 'option given' do
      let(:options) { { pokemon_per_side: 2 } }
      it { expect(subject.pokemon_per_side).to eq(2) }
    end

    context 'more trainers per team' do
      let(:team1) { [trainer1, trainer3] }
      it { expect(subject.pokemon_per_side).to eq(2) }
    end
  end

  describe '#valid_actions_for' do
    it { expect(subject.valid_actions_for(trainer1)).to eq(valid_actions) }
  end

  describe '#side_by_id' do
    it { expect(subject.side_by_id('Trainer1')).to eq(subject.sides.first) }
    it { expect(subject.side_by_id('Trainer2')).to eq(subject.sides.last) }
    it { expect(subject.side_by_id('foo')).to be_nil }
  end

  describe '#pokemon_by_id' do
    it { expect(subject.pokemon_by_id(pok1.id)).to eq(pok1) }
    it { expect(subject.pokemon_by_id(pok2.id)).to eq(pok2) }
    it { expect(subject.pokemon_by_id('foobar')).to be_nil }
  end

  describe '#trainers' do
    it { expect(subject.trainers).to eq([trainer1, trainer2]) }
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

  describe '#add_to_log' do
    it 'adds to log' do
      subject.add_to_log 'some', 'message'
      expect(subject.current_log).to eq([%w[some message]])
    end
  end

  describe '#remove_fainted' do
    let(:side1) { double(:side) }
    let(:side2) { double(:side) }
    let(:sides) { [side1, side2] }

    before do
      allow(subject).to receive(:sides).and_return(sides)
    end

    it 'removes fainted' do
      expect(side1).to receive(:remove_fainted)
      expect(side2).to receive(:remove_fainted)
      subject.remove_fainted
    end
  end

  describe '#finished?' do
    let(:fainted1) { false }
    let(:fainted2) { false }
    let(:side1) { double(:side, fainted?: fainted1) }
    let(:side2) { double(:side, fainted?: fainted2) }
    let(:sides) { [side1, side2] }

    before do
      allow(subject).to receive(:sides).and_return(sides)
    end

    it { expect(subject).not_to be_finished }

    context 'side 1 fainted' do
      let(:fainted1) { true }
      it { expect(subject).to be_finished }
    end
  end

  describe '#winner?' do
    let(:fainted1) { false }
    let(:fainted2) { false }
    let(:side1) { double(:side, fainted?: fainted1) }
    let(:side2) { double(:side, fainted?: fainted2, trainers: [trainer2]) }
    let(:sides) { [side1, side2] }

    before do
      allow(subject).to receive(:sides).and_return(sides)
    end

    it { expect(subject.winner).to be_nil }

    context 'side 1 fainted' do
      let(:fainted1) { true }
      it { expect(subject.winner).to eq([trainer2]) }
    end
  end

  describe '#continue' do
    let(:side1) { double(:side, trainers: team1) }
    let(:side2) { double(:side, trainers: team2) }
    let(:action1) { double(:action) }
    let(:action2) { double(:action) }
    let(:valid_actions1) { [action1] }
    let(:valid_actions2) { [action2] }
    let(:sides) { [side1, side2] }
    let(:turn) { double(:turn) }

    before do
      allow(subject).to receive(:sides).and_return(sides)
      allow(subject).to receive(:valid_actions_for).with(trainer1)
        .and_return(valid_actions1)
      allow(subject).to receive(:valid_actions_for).with(trainer2)
        .and_return(valid_actions2)
      allow(Oakdex::Battle::Turn).to receive(:new).with(subject, [])
        .and_return(turn)
    end

    it 'starts battle' do
      expect(side1).to receive(:send_to_battle)
      expect(side2).to receive(:send_to_battle)
      expect(subject.continue).to be(true)
      expect(subject.log).to eq([[]])
    end

    context 'battle started' do
      before do
        allow(side1).to receive(:send_to_battle)
        allow(side2).to receive(:send_to_battle)
        subject.continue
      end

      it 'does not continue' do
        expect(subject.continue).to be(false)
      end

      context 'no actions available' do
        let(:valid_actions1) { [] }
        let(:valid_actions2) { [] }

        it 'continues' do
          expect(turn).to receive(:execute)
          expect(subject.continue).to be(true)
          expect(subject.log).to eq([[], []])
        end
      end
    end
  end
end
