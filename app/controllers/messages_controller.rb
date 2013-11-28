class MessagesController < ApplicationController
  include ActionController::Live

  def index
    @message = Message.new
    @messages = Message.all
  end

  def create
    attributes = params.require(:message).permit(:name, :body)
    @message = Message.create!(attributes)
    $redis.publish('messages.create', @message.to_json)
    head :no_content
  end

  def events
    response.headers["Content-Type"] = "text/event-stream"
    redis = Redis.new
    redis.subscribe('messages.create') do |on|
      on.message do |event, data|
        response.stream.write("data: #{data}\n\n")
      end
    end
  rescue IOError
    logger.info "Stream closed"
  ensure
    redis.quit
    response.stream.close
  end
end
