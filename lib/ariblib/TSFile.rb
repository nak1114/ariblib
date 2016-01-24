#! ruby
# -*- encoding: utf-8 -*-
require 'pry'

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

	#TSパケット
	class TransportStreamPacket
		def initialize
		end
		def set(ts)
		end
	end

	#TSファイル
	class TransportStreamFile
		attr_reader :payload_ap
		attr_reader :pid
		attr_reader :adaptation_field_control
		attr_reader :packet_start_pos


		attr_reader :payload
		attr_reader :bs
		attr_reader :continuity_counter
		attr_reader :payload_unit_start_indicator
		attr_reader :payload_length

		Default_payload={
			0x12 => EventInformationTable.new
		}
		ReadSize=188*20
		def initialize(filename,payload_list=Default_payload)
			@file=open(filename,'rb')
			@bs=BitStream.new(@file.read(ReadSize))
			@payload=payload_list
			@payload.default=TransportStreamPacket.new
			@payload.merge!(payload_list)
			@payload_ap=Hash.new(0)
			@packet_count=0
		end

		def eof?
			@file.eof? && (@bs.lest <= 0)
		end

		def close
			@file.close
		end

		def sync
			while(@bs.lest>0 and (c=@bs.read(8))!=0x47) do
			end
			return false if @bs.lest<=0
			@bs.pos-=8
			true
		end

		def transport_packet
			@bs=BitStream.new(@file.read(ReadSize)) if @bs.lest <= 0
			packet_start_pos              = @bs.pos
			sync_byte                     = @bs.getc
			return :async unless sync_byte==0x47
			tmp                           = @bs.getc
			tmp=(tmp<<8)|                   @bs.getc
			#transport_error_indicator     = @bs.read  1 #bslbf
			#@payload_unit_start_indicator = @bs.read  1 #bslbf
			#transport_priority            = @bs.read  1 #bslbf
			#@pid                          = @bs.read  13 #uimsbf
			transport_error_indicator     = tmp & 0x8000 #1 bslbf
			@payload_unit_start_indicator = tmp & 0x4000 #1 bslbf
			transport_priority            = tmp & 0x2000 #1 bslbf
			@pid                          = tmp & 0x1fff #13 uimsbf
			tmp                           = @bs.getc
			#transport_scrambling_control  = @bs.read  2 #bslbf
			#@adaptation_field_control     = @bs.read  2 #bslbf
			#@continuity_counter           = @bs.read  4 #uimsbf
			transport_scrambling_control  = tmp & 0xc0 #2 bslbf
			adaptation_field_control1     = tmp & 0x20 #2 bslbf
			adaptation_field_control2     = tmp & 0x10 #2 bslbf
			@continuity_counter           = tmp & 0x0f #4 uimsbf
			if(adaptation_field_control1 !=0 )
				#adaptation_field()
				@adaptation_field_length    = @bs.getc
				@adaptation_field_length   += 1 #uimsbf
				@adaptation_pos=@bs.pos
				@bs.pos+=@adaptation_field_length
			end
			count = packet_start_pos+188*8
			@payload_length=((count)-@bs.pos)/8
			if(adaptation_field_control2 !=0 )
				@payload[@pid].set(self)
				@payload_ap[@pid]+=1
			end
			@bs.pos=count
			true
		end

	end
end

__END__
