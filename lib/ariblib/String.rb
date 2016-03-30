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

		Ctrl_code={
			0x0F => [:set_locking_gl , 0 ].freeze,# LS0
			0x0E => [:set_locking_gl , 1 ].freeze,# LS1
			0x19 => [:set_single_gl  , 2 ].freeze,# SS2
			0x1D => [:set_single_gl  , 3 ].freeze,# SS3
			0x1B => [:esc_seq ,Esc_1st,nil].freeze,  # ESC
			#0x89 => [:set_em_str_size , :STR_MEDIUM ].freeze,# MSZ
			#0x8A => [:set_em_str_size , :STR_NORMAL ].freeze,# NSZ
			0x20 => [:put_alphanumeric_narrow, 0x20 ].freeze,# space
			0xA0 => [:put_alphanumeric_narrow, 0x20 ].freeze,# space(ARIB)
			0x09 => [:put_alphanumeric_narrow, 0x20 ].freeze,# HT
			0x0D => [:put_alphanumeric_narrow, 0x0d ].freeze,
			0x0A => [:put_alphanumeric_narrow, 0x0d ].freeze,
		}.freeze

		def set_em_str_size(val)
			@m_emStrSize = val
		end
		def set_single_gl(val)
			@m_pSingleGL = val
		end
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
			args=hash.fetch(@bs.getc,Esc_Error)
			send *args if @bs.pos <= @len
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
		Code_gaiji = {
	  0x7A => [ nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,#0x21-0x2f
	        nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,#0x30-0x3f
	        nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,#0x40-0x4f
	        "【HV】","【SD】","【Ｐ】","【Ｗ】","【MV】","【手】","【字】","【双】",
	        "【デ】","【Ｓ】","【二】","【多】","【解】","【SS】","【Ｂ】","【Ｎ】",
	        "■"    ,"●"    ,"【天】","【交】","【映】","【無】","【料】","【年齢制限】",
	        "【前】","【後】","【再】","【新】","【初】","【終】","【生】","【販】",
	        "【声】","【吹】","【PPV】","（秘）","ほか",],
	  0x7C=>[      "→"  ,"←"  ,"↑"  ,"↓"  ,"●"  ,"○"  ,"年"  ,
	        "月"  ,"日"  ,"円"  ,"㎡"  ,"㎥"  ,"㎝"  ,"㎠"  ,"㎤"  ,
	        "０." ,"１." ,"２." ,"３." ,"４." ,"５." ,"６." ,"７." ,
	        "８." ,"９." ,"氏"  ,"副"  ,"元"  ,"故"  ,"前"  ,"[新]",
	        "０," ,"１," ,"２," ,"３," ,"４," ,"５," ,"６," ,"７," ,
	        "８," ,"９," ,"(社)","(財)","(有)","(株)","(代)","(問)",
	        "▶"   ,"◀"   ,"〖"  ,"〗"  ,"⟐"   ,"^2"  ,"^3"  ,"(CD)",
	        "(vn)","(ob)","(cb)","(ce" ,"mb)" ,"(hp)","(br)","(p)" ,
	        "(s)" ,"(ms)","(t)" ,"(bs)","(b)" ,"(tb)","(tp)","(ds)",
	        "(ag)","(eg)","(vo)","(fl)","(ke" ,"y)"  ,"(sa" ,"x)"  ,
	        "(sy" ,"n)"  ,"(or" ,"g)"  ,"(pe" ,"r)"  ,"(R)" ,"(C)" ,
	        "(箏)","DJ"  ,"[演]","Fax",],
	  0x7D=>[         "㈪"     ,"㈫"     ,"㈬"     ,
	        "㈭"     ,"㈮"     ,"㈯"     ,"㈰"     ,
	        "㈷"     ,"㍾"     ,"㍽"     ,"㍼"     ,
	        "㍻"     ,"№"     ,"℡"     ,"〶"     ,
	        "○"     ,"〔本〕" ,"〔三〕" ,"〔二〕" ,
	        "〔安〕" ,"〔点〕" ,"〔打〕" ,"〔盗〕" ,
	        "〔勝〕" ,"〔敗〕" ,"〔Ｓ〕" ,"［投］" ,
	        "［捕］" ,"［一］" ,"［二］" ,"［三］" ,
	        "［遊］" ,"［左］" ,"［中］" ,"［右］" ,
	        "［指］" ,"［走］" ,"［打］" ,"㍑"     ,
	        "㎏"     ,"㎐"     ,"ha"     ,"㎞"     ,
	        "㎢"     ,"㍱"     ,"・"     ,"・"     ,
	        "1/2"    ,"0/3"    ,"1/3"    ,"2/3"    ,
	        "1/4"    ,"3/4"    ,"1/5"    ,"2/5"    ,
	        "3/5"    ,"4/5"    ,"1/6"    ,"5/6"    ,
	        "1/7"    ,"1/8"    ,"1/9"    ,"1/10"   ,
	        "☀"     ,"☁"     ,"☂"     ,"☃"     ,
	        "☖"     ,"☗"     ,"▽"     ,"▼"     ,
	        "♦"      ,"♥"      ,"♣"      ,"♠"      ,
	        "⌺"      ,"⦿"     ,"‼"      ,"⁉"      ,
	        "(曇/晴)","☔"      ,"(雨)"   ,"(雪)"   ,
	        "(大雪)" ,"⚡"      ,"(雷雨)" ,"　"     ,
	        "・"     ,"・"     ,"♬"      "☎"      ,],
	  0x7E=>[     "Ⅰ" ,"Ⅱ" ,"Ⅲ" ,"Ⅳ" ,"Ⅴ" ,"Ⅵ" ,"Ⅶ" ,
	        "Ⅷ" ,"Ⅸ" ,"Ⅹ" ,"Ⅺ" ,"Ⅻ" ,"⑰" ,"⑱" ,"⑲" ,
	        "⑳" ,"⑴" ,"⑵" ,"⑶" ,"⑷" ,"⑸" ,"⑹" ,"⑺" ,
	        "⑻" ,"⑼" ,"⑽" ,"⑾" ,"⑿" ,"㉑" ,"㉒" ,"㉓" ,
	        "㉔" ,"(A)","(B)","(C)","(D)","(E)","(F)","(G)",
	        "(H)","(I)","(J)","(K)","(L)","(M)","(N)","(O)",
	        "(P)","(Q)","(R)","(S)","(T)","(U)","(V)","(W)",
	        "(X)","(Y)","(Z)","㉕" ,"㉖" ,"㉗" ,"㉘" ,"㉙" ,
	        "㉚" ,"①" ,"②" ,"③" ,"④" ,"⑤" ,"⑥" ,"⑦" ,
	        "⑧" ,"⑨" ,"⑩" ,"⑪" ,"⑫" ,"⑬" ,"⑭" ,"⑮" ,
	        "⑯" ,"❶" ,"❷" ,"❸" ,"❹" ,"❺" ,"❻" ,"❼" ,
	        "❽" ,"❾" ,"❿" ,"⓫" ,"⓬" ,"㉛" ,],
	  0x75=>[    "㐂","亭","份","仿","侚","俉","傜",
	        "儞","冼","㔟","匇","卡","卬","詹","吉",
	        "呍","咖","咜","咩","唎","啊","噲","囤",
	        "圳","圴","塚","墀","姤","娣","婕","寬",
	        "﨑","㟢","庬","弴","彅","德","怗","恵",
	        "愰","昤","曈","曙","曺","曻","桒","・",
	        "椑","椻","橅","檑","櫛","・","・","・",
	        "毱","泠","洮","海","涿","淊","淸","渚",
	        "潞","濹","灤","・","・","煇","燁","爀",
	        "玟","・","珉","珖","琛","琡","琢","琦",
	        "琪","琬","琹","瑋","㻚","畵","疁","睲",
	        "䂓","磈","磠","祇","禮","・","・",],
	  0x76=>[    "・","秚","稞","筿","簱","䉤","綋",
	        "羡","脘","脺","・","芮","葛","蓜","蓬",
	        "蕙","藎","蝕","蟬","蠋","裵","角","諶",
	        "跎","辻","迶","郝","鄧","鄭","醲","鈳",
	        "銈","錡","鍈","閒","雞","餃","饀","髙",
	        "鯖","鷗","麴","麵",],
		}
		Code_gaiji.default=[]
		Code_gaiji.freeze

		def put_kanji(char1,char2)
			Code_kanji[3]=char1
			Code_kanji[4]=char2
			@dst+=Code_kanji.pack('C*').force_encoding('ISO-2022-JP').encode('utf-8')
		#rescue => e
		#	puts e.message
		#	p (@bs.pos-@debug_pos)/8
		#	@bs.pos=@debug_pos
		#	p @bs.str(@debug_len).unpack('C*')
		#	puts @dst
		#	exit
		end
		def put_alphanumeric(char1,char2)
			@dst+=char1.chr
		end
		def put_alphanumeric_narrow(char1,char2)
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
			return if char2 < 0x21
			@dst+=Code_gaiji[char1][char2-0x21]||''
		end
		def put_ignore(char1,char2)
		end

		def initialize(bs,len)
			@len=bs.pos+len*8
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

			#@str=bs.str(len).unpack('C*')
			#bs.pos-=len*8
			#@debug_pos=bs.pos
			#@debug_len=len

			conv
		end

		def to_utf8
			@dst
		end

		def conv
			#@m_emStrSize = :STR_NORMAL
			while(@bs.pos < @len)
				dwSrcData = @bs.getc

				if((dwSrcData >= 0x21) && (dwSrcData <= 0x7E)) #GL領域
					curCodeSet = @m_CodeG[@m_pSingleGL || @m_pLockingGL];
					@m_pSingleGL=nil
					char2 = (curCodeSet[1])? @bs.getc  : nil #// 2バイトコード
					send( curCodeSet[0],dwSrcData,char2) if @bs.pos <= @len

				elsif((dwSrcData >= 0xA1) && (dwSrcData <= 0xFE)) #// GR領域
					curCodeSet = @m_CodeG[@m_pLockingGR];
					char2 = (curCodeSet[1])? @bs.getc  : nil #// 2バイトコード
					send( curCodeSet[0],dwSrcData & 0x7f,char2 & 0x7f) if @bs.pos <= @len

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
