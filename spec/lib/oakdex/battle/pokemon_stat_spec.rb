require 'spec_helper'

describe Oakdex::Battle::PokemonStat do
  describe '.initial_stat' do
    let(:stat) { :hp }
    let(:level) { 12 }
    let(:iv) { 15 }
    let(:ev) { 0 }
    let(:base_stat) { 80 }
    let(:increased_stat) { nil }
    let(:decreased_stat) { nil }
    let(:nature) do
      double(
        :nature,
        increased_stat: increased_stat,
        decreased_stat: decreased_stat
      )
    end
    let(:options) do
      {
        level: level,
        iv: { :"#{stat}" => iv },
        ev: { :"#{stat}" => ev },
        base_stats: { "#{stat}" => base_stat },
        nature: nature
      }
    end
    subject { described_class.initial_stat(stat, options) }

    it { expect(subject).to eq(43) }

    context 'higher level' do
      let(:level) { 20 }
      it { expect(subject).to eq(65) }
    end

    context 'higher iv' do
      let(:iv) { 30 }
      it { expect(subject).to eq(44) }
    end

    context 'higher ev' do
      let(:ev) { 40 }
      it { expect(subject).to eq(44) }
    end

    context 'base stat' do
      let(:base_stat) { 120 }
      it { expect(subject).to eq(52) }
    end

    context 'other stat' do
      let(:stat) { :atk }

      it { expect(subject).to eq(26) }

      context 'with positive nature' do
        let(:increased_stat) { 'atk' }
        it { expect(subject).to eq((26 * 1.1).to_i) }
      end

      context 'with negative nature' do
        let(:decreased_stat) { 'atk' }
        it { expect(subject).to eq((26 * 0.9).to_i) }
      end
    end
  end

  describe '.level_by_exp' do
    let(:exp) { 158 }
    subject { described_class.level_by_exp(leveling_rate, exp) }

    context 'Slow' do
      let(:leveling_rate) { 'Slow' }
      it { expect(subject).to eq(5) }

      context 'exact exp' do
        let(:exp) { 156 }
        it { expect(subject).to eq(5) }
      end

      context 'one less' do
        let(:exp) { 155 }
        it { expect(subject).to eq(4) }
      end
    end
  end

  describe '.exp_by_level' do
    let(:level) { 5 }
    subject { described_class.exp_by_level(leveling_rate, level) }

    context 'Slow' do
      let(:leveling_rate) { 'Slow' }
      it { expect(subject).to eq(156) }
    end

    context 'Fast' do
      let(:leveling_rate) { 'Fast' }
      it { expect(subject).to eq(100) }
    end

    context 'Medium Fast' do
      let(:leveling_rate) { 'Medium Fast' }
      it { expect(subject).to eq(125) }
    end

    context 'Medium Slow' do
      let(:leveling_rate) { 'Medium Slow' }
      it { expect(subject).to eq(135) }
    end

    context 'Fluctuating' do
      let(:leveling_rate) { 'Fluctuating' }
      it { expect(subject).to eq(65) }

      context 'level bigger than 15' do
        let(:level) { 20 }
        it { expect(subject).to eq(5440) }
      end

      context 'level bigger than 36' do
        let(:level) { 40 }
        it { expect(subject).to eq(66_560) }
      end
    end
  end
end
