#! ruby
# -*- encoding: utf-8 -*-

module Ariblib
	#記述子
	class Descriptor
		def initialize(h,bs)
			parser(h,bs,bs.read( 8))
		end
		def parser(h,bs,descriptor_length)
			bs.pos+=descriptor_length * 8
			@tag=h[:tag]
		end
	end

	class ShortEventDescriptor < Descriptor
		def parser(h,bs,descriptor_length)
		
			@ISO_639_language_code =bs.read 24 #bslbf
			event_name_length      =bs.getc #8 uimsbf
			@event_name_char       =Ariblib::String.new(bs,event_name_length).to_utf8
			text_length            =bs.getc #8 uimsbf
			@text_char             =Ariblib::String.new(bs,text_length).to_utf8
		end
		attr_reader :ISO_639_language_code
		attr_reader :event_name_char
		attr_reader :text_char
	end
	class ExtendedEventDescriptor < Descriptor
		def parser(h,bs,descriptor_length)
			@item=[]
			descriptor_number      =bs.read 4 #uimsbf
			last_descriptor_number =bs.read 4 #uimsbf
			@ISO_639_language_code =bs.read 24 #bslbf
			length_of_items        =bs.getc #8 uimsbf
			length_of_items.times do
				item_description_length =bs.getc #8 uimsbf
				item_description_char   =bs.str(item_description_length)
				item_length =bs.read 8 #uimsbf
				item_char   =bs.str(item_length)
				@item << [item_description_char,item_char]
			end
			text_length            =bs.getc #8 uimsbf
			@text_char             =bs.str(text_length)
		end
		attr_reader :ISO_639_language_code
		attr_reader :item
		attr_reader :text_char
	end
	class ContentDescriptor < Descriptor
		def parser(h,bs,descriptor_length)
			@content=bs.read 8
			bs.pos+=descriptor_length-1
		end
		attr_reader :content
	end
	class ContentDescriptor < Descriptor
		def parser(h,bs,descriptor_length)
			@content_nibble_level_1=bs.read 4
			@content_nibble_level_2=bs.read 4
			bs.pos+=descriptor_length-1
		end
		attr_reader :content_nibble_level_1
		attr_reader :content_nibble_level_2
	end
	class ServiceDescriptor < Descriptor
		def parser(h,bs,descriptor_length)
			@service_type          =bs.read 8 #uimsbf
			service_provider_name_length =bs.read 8 #uimsbf
			@service_provider_name =bs.str(service_provider_name_length)
			service_name_length    =bs.read 8 #uimsbf
			@service_name          =bs.str(service_name_length)
		end
		attr_reader :service_type
		attr_reader :service_provider_name
		attr_reader :service_name
	end
	class DataContentDescriptor < Descriptor
		def parser(h,bs,descriptor_length)
			data_component_id     = bs.read 16 #uimsbf
			entry_component       = bs.getc #8 uimsbf
			selector_length       = bs.getc #8 uimsbf
			selector_byte         = bs.str(selector_length)
			num_of_component_ref  = bs.getc #8 uimsbf
			component_ref         = bs.str(num_of_component_ref)

			iso_639_language_code = bs.read 24 #bslbf
			text_length           = bs.getc #8 uimsbf
			@text_char = Ariblib::String.new(bs,text_length).to_utf8
		end
		attr_reader :text_char
	end
	class AudioComponentDescriptor < Descriptor
		def parser(h,bs,descriptor_length)
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
			@text_char = Ariblib::String.new(bs,text_length).to_utf8
		end
		attr_reader :text_char
	end
	class ComponentDescriptor < Descriptor
		def parser(h,bs,descriptor_length)
			text_length = descriptor_length - 6#8 uimsbf
			reserved_future_use    = bs.read 4 #bslbf
			stream_content         = bs.read 4 #uimsbf
			component_type         = bs.getc #8 uimsbf
			component_tag          = bs.getc #8 uimsbf
			iso_639_language_code  = bs.read 24 #bslbf
			@text_char = Ariblib::String.new(bs,text_length).to_utf8
		end
		attr_reader :text_char
	end
	class EventGroupDescriptor < Descriptor
	end
	class ServiceGroupDescriptor < Descriptor
	end

	DescriptorTag={
		0x4D => ShortEventDescriptor,   #  Short event descriptor
		0x4E => ExtendedEventDescriptor,#  Extended event descriptor
		0x54 => ContentDescriptor,      #  Content descriptor
		0x48 => ServiceDescriptor,      #  Service descriptor
		#80   => ComponentDescriptor,  #
		#196  => AudioComponentDescriptor,  #
		#199  => DataContentDescriptor,  #
		214  => EventGroupDescriptor,  #
		224  => ServiceGroupDescriptor,  #
	}
	DescriptorTag.default=Descriptor
	DescriptorTag.freeze
end

__END__
