class EventHandler

  include Message::Conditions
  include Message::Handlers

  attr_reader :client, :data, :user

  def initialize(client, data)
    @client = client
    @data   = data
  end

  def handle_message
    return if data.bot_id
    puts "Handling message: #{data.text}"
    @user = User.find_by(uid: data.user)

    if message_is_request_for_project
      handle_message_show_projects
    elsif message_is_request_for_help
      handle_message_show_help
    elsif message_is_enter_time_for_day
      handle_message_time_for_other_day
    elsif message_is_over
      handle_message_over
    elsif user.is_speaking
      handle_timesheet_entry
    else
      handle_unknown_message
    end
  rescue => e
    puts e
    puts e.backtrace.join("\n\t")
    send_message('Sorry. An error occurred.')
  end

  private

  def send_message(text)
    client.web_client.chat_postMessage(channel: user.uid, text: text, as_user: true)
    puts "Send message with text: #{text}"
  end
end