# encoding: utf-8

# CUI操作のタイマーアプリ

# 準備
# play.exeを同フォルダに用意
# http://www.cepstrum.co.jp/download/recplay/recplay.html
# 音声ファイルを用意
# Windows10の場合 C:\Windows\WinSxS\ で sounds で検索

# 使用例
# DOSで実行する
# ruby timer.rb 25m && play Alarm04.wav

# 参考
# # timersクラス
# https://github.com/socketry/timers
# http://qiita.com/tbpgr/items/3b7f731bb8de4d293830
# waitメソッドを使わないとタイマー開始しないが、waitで処理が止まる
# pause中はwait_intervalメソッドの戻り値が残り秒数ではなくブランクになるバグ有り
#
# # スレッド処理
# http://www.atmarkit.co.jp/ait/articles/1412/12/news037.html
# http://www.atmarkit.co.jp/ait/articles/1412/12/news037.html
#
# # 起動オプション
# http://d.hatena.ne.jp/zariganitosh/20140819/ruby_optparser_true_power

require 'time'
require 'io/console'
require 'optparse'

# タイマー設定可能な数値かチェック
def available_number?(t)
  return false if !t   # nil判定
  return true if /^\d+?$/ =~ t   # 数値判定
  return true if /^\d+?:\d+?$/ =~ t
  return true if /^\d+?:\d+?:\d+?$/ =~ t
  return true if /^\d+?s$/ =~ t
  return true if /^\d+?m$/ =~ t
  return true if /^\d+?h$/ =~ t
  return true if /^\d+?m\d+?s$/ =~ t
  return true if /^\d+?h\d+?m$/ =~ t
  return true if /^\d+?h\d+?s$/ =~ t
  return true if /^\d+?h\d+?m\d+?s$/ =~ t
  return false
end

# 秒変換
def to_sec(t)
  return t.to_i if /^\d+?$/ =~ t

  m = t.match(/^(\d+?):(\d+?)$/)
  return (m[1].to_i * 60)  + m[2].to_i if !m.nil?

  m = t.match(/^(\d+?):(\d+?):(\d+?)$/)
  return (m[1].to_i * 3600) + (m[2].to_i * 60)  + m[3].to_i if /^\d+?:\d+?:\d+?$/ =~ t

  m = t.match(/^(\d+?)s$/)
  return m[1].to_i if /^\d+?s$/ =~ t

  m = t.match(/^(\d+?)m$/)
  return m[1].to_i * 60 if /^\d+?m$/ =~ t

  m = t.match(/^(\d+?)h$/)
  return m[1].to_i * 3600 if /^\d+?h$/ =~ t

  m = t.match(/^(\d+?)m(\d+?)s$/)
  return (m[1].to_i * 60) + m[2].to_i if /^\d+?m\d+?s$/ =~ t

  m = t.match(/^(\d+?)h(\d+?)m$/)
  return (m[1].to_i * 3600) + (m[2].to_i * 60) if /^\d+?h\d+?m$/ =~ t

  m = t.match(/^(\d+?)h(\d+?)s$/)
  return (m[1].to_i * 3600) + m[2].to_i if /^\d+?h\d+?s$/ =~ t

  m = t.match(/^(\d+?)h(\d+?)m(\d+?)s$/)
  return (m[1].to_i * 3600) + (m[2].to_i * 60) + m[3].to_i if /^\d+?h\d+?m\d+?s$/ =~ t
end

# 時分秒変換
def to_hms(sec)
  day = sec.to_i / 86400
  return (Time.parse("1/1") + (sec - day * 86400)).strftime("#{day}日 %H:%M:%S")
end

# タイムアウト処理
def timeout
  puts ""
  print "\033[2K\r" # 画面クリア
  exit 0
end

# --------- メイン処理 ---------

# オプション設定
option={}
OptionParser.new do |opt|
  opt.on_head('実行中に以下文字を入力することで各処理が行われる',
              'p 一時停止',
              'r 再開',
              's 停止',
              'd 残り時間表示')

  opt.on('-d', '残り時間を常に表示する') {|v| option[:d] = v}
  opt.parse!(ARGV)
end

# 引数エラーチェック
raise RuntimeError if !ARGV[0]
raise RuntimeError if !available_number?(ARGV[0])

# 引数 時刻 秒 相変換
sec = to_sec(ARGV[0])

pause_flg = false

wait_t = Thread.new do
  loop do
    sleep(0.1)

    # タイムアウト判定
    sec -= 0.1 if !pause_flg
    timeout if sec <= 0

    # 残り時間表示
    if option[:d]
      print "\033[2K\r" # 画面クリア
      print to_hms(sec)
    end
  end
end

# 入力判定
in_t = Thread.new do
  loop do
    case STDIN.getch
    when "p"
      pause_flg = true
    when "r"
      pause_flg = false
    when "s", "q"
      puts ""
      exit 1
    when "d"
      puts to_hms(sec)
    end
  end
end

wait_t.join
in_t.join
