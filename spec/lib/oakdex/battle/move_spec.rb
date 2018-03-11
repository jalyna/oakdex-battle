require 'spec_helper'

describe Oakdex::Battle::Move do
  let(:move_type) { Oakdex::Pokedex::Move.find('Thunder Shock') }
  subject { described_class.new(move_type, 30, 30) }

  describe '#name' do
    it { expect(subject.name).to eq('Thunder Shock') }
  end

  describe '#pp' do
    it { expect(subject.pp).to eq(30) }
  end

  %i[target priority accuracy].each do |attr|
    describe "##{attr}" do
      it {
        expect(subject.public_send(attr))
        .to eq(move_type.public_send(attr))
      }
    end
  end
end
