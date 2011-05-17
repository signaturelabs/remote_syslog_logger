require File.expand_path('../helper', __FILE__)

class TestRemoteSyslogLogger < Test::Unit::TestCase
  def setup
    @server_port = rand(50000) + 1024
    @socket = UDPSocket.new
    @socket.bind('127.0.0.1', @server_port)
  end
  
  def test_logger
    @logger = RemoteSyslogLogger.new('127.0.0.1', @server_port)
    @logger.info "This is a test"
    
    message, addr = *@socket.recvfrom(1024)
    assert_match /This is a test/, message
  end

  def test_logger_multiline
    @logger = RemoteSyslogLogger.new('127.0.0.1', @server_port)
    @logger.info "This is a test\nThis is the second line"

    message, addr = *@socket.recvfrom(1024)
    assert_match /This is a test/, message

    message, addr = *@socket.recvfrom(1024)
    assert_match /This is the second line/, message
  end

  def test_whinyerrors
    assert_nothing_raised do
      @logger = RemoteSyslogLogger.new('this_is_an_invalid_url', @server_port,
        :whinyerrors => false)
      @logger.info "This will never be received"
    end

    assert_raise SocketError do
      @logger = RemoteSyslogLogger.new('this_is_an_invalid_url', @server_port,
        :whinyerrors => true)
      @logger.info "This will never be received"
    end
  end

  def test_backuplog
    assert_nothing_raised do
      @logger = RemoteSyslogLogger.new('this_is_an_invalid_url', @server_port,
        :backuplog => RemoteSyslogLogger.new('127.0.0.1', @server_port),
        :whinyerrors => false)
      @logger.info "This will never be received"
    end
    message, addr = *@socket.recvfrom(1024)
    assert_match /SocketError/, message

    assert_raise SocketError do
      @logger = RemoteSyslogLogger.new('this_is_an_invalid_url', @server_port,
        :backuplog => RemoteSyslogLogger.new('127.0.0.1', @server_port),
        :whinyerrors => true)
      @logger.info "This will never be received"
    end
    message, addr = *@socket.recvfrom(1024)
    assert_not_nil message
  end

end
