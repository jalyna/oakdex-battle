require 'spec_helper'

describe Oakdex::Battle::ActiveInBattlePokemon do
  let(:actions) { [] }
  let(:hp_zero) { false }
  let(:pokemon_per_side) { 1 }
  let(:moves_with_pp) { double(:moves_with_pp) }
  let(:pokemon) do
    double(:pokemon,
           fainted?: hp_zero,
           moves_with_pp: moves_with_pp)
  end
  let(:side) { double(:side1, battle: battle) }
  let(:side2) { double(:side2, battle: battle) }
  let(:sides) { [side, side2] }
  let(:battle) { double(:battle, pokemon_per_side: pokemon_per_side) }
  subject { described_class.new(pokemon, side) }

  before do
    allow(battle).to receive(:sides).and_return(sides)
    allow(battle).to receive(:actions).and_return(actions)
    allow(side2).to receive(:pokemon_in_battle?).with(0).and_return(true)
    allow(side2).to receive(:pokemon_in_battle?).with(1).and_return(true)
    allow(side2).to receive(:pokemon_in_battle?).with(2).and_return(true)
    allow(side).to receive(:pokemon_in_battle?).with(0).and_return(true)
    allow(side).to receive(:pokemon_in_battle?).with(1).and_return(true)
    allow(side).to receive(:pokemon_in_battle?).with(2).and_return(true)
  end

  describe '#pokemon' do
    it { expect(subject.pokemon).to eq(pokemon) }
  end

  describe '#position' do
    it { expect(subject.position).to eq(0) }
    context 'position given' do
      subject { described_class.new(pokemon, side, 1) }
      it { expect(subject.position).to eq(1) }
    end
  end

  %i[fainted? moves_with_pp].each do |field|
    describe "##{field}" do
      it {
        expect(subject.public_send(field))
        .to eq(pokemon.public_send(field))
      }
    end
  end

  describe '#action_added?' do
    let(:pokemon2) { double(:pokemon) }
    it { expect(subject).not_to be_action_added }

    context 'action exist' do
      let(:action1) { double(:action, pokemon: pokemon) }
      let(:actions) { [action1] }
      it { expect(subject).to be_action_added }

      context 'for other pokemon' do
        let(:action1) { double(:action, pokemon: pokemon2) }
        it { expect(subject).not_to be_action_added }
      end
    end
  end

  describe '#valid_move_actions' do
    let(:action_added) { false }
    let(:target) { 'target_adjacent_single' }
    let(:move1) { double(:move, name: 'Cool Move', target: target) }
    let(:moves_with_pp) { [move1] }
    let(:pokemon2) { double(:pokemon) }
    let(:active_in_battle_pokemon2) do
      double(:active_in_battle_pokemon, pokemon: pokemon2, side: side2,
                                 position: 0)
    end
    let(:active_in_battle_pokemon3) do
      double(:active_in_battle_pokemon, side: side2, position: 1)
    end
    let(:active_in_battle_pokemon4) do
      double(:active_in_battle_pokemon, side: side2, position: 2)
    end
    let(:active_in_battle_pokemon5) do
      double(:active_in_battle_pokemon, side: side, position: 0)
    end
    let(:active_in_battle_pokemon6) do
      double(:active_in_battle_pokemon, side: side, position: 1)
    end
    let(:active_in_battle_pokemon7) do
      double(:active_in_battle_pokemon, side: side, position: 2)
    end

    before do
      allow(side2).to receive(:active_in_battle_pokemon) do
        [active_in_battle_pokemon2]
      end
      allow(side).to receive(:active_in_battle_pokemon) do
        [subject]
      end
      allow(subject).to receive(:action_added?).and_return(action_added)
    end

    it 'returns all moves that have enough pp' do
      expect(subject.valid_move_actions).to eq([
                                                 {
                                                   action: 'move',
                                                   pokemon: pokemon,
                                                   move: move1,
                                                   target: [side2, 0]
                                                 }
                                               ])
    end

    context '3 vs. 3' do
      let(:pokemon_per_side) { 3 }
      before do
        allow(side2).to receive(:active_in_battle_pokemon) do
          [active_in_battle_pokemon2, active_in_battle_pokemon3, active_in_battle_pokemon4]
        end
        allow(side).to receive(:active_in_battle_pokemon) do
          [subject, active_in_battle_pokemon6, active_in_battle_pokemon7]
        end
      end

      it 'returns targets' do
        expect(subject.valid_move_actions.map { |m| m[:target] })
          .to eq([[side2, 0], [side2, 1], [side, 1]])
      end

      context 'target_adjacent_user_single' do
        let(:target) { 'target_adjacent_user_single' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[side, 1]])
        end
      end

      context 'target_user_or_adjacent_user' do
        let(:target) { 'target_user_or_adjacent_user' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[side, 0], [side, 1]])
        end
      end

      context 'user' do
        let(:target) { 'user' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[side, 0]])
        end
      end

      context 'user_and_random_adjacent_foe' do
        let(:target) { 'user_and_random_adjacent_foe' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[side, 0]])
        end
      end

      context 'all_users' do
        let(:target) { 'all_users' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[[side, 0], [side, 1], [side, 2]]])
        end
      end

      context 'all_adjacent' do
        let(:target) { 'all_adjacent' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[[side2, 0], [side2, 1], [side, 1]]])
        end
      end

      context 'adjacent_foes_all' do
        let(:target) { 'adjacent_foes_all' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[[side2, 0], [side2, 1]]])
        end
      end

      context 'all_foes' do
        let(:target) { 'all_foes' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[[side2, 0], [side2, 1], [side2, 2]]])
        end
      end

      context 'all_except_user' do
        let(:target) { 'all_except_user' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[[side2, 0], [side2, 1], [side2, 2], [side, 1], [side, 2]]])
        end
      end

      context 'all' do
        let(:target) { 'all' }

        it 'returns targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[[side2, 0], [side2, 1], [side2, 2], [side, 0],
                     [side, 1], [side, 2]]])
        end
      end

      context 'not all pokemon in battle' do
        before do
          allow(side2).to receive(:pokemon_in_battle?).with(1).and_return(false)
          allow(side2).to receive(:pokemon_in_battle?).with(2).and_return(false)
          allow(side2).to receive(:pokemon_left?).and_return(true)
        end

        it 'returns available targets' do
          expect(subject.valid_move_actions.map { |m| m[:target] })
            .to eq([[side2, 0], [side, 1]])
        end

        context 'all' do
          let(:target) { 'all' }

          it 'returns targets' do
            expect(subject.valid_move_actions.map { |m| m[:target] })
              .to eq([[[side2, 0], [side2, 1], [side2, 2], [side, 0],
                       [side, 1], [side, 2]]])
          end
        end

        context 'whole side not available' do
          before do
            allow(side2).to receive(:pokemon_in_battle?)
              .with(0).and_return(false)
            allow(side2).to receive(:pokemon_left?).and_return(false)
          end

          it 'returns available targets' do
            expect(subject.valid_move_actions.map { |m| m[:target] })
              .to eq([[side2, 0], [side, 1]])
          end

          context 'all' do
            let(:target) { 'all' }

            it 'returns targets' do
              expect(subject.valid_move_actions.map { |m| m[:target] })
                .to eq([[[side2, 0], [side2, 1], [side2, 2], [side, 0],
                         [side, 1], [side, 2]]])
            end
          end

          context 'all_foes' do
            let(:target) { 'all_foes' }

            it 'returns targets' do
              expect(subject.valid_move_actions.map { |m| m[:target] })
                .to be_empty
            end
          end
        end
      end
    end

    context 'no moves' do
      let(:moves_with_pp) { [] }
      let(:struggle_move) do
        double(:struggle_move,
               target: 'target_adjacent_single')
      end
      before do
        allow(Oakdex::Pokemon::Move).to receive(:new)
          .and_return(struggle_move)
      end

      it 'returns struggle' do
        expect(subject.valid_move_actions).to eq([
                                                   {
                                                     action: 'move',
                                                     pokemon: pokemon,
                                                     move: struggle_move,
                                                     target: [side2, 0]
                                                   }
                                                 ])
      end
    end

    context 'existing move for this pokemon' do
      let(:action_added) { true }
      it { expect(subject.valid_move_actions).to be_empty }
    end
  end
end
