module IrcMachine
  class Session
    include Commands

    attr_reader :options
    attr_reader :state
    attr_accessor :irc_connection

    def initialize(options)
      IrcMachine::Plugin::Reloader.load_all

      @options = OpenStruct.new(options)
      @state = State.new
      @router = HttpRouter.new(self)
      @plugins = [
        Core.new(self),
        Plugin::Verbose.new(self),
        Plugin::Die.new(self),
        Plugin::Hello.new(self),
        Plugin::Reloader.new(self)
      ]
    end

    def start
      EM.run do

        EM.connect options.server, options.port, IrcConnection do |c|
          self.irc_connection = c
          c.session = self
        end

        EM.start_server "0.0.0.0", 8421, HttpServer do |c|
          c.router = @router
        end

        dispatch :start
      end
    end

    def receive_line(line)
      dispatch :receive_line, line
    end

    private

    def dispatch(method, *params)
      @plugins.each { |p| p.send(method, *params) if p.respond_to? method }
    end

  end
end
