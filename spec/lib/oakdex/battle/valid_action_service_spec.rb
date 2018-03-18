require 'spec_helper'

describe Oakdex::Battle::ValidActionService do
  let(:move1) { double(:move, name: 'My Move') }
  let(:moves_with_pp) { [move1] }
  let(:hp) { 12 }
  let(:pokemon1) do
    double(:pokemon,
           moves_with_pp: moves_with_pp,
           current_hp: hp)
  end
  let(:pokemon2) { double(:pokemon) }
  let(:team) { [pokemon1] }
  let(:trainer1) { double(:trainer, team: team) }
  let(:trainer2) { double(:trainer) }
  let(:actions) { [] }
  let(:arena) do
    {
      sides: [
        [[trainer1, [pokemon1]]],
        [[trainer2, [pokemon2]]]
      ]
    }
  end
  let(:battle) do
    double(:battle,
           arena: arena,
           actions: actions,
           team1: [trainer1]
          )
  end
  subject { described_class.new(battle) }

  describe '#valid_actions_for' do
    it 'contains only move action' do
      expect(subject.valid_actions_for(trainer1))
      .to eq([{
               action: 'move',
               pokemon: pokemon1,
               move: 'My Move',
               target: pokemon2
             }])
    end

    context 'no moves available' do
      let(:moves_with_pp) { [] }

      it 'contains only struggle move action' do
        expect(subject.valid_actions_for(trainer1))
        .to eq([{
                 action: 'move',
                 pokemon: pokemon1,
                 move: 'Struggle',
                 target: pokemon2
               }])
      end
    end

    context 'second pokemon' do
      let(:pokemon3) { double(:pokemon, current_hp: 12) }
      let(:team) { [pokemon1, pokemon3] }

      it 'contains recall too' do
        expect(subject.valid_actions_for(trainer1))
        .to eq([{
                 action: 'move',
                 pokemon: pokemon1,
                 move: 'My Move',
                 target: pokemon2
               },
                {
                  action: 'recall',
                  pokemon: pokemon1,
                  target: pokemon3
                }])
      end

      context 'pokemon in arena fainted' do
        let(:hp) { 0 }
        let(:arena) do
          {
            sides: [
              [[trainer1, []]],
              [[trainer2, [pokemon2]]]
            ]
          }
        end

        it 'contains recall only' do
          expect(subject.valid_actions_for(trainer1))
          .to eq([
                   {
                     action: 'recall',
                     pokemon: nil,
                     target: pokemon3
                   }])
        end
      end

      context 'but without hp' do
        let(:pokemon3) { double(:pokemon, current_hp: 0) }

        it 'does not contain recall' do
          expect(subject.valid_actions_for(trainer1))
          .to eq([{
                   action: 'move',
                   pokemon: pokemon1,
                   move: 'My Move',
                   target: pokemon2
                 }])
        end
      end
    end
  end
end
