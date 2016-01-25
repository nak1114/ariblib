require 'spec_helper'
require 'pp'

describe Ariblib::String do
	let(:ts){Ariblib::TransportStreamFile.new('spec/data/test_aa.ts')}
	before do
		Encoding.default_external='utf-8'
	end
	it '#new' , :debug => false do
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
			expect(ts.payload[0x12].event[i][4][0].event_name_char).to eq ref[i][0]
			expect(ts.payload[0x12].event[i][4][0].text_char).to eq ref[i][1]
		end
	end
end
