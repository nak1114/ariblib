#!ruby
# -*- encoding: utf-8 -*-
require 'date'

module Ariblib

	#PSI TSペイロード
	class ProgramSpecificInformation
		def initialize
			@buf=''.force_encoding('ASCII-8BIT')
			@count=nil
			@length=nil
			@contents=[]
			@descriptor_set=DescriptorTag
		end
		def init_buf
			@buf.clear
			@length=nil
		end

		def set_buf(ts,buf)
			return unless @count
			@buf+=buf
			@length=(((@buf.getbyte(1)<<8) | @buf.getbyte(2))&0x0fff)+3 if (@length==nil) && (@buf.length>=3)
			if @buf.length>=@length
				@ts=ts
				tmp =parse_buf 
				@contents << tmp if tmp 
				@count=nil
			else
				@count=(@count+1)&0x0f
			end
		end
		
		def set(ts)
			@count=nil if ts.continuity_counter != @count
			buf=ts.bs.str(ts.payload_length)

			if ts.payload_unit_start_indicator != 0
				set_buf(ts,buf.byteslice(1,188))

				@count=ts.continuity_counter
				init_buf
				set_buf(ts,buf.byteslice(buf.getbyte(0)+1,188))
			else
				set_buf(ts,buf)
			end
		end
		
		def arib_to_utf8(buf)
					Ariblib::String.new(Ariblib::BitStream.new(buf),buf.length).to_utf8
		end
		def descriptor(bs,len)
			return nil if len==0
			h={:tag => [],
				:verbose_pair=>[],
				:verbose=>''.force_encoding('ASCII-8BIT'),
			}

			len=bs.pos+len*8
			while bs.pos < len
				descriptor_tag     =bs.getc #8 uimsbf
				descriptor_length  =bs.getc #8 uimsbf
				len2=bs.pos+descriptor_length*8
				@descriptor_set[descriptor_tag].new(h,bs,descriptor_tag,descriptor_length)
				bs.pos=len2
			end
			bs.pos=len
			h[:verbose_pair]=h[:verbose_pair].map{|v|[v[0],arib_to_utf8(v[1])]}
			h[:verbose]=arib_to_utf8(h[:verbose])
			h.delete :verbose_pair if h[:verbose_pair].size==0
			h.delete :verbose if h[:verbose].size==0
			h
		end
		attr_reader :contents
	end
	class ServiceDescriptionTable < ProgramSpecificInformation #< 1Kbyte
		def parse_buf
			ret=[]
			bs=BitStream.new(@buf)
			#service_description_section(){
			table_id                  =bs.read 8 #uimsbf
			#staff_table if table_id == 0x72
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
			ret << [table_id,original_network_id,transport_stream_id]
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
				desc=descriptor(bs,descriptors_loop_length)
				ret << [service_id,desc]
			end
			cCRC_32  =bs.read 32 #rpchof
			ret
		end
	end
	class ProgramAssociationTable < ProgramSpecificInformation #< 1Kbyte
		def parse_buf
			bs=BitStream.new(@buf)
			table_id                  =bs.read 8 #uimsbf
			section_syntax_indicator  =bs.read 1 #bslbf
			reserved_future_use       =bs.read 1 #bslbf
			reserved                  =bs.read 2 #bslbf
			section_length            =bs.read 12 #uimsbf
			transport_stream_id       =bs.read 16 #uimsbf
			reserved                  =bs.read 2 #bslbf
			version_number            =bs.read 5 #uimsbf
			current_next_indicator    =bs.read 1 #bslbf
			section_number            =bs.read 8 #uimsbf
			last_section_number       =bs.read 8 #uimsbf
			count=(section_length-5-4)/4
			count.times do
				program_number          =bs.read 16 #uimsbf
				reserved                =bs.read 3 #bslbf
				if(program_number == 0)
					network_PID           =bs.read 13 #uimsbf
				else
					program_map_PID       =bs.read 13 #uimsbf
				end
			end
			cCRC_32  =bs.read 32 #rpchof
			nil
		end
	end
	class ProgramMapTable < ProgramSpecificInformation #< 1Kbyte
		def parse_buf
		#TS_program_map_section() 
			bs=BitStream.new(@buf)
			table_id                  =bs.read 8 #uimsbf
			section_syntax_indicator  =bs.read 1 #bslbf
			reserved_future_use       =bs.read 1 #bslbf
			reserved                  =bs.read 2 #bslbf
			section_length            =bs.read 12 #uimsbf
			len=section_length*8+bs.pos-32
			program_number          =bs.read 16 #uimsbf
			reserved                =bs.read 2 #bslbf
			version_number          =bs.read 5 #uimsbf
			current_next_indicator  =bs.read 1 #bslbf
			section_number          =bs.read 8 #uimsbf
			last_section_number     =bs.read 8 #uimsbf
			reserved                =bs.read 3 #bslbf
			iPCR_PID                =bs.read 13 #uimsbf
			reserved                =bs.read 4 #bslbf
			program_info_length     =bs.read 12 #uimsbf
			descriptor(bs,program_info_length)

			while(bs.pos < len)
				stream_type     =bs.read 8 #uimsbf
				reserved        =bs.read 3 #bslbf
				elementary_PID  =bs.read 13 #uimsnf
				reserved        =bs.read 4 #bslbf
				es_info_length  =bs.read 12 #uimsbf
				descriptor(bs,es_info_length)
			end
			cCRC_32  =bs.read 32 #rpchof
			nil
		end
	end
	class ConditionalAccessTable < ProgramSpecificInformation #< 1Kbyte
		def parse_buf
			bs=BitStream.new(@buf)
			table_id                  =bs.read 8 #uimsbf
			section_syntax_indicator  =bs.read 1 #bslbf
			reserved_future_use       =bs.read 1 #bslbf
			reserved                  =bs.read 2 #bslbf
			section_length            =bs.read 12 #uimsbf
			reserved                  =bs.read 18 #bslbf
			version_number            =bs.read 5 #uimsbf
			current_next_indicator    =bs.read 1 #bslbf
			section_number            =bs.read 8 #uimsbf
			last_section_number       =bs.read 8 #uimsbf
			count=section_length-9
			descriptor(bs,count)
			cCRC_32                   =bs.read 32 #rpchof
			nil
		end
	end
	class NetworkInformationTable < ProgramSpecificInformation #< 1Kbyte
		def parse_buf
			ret=[]
			bs=BitStream.new(@buf)
			table_id                        =bs.read 8 #uimsbf
			section_syntax_indicator        =bs.read 1 #bslbf
			reserved_future_use             =bs.read 1 #bslbf
			reserved                        =bs.read 2 #bslbf
			section_length                  =bs.read 12 #uimsbf
			network_id                      =bs.read 16 #uimsbf
			reserved                        =bs.read 2 #bslbf
			version_number                  =bs.read 5 #uimsbf
			current_next_indicator          =bs.read 1 #bslbf
			section_number                  =bs.read 8 #uimsbf
			last_section_number             =bs.read 8 #uimsbf
			reserved_future_use             =bs.read 4 #bslbf
			network_descriptors_length      =bs.read 12 #uimsbf
			desc=descriptor(bs,network_descriptors_length)
			ret << [:NIT,table_id,desc]
			reserved_future_use             =bs.read 4 #bslbf
			transport_stream_loop_length    =bs.read 12 #uimsbf
			
			len=bs.pos+transport_stream_loop_length*8
			while bs.pos < len
				transport_stream_id           =bs.read 16 #uimsbf
				original_network_id           =bs.read 16 #uimsbf
				reserved_future_use           =bs.read 4 #bslbf
				transport_descriptors_length  =bs.read 12 #uimsbf
				desc=descriptor(bs,transport_descriptors_length)
				ret << [transport_stream_id,original_network_id,desc]
			end
			cCRC_32                         =bs.read 32 #rpchof
			ret
		end
	end
	class TimeOffsetTable < ProgramSpecificInformation #< 1Kbyte
		def parse_buf
			ret=nil
			bs=BitStream.new(@buf)
			table_id                        =bs.read 8 #uimsbf
			section_syntax_indicator        =bs.read 1 #bslbf
			reserved_future_use             =bs.read 1 #bslbf
			reserved                        =bs.read 2 #bslbf
			section_length                  =bs.read 12 #uimsbf
			jst_time                        =bs.read 40 #bslbf
			if table_id == 0x73
				reserved  =bs.read 4 #bslbf
				descriptors_loop_length  =bs.read 12 #uimsbf
				desc=descriptor(bs,descriptors_loop_length)
				ret=[jst_time,desc]
			else
				ret=[jst_time]
			end
			cCRC_32                         =bs.read 32 #rpchof
			ret
		end
		def to_datetime(n=0)
			dat=@contents[n]
			return nil unless dat
			jst=dat[0]
			sec1  =(jst>> 0)&0x0f
			sec10 =(jst>> 4)&0x0f
			min1  =(jst>> 8)&0x0f
			min10 =(jst>>12)&0x0f
			hour1 =(jst>>16)&0x0f
			hour10=(jst>>20)&0x0f
			mjd   =(jst>>24)+2400001
			return DateTime.jd(mjd,hour10*10+hour1,min10*10+min1,sec10*10+sec1)#+Rational(1,24*60)
		end
	end
	class CommonDataTable < ProgramSpecificInformation #< 1Kbyte
		def parse_buf
			ret=nil
			bs=BitStream.new(@buf)
			table_id                        =bs.read 8 #uimsbf
			section_syntax_indicator        =bs.read 1 #bslbf
			reserved_future_use             =bs.read 1 #bslbf
			reserved                        =bs.read 2 #bslbf
			section_length                  =bs.read 12 #uimsbf

			download_data_id    =bs.read 16 #uimsbf
			reserved            =bs.read 2 #bslbf
			version_number      =bs.read 5 #uimsbf
			current_next_indicator =bs.read 1 #bslbf
			section_number      =bs.read 8 #uimsbf
			last_section_number =bs.read 8 #uimsbf
			original_network_id =bs.read 16 #uimsbf
			data_type           =bs.read 8 #uimsbf =0x01
			reserved_future_use =bs.read 4 #bslbf
			descriptors_loop_length =bs.read 12 #uimsbf
			desc=descriptor(bs,descriptors_loop_length)

			ret = 'ddid=%04x vid=%02x onid=%04x type=%02x' % [
					download_data_id,
					version_number,
					original_network_id,
					data_type]

			if data_type == 0x01
				logo_type            =bs.read 8 #uimsbf
				reserved_future_use  =bs.read 7 #bslbf
				logo_id              =bs.read 9 #uimsbf
				reserved_future_use  =bs.read 4 #bslbf
				logo_version         =bs.read 12 #uimsbf
				data_size            =bs.read 16 #uimsbf
				data_byte            =bs.str data_size
				ret = ['ddid=%04x vid=%02x onid=%04x type=%02x loid=%02x lver=%03x dt=%s' % [
					download_data_id,
					version_number,
					original_network_id,
					logo_type,logo_id,logo_version,data_byte],desc]
				
			else
				len=(section_length+3)-10-descriptors_loop_length-4
				data_module_byte =bs.str len
			end

			cCRC_32                         =bs.read 32 #rpchof
			ret
		end
	end
end
__END__
data_module_byte(){
