#! ruby -EUTF-8:UTF-8
# coding: UTF-8

$LOAD_PATH.unshift File.join( File.dirname(__FILE__), 'lib' )

require 'webrick'

server = WEBrick::HTTPServer.new( DocumentRoot: File.join( File.dirname(__FILE__), 'www' ), Port: 8000 )
server.mount_proc( '/time_stream' ) do |req, res|
  res.content_type = 'text/event-stream'
  r,w = IO.pipe
  res.body = r
  res.chunked = true
  t = Thread.new do
    begin
      20.times do
        w << 'data: ' << Time.now.to_s << "\x0D\x0A"
        w << "\x0D\x0A"
        sleep 1
      end
      w << 'event: end' << "\x0D\x0A"
      w << 'data: end'  << "\x0D\x0A"
      w << "\x0D\x0A"
    rescue => err
      # 接続断で r 側が閉じられた場合に w への書き込みを行おうとすると
      # Errno::EPIPE エラー
    ensure
      w.close()
    end
  end
end

trap :INT do server.shutdown end
server.start
