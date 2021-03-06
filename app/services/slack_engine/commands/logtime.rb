# frozen_string_literal: true

module SlackEngine
  module Commands
    class Logtime
      def initialize(params)
        @trigger_id = params[:trigger_id]
        @client = Slack::Web::Client.new(token: ENV.fetch('TIMEBOT_APP_TOKEN'))
      end

      def perform
        client.dialog_open(dialog: dialog, trigger_id: trigger_id)
      end

      private

      attr_reader :client, :trigger_id

      def dialog
        {
          callback_id: SlackEngine::CollbackConstants::LOGTIME,
          title: 'Log time',
          submit_label: 'Add',
          elements: elements
        }
      end

      def elements
        [
          {
            label: 'Select project', type: 'select', name: 'project',
            options: Project.order_by_entries_number.map { |p| { label: p.name, value: p.id } }
          },
          {
            label: 'Week', type: 'select', name: 'week', value: 0,
            options: [{ label: 'Current', value: 0 }, { label: 'Previous', value: 1 }]
          },
          {
            label: 'Select date', type: 'select', name: 'date', value: Time.current.strftime('%Y-%m-%d'),
            options: date_range
          },
          { type: 'text', label: 'Time spent (00:00)', name: 'time' },
          { label: 'What have you done?', name: 'details', type: 'textarea' }
        ]
      end

      def date_range
        (Time.current.beginning_of_week.to_date..Time.current.end_of_week.to_date)
          .to_a
          .map { |t| { label: t.strftime('%A'), value: t.strftime('%Y-%m-%d') } }
      end
    end
  end
end
