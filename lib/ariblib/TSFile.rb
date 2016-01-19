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
		def << (buf)
			@buf << buf
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
		end
		def read(size)
			pos =@bitstream_postion>>3
			modd=@bitstream_postion&0x07
			@bitstream_postion+=size
			mod =(((@bitstream_postion)^0x07).succ)&0x07
			poss=((size+modd+7)>>3)
			tmp=0
			poss.times do |i|
				tmp<<=8
				tmp|=@bitstream_buffer.getbyte(pos+i)
			end
			tmpd = (tmp>>mod) & ((1<<size)-1)
			return tmpd
		end
		def lest
			@bitstream_buffer.size*8-@bitstream_postion
		end
		def buf
			@bitstream_buffer
		end
		def buf=(a)
			@bitstream_buffer=a
		end
		def pos
			@bitstream_postion
		end
		def pos=(a)
			@bitstream_postion=a
		end
	end

	class TransportStreamFile
		attr_reader :bs
		attr_reader :payload
		attr_reader :payload_ap
		attr_reader :payload_unit_start_indicator
		attr_reader :pid
		attr_reader :adaptation_field_control

		def initialize(filename,pid_list=[0x00,0x12,0x13,0x14])
			@bs=BitStream.new(open(filename,'rb').read)
			@payload=Hash.new{|k,v|k[v]=''.force_encoding('ASCII-8BIT')}
			@payload_ap=Hash.new(0)
			@target_pid=[0x00,0x12,0x26,0x27,0x14]
		end

		def eof?
			@bs.lest<=0
		end

		def sync
			while(@bs.lest>0 and (c=@bs.read(8))!=0x47) do
			end
			return false if @bs.lest<=0
			@bs.pos-=8
			true
		end

		def transport_packet
			count                         = @bs.pos+188*8
			sync_byte                     = @bs.read  8 #bslbf'0x47'
			return :async unless sync_byte==0x47
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
				adaptation_field_length   += 1 #uimsbf
				@bs.pos+=adaptation_field_length
			end
			n=(count)-@bs.pos
			if(adaptation_field_control==1 || adaptation_field_control==3 )
				if @target_pid.include? pid then
					@payload[@pid]+=@bs.buf.byteslice(@bs.pos/8, n/8)
				end
				@payload_ap[@pid]+=1
			end
			@bs.pos=count
			true
		end

	end
end

__END__
