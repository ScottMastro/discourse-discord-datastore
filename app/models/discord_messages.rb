# frozen_string_literal: true

class DiscordMessage < ActiveRecord::Base

  self.table_name = 'discord_messages'

  def self.add(message)
    puts "ADDING MESSAGE !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    DiscordMessage.create!(
      message_id: message.id,
      user_id: message.author.id,
      channel_id: message.channel.id,
      message: message.content,
      date: message.timestamp
    )

  end
end



#    DB.exec(<<~SQL, since: since_date)
#      INSERT INTO gamification_scores (user_id, date, score)
#      SELECT user_id, date, SUM(points) AS score
#      FROM (
#        #{queries}
#      ) AS source
#      GROUP BY 1, 2
#      ON CONFLICT (user_id, date) DO UPDATE
#      SET score = EXCLUDED.score
#    SQL
