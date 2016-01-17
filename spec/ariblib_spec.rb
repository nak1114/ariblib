require 'spec_helper'

describe Ariblib do
  it 'has a version number' do
    expect(Ariblib::VERSION).not_to be nil
  end
	describe :FIFO do
		let(:fifo){Ariblib::FIFO.new([0xaa,1,2,3,4,5,6,7,8])}
	  it '#getbyte' do
			expect(fifo.getbyte).to be 0xaa
	  end
		it '#size' do
			expect(fifo.size).to be 9*8
		end
		it '#add' do
			expect(fifo.add([0xaa,1])).to eq [0xaa,1,2,3,4,5,6,7,8,0xaa,1]
		end
		it '#clear' do
			expect(fifo.clear).to eq []
		end
		it '#eof?' do
			expect(fifo.eof?).to be false
		end
		context 'after clear' do
			before do
				fifo.clear
			end
		  it '#getbyte' do
				expect(fifo.getbyte).to be nil
		  end
			it '#size' do
				expect(fifo.size).to be 0
			end
			it '#add' do
				expect(fifo.add([0xaa,1])).to eq [0xaa,1]
			end
			it '#eof?' do
				expect(fifo.eof?).to be true
			end
		end
	end

end
