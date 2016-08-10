class User < ApplicationRecord

  has_many :time_entries

  validates :name, presence: true, uniqueness: true
  validates :uid, presence: true, uniqueness: true

  def add_time_entry(project_id:, time:, details:, date: Date.today)
    raise 'Invalid date' if date > Date.today
    entry = self.time_entries.find_by(project_id: project_id, date: date) || self.time_entries.build(project_id: project_id, date: date)
    entry.time    = time
    entry.minutes = parse_time(time)
    entry.details = details
    entry.save!
  end

  private

  def parse_time(time)
    match_data = time.match(/^(\d?\d):([0-5]\d)$/)
    match_data[1].to_i * 60 + match_data[2].to_i
  end
end