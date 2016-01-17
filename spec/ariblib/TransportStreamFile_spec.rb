require 'spec_helper'

describe Ariblib::TransportStreamFile do
	let(:ts){Ariblib::TransportStreamFile.new('spec/data/test_aa.ts')}
	it '#sync' do
		expect(ts.sync).to be true
		expect(ts.bs.buf.pos).to be 0
	end
	it '#transport_packet' do
		while(not ts.eof?) do
			unless ts.transport_packet
				break
			end
		end
		expect(ts.payload_ap).to eq ({18 => 5})
		expect(ts.bs.buf.pos).to be 940
	end
	context 'after read 8' do
		before do
			ts.bs.read 8
		end
		it '#sync' do
			expect(ts.sync).to be true
			expect(ts.bs.buf.pos).to be 188
		end
	end
end
