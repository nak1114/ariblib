#! ruby
# -*- encoding: utf-8 -*-

module Ariblib

	#PSI TSペイロード
	class ProgramSpecificInformation
		def initialize
			@buf=''.force_encoding('ASCII-8BIT')
			@count=nil
			@length=nil
		end
		def init_buf
			@buf.clear
			@length=nil
		end

		def set_buf(buf)
			return unless @count
			@buf+=buf
			@length=(((@buf.getbyte(1)<<8) + @buf.getbyte(2))&0x0fff)+3 if (@length==nil) && (@buf.length>=3)
			if @buf.length>=@length
				parse_buf 
				@count=nil
			else
				@count=(@count+1)&0x0f
			end
		end
		
		def set(ts)
			@count=nil if ts.continuity_counter != @count
			buf=ts.bs.str(ts.payload_length)

			if ts.payload_unit_start_indicator != 0
				set_buf(buf.byteslice(1,188))

				@count=ts.continuity_counter
				init_buf
				set_buf(buf.byteslice(buf.getbyte(0)+1,188))
			else
				set_buf(buf)
			end
		end
		
		def descriptor(bs,len)
			h={}
			ret=[]
			len+=bs.pos
			while bs.pos < len
				descriptor_tag     =bs.read 8 #uimsbf
				h[:tag]=descriptor_tag
				ret << DescriptorTag[descriptor_tag].new(h,bs)
			end
			bs.pos=len
			ret
		end
	end
	class EventInformationTable < ProgramSpecificInformation
		attr_reader :event
		def parse_buf
			bs=BitStream.new(@buf)
			@event||=[]
			#event_information_section(){
			table_id                     =bs.read 8 #uimsbf
			section_syntax_indicator     =bs.read 1 #bslbf
			reserved_future_use          =bs.read 1 #bslbf
			reserved                     =bs.read 2 #bslbf
			section_length               =bs.read 12 # < 4096 -3
			service_id                   =bs.read 16 #uimsbf
			reserved                     =bs.read 2 #bslbf
			version_number               =bs.read 5 #uimsbf
			current_next_indicator       =bs.read 1 #bslbf
			section_number               =bs.read 8 #uimsbf
			last_section_number          =bs.read 8 #uimsbf
			transport_stream_id          =bs.read 16 #uimsbf
			original_network_id          =bs.read 16 #uimsbf
			segment_last_section_number  =bs.read 8 #uimsbf
			last_table_id                =bs.read 8 #uimsbf

			len=(section_length+3-4)*8
			while bs.pos < len
				event_id                   =bs.read 16 #uimsbf
				start_time                 =bs.read 40 #bslbf
				duration                   =bs.read 24 #uimsbf
				running_status             =bs.read 3 #uimsbf
				free_CA_mode               =bs.read 1 #bslbf
				descriptors_loop_length    =bs.read 12 #uimsbf
				desc = descriptor(bs,descriptors_loop_length*8)
				@event << [service_id,event_id,start_time,duration,desc]
			end
			cCRC_32 =bs.read 32 #rpchof
		end
	end
	class ServiceDescriptionTable < ProgramSpecificInformation
		def parse_buf
			bs=BitStream.new(@buf)
			#service_description_section(){
			table_id                  =bs.read 8 #uimsbf
			section_syntax_indicator  =bs.read 1 #bslbf
			reserved_future_use       =bs.read 1 #bslbf
			reserved                  =bs.read 2 #bslbf
			section_length            =bs.read 12 #uimsbf# < 1024 -3
			transport_stream_id       =bs.read 16 #uimsbf
			reserved                  =bs.read 2 #bslbf
			version_number            =bs.read 5 #uimsbf
			current_next_indicator    =bs.read 1 #bslbf
			section_number            =bs.read 8 #uimsbf
			last_section_number       =bs.read 8 #uimsbf
			original_network_id       =bs.read 16 #uimsbf
			reserved_future_use       =bs.read 8 #bslbf
			
			len=(section_length+3-4)*8
			while bs.pos < len
				service_id                  =bs.read 16 #uimsbf
				reserved_future_use         =bs.read 3 #bslbf
				fEIT_user_defined_flags     =bs.read 3 #bslbf
				fEIT_schedule_flag          =bs.read 1 #bslbf
				fEIT_present_following_flag =bs.read 1 #bslbf
				running_status              =bs.read 3 #uimsbf
				free_CA_mode                =bs.read 1 #bslbf
				descriptors_loop_length     =bs.read 12 #uimsbf
				descriptor(bs,descriptors_loop_length*8)
			end
			cCRC_32  =bs.read 32 #rpchof
		end
	end
end
