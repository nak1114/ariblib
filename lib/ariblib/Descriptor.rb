#! ruby
# -*- encoding: utf-8 -*-

module Ariblib
	#記述子
	class Descriptor
		def initialize(h,bs,tag,length)
			parse(h,bs,tag,length)
		end
		def parse(h,bs,tag,descriptor_length)
			h[:tag] << tag
		end
	end

	class ShortEventDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
		
			iso_639_language_code  =bs.get3 #24 bslbf
			event_name_length      =bs.getc #8 uimsbf
			event_name_char       =Ariblib::String.new(bs,event_name_length).to_utf8
			text_length            =bs.getc #8 uimsbf
			text_char             =Ariblib::String.new(bs,text_length).to_utf8
			h[:title]=event_name_char
			h[:desc ]=text_char
		end
	end
	class ExtendedEventDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			descriptor_number      =bs.read 4 #uimsbf
			last_descriptor_number =bs.read 4 #uimsbf
			iso_639_language_code  =bs.get3 #24 bslbf
			length_of_items        =bs.getc #8 uimsbf
			len=bs.pos+length_of_items*8
			while bs.pos < len
				item_description_length =bs.getc #8 uimsbf
				item_description_char   =Ariblib::String.new(bs,item_description_length).to_utf8
				item_length             =bs.getc #8 uimsbf
				item_char               =bs.str(item_length)
				if item_description_length==0
					(h[:verbose_pair].last)[1] += item_char
				else
					h[:verbose_pair] << [item_description_char,item_char]
				end
				#item_char               =Ariblib::String.new(bs,item_length).to_utf8
				#h[item_description_char]||=[]
				#h[item_description_char] << item_char
				#verbose << [item_description_char,item_char]
			end
			text_length            =bs.getc #8 uimsbf
			text_char             =bs.str(text_length)
			h[:verbose] += text_char
		end
	end
	class ContentDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			content_nibble_level_1=bs.read 4
			content_nibble_level_2=bs.read 4
			bs.pos+=descriptor_length-1
			h[:content]=[content_nibble_level_1,content_nibble_level_2]
		end
	end
	class ServiceDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			service_type          =bs.read 8 #uimsbf
			service_provider_name_length =bs.read 8 #uimsbf
			service_provider_name =Ariblib::String.new(bs,service_provider_name_length).to_utf8#bs.str(service_provider_name_length)
			service_name_length    =bs.read 8 #uimsbf
			service_name          =Ariblib::String.new(bs,service_name_length).to_utf8#bs.str(service_name_length)
			h[:service_type]=service_type
			h[:service_provider_name]=service_provider_name
			h[:service_name]=service_name
		end
	end
	class DataContentDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			data_component_id     = bs.read 16 #uimsbf
			entry_component       = bs.getc #8 uimsbf
			selector_length       = bs.getc #8 uimsbf
			selector_byte         = bs.str(selector_length)
			num_of_component_ref  = bs.getc #8 uimsbf
			component_ref         = bs.str(num_of_component_ref)

			iso_639_language_code = bs.read 24 #bslbf
			text_length           = bs.getc #8 uimsbf
			text_char = Ariblib::String.new(bs,text_length).to_utf8
			h[:data_component]=text_char
		end
	end
	class AudioComponentDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			text_length = descriptor_length - 9#8 uimsbf
			reserved_future_use        = bs.read 4 #bslbf
			stream_content             = bs.read 4 #uimsbf
			component_type             = bs.getc #8 uimsbf
			component_tag              = bs.getc #8 uimsbf
			stream_type                = bs.getc #8 uimsbf
			simulcast_group_tag        = bs.getc #8 bslbf
			es_multi_lingual_flag      = bs.read 1 #bslbf
			main_component_flag        = bs.read 1 #bslbf
			quality_indicator          = bs.read 2 #bslbf
			sampling_rate              = bs.read 3 #uimsbf
			reserved_future_use        = bs.read 1 #bslbf
			iso_639_language_code      = bs.read 24 #bslbf
			if (es_multi_lingual_flag == 1)
				iso_639_language_code_2  = bs.read 24 #bslbf
				text_length-= 3
			end
			text_char = Ariblib::String.new(bs,text_length).to_utf8
			h[:audio_component]=text_char
		end
	end
	class ComponentDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			text_length = descriptor_length - 6#8 uimsbf
			reserved_future_use    = bs.read 4 #bslbf
			stream_content         = bs.read 4 #uimsbf
			component_type         = bs.getc #8 uimsbf
			component_tag          = bs.getc #8 uimsbf
			iso_639_language_code  = bs.read 24 #bslbf
			text_char = Ariblib::String.new(bs,text_length).to_utf8
			h[:component]=text_char
		end
	end
	class EventGroupDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			list=[]
			#event_group_descriptor (){
			group_type   = bs.read 4 #uimsbf
			event_count  = bs.read 4 #uimsbf
			event_count.times do 
				service_id = bs.read 16 #uimsbf
				event_id   = bs.read 16 #uimsbf
				list <<[service_id,event_id]
			end
			if(group_type == 4 || group_type ==5)
				len=(descriptor_length-1-event_count*4)/8
				len.times do
					original_network_id  = bs.read 16 #uimsbf
					transport_stream_id  = bs.read 16 #uimsbf
					service_id           = bs.read 16 #uimsbf
					event_id             = bs.read 16 #uimsbf
				end
			else
				len=(descriptor_length-1-event_count*4)
				private_data_byte = bs.str len #uimsbf
			end
			h[:event_group]=[group_type,list]
		end
	end
	class LogoTransmissionDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			#h[:tag] << :digital_copy_control
			logo_transmission_type = bs.read 8 #uimsbf
			if(logo_transmission_type == 0x01)
				reserved_future_use  = bs.read 7 #bslbf
				logo_id              = bs.read 9 #uimsbf
				reserved_future_use  = bs.read 4 #bslbf
				logo_version         = bs.read 12 #uimsbf
				download_data_id     = bs.read 16 #uimsbf
				h[:logo]=[logo_id,logo_version,download_data_id]
			elsif(logo_transmission_type == 0x02)
				reserved_future_use  = bs.read 7 #bslbf
				logo_id              = bs.read 9 #uimsbf
				h[:logo]=[logo_id]
			elsif(logo_transmission_type == 0x03)
				len=(descriptor_length-1)
				logo_char = Ariblib::String.new(bs,len).to_utf8 #uimsbf
				h[:logo_char]=logo_char
			else
				len=(descriptor_length-1)
				reserved_future_use = bs.str len #bslbf
			end
		end
	end
	class ServiceGroupDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			h[:tag] << :service_groupe
		end
	end
	class DigitalCopyControlDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			h[:tag] << :digital_copy_control
		end
	end
	class NetworkNameDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			network_name = Ariblib::String.new(bs,descriptor_length).to_utf8 #uimsbf
			h[:network_name] = network_name
		end
	end
	class TSInformationDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			ret=[]
			start_pos=bs.pos
			remote_control_key_id    = bs.read 8 #uimsbf
			length_of_ts_name        = bs.read 6 #uimsbf
			transmission_type_count  = bs.read 2 #uimsbf
			ts_name_char = Ariblib::String.new(bs,length_of_ts_name).to_utf8 #uimsbf
			transmission_type_count.times do
				transmission_type_info  = bs.read 8 #bslbf
				num_of_service  = bs.read 8 #uimsbf
				num_of_service.times do
					service_id  = bs.read 16 #uimsbf
					ret << service_id
				end
			end
			len=descriptor_length-(bs.pos-start_pos)/8
			#for (l = 0;l< N;l++) {
			#reserved_future_use 8 bslbf
			#}
			h[:TS_remote_key]=remote_control_key_id
			h[:TS_name]=ts_name_char
			h[:TS_service]=ret
		end
	end
	class TerrestrialDeliverySystemDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			ret=[]
			area_code  = bs.read 12 #bslbf
			guard_interval  = bs.read 2 #bslbf
			transmission_mode  = bs.read 2 #bslbf
			len=descriptor_length-2
			(len/2).times do
				frequency  = bs.read 16 #uimsbf
				ret << frequency
			end
			h[:TDS]=[area_code,transmission_mode,ret]
		end
	end
	class PartialReceptionDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			ret=[]
			(descriptor_length/2).times do
				service_id  = bs.read 16 #uimsbf
				ret << service_id
			end
			h[:PartialReception]=ret
		end
	end
	class SystemManagementDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			h[:tag] << :system_management
			#system_management_id 16 uimsbf
			#for (i=0;i <N;i++){
			#	additional_identification_info 8 uimsbf　不要
			#}
		end
	end
	class ServiceListDescriptor < Descriptor
		def parse(h,bs,tag,descriptor_length)
			ret=[]
			(descriptor_length/3).times do
				service_id    = bs.read 16 #uimsbf
				service_type  = bs.read 8 #uimsbf
				ret << [service_id,service_type]
			end
			h[:service_list]=ret
		end
	end
	DescriptorTag={
		0x4D => ShortEventDescriptor,      #-----o---o n 0x4D 短形式イベント記述子*2
		0x4E => ExtendedEventDescriptor,   #-----o---o r 0x4E 拡張形式イベント記述子
		0x54 => ContentDescriptor,         #-----o---- r 0x54 コンテント記述子
		80   => ComponentDescriptor,       #-o---o---- r 0x50 コンポーネント記述子
		196  => AudioComponentDescriptor,  #-----o---- r 0xC4 音声コンポーネント記述子
		0xC7 => DataContentDescriptor,     #-----o---- r 0xC7 データコンテンツ記述子
		214  => EventGroupDescriptor,      #-----o---- r 0xD6 イベントグループ記述子
	#for SDT(地上波)
		0x48 => ServiceDescriptor,         #----o----- n 0x48 サービス記述子*2
		207  => LogoTransmissionDescriptor,#----o----- r 0xCF ロゴ伝送記述子
	#for NIT(地上波)
		0x40 => NetworkNameDescriptor,              #--o------- n 0x40* ネットワーク名記述子*2
		0x41 => ServiceListDescriptor,              #--oo---o-- n 0x41* サービスリスト記述子*1
		0xFA => TerrestrialDeliverySystemDescriptor,#--o------- n 0xFA* 地上分配システム記述子*1
		0xFE => SystemManagementDescriptor,         #-oo------- n 0xFE* システム管理記述子*1
		224  => ServiceGroupDescriptor,             #--o------- r 0xE0 サービスグループ記述子
		0xCD => TSInformationDescriptor,            #--o------- r 0xCD* TS 情報記述子
		0xFB => PartialReceptionDescriptor,         #--o------- j 0xFB* 部分受信記述子*1(ワンセグ)
	}
	DescriptorTag.default=Descriptor
	DescriptorTag.freeze
end

__END__
SDT -> 
    ->CommonDataTable ->
    ->EIT ->

NIT -> tpid,onid,*:service_list :TS_name || *:network_name


NIT(事業者情報)
id,(tpid,onid),ts_name,remote_key

SDT(サービス情報)
id,(tpid,onid,sid),service_type,service_name,logo_id,logo_name

EIT(番組情報)
id,(tpid,onid,sid,eid),start,fin,title,desc,colspan

CDT(ロゴ情報)
id (logo_id),logo0,1,2,3,4,5

