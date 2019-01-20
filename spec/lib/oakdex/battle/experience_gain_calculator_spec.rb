require 'spec_helper'

describe Oakdex::Battle::ExperienceGainCalculator do
  let(:fainted) do
    Oakdex::Battle::Pokemon.create('Pikachu', level: 10)
  end

  let(:winner) do
    Oakdex::Battle::Pokemon.create('Bulbasaur', level: 12)
  end

  let(:flat) { false }

  let(:options) { { flat: flat } }

  describe '.calculate' do
    let(:result) { described_class.calculate(fainted, winner, options) }
    it { expect(result).to eq(269) }

    context 'when the fainted pokemon species is different' do
      let(:fainted) do
        Oakdex::Battle::Pokemon.create('Charmander', level: 10)
      end
      it { expect(result).to eq(159) }
    end

    context 'when the fainted pokemon has a higher level' do
      let(:fainted) do
        Oakdex::Battle::Pokemon.create('Pikachu', level: 15)
      end
      it { expect(result).to eq(575) }
    end

    context 'when the winner pokemon has a higher level' do
      let(:winner) do
        Oakdex::Battle::Pokemon.create('Bulbasaur', level: 14)
      end
      it { expect(result).to eq(231) }
    end

    context 'when the winner affection is more than level 1' do
      let(:winner) do
        Oakdex::Battle::Pokemon.create('Bulbasaur', level: 12, amie: {
          affection: 254
        })
      end
      it { expect(result).to eq(269) }
    end

    context 'when the winner was traded' do
      before do
        allow(winner).to receive(:traded?).and_return(true)
      end
      it { expect(result).to eq(403) }
    end

    context 'when the winner is holding lucky egg' do
      let(:winner) do
        Oakdex::Battle::Pokemon.create('Bulbasaur', level: 12, item_id: 'Lucky Egg')
      end
      it { expect(result).to eq(403) }
    end

    context 'when the winner uses exp share' do
      let(:options) { { flat: flat, winner_using_exp_share: true } }
      it { expect(result).to eq(135) }
    end

    context 'flat' do
      let(:flat) { true }
      it { expect(result).to eq(225) }

      context 'when the fainted pokemon species is different' do
        let(:fainted) do
          Oakdex::Battle::Pokemon.create('Charmander', level: 10)
        end
        it { expect(result).to eq(132) }
      end

      context 'when the fainted pokemon has a higher level' do
        let(:fainted) do
          Oakdex::Battle::Pokemon.create('Pikachu', level: 15)
        end
        it { expect(result).to eq(337) }
      end

      context 'when the winner pokemon has a higher level' do
        let(:winner) do
          Oakdex::Battle::Pokemon.create('Bulbasaur', level: 14)
        end
        it { expect(result).to eq(225) }
      end
    end
  end
end
