#! ruby
# -*- encoding: utf-8 -*-

module Ariblib

	#ビットストリーム
	class BitStream
		def initialize(buf)
			@bitstream_buffer=buf||("".encode("BINARY"))
			@bitstream_postion=0
		end
		def str(byte)
				ret=@bitstream_buffer.byteslice(@bitstream_postion/8,byte)
				@bitstream_postion+=byte*8
				ret
		end
		def getc
			len=@bitstream_postion/8
			@bitstream_postion+=8
			ret =@bitstream_buffer.getbyte(len  )
			ret
		end
		def gets
			len=@bitstream_postion/8
			@bitstream_postion+=8*2
			ret =@bitstream_buffer.getbyte(len  ) <<  8
			ret|=@bitstream_buffer.getbyte(len+1)
			ret
		end
		def get3
			len=@bitstream_postion/8
			@bitstream_postion+=8*3
			ret =@bitstream_buffer.getbyte(len  ) << 16
			ret|=@bitstream_buffer.getbyte(len+1) <<  8
			ret|=@bitstream_buffer.getbyte(len+2)
			ret
		end
		def read(size)
			pos =@bitstream_postion>>3
			modd=@bitstream_postion&0x07
			@bitstream_postion+=size
			mod =((~(@bitstream_postion)).succ)&0x07
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
end