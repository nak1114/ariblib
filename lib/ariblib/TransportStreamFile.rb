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
			#0x0000 => ProgramAssociationTable.new,
			#0x0001 => ConditionalAccessTable.new,
			0x0012 => EventInformationTable.new,
			0x0011 => ServiceDescriptionTable.new,
			0x0010 => NetworkInformationTable.new,
			0x0014 => TimeOffsetTable.new,
			0x0029 => CommonDataTable.new,
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
			if @bs.lest <= 0
				tmp=@file.read(ReadSize)
				return nil unless tmp
				@bs=BitStream.new(tmp)
			end
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
#Default_payload  一覧
#          PID           table_id
#PMT*1  PATによる間接指定   0x02 +必須 1@100ms
#INT*1  PMTによる間接指定   0x4c  任意 1@30s

#PID table_id
#0x0000 0x00 PAT +必須 1@100ms
#0x0001 0x01 CAT +必須 1@1s
#0x0010 0x40 NIT *必須 1@10s(自ストリーム)
#0x0010 0x41 NIT *任意 1@10s(他ストリーム)
#0x0011 0x42 SDT *必須 1@10s(自ストリーム)
#0x0011 0x46 SDT *任意 1@10s(他ストリーム)
#0x0011 0x4a BAT  任意 1@10s(他ストリーム)
#0x0012 0x4e EIT *必須 1@2s(EITpf自ストリーム)
#0x0012 0x4f EIT  任意 1@10s(EITpf自ストリーム)
#0x0012 0x5? EIT  任意 1@10s(自ストリーム8日以内)
#0x0012 0x5? EIT  任意 1@30s(自ストリーム8日以降)
#0x0012 0x6? EIT  任意 1@10s(他ストリーム8日以内)
#0x0012 0x6? EIT  任意 1@30s(他ストリーム8日以降)
#0x0012,0x0026,0x0027 EIT
#0x0013 0x71 RST  任意 任意
#0x0014 0x70 TDT *必須 1@30s
#0x0014 0x73 TOT *必須 1@30s
#0x0022 0xc2 PCAT 任意 任意
#0x0024 0xc4 BIT  任意 1@20s
#0x0025 0xc5 NBIT 任意 1@20s
#0x0025 0xc6 NBIT 任意 1@10s
#0x002E 0xfe AMT  任意 1@10s
#?????? 0x72 ST 任意 任意 (0x0000, 0x0001, 0x0014を除く)

#ECM*1  PMTによる間接指定
#EMM*1  CATによる間接指定
#DLT*3  DCTによる間接指定
#LIT*5  PMTによる間接指定*6(Default:0x20)
#ERT*5  PMTによる間接指定*6(Default:0x21)
#ITT    PMTによる間接指定
#AIT*9  PMTによる間接指定
#DCM*10 PMTによる間接指定
#DSM-CCセクション*4 PMTによる間接指定
#DMM*10 SDTTによる間接指定

#0x0017 DCT*3 
#0x001E DIT*2 
#0x001F SIT*2 
#0x0020 LIT*5
#0x0021 ERT*5
#0x0023、0x0028 SDTT
#0x0025 0xc7 LDT
#0x0029 CDT
#0x002D 分割TLVパケット*11 
#0x002F 多重フレームヘッダ情報*7 
#0x1FFF ???? ヌルパケット*1 

#記述子タグ()
#CAT SDT NBIT
# PMT EIT LDT
#  NIT TOT
#   BAT BIT
#-o-------- j 0x04 階層符号化記述子*1, 8
#-o-------- j 0x05 登録記述子*8
#oo-------- * 0x09 限定受信方式記述子*1
#-o-------- * 0x0D 著作権記述子*1
#             0x13 カルーセル識別記述子*7
#             0x14 アソシエーションタグ記述子*7
#             0x15 拡張アソシエーションタグ記述子*7
#-o-------- j 0x1C MPEG-4 オーディオ記述子*8
#-o-------- r 0x28 AVC ビデオ記述子*8
#-o-------- r 0x2A AVC タイミングHRD 記述子*8
#-o-------- j 0x2E MPEG-4 オーディオ拡張記述子*8
#-o-------- j 0x38 HEVC ビデオ記述子*8
#--o------- n 0x40* ネットワーク名記述子*2
#--oo---o-- n 0x41* サービスリスト記述子*1
#--oooo--oo r 0x42 スタッフ記述子
#--o------- n 0x43 衛星分配システム記述子*1
#             0x44 有線分配システム記述子*4
#---oo----- n 0x47 ブーケ名記述子
#----o----- n 0x48 サービス記述子*2
#-o-oo----- r 0x49 国別受信可否記述子
#-ooooo---- r 0x4A リンク記述子
#----o----- j 0x4B NVOD 基準サービス記述子
#----o----- j 0x4C タイムシフトサービス記述子*2
#-----o---o n 0x4D 短形式イベント記述子*2
#-----o---o r 0x4E 拡張形式イベント記述子
#-----o---- j 0x4F タイムシフトイベント記述子*2
#-o---o---- r 0x50 コンポーネント記述子
#-o--o----- r 0x51 モザイク記述子
#-o-------- r 0x52 ストリーム識別記述子
#---ooo---- r 0x53 CA 識別記述子
#-----o---- r 0x54 コンテント記述子
#-o---o---- r 0x55 パレンタルレート記述子
#------o--- j 0x58 ローカル時間オフセット記述子
#             0x63 パーシャルトランスポートストリーム記述子*3
#-o-------- r 0x66 データブロードキャスト識別記述子
#             0x67 素材情報記述子
#-o-------- r 0x68 通信連携情報記述子
#             0x80-
#             0xBF 事業者定義記述子のタグ値として選択可能な範囲
#-o-------- j 0xC0 階層伝送記述子
#-o--oo---- r 0xC1 デジタルコピー制御記述子
#             0xC2 ネットワーク識別記述子*3
#             0xC3 パーシャルトランスポートストリームタイム記述子*3
#-----o---- r 0xC4 音声コンポーネント記述子
#-----o-o-- r 0xC5 ハイパーリンク記述子
#-o-------- r 0xC6 対象地域記述子
#-----o---- r 0xC7 データコンテンツ記述子
#-o-------- r 0xC8 ビデオデコードコントロール記述子
#             0xC9 ダウンロードコンテンツ記述子*3
#             0xCA CA_EMM_TS 記述子*5
#             0xCB CA 契約情報記述子*5
#             0xCC CA サービス記述子*5
#--o------- r 0xCD* TS 情報記述子
#-------o-- r 0xCE 拡張ブロードキャスタ記述子
#----o----- r 0xCF ロゴ伝送記述子
#             0xD0 基本ローカルイベント記述子
#             0xD1 リファレンス記述子
#             0xD2 ノード関係記述子
#             0xD3 短形式ノード情報記述子
#             0xD4 STC 参照記述子
#-----o---- r 0xD5 シリーズ記述子
#-----o---- r 0xD6 イベントグループ記述子
#-------o-- r 0xD7 SI 伝送パラメータ記述子
#-------o-- r 0xD8 ブロードキャスタ名記述子
#-----o---- r 0xD9 コンポーネントグループ記述子
#-------o-- r 0xDA SI プライムTS 記述子
#--------o- r 0xDB 掲示板情報記述子
#-----o---- r 0xDC LDT リンク記述子
#--o------- j 0xDD 連結送信記述子
#-o--oo---- r 0xDE コンテント利用記述子
#             0xDF タグ値拡張用(未規定)
#--o------- r 0xE0 サービスグループ記述子
#--o------- j 0xE1 エリア放送情報記述子
#             0xE2 ネットワークダウンロードコンテンツ記述子*3
#             0xE3 ダウンロード保護記述子*9
#             0xE4 CA 起動記述子*9
#             0xE5-
#             0xF2 未規定
#             0xF3 有線複数搬送波伝送分配システム記述子*10
#             0xF4 高度有線分配システム記述子*10
#oo-------- j 0xF5 スクランブル方式記述子*1
#oo-------- j 0xF6 アクセス制御記述子*1
#-o---o---- r 0xF7 カルーセル互換複合記述子*1
#oo-------- j 0xF8 限定再生方式記述子*1, *5
#             0xF9 有線TS 分割システム記述子*6
#--o------- n 0xFA* 地上分配システム記述子*1
#--o------- j 0xFB* 部分受信記述子*1
#-oo------- j 0xFC 緊急情報記述子*1
#-o-------- j 0xFD データ符号化方式記述子*1
#-oo------- n 0xFE* システム管理記述子*1
