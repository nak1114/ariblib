#! ruby
# -*- encoding: utf-8 -*-

module Ariblib
	class String
		DesignationGSET={
			0x42 => [:set_code_group, [:put_kanji        ,true ].freeze].freeze,#:CODE_KANJI             
			0x4A => [:set_code_group, [:put_alphanumeric ,false].freeze].freeze,#:CODE_ALPHANUMERIC      
			0x30 => [:set_code_group, [:put_hiragana     ,false].freeze].freeze,#:CODE_HIRAGANA          
			0x31 => [:set_code_group, [:put_katakana     ,false].freeze].freeze,#:CODE_KATAKANA          
			0x32 => [:set_code_group, [:put_ignore       ,false].freeze].freeze,#:CODE_MOSAIC_A          
			0x33 => [:set_code_group, [:put_ignore       ,false].freeze].freeze,#:CODE_MOSAIC_B          
			0x34 => [:set_code_group, [:put_ignore       ,false].freeze].freeze,#:CODE_MOSAIC_C          
			0x35 => [:set_code_group, [:put_ignore       ,false].freeze].freeze,#:CODE_MOSAIC_D          
			0x36 => [:set_code_group, [:put_alphanumeric ,false].freeze].freeze,#:CODE_PROP_ALPHANUMERIC 
			0x37 => [:set_code_group, [:put_hiragana     ,false].freeze].freeze,#:CODE_PROP_HIRAGANA     
			0x38 => [:set_code_group, [:put_katakana     ,false].freeze].freeze,#:CODE_PROP_KATAKANA     
			0x49 => [:set_code_group, [:put_jis_katakana ,false].freeze].freeze,#:CODE_JIS_X0201_KATAKANA
			0x39 => [:set_code_group, [:put_kanji        ,true ].freeze].freeze,#:CODE_JIS_KANJI_PLANE_1 
			0x3A => [:set_code_group, [:put_kanji        ,true ].freeze].freeze,#:CODE_JIS_KANJI_PLANE_2 
			0x3B => [:set_code_group, [:put_symbols      ,true ].freeze].freeze,#:CODE_ADDITIONAL_SYMBOLS
		}.freeze
		DesignationDRCS={
			0x40 => [:set_code_group, [:put_ignore,true ].freeze].freeze,# DRCS-0
			0x41 => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-1
			0x42 => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-2
			0x43 => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-3
			0x44 => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-4
			0x45 => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-5
			0x46 => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-6
			0x47 => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-7
			0x48 => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-8
			0x49 => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-9
			0x4A => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-10
			0x4B => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-11
			0x4C => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-12
			0x4D => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-13
			0x4E => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-14
			0x4F => [:set_code_group, [:put_ignore,false].freeze].freeze,# DRCS-15
			0x70 => [:set_code_group, [:put_ignore,false].freeze].freeze,# Macro
		}.freeze

		Esc_4th=DesignationDRCS.freeze
		Esc_3rd_drcs=DesignationDRCS.merge({0x20 => [:esc_seq,Esc_4th,nil].freeze}).freeze
		Esc_3rd_gset=DesignationGSET.merge({0x20 => [:esc_seq,Esc_4th,nil].freeze}).freeze
		Esc_2nd={
			0x20 => [:esc_seq,Esc_3rd_drcs ,nil].freeze,
			0x28 => [:esc_seq,Esc_3rd_drcs ,  0].freeze,
			0x29 => [:esc_seq,Esc_3rd_gset ,  1].freeze,
			0x2A => [:esc_seq,Esc_3rd_gset ,  2].freeze,
			0x2B => [:esc_seq,Esc_3rd_gset ,  3].freeze,
		}.merge(DesignationGSET).freeze
		Esc_1st={
			# Invocation of code elements
			0x6E => [:set_locking_gl,2].freeze,# LS2
			0x6F => [:set_locking_gl,3].freeze,# LS3
			0x7E => [:set_locking_gr,1].freeze,# LS1R
			0x7D => [:set_locking_gr,2].freeze,# LS2R
			0x7C => [:set_locking_gr,3].freeze,# LS3R
				# Designation of graphic sets
			0x24 => [:esc_seq,Esc_2nd,0].freeze,
			0x28 => [:esc_seq,Esc_2nd,0].freeze,
			0x29 => [:esc_seq,Esc_2nd,1].freeze,
			0x2A => [:esc_seq,Esc_2nd,2].freeze,
			0x2B => [:esc_seq,Esc_2nd,3].freeze,
		}.freeze
		Esc_Error=[:escape_error].freeze

		def set_locking_gl(val)
			@m_pLockingGL = val
		end
		def set_locking_gr(val)
			@m_pLockingGR = val
		end
		def set_code_group(val)
			@m_CodeG[@byIndexG]=val
		end
		def escape_error
		end
		def esc_seq(hash , byIndexG)
			@byIndexG=byIndexG if byIndexG
			#binding.pry
			args=hash.fetch(@bs.getc,Esc_Error)
			send *args
		end
		
		Code_kanji = [0x1B, 0x24, 0x40,nil,nil,0x1B,0x28,0x4a]
		Code_alphanumeric = (
		"　　　　　　　　　　　　　　　　"+
		"　　　　　　　　　　　　　　　　"+
		"　！”＃＄％＆’（）＊＋，－．／"+
		"０１２３４５６７８９：；＜＝＞？"+
		"＠ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯ"+
		"ＰＱＲＳＴＵＶＷＸＹＺ［￥］＾＿"+
		"　ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏ"+
		"ｐｑｒｓｔｕｖｗｘｙｚ｛｜｝￣　").freeze
		Code_hiragana = (
		"　　　　　　　　　　　　　　　　"+
		"　　　　　　　　　　　　　　　　"+
		"　ぁあぃいぅうぇえぉおかがきぎく"+
		"ぐけげこごさざしじすずせぜそぞた"+
		"だちぢっつづてでとどなにぬねのは"+
		"ばぱひびぴふぶぷへべぺほぼぽまみ"+
		"むめもゃやゅゆょよらりるれろゎわ"+
		"ゐゑをん　　　ゝゞー。「」、・　").freeze
		Code_katakana = (
		"　　　　　　　　　　　　　　　　"+
		"　　　　　　　　　　　　　　　　"+
		"　ァアィイゥウェエォオカガキギク"+
		"グケゲコゴサザシジスズセゼソゾタ"+
		"ダチヂッツヅテデトドナニヌネノハ"+
		"バパヒビピフブプヘベペホボポマミ"+
		"ムメモャヤュユョヨラリルレロヮワ"+
		"ヰヱヲンヴヵヶヽヾー。「」、・　").freeze
		Code_jis_katakana = (
		"　　　　　　　　　　　　　　　　"+
		"　　　　　　　　　　　　　　　　"+
		"　。「」、・ヲァィゥェォャュョッ"+
		"ーアイウエオカキクケコサシスセソ"+
		"タチツテトナニヌネノハヒフヘホマ"+
		"ミムメモヤユヨラリルレロワン゛゜"+
		"　　　　　　　　　　　　　　　　"+
		"　　　　　　　　　　　　　　　　").freeze
	
		def put_kanji(char1,char2)
			Code_kanji[3]=char1
			Code_kanji[4]=char2
			@dst+=Code_kanji.pack('C*').force_encoding('ISO-2022-JP').encode('utf-8')
		end
		def put_alphanumeric(char1,char2)
			@dst+=char1.chr
		end
		def put_alphanumeric_wide(char1,char2)
			@dst+=Code_alphanumeric[char1]
		end
		def put_hiragana(char1,char2)
			@dst+=Code_hiragana[char1]
		end
		def put_katakana(char1,char2)
			@dst+=Code_katakana[char1]
		end
		def put_jis_katakana(char1,char2)
			@dst+=Code_jis_katakana[char1]
		end
		def put_symbols(char1,char2)
			#@dst+=
		end
		def put_ignore(char1,char2)
		end

		def initialize(bs,len)
			@bs=bs
			@dst=''.force_encoding('utf-8')

			# 状態初期設定
			@m_CodeG =[ DesignationGSET[0x42][1],
			            DesignationGSET[0x4a][1],
			            DesignationGSET[0x30][1],
			            DesignationGSET[0x31][1]]
			@m_pLockingGL = 0
			@m_pLockingGR = 2
			@m_pSingleGL = nil
			conv(len*8)
		end

		def to_utf8
			@dst
		end

		def conv(len)
			#@m_emStrSize = :STR_NORMAL
			len+=@bs.pos
			while(@bs.pos < len)
				dwSrcData = @bs.getc

				if((dwSrcData >= 0x21) && (dwSrcData <= 0x7E)) #GL領域
					curCodeSet = @m_CodeG[@m_pSingleGL || @m_pLockingGL];
					@m_pSingleGL=nil
					char2 = (curCodeSet[1])? @bs.getc  : nil #// 2バイトコード
					send( curCodeSet[0],dwSrcData,char2)

				elsif((dwSrcData >= 0xA1) && (dwSrcData <= 0xFE)) #// GR領域
					curCodeSet = @m_CodeG[@m_pLockingGR];
					char2 = (curCodeSet[1])? @bs.getc  : nil #// 2バイトコード
					send( curCodeSet[0],dwSrcData & 0x7f,char2 & 0x7f)

				else
					#// 制御コード
					case(dwSrcData)
						when 0x0F then @m_pLockingGL = 0 # LS0
						when 0x0E then @m_pLockingGL = 1 # LS1
						when 0x19 then @m_pSingleGL  = 2 # SS2
						when 0x1D then @m_pSingleGL  = 3 # SS3
						when 0x1B then esc_seq(Esc_1st,nil)  # ESC
						#when 0x89 then @m_emStrSize = :STR_MEDIUM # MSZ
						#when 0x8A then @m_emStrSize = :STR_NORMAL # NSZ
						when 0x20 then @dst+=' ' # space
						when 0xA0 then @dst+=' ' # space(ARIB)
						when 0x09 then @dst+=' ' # HT
						when 0x0D then @dst+="\r"
						when 0x0A then @dst+="\r"
					else
					end
				end
			end
			@dst
		end
	end
end

__END__
