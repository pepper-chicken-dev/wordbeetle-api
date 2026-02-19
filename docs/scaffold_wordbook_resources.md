# Wordbook Resources 構築手順

このドキュメントでは、wordbeetle-api に単語帳機能のリソース（モデル、コントローラ、マイグレーション）を追加する手順を説明します。

## 1. ブランチの作成

```bash
git checkout -b feature/scaffold-wordbook-resources
```

## 2. モデルとマイグレーションの生成

### Wordbook モデル

```bash
bin/rails generate model Wordbook user:references title:string
```

生成後、マイグレーションファイルを編集して `null: false` 制約を追加：

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_wordbooks.rb
class CreateWordbooks < ActiveRecord::Migration[8.1]
  def change
    create_table :wordbooks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false

      t.timestamps
    end
  end
end
```

モデルファイルにバリデーションとアソシエーションを追加：

```ruby
# app/models/wordbook.rb
class Wordbook < ApplicationRecord
  belongs_to :user
  has_many :words, dependent: :destroy

  validates :title, presence: true
end
```

### Word モデル

```bash
bin/rails generate model Word wordbook:references spelling:string status:string next_review_date:date
```

マイグレーションファイルを編集：

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_words.rb
class CreateWords < ActiveRecord::Migration[8.1]
  def change
    create_table :words do |t|
      t.references :wordbook, null: false, foreign_key: true
      t.string :spelling, null: false
      t.string :status, null: false
      t.date :next_review_date

      t.timestamps
    end
  end
end
```

モデルファイルを編集：

```ruby
# app/models/word.rb
class Word < ApplicationRecord
  belongs_to :wordbook
  has_many :meanings, dependent: :destroy
  has_many :examples, dependent: :destroy

  validates :spelling, presence: true
  validates :status, presence: true

  enum :status, { learning: 'learning', learned: 'learned' }
end
```

### Meaning モデル

```bash
bin/rails generate model Meaning word:references content:text display_order:integer
```

マイグレーションファイルを編集：

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_meanings.rb
class CreateMeanings < ActiveRecord::Migration[8.1]
  def change
    create_table :meanings do |t|
      t.references :word, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :display_order, null: false

      t.timestamps
    end
  end
end
```

モデルファイルを編集：

```ruby
# app/models/meaning.rb
class Meaning < ApplicationRecord
  belongs_to :word

  validates :content, presence: true
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
```

### Example モデル

```bash
bin/rails generate model Example word:references sentence:text translation:text display_order:integer
```

マイグレーションファイルを編集：

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_examples.rb
class CreateExamples < ActiveRecord::Migration[8.1]
  def change
    create_table :examples do |t|
      t.references :word, null: false, foreign_key: true
      t.text :sentence, null: false
      t.text :translation, null: false
      t.integer :display_order, null: false

      t.timestamps
    end
  end
end
```

モデルファイルを編集：

```ruby
# app/models/example.rb
class Example < ApplicationRecord
  belongs_to :word

  validates :sentence, presence: true
  validates :translation, presence: true
  validates :display_order, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
```

### Setting モデル

```bash
bin/rails generate model Setting user:references hard_interval_days:integer uncertain_interval_days:integer easy_interval_days:integer
```

マイグレーションファイルを編集：

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_settings.rb
class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :hard_interval_days, null: false
      t.integer :uncertain_interval_days, null: false
      t.integer :easy_interval_days, null: false

      t.timestamps
    end
  end
end
```

モデルファイルを編集：

```ruby
# app/models/setting.rb
class Setting < ApplicationRecord
  belongs_to :user

  validates :hard_interval_days, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :uncertain_interval_days, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :easy_interval_days, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
```

### User モデルにアソシエーション追加

```ruby
# app/models/user.rb
class User < ApplicationRecord
  has_many :wordbooks, dependent: :destroy
  has_one :setting, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :google_id, presence: true, uniqueness: true
end
```

## 3. マイグレーションの実行

```bash
bin/rails db:migrate
```

## 4. コントローラの生成

### Wordbooks コントローラ

```bash
bin/rails generate controller Api::V1::Wordbooks --skip-routes --skip-helper --skip-assets
```

生成されたコントローラファイルを編集：

```ruby
# app/controllers/api/v1/wordbooks_controller.rb
module Api
  module V1
    class WordbooksController < ApplicationController
      before_action :set_wordbook, only: [:show, :update, :destroy]

      def index
        wordbooks = Wordbook.all
        render json: wordbooks
      end

      def show
        render json: @wordbook
      end

      def create
        wordbook = Wordbook.new(wordbook_params)

        if wordbook.save
          render json: wordbook, status: :created
        else
          render json: { errors: wordbook.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @wordbook.update(wordbook_params)
          render json: @wordbook
        else
          render json: { errors: @wordbook.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @wordbook.destroy
        head :no_content
      end

      private

      def set_wordbook
        @wordbook = Wordbook.find(params[:id])
      end

      def wordbook_params
        params.require(:wordbook).permit(:user_id, :title)
      end
    end
  end
end
```

### 同様に他のコントローラも生成

```bash
bin/rails generate controller Api::V1::Words --skip-routes --skip-helper --skip-assets
bin/rails generate controller Api::V1::Meanings --skip-routes --skip-helper --skip-assets
bin/rails generate controller Api::V1::Examples --skip-routes --skip-helper --skip-assets
bin/rails generate controller Api::V1::Settings --skip-routes --skip-helper --skip-assets
```

各コントローラファイルに CRUD アクションを実装（Wordbooks コントローラと同様のパターン）

## 5. ルーティングの設定

```ruby
# config/routes.rb
Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Authentication
      post "auth/google", to: "auth#google"

      # Resources
      resources :wordbooks
      resources :words
      resources :meanings
      resources :examples
      resources :settings
    end
  end
end
```

ルーティングの確認：

```bash
bin/rails routes | grep api
```

## 6. シードデータの作成

```ruby
# db/seeds.rb
# テスト用のシードデータ

puts "Cleaning database..."
Setting.destroy_all
Example.destroy_all
Meaning.destroy_all
Word.destroy_all
Wordbook.destroy_all
User.destroy_all

puts "Creating test users..."
user1 = User.create!(
  email: "test@example.com",
  name: "Test User",
  google_id: "test123",
  avatar_url: "https://example.com/avatar.jpg"
)

user2 = User.create!(
  email: "demo@example.com",
  name: "Demo User",
  google_id: "demo456",
  avatar_url: "https://example.com/demo.jpg"
)

puts "Creating settings..."
Setting.create!(
  user: user1,
  hard_interval_days: 1,
  uncertain_interval_days: 3,
  easy_interval_days: 7
)

puts "Creating wordbooks..."
wordbook1 = Wordbook.create!(
  user: user1,
  title: "英単語基礎"
)

wordbook2 = Wordbook.create!(
  user: user1,
  title: "ビジネス英語"
)

puts "Creating words..."
word1 = Word.create!(
  wordbook: wordbook1,
  spelling: "apple",
  status: "learning",
  next_review_date: Date.today + 1
)

word2 = Word.create!(
  wordbook: wordbook1,
  spelling: "book",
  status: "learning",
  next_review_date: Date.today + 3
)

puts "Creating meanings..."
Meaning.create!(
  word: word1,
  content: "りんご",
  display_order: 1
)

Meaning.create!(
  word: word2,
  content: "本",
  display_order: 1
)

puts "Creating examples..."
Example.create!(
  word: word1,
  sentence: "I like apples.",
  translation: "私はりんごが好きです。",
  display_order: 1
)

puts "Seed data created successfully!"
puts "Users: #{User.count}"
puts "Settings: #{Setting.count}"
puts "Wordbooks: #{Wordbook.count}"
puts "Words: #{Word.count}"
puts "Meanings: #{Meaning.count}"
puts "Examples: #{Example.count}"
```

シードデータの投入：

```bash
bin/rails db:seed
```

## 7. 動作確認

### サーバーの起動

```bash
bin/rails server -p 3001
```

### API のテスト

```bash
# Wordbooks 一覧取得
curl http://localhost:3001/api/v1/wordbooks | python3 -m json.tool

# Words 一覧取得
curl http://localhost:3001/api/v1/words | python3 -m json.tool

# 特定の Word 取得
curl http://localhost:3001/api/v1/words/1 | python3 -m json.tool

# Wordbook 作成
curl -X POST http://localhost:3001/api/v1/wordbooks \
  -H "Content-Type: application/json" \
  -d '{"wordbook": {"user_id": 1, "title": "新しい単語帳"}}' | python3 -m json.tool

# Meanings 一覧取得
curl http://localhost:3001/api/v1/meanings | python3 -m json.tool

# Examples 一覧取得
curl http://localhost:3001/api/v1/examples | python3 -m json.tool
```

## 8. コミット

```bash
git add .
git commit -m "Add wordbook resources (models, controllers, migrations)"
```

## 注意事項

- マイグレーションファイルのタイムスタンプは生成時に自動で付与されます
- `enum` の構文は Rails 8.1 では `enum :attribute, { ... }` の形式を使用します
- 外部キー制約は `foreign_key: true` で自動的に設定されます
- `dependent: :destroy` により親レコード削除時に関連レコードも削除されます

## 生成されたファイル一覧

### モデル (5)

- `app/models/wordbook.rb`
- `app/models/word.rb`
- `app/models/meaning.rb`
- `app/models/example.rb`
- `app/models/setting.rb`

### コントローラ (5)

- `app/controllers/api/v1/wordbooks_controller.rb`
- `app/controllers/api/v1/words_controller.rb`
- `app/controllers/api/v1/meanings_controller.rb`
- `app/controllers/api/v1/examples_controller.rb`
- `app/controllers/api/v1/settings_controller.rb`

### マイグレーション (5)

- `db/migrate/YYYYMMDDHHMMSS_create_wordbooks.rb`
- `db/migrate/YYYYMMDDHHMMSS_create_words.rb`
- `db/migrate/YYYYMMDDHHMMSS_create_meanings.rb`
- `db/migrate/YYYYMMDDHHMMSS_create_examples.rb`
- `db/migrate/YYYYMMDDHHMMSS_create_settings.rb`

### その他の変更ファイル

- `app/models/user.rb` (アソシエーション追加)
- `config/routes.rb` (ルーティング追加)
- `db/schema.rb` (自動更新)
- `db/seeds.rb` (テストデータ作成)
