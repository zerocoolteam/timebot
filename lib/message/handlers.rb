module Message::Handlers

  private

  def handle_message_show_projects
    projects = Project.order(:id)
    text = projects.empty? ? 'No projects added yet.' : projects.map { |project| project.to_s }.join("\n")
    send_message(text)
  end

  def handle_unknown_message
    send_message('I don\'t understand you.')
  end

  def handle_message_show_help
    message = File.open(Rails.root.join('public', 'messages', 'help.txt').to_s, 'r').read
    send_message(message)
  end

  def handle_message_over
    user.update(is_speaking: false)
    send_message('Thanks bro! Have a nice day! :smiley: ')
  end

  def handle_message_time_for_other_day
    match_data = data.text.match Message::Conditions::ENTER_TIME_FOR_DAY_REGEXP

    day          = match_data[1].to_i
    month        = match_data[2].to_i
    year         = match_data[3].to_i < 2000 ? match_data[3].to_i + 2000 : match_data[3].to_i
    project_name = match_data[4]
    time         = match_data[5]
    details      = match_data[6]

    project = find_project_by_name(project_name)

    unless project
      send_message('No such project.')
      handle_message_show_projects
      return
    end

    date = Date.new(year, month, day)

    user.add_time_entry(project_id: project.id, time: time, details: details, date: date)

    message = "Set timesheet for #{date.strftime('%-d.%-m.%Y')} for #{project.name}: #{time}."
    if details
      message += " Details: #{details || 'none'}."
    end

    send_message(message)
  end

  def handle_timesheet_entry
    match_data = data.text.match(Message::Conditions::ENTER_TIME_REGEXP)
    if match_data
      handle_valid_timesheet_entry(match_data[1], match_data[2], match_data[3])
    else
      handle_invalid_timesheet_entry
    end
  end

  def handle_valid_timesheet_entry(project_name, time, details)
    project = find_project_by_name(project_name)

    unless project
      send_message('No such project.')
      handle_message_show_projects
      return
    end

    user.add_time_entry(project_id: project.id, time: time, details: details)
    send_message('Do you have any other projects to log? Write `no` to finish logging time.')
  end

  def handle_invalid_timesheet_entry
    send_message('Please add entry in following format: `PROJECT_NAME HOURS:MINUTES COMMENT(OPTIONAL)`')
  end

  def handle_add_project
    project_name = data.text.match(Message::Conditions::ADD_PROJECT_REGEXP)[1]
    project = find_project_by_name(project_name)

    if project
      handle_project_exists(project)
      return
    end

    if project_name.length < Project::MINIMUM_PROJECT_NAME_LENGTH
      handle_project_name_too_short
      return
    end

    project = Project.create!(name: project_name)
    handle_project_created(project)
  end

  def handle_project_exists(project)
    send_message("Project with name #{project.name} already exists.")
  end

  def handle_project_name_too_short
    send_message("Project name is too short - must be at least #{Project::MINIMUM_PROJECT_NAME_LENGTH} characters.")
  end

  def handle_project_created(project)
    send_message("Project with name #{project.name} is created.")
  end

  def handle_show_week
    handle_report(1.week.ago.to_date, Date.today)
  end

  def handle_show_month
    handle_report(Date.new(Date.today.year, Date.today.month, 1), Date.today)
  end

  def handle_report(start_date, end_date)
    list = (start_date..end_date).to_a.map do |date|
      entries = user.time_entries.where(date: date)
      entries.empty? ? [date, 'No entries'] : [date, entries.map(&:description).join('; ')]
    end

    strings = []
    list.each { |date, entries| strings << "`#{date.strftime('%d.%m.%y (%A)')}`: #{entries}" }
    strings << "*Total*: #{user.total_time_for_range(start_date, end_date)}."
    send_message(strings.join("\n"))
  end

  def find_project_by_name(project_name)
    Project.where(['lower(name) = ? OR lower(alias) = ?', project_name.downcase, project_name.downcase]).first
  end
end