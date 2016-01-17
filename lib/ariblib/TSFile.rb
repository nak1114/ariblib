module Ariblib
	class FIFO
		attr_accessor :buf
		def initialize(buf)
			@buf=buf
		end
		def getbyte
			@buf.shift
		end
		def add(buf)
			@buf += buf
		end
		def clear
			@buf.clear
		end
		def size
			@buf.size * 8
		end
		def eof?
			@buf.size == 0
		end
	end

	class BitStream
		def initialize(buf)
			@bitstream_buffer=buf
			@bitstream_postion=0
			@bitstream_content=0
		end
		def read(size)
			while(@bitstream_postion<size) do
				@bitstream_postion+=8
				@bitstream_content<<=8
				@bitstream_content+=(@bitstream_buffer.getbyte||0)
			end
			@bitstream_postion-=size
			tmp = (@bitstream_content>>@bitstream_postion) & ((1<<size)-1)
			return tmp
		end
		def buf
			@bitstream_buffer
		end
	end

	class TransportStreamFile
		attr_reader :bs
		attr_reader :payload
		attr_reader :payload_ap
		attr_reader :payload_unit_start_indicator
		attr_reader :pid
		attr_reader :adaptation_field_control

		def initialize(filename)
			@bs=BitStream.new(open(filename,'rb'))
			@payload=Hash.new{|k,v|k[v]=[]}
			@payload_ap=Hash.new(0)
		end

		def eof?
			@bs.buf.eof?
		end

		def sync
			while(not @bs.buf.eof? and (c=@bs.read(8))!=0x47) do
			end
			@bs.buf.seek(-1,IO::SEEK_CUR) unless @bs.buf.eof?
			return false if @bs.buf.eof?
			true
		end

		def transport_packet
			adaptation_field_length       = -1
			sync_byte                     = @bs.read  8 #bslbf'0x47'
			return false unless sync_byte==0x47
			transport_error_indicator     = @bs.read  1 #bslbf
			@payload_unit_start_indicator = @bs.read  1 #bslbf
			transport_priority            = @bs.read  1 #bslbf
			@pid                          = @bs.read  13 #uimsbf
			transport_scrambling_control  = @bs.read  2 #bslbf
			@adaptation_field_control     = @bs.read  2 #bslbf
			continuity_counter            = @bs.read  4 #uimsbf
			if(adaptation_field_control==2 || adaptation_field_control==3)
				#adaptation_field()
				adaptation_field_length    = @bs.read  8 #uimsbf
				adaptation_field_length   += 1
				adaptation_field_length.times{@bs.read  8}
			end
			n=188-5-adaptation_field_length
			if(adaptation_field_control==1 || adaptation_field_control==3)
				n.times{ @payload[@pid] << @bs.read(8)}
				@payload_ap[@pid]+=1
			else
				n.times{ @bs.read(8)}
			end
			true
		end

	end
end

__END__
