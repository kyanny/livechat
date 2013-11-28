class MessagesController < ApplicationController
  include ActionController::Live

  def index
    @message = Message.new
    @messages = Message.all
  end

  def create
    if message = Message.create(params.require(:message).permit(:name, :body))
      head :no_content
    else
      render json: message.errors, status: :unprocessable_entity
    end
  end

  def events
    response.headers["Content-Type"] = "text/event-stream"
    start = Time.zone.now
    10.times do
      Message.uncached do
        Message.where('created_at > ?', start).each do |message|
          response.stream.write("data: #{message.to_json}\n\n")
          start = Time.zone.now
        end
      end
      sleep 2
    end
  rescue IOError
    logger.info "Stream closed"
  ensure
    response.stream.close
  end
end
