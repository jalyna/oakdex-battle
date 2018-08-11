require 'spec_helper'

describe Oakdex::Battle::MoveExecution do
  let(:move1_accuracy) { 100 }
  let(:pokemon1_accuracy) { 1.0 }
  let(:target_evasion) { 1.0 }
  let(:move1_power) { 100 }
  let(:in_battle_properties) { nil }
  let(:move1_stat_modifiers) { [] }
  let(:move1) do
    double(:move,
           accuracy: move1_accuracy,
           name: 'cool move',
           power: move1_power,
           stat_modifiers: move1_stat_modifiers,
           in_battle_properties: in_battle_properties)
  end
  let(:pokemon1) do
    double(:pokemon1,
           accuracy: pokemon1_accuracy, name: 'attacker',
           trainer: trainer1)
  end
  let(:target) do
    double(:target, evasion: target_evasion,
                    status_conditions: [],
                    trainer: trainer2, name: 'defender')
  end
  let(:trainer1) { double(:trainer, name: 'test') }
  let(:trainer2) { double(:trainer, name: 'trainer2') }
  let(:battle) { double(:battle) }
  let(:turn) { double(:turn) }
  let(:action) do
    double(:action, move: move1, pokemon: pokemon1,
                    trainer: trainer1, battle: battle, turn: turn)
  end
  let(:turn) { double(:turn, battle: battle) }
  let(:hitting) { true }
  let(:damage_points) { 4 }
  let(:target_hp) { 10 }
  let(:damage) { double(:damage, damage: damage_points) }
  let(:conditions) { [] }

  subject { described_class.new(action, target) }

  before do
    allow(pokemon1).to receive(:status_conditions).and_return(conditions)
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
      let(:target_evasion) { 0.8 }
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
    before do
      allow(battle).to receive(:add_to_log)
      allow(battle).to receive(:remove_fainted)
      allow(subject).to receive(:hitting?).and_return(hitting)
      allow(Oakdex::Battle::Damage).to receive(:new)
        .with(turn, subject).and_return(damage)
      allow(pokemon1).to receive(:change_pp_by)
        .with(move1.name, -1)
      allow(target).to receive(:change_hp_by)
        .with(-damage_points)
      allow(target).to receive(:current_hp).and_return(target_hp)
    end

    it 'reduces pp' do
      expect(pokemon1).to receive(:change_pp_by)
        .with(move1.name, -1)
      subject.execute
    end

    it 'reduces hp' do
      expect(target).to receive(:change_hp_by)
        .with(-damage_points)
      subject.execute
    end

    it 'adds log' do
      expect(battle).to receive(:add_to_log)
        .with('uses_move', trainer1.name, pokemon1.name, move1.name)
      expect(battle).to receive(:add_to_log)
        .with('received_damage', trainer2.name, target.name,
              move1.name, damage_points)
      subject.execute
    end

    it 'removes fainted' do
      expect(battle).to receive(:remove_fainted)
      subject.execute
    end

    it 'executes status condition after_received_damage' do
      status_condition = double(:status_condition)
      allow(target).to receive(:status_conditions)
        .and_return([status_condition])
      expect(status_condition).to receive(:after_received_damage)
        .with(subject)
      subject.execute
    end

    context 'status condition' do
      let(:condition) { double(:condition) }
      let(:prevents) { true }
      let(:conditions) { [condition] }

      before do
        allow(condition).to receive(:prevents_move?)
          .with(subject)
          .and_return(prevents)
      end

      it 'does nothing' do
        expect(battle).not_to receive(:add_to_log)
        expect(target).not_to receive(:change_hp_by)
        subject.execute
      end

      context 'does not prevent' do
        let(:prevents) { false }

        it 'does it normally' do
          expect(battle).to receive(:add_to_log)
          expect(target).to receive(:change_hp_by)
          subject.execute
        end
      end
    end

    context 'move that has no power' do
      let(:move1_power) { 0 }

      it 'does not reduce hp' do
        expect(target).not_to receive(:change_hp_by)
        subject.execute
      end

      it 'add logs' do
        expect(battle).to receive(:add_to_log)
          .with('uses_move', trainer1.name, pokemon1.name, move1.name)
        expect(battle).not_to receive(:add_to_log)
          .with('received_damage', trainer2.name, target.name,
                move1.name, damage_points)
        subject.execute
      end

      it 'does not execute status condition after_received_damage' do
        status_condition = double(:status_condition)
        allow(target).to receive(:status_conditions)
          .and_return([status_condition])
        expect(status_condition).not_to receive(:after_received_damage)
          .with(subject)
        subject.execute
      end

      context 'with Non-volatile status' do
        let(:condition) { 'poison' }
        let(:probability) { 100 }
        let(:in_battle_properties) do
          {
            'status_conditions' => [
              {
                'condition' => condition,
                'probability' => probability
              }
            ]
          }
        end
        let(:rand_number) { 20 }
        before do
          allow(subject).to receive(:rand).with(1..100).and_return(rand_number)
          allow(target).to receive(:add_status_condition).with(condition)
        end

        it 'adds logs' do
          expect(battle).to receive(:add_to_log)
            .with('target_condition_added', trainer2.name,
                  target.name, condition)
          subject.execute
        end

        it 'adds condition' do
          expect(target).to receive(:add_status_condition)
            .with(condition)
          subject.execute
        end

        context 'probability is less' do
          let(:probability) { 10 }

          it 'does not add logs' do
            expect(battle).not_to receive(:add_to_log)
              .with('target_condition_added', trainer2.name,
                    target.name, condition)
            subject.execute
          end

          it 'does not add condition' do
            expect(target).not_to receive(:add_status_condition)
              .with(condition)
            subject.execute
          end
        end
      end

      context 'with stat modifier' do
        let(:changed_stat) { true }
        let(:stat) { 'atk' }
        let(:affects_user) { false }
        let(:move1_stat_modifiers) do
          [
            {
              'stat' => stat,
              'change_by' => -2,
              'affects_user' => affects_user
            }
          ]
        end

        before do
          allow(target).to receive(:change_stat_by).and_return(changed_stat)
          allow(pokemon1).to receive(:change_stat_by).and_return(changed_stat)
        end

        it 'changes stat' do
          expect(target).to receive(:change_stat_by)
            .with(:atk, -2).and_return(changed_stat)
          subject.execute
        end

        it 'add logs' do
          expect(battle).to receive(:add_to_log)
            .with('uses_move', trainer1.name, pokemon1.name, move1.name)
          expect(battle).to receive(:add_to_log)
            .with('changes_stat', trainer2.name, target.name,
                  'atk', -2)
          subject.execute
        end

        context 'affects user' do
          let(:affects_user) { true }
          it 'changes stat' do
            expect(pokemon1).to receive(:change_stat_by)
              .with(:atk, -2).and_return(changed_stat)
            subject.execute
          end

          it 'add logs' do
            expect(battle).to receive(:add_to_log)
              .with('uses_move', trainer1.name, pokemon1.name, move1.name)
            expect(battle).to receive(:add_to_log)
              .with('changes_stat', trainer1.name, pokemon1.name,
                    'atk', -2)
            subject.execute
          end
        end

        context 'random stat' do
          let(:stat) { 'random' }
          it 'changes stat' do
            expect(target).to receive(:change_stat_by)
              .with(anything, -2).and_return(changed_stat)
            subject.execute
          end
        end

        context 'stat was not changed' do
          let(:changed_stat) { false }

          it 'add logs' do
            expect(battle).to receive(:add_to_log)
              .with('uses_move', trainer1.name, pokemon1.name, move1.name)
            expect(battle).not_to receive(:add_to_log)
              .with('changes_stat', trainer2.name, target.name,
                    'atk', -2)
            expect(battle).to receive(:add_to_log)
              .with('changes_no_stat', trainer2.name, target.name,
                    'atk', -2)
            subject.execute
          end
        end
      end
    end

    context 'damage is 0' do
      let(:damage_points) { 0 }

      it 'adds log' do
        expect(battle).to receive(:add_to_log)
          .with('received_no_damage', trainer2.name,
                target.name, move1.name)
        subject.execute
      end
    end

    context 'not hitting' do
      let(:hitting) { false }

      it 'adds log' do
        expect(battle).to receive(:add_to_log)
          .with('move_does_not_hit', trainer1.name,
                pokemon1.name, move1.name)
        subject.execute
      end
    end
  end
end
