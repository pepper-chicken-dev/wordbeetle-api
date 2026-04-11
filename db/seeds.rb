# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

Rails.logger.debug 'Cleaning database...'
Setting.destroy_all
Example.destroy_all
Meaning.destroy_all
Word.destroy_all
Wordbook.destroy_all
User.destroy_all

Rails.logger.debug 'Creating test users...'
user1 = User.create!(
  email: 'test@example.com',
  name: 'Test User',
  provider: 'google',
  provider_uid: 'test123',
  avatar_url: 'https://example.com/avatar.jpg'
)

user2 = User.create!(
  email: 'demo@example.com',
  name: 'Demo User',
  provider: 'google',
  provider_uid: 'demo456',
  avatar_url: 'https://example.com/demo.jpg'
)

Rails.logger.debug 'Creating settings...'
Setting.create!(
  user: user1,
  hard_interval: 1.day,
  uncertain_interval: 3.days,
  easy_interval: 7.days
)

Setting.create!(
  user: user2,
  hard_interval: 2.days,
  uncertain_interval: 5.days,
  easy_interval: 10.days
)

Rails.logger.debug 'Creating wordbooks...'
wordbook1 = Wordbook.create!(
  user: user1,
  title: '英単語基礎'
)

wordbook2 = Wordbook.create!(
  user: user1,
  title: 'ビジネス英語'
)

Wordbook.create!(
  user: user2,
  title: 'TOEIC対策'
)

Rails.logger.debug 'Creating words...'
word1 = Word.create!(
  wordbook: wordbook1,
  spelling: 'apple',
  status: 'hard',
  next_review_at: 1.day.from_now
)

word2 = Word.create!(
  wordbook: wordbook1,
  spelling: 'book',
  status: 'uncertain',
  next_review_at: 3.days.from_now
)

word3 = Word.create!(
  wordbook: wordbook2,
  spelling: 'negotiate',
  status: 'not_studied',
  next_review_at: 2.days.from_now
)

Rails.logger.debug 'Creating meanings...'
Meaning.create!(
  word: word1,
  definition: 'りんご',
  display_order: 1
)

Meaning.create!(
  word: word2,
  definition: '本',
  display_order: 1
)

Meaning.create!(
  word: word2,
  definition: '予約する',
  display_order: 2
)

Meaning.create!(
  word: word3,
  definition: '交渉する',
  display_order: 1
)

Rails.logger.debug 'Creating examples...'
Example.create!(
  word: word1,
  sentence: 'I like apples.',
  translation: '私はりんごが好きです。',
  display_order: 1
)

Example.create!(
  word: word1,
  sentence: 'This is a red apple.',
  translation: 'これは赤いりんごです。',
  display_order: 2
)

Example.create!(
  word: word2,
  sentence: 'I read a book every day.',
  translation: '私は毎日本を読みます。',
  display_order: 1
)

Example.create!(
  word: word3,
  sentence: 'We need to negotiate the terms.',
  translation: '私たちは条件を交渉する必要があります。',
  display_order: 1
)

Rails.logger.debug 'Seed data created successfully!'
Rails.logger.debug { "Users: #{User.count}" }
Rails.logger.debug { "Settings: #{Setting.count}" }
Rails.logger.debug { "Wordbooks: #{Wordbook.count}" }
Rails.logger.debug { "Words: #{Word.count}" }
Rails.logger.debug { "Meanings: #{Meaning.count}" }
Rails.logger.debug { "Examples: #{Example.count}" }
