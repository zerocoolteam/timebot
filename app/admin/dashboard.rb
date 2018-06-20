# frozen_string_literal: true
ActiveAdmin.register_page 'Dashboard' do
  menu priority: 1, label: proc { I18n.t('active_admin.dashboard') }

  controller do
    def index
      unless params.dig(:q, :date_gteq_date) && params.dig(:q, :date_lteq_date)
        redirect_to admin_dashboard_url(q: { date_gteq_date: Date.today.beginning_of_week,
                                             date_lteq_date: Date.today.end_of_week })
      end
    end
  end

  content title: proc { I18n.t('active_admin.dashboard') } do
    start_date = Date.parse(params.dig(:q, :date_gteq_date))
    end_date   = Date.parse(params.dig(:q, :date_lteq_date))

    h2 "Statistics for #{start_date.strftime('%b %e, %Y')} - #{end_date.strftime('%b %e, %Y')}"

    h3 'Users'
    users = dashboard_users_stats
    table_for users, class: 'index_table' do
      column('Name') { |user| user[:name] }
      column('Hours Worked') { |user| user[:hours_worked] }
      column('Estimated Hours Worked') { |user| user[:estimated_hours_worked] }
      column('Difference') { |user| user[:difference] }
    end

    h3 'Project by User'
    projects = sql_dashboard_projects_stats
    table(class: 'index_table report') do
      thead do
        th 'Project'
        th 'User'
        th 'Details'
        th 'Labels'
        th 'Estimate'
        th 'Time'
      end
      tbody do
        projects.each_with_index do |project, index|
          tr(class: 'even report_by_user__project-name', 'data-id': project[:id]) do
            td do
              b project[:name]
            end
            td
            td
            td
            td
            td do
              b project[:total]
            end
          end
          tbody('data-by-user-project-id': project[:id], style:'display: none') do
            project[:users].each do |user|
              tr do
                td
                td user[:name]
                td
                td
                td
                td do
                  b user[:total]
                end
              end
              user[:entries].each do |time_entry|
                tr do
                  td
                  td
                  td time_entry[:details]
                  td formatted_labels(time_entry[:labels]).dig(:labels)
                  td formatted_labels(time_entry[:labels]).dig(:estimate)
                  td time_entry[:time]
                end
              end
            end
          end
        end
      end
    end

    h3 'Project by Ticket'
    table(class: 'index_table report') do
      thead do
        th 'Project'
        th 'Ticket'
        th 'Labels'
        th 'Users Worked on'
        th 'Estimate'
        th 'Time'
      end
      tbody do
        project_time_entries.each_with_index do |company_time_entry, index|
          tr(class: 'even report_by_ticket__project-name', 'data-id': company_time_entry.first.id) do
            td do
              b company_time_entry.first.name
            end
            td
            td
            td
            td
            td do
              b time_worked(company_time_entry)
            end
          end
          tbody('data-by-ticket-project-id': company_time_entry.first.id, style: 'display: none') do
            company_time_entry.last.group_by(&:details).each do |detail_time_entry|
              tr do
                td
                td detail_time_entry.first
                td formatted_labels(detail_time_entry.last.map(&:trello_labels))[:labels]
                td user_names(detail_time_entry)
                td formatted_labels(detail_time_entry.last.map(&:trello_labels))[:estimate]
                td time_worked(detail_time_entry)
              end
            end
          end
        end
      end
    end

    Team.all.each do |team|
      h3 "Project by Team #{team.name}"
      table(class: 'index_table report') do
        thead do
          th 'Project'
          th 'Ticket'
          th 'Labels'
          th 'Users Worked on'
          th 'Estimate'
          th 'Time'
        end
        tbody do
          team_project_time_entries(team.id).each_with_index do |company_time_entry, index|
            tr(class: 'even report_by_ticket__project-name', 'data-id': company_time_entry.first.id) do
              td do
                b company_time_entry.first.name
              end
              td
              td
              td
              td
              td do
                b time_worked(company_time_entry)
              end
            end
            tbody('data-by-ticket-project-id': company_time_entry.first.id, style: 'display: none') do
              company_time_entry.last.group_by(&:details).each do |detail_time_entry|
                tr do
                  td
                  td detail_time_entry.first
                  td formatted_labels(detail_time_entry.last.map(&:trello_labels))[:labels]
                  td user_names(detail_time_entry)
                  td formatted_labels(detail_time_entry.last.map(&:trello_labels))[:estimate]
                  td time_worked(detail_time_entry)
                end
              end
            end
          end
        end
      end
    end
  end

  sidebar :filters do
    form class: 'filter_form', method: '/get', action: '/admin' do
      div class: 'buttons' do
        button type: 'submit' do
          'Filter'
        end
        a class: 'clear_filters_btn', href: '#' do
          'Clear Filters'
        end
      end
    end
  end
end
