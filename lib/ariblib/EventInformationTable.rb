#!ruby
# -*- encoding: utf-8 -*-

module Ariblib

	#番組表テーブル
	class EventInformationTable < ProgramSpecificInformation #< 4Kbyte super(x,y)


		class SelfWeeklyMultiEventSchedule
			def initialize
				refresh
			end
			def refresh
				@table=[]
				@start=nil
				@end=nil
				@cur=nil
			end
			def finish
			end
			def inc
				while @cur < @table.size
					cur =@table[@cur  ][2]
					nxt =@table[@cur+1][1]
					@cur+=1 if cur==nxt
				end
			end
			def binary_insert(a,e)
				if a.size > 0
					index = [*a.each_with_index].bsearch{|x, _| x[1] > e[1]}.last
					a.insert(index, e) if a[index][1]!=e[1]
					while a[@cur][2]==a[@cur+1][1]
						@cur+=1
					end
				else
					a.insert(0, e)
					@cur=0
				end
			end
			def check(uid,tid,last_tid,seg_last,list)
				if tid ==0x4e00 && list.size >0#自ストリーム現在地
					unless @cur
						tmp=list[0][1]
						@cur=0 if @table.bsearch{|v|v[1]>=tmp}
					end
				elsif tid < 0x5000 #他ストリームnext
				elsif tid < 0x5200 #自ストリームtable 0x1ff -> 3f
					@end=list.last if @end==nil and tid==last_tid #and list.size >0
					tmp=@table && @start[2]
					list.each do |v|
						next unless v[3][:title]
						@table << v
					end
				end
			end
		end


		class SelfWeeklyMultiSchedule
			def initialize
				refresh
			end
			#8[bit/seg]*8[seg/day]*8[day]=512[bit]=64byte=16word
			#512[bit]/8[day]=64[bit/day]
			#64[bit/day]/8[seg/day]=8[bit/seg]
			def refresh
				@table=Hash.new(){|k,v|k[v]=[Array.new(512/8,0),false]}
			end
			def finish
				return false if table.size==0
				@table.values.inject(true){|ret,v|ret && v[1]}
			end
			
			def check(uid,tid,last_tid,seg_last,list)
					#if tid < 0x4800 #違法
					if tid ==0x4e00 && list.size >0#自ストリーム現在地
						seg=@table[uid][0]
						#過去セグメントを埋める。
						hour=list[0][1].hour
						#p 'uid=%08x tid=%04x,last=%02x,hour=%02x' % [uid,tid,seg_last,hour]
						(hour/3).floor.times{|v|seg[v]=0xff}
					#elsif tid <0x4900 #自ストリームnext
					#elsif tid ==0x4900 #他ストリーム現在地
					elsif tid < 0x5000 #他ストリームnext
					elsif tid < 0x5200 #自ストリームtable 0x1ff -> 3f
						ind=(tid-0x5000)>>3
						seg=@table[uid][0]
						tmp =seg[ind]
						if tmp !=0xff
							tmp4=((tid&0x00ff)==seg_last)?0xff : 1
							tmp5=tmp | ((tmp4<<(tid&0x0007))&0xff)
							seg[ind]=tmp5
							if tmp5==0xff
								t=seg[0,512/8].inject{|x,y|x&y}
								@table[uid][1]=true if t==0xff
							end
						end
					#elsif tid <0x6000 #自ストリーム詳細
					#elsif tid <0x7000 #他ストリームtable
					else #違法
					end
			end
		end


		def initialize
			super
			@schedule=SelfWeeklyMultiSchedule.new
		end
		attr_reader :schedule
		def parse_buf
			ret=[]
			bs=BitStream.new(@buf)
			#event_information_section(){
			table_id                     =bs.getc #8 uimsbf
			#staff_table if table_id == 0x72
			tmp                          =bs.gets
			section_length               =tmp & 0x0fff
			#section_syntax_indicator     =bs.read 1 #bslbf
			#reserved_future_use          =bs.read 1 #bslbf
			#reserved                     =bs.read 2 #bslbf
			#section_length               =bs.read 12 # < 4096 -3
			service_id                   =bs.gets #16 uimsbf
			tmp                          =bs.getc
			#reserved                     =bs.read 2 #bslbf
			#version_number               =bs.read 5 #uimsbf
			#current_next_indicator       =bs.read 1 #bslbf
			section_number               =bs.getc #8 uimsbf
			last_section_number          =bs.getc #8 uimsbf
			transport_stream_id          =bs.gets #16 uimsbf
			original_network_id          =bs.gets #16 uimsbf
			segment_last_section_number  =bs.getc #8 uimsbf
			last_table_id                =bs.getc #8 uimsbf

			uid=(original_network_id<<(16+16))|(transport_stream_id<<(16))|service_id
			tid     =(     table_id<<8)|     section_number
			last_tid=(last_table_id<<8)|last_section_number

			len=(section_length+3-4)*8
			while bs.pos < len
				event_id                   =bs.gets #16 #uimsbf
				start_mdj                  =bs.gets #16 #bslbf
				start_time                 =bs.get3 #24 #bslbf
				duration                   =bs.get3 #24 #uimsbf
				tmp                        =bs.gets
				#running_status             =bs.read 3 #uimsbf
				#free_CA_mode               =bs.read 1 #bslbf
				#descriptors_loop_length    =bs.read 12 #uimsbf
				desc = descriptor(bs,tmp & 0x0fff)

				start=Date.jd(start_mdj+2400001).to_datetime + time_to_datetime(start_time)
				fin  =start+time_to_datetime(duration)
				@contents << [uid,tid,event_id,start,fin,desc]
				#ret << '    %04x|%s|%s' % [event_id,start.strftime('%Y%m%d%H%M'),fin.strftime('%Y%m%d%H%M')]
			end
			cCRC_32 =bs.read 32 #rpchof

			#@schedule.check(uid,tid,last_tid,segment_last_section_number,ret)
			#tmp= [table_id,transport_stream_id,original_network_id,service_id,section_number,last_section_number,segment_last_section_number,last_table_id,ret.size]
			#ret.unshift("tid=%02x,tpid=%04x,nid=%04x,serid=%04x,secnum=%02x,lastsec=%02x,seglast=%02x,ltid=%02x,n=%d" % tmp)
			#@debug||=Hash.new(){|k,v|k[v]={}}
			#tmp=@debug[uid][tid]
			#@debug[uid][tid] = ret
			#@debug[uid]=@debug[uid].sort_by{|k,v| k}.to_h unless tmp
			nil
		end
		def time_to_datetime(t)
				sec =(t & 0x0000000f)
				t>>=4
				sec+=(t & 0x0000000f)*10
				t>>=4
				sec+=(t & 0x0000000f)*60
				t>>=4
				sec+=(t & 0x0000000f)*600
				t>>=4
				sec+=(t & 0x0000000f)*3600
				t>>=4
				sec+=(t & 0x0000000f)*36000
				Rational(sec,24*60*60)
		end
	end
end
__END__
