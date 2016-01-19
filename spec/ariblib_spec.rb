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
		it '#<<' do
			expect(fifo << 0xaa).to eq [0xaa,1,2,3,4,5,6,7,8,0xaa]
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
			it '#<<' do
				expect(fifo << 0xaa).to eq [0xaa]
			end
			it '#eof?' do
				expect(fifo.eof?).to be true
			end
		end
	end
	describe :BitStream do
		let(:bs){Ariblib::BitStream.new([0xaa,1,2,3,4,5,6,7,8].pack("C*"))}
		it '#read 8' do
			expect(bs.read 8).to be 0xaa
		end
		it '#read 7' do
			expect(bs.read 7).to be 0x55
		end
		it '#lest' do
			expect(bs.lest).to be 72
		end
		context 'after read 1' do
			before do
				bs.read 1
			end
			it '#read 8' do
				expect(bs.read 8).to be 0x54
			end
			it '#read 16' do
				expect(bs.read 16).to be 0x5402
			end
			it '#lest' do
				expect(bs.lest).to be 71
			end
		end
	end

end
