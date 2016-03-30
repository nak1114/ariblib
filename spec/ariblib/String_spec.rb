require 'spec_helper'
require 'pp'

describe Ariblib::String do
	let(:ts){Ariblib::TransportStreamFile.new('spec/data/test_aa.ts')}
	let(:str){"7Y;kD#A\\::0l2]\xCE@>K\\7:;v\xCEN1<iHVEEOC\xCB\xFDBg3X;~Be\xCE\x1D5\xF9\x1D/\x1DkCg4V\xC0\xC3\xBFLnB<\xD2\xED\xDF\xAB\xE9\xFB;d\xFD;&\xB5\xEC\xDE\xB9\xFD=u\xB1\xC62<\xB5\xA4\xFAEl?RK7\xCBMh\xC6\xAF\xC0\xB5\xA4\xFC\xC8\xFD\xBF\xC0\xB4\xC8\xC7\xCF\xCA\xA4\e|\xE1\xC3\xBB\xF9\xB8\x19,?a\x19-9~\e}\xDE\xEC\xC6\xA4\xBF\xFA0lJ}@$EDC+\xC75/\xAD\xBF;&?M;v7o\xCEMF5?<T\xCBLnB<\xD2\xED\xDF\xAC>e\xAC\xC3\xBF\xFAF0MI\xB7\xBF@>K\\7:;v\xCF==DE@n7YIt\xCBAjCL\xF2\xB7\xFDC1?H\xFDE"}
	before do
		Encoding.default_external='utf-8'
	end
	it 'aoid error w/ illegal string' do
		ret=Ariblib::String.new(Ariblib::BitStream.new(str),str.size).to_utf8

		expect(ret).to eq "警視庁捜査一課の西本刑事の留守番電話に、大学時代のサークル仲間だった野村ひろみから「私、殺されます、助けて下さい。東尋坊に来てください」と、ただごとではないメッセージが吹き込まれていた。一方世田谷で起きた殺人事件の容疑者に野村ひろみが上がった。動揺した西本刑事は十津川警部に相談"
	end
	it '#new' do
		5.times do
			unless ts.transport_packet
				break
			end
		end
		ts.close

		ref=[
		["北海道・東北ふるさとタイム　＃５８　北海道特集","毎回一つの県にスポットを当てて、地元ＣＡＴＶが制作した地方色たっぷりの番組と、ご当地グルメやお祭りなどの旬な地域情報を紹介するニッポンのふるさと情報バラエティ！"],
		["テレビショッピング","　"],
		["ＣＮＮｊ〜世界のニュース〜","世界の最新情報を真っ先にお届けする専門チャンネル「ＣＮＮｊ」のおすすめ番組をこの時間におためしでご覧いただけます。この番組は日本語通訳付きでお送りしています。"],
		["まるごと動物ウォッチ　＃１７　静岡市立日本平動物園（静岡県）","テレビで楽しめるバーチャル動物園番組！今回は、静岡市立日本平動物園をご紹介。オオアリクイのハヅキは母親に甘えたり、飼育員さんの指をなめたり愛らしさ満点！"],
		["ＱＶＣ","　"],]
		5.times do |i|
			expect(ts.payload[0x12].contents[i][5][:title]).to eq ref[i][0]
			expect(ts.payload[0x12].contents[i][5][:desc]).to eq ref[i][1]
		end
	end
end
