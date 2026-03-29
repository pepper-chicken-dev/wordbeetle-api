class ChangeIntervalsToIntervalType < ActiveRecord::Migration[8.1]
  def up
    # settings: integer -> interval type
    add_column :settings, :hard_interval, :interval
    add_column :settings, :uncertain_interval, :interval
    add_column :settings, :easy_interval, :interval

    execute <<~SQL.squish
      UPDATE settings
      SET hard_interval = make_interval(days => hard_interval_days),
          uncertain_interval = make_interval(days => uncertain_interval_days),
          easy_interval = make_interval(days => easy_interval_days)
    SQL

    change_column_null :settings, :hard_interval, false
    change_column_null :settings, :uncertain_interval, false
    change_column_null :settings, :easy_interval, false
    remove_column :settings, :hard_interval_days
    remove_column :settings, :uncertain_interval_days
    remove_column :settings, :easy_interval_days

    # words: date -> datetime, rename next_review_date -> next_review_at
    rename_column :words, :next_review_date, :next_review_at
    change_column :words, :next_review_at, :datetime
  end

  def down
    # words: datetime -> date
    change_column :words, :next_review_at, :date
    rename_column :words, :next_review_at, :next_review_date

    # settings: interval -> integer
    add_column :settings, :hard_interval_days, :integer
    add_column :settings, :uncertain_interval_days, :integer
    add_column :settings, :easy_interval_days, :integer

    execute <<~SQL.squish
      UPDATE settings
      SET hard_interval_days = EXTRACT(EPOCH FROM hard_interval) / 86400,
          uncertain_interval_days = EXTRACT(EPOCH FROM uncertain_interval) / 86400,
          easy_interval_days = EXTRACT(EPOCH FROM easy_interval) / 86400
    SQL

    change_column_null :settings, :hard_interval_days, false
    change_column_null :settings, :uncertain_interval_days, false
    change_column_null :settings, :easy_interval_days, false
    remove_column :settings, :hard_interval
    remove_column :settings, :uncertain_interval
    remove_column :settings, :easy_interval
  end
end
