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

end

__END__
