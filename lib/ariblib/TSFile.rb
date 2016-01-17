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
end

__END__
