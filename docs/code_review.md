# WordBeetle API コードレビュー

レビュー実施日: 2026-03-24

## 概要

リポジトリ全体をレビューし、改善すべき点を優先度別にまとめました。
現時点でセキュリティの基本（認証・認可・Strong Parameters・スコープ付きクエリ）はしっかり実装されています。

---

## 優先度: 高

### 1. グローバルエラーハンドリングの不足

**現状**: `ApplicationController` では `ActiveRecord::RecordNotFound` のみ rescue している。

```ruby
# app/controllers/application_controller.rb
rescue_from ActiveRecord::RecordNotFound do
  render json: { error: "Not found" }, status: :not_found
end
```

**問題**:
- `ActionController::ParameterMissing`（例: `params.require(:word)` でキーがない場合）が 500 エラーになる
- 予期しない例外が発生した場合、本番環境で適切な JSON レスポンスが返らない可能性がある

**改善案**:

```ruby
class ApplicationController < ActionController::API
  include Authenticatable

  # 本番環境のみ: 予期しないエラーのキャッチオール（最低優先度）
  # rescue_from は後に定義されたハンドラほど優先度が高いため、StandardError は一番上に置く
  if Rails.env.production?
    rescue_from StandardError do |e|
      Rails.logger.error("Unhandled error: #{e.class} - #{e.message}")
      Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
      render json: { error: "Internal server error" }, status: :internal_server_error
    end
  end

  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Not found" }, status: :not_found
  end

  rescue_from ActiveRecord::RecordNotUnique do
    render json: { error: "Duplicate record" }, status: :conflict
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :bad_request
  end
end
```

### 2. ルーティング構造がモデルの親子関係を反映していない

**対象ファイル**: `config/routes.rb`

**現状**:

```ruby
resources :wordbooks
resources :words
resources :meanings
resources :examples
resources :settings
```

全てフラットなトップレベルリソースになっている。

**問題**:
- モデル上は `Wordbook has_many :words`、`Word has_many :meanings, :examples` という親子関係があるのに、ルーティングがそれを反映していない
- `POST /api/v1/words` で `wordbook_id` をボディに渡す必要がある（URL から親リソースが分からない）
- `GET /api/v1/words` が全単語帳の単語を横断取得する（一般的なユースケースではない）
- `GET /api/v1/meanings`, `GET /api/v1/examples` も同様に全単語の意味・例文を横断取得する
- `settings` は1ユーザにつき1つだが `resources`（複数形）で定義されており、ID 指定が必要

**改善案**:

```ruby
resources :wordbooks do
  resources :words, shallow: true do
    resources :meanings, shallow: true
    resources :examples, shallow: true
  end
end
resource :setting, only: [:show, :create, :update, :destroy]
```

`shallow: true` により、一覧・作成は親リソースの下にネスト、個別リソース操作（show/update/delete）は短い URL のまま。

| 現状 | 改善後 |
|------|--------|
| `GET /api/v1/words` | `GET /api/v1/wordbooks/:wordbook_id/words` |
| `POST /api/v1/words` (body に wordbook_id) | `POST /api/v1/wordbooks/:wordbook_id/words` |
| `GET /api/v1/words/:id` | `GET /api/v1/words/:id` (shallow) |
| `POST /api/v1/meanings` (body に word_id) | `POST /api/v1/words/:word_id/meanings` |
| `GET /api/v1/settings/:id` | `GET /api/v1/setting` (ID 不要) |

### 3. N+1 クエリのリスク

**対象ファイル**:
- `app/controllers/api/v1/words_controller.rb:7`
- `app/controllers/api/v1/meanings_controller.rb:7`
- `app/controllers/api/v1/examples_controller.rb:7`
- `app/controllers/api/v1/wordbooks_controller.rb:7`

**問題**: 一覧取得時に関連データを eager loading していない。現時点では `render json:` で `as_json` のデフォルト動作が使われており、関連を含まないため直ちに N+1 は発生しないが、今後シリアライザを導入して関連データ（Word の meanings/examples 等）を含めるようになった際に確実に問題になる。

**改善案**: 将来的にシリアライザ導入時は `includes` を追加する。

```ruby
# words_controller.rb
def index
  words = Word.joins(:wordbook)
              .where(wordbooks: { user_id: current_user.id })
              .includes(:meanings, :examples)
  render json: words
end
```

### 4. ゲストユーザの期限切れ削除ジョブが未実装

**根拠**: 要件 `docs/requirements.md` に「期限切れ後、ゲストユーザとデータを自動削除」と記載あり（P0）。

**問題**: `guest_expires_at` を過ぎたゲストユーザを削除するバックグラウンドジョブが存在しない。`ApplicationJob` は空のまま。

**改善案**:

```ruby
# app/jobs/cleanup_expired_guests_job.rb
class CleanupExpiredGuestsJob < ApplicationJob
  queue_as :default

  def perform
    User.where(provider: "guest").where("guest_expires_at < ?", Time.current).find_each(&:destroy)
  end
end
```

Solid Queue の recurring タスクとして登録（例: 毎日1回実行）。

### 5. ゲストユーザの期限切れチェックが認証時に行われていない

**対象ファイル**: `app/controllers/concerns/authenticatable.rb:12-20`

**問題**: JWT の `exp` はゲストユーザの `guest_expires_at` に基づいて設定されるが、`guest_expires_at` を直接変更された場合（管理操作等）や、JWT 発行後にユーザ状態が変わった場合の考慮がない。

**改善案**: `authenticate_user!` 内でゲストユーザの有効期限も確認する。

```ruby
def authenticate_user!
  # ... 既存の処理 ...
  @current_user = User.find_by(id: payload["sub"])
  return render_unauthorized unless @current_user
  return render_unauthorized if @current_user.guest? && @current_user.guest_expires_at&.past?
end
```

---

## 優先度: 中

### 6. レスポンスのシリアライゼーション戦略が不統一

**問題**:
- ほとんどのコントローラは `render json: model` でデフォルトの `as_json` を使用（全カラムが出力される）
- `SettingsController` だけカスタムの `setting_response` メソッドを使用
- `AuthController` は `as_json(only: [...])` で出力を制限

**リスク**: デフォルトの `as_json` は `id`, `created_at`, `updated_at`, `user_id` 等の内部情報を全て返す。今後カラムが増えた際に意図せず機密情報が露出する可能性がある。

**改善案**: シリアライザ（`blueprinter`, `alba`, `jsonapi-serializer` 等）を導入し、レスポンスの形を明示的に定義する。

### 7. ページネーションの未実装

**問題**: 全ての一覧エンドポイント（`GET /api/v1/words`, `GET /api/v1/meanings` 等）がページネーションなしで全件返す。

**リスク**: ユーザのデータが増えるとレスポンスが巨大になり、パフォーマンスが劣化する。要件にも「API レスポンスタイム: 500ms 以内」の非機能要件がある。

**改善案**: `kaminari` や `pagy` を導入し、`page` / `per_page` パラメータをサポートする。

### 8. レート制限の未実装

**問題**: API へのレート制限がない。認証エンドポイント（`POST /api/v1/auth/guest`, `POST /api/v1/auth/google`）を含む全エンドポイントが無制限。

**リスク**:
- ゲストユーザ作成の乱用（大量のゴミデータ）
- Google 認証エンドポイントへのブルートフォース
- DoS 攻撃に対する脆弱性

**改善案**: `rack-attack` gem を導入。

```ruby
# config/initializers/rack_attack.rb
Rack::Attack.throttle("auth/guest", limit: 5, period: 1.minute) do |req|
  req.ip if req.path == "/api/v1/auth/guest" && req.post?
end

Rack::Attack.throttle("api/ip", limit: 300, period: 5.minutes) do |req|
  req.ip if req.path.start_with?("/api/")
end
```

### 9. `find_or_create_by` のレースコンディション

**対象ファイル**: `app/controllers/api/v1/auth_controller.rb:38`

```ruby
user = User.find_or_create_by(provider: "google", provider_uid: payload["sub"]) do |u|
  u.email = email
  u.name = payload["name"]
  u.avatar_url = payload["picture"]
end
```

**問題**: 同一ユーザが同時に Google 認証を行った場合、`find_or_create_by` はレースコンディションで `ActiveRecord::RecordNotUnique` を投げる可能性がある（DB にユニーク制約があるため）。

**改善案**: リトライロジックを追加。

```ruby
user = User.find_or_create_by(provider: "google", provider_uid: payload["sub"]) do |u|
  u.email = email
  u.name = payload["name"]
  u.avatar_url = payload["picture"]
end
rescue ActiveRecord::RecordNotUnique
  retry
```

### 10. Google 認証時にユーザ情報が更新されない

**対象ファイル**: `app/controllers/api/v1/auth_controller.rb:38-42`

**問題**: `find_or_create_by` のブロックはレコード作成時にのみ実行される。既存ユーザがログインした場合、Google 側で名前やアバターを変更してもアプリ側には反映されない。

**改善案**:

```ruby
user = User.find_or_create_by(provider: "google", provider_uid: payload["sub"]) do |u|
  u.email = email
  u.name = payload["name"]
  u.avatar_url = payload["picture"]
end
user.update(name: payload["name"], avatar_url: payload["picture"]) unless user.previously_new_record?
```

### 11. Settings が1ユーザにつき複数作成可能

**対象ファイル**: `app/models/setting.rb`, `db/schema.rb`

**問題**:
- `User has_one :setting` だがDBレベルでの一意制約がない（`user_id` に UNIQUE インデックスがない）
- `SettingsController` の `create` アクションに重複チェックがない
- 同一ユーザが `POST /api/v1/settings` を2回呼ぶと2つの Settings が作成される

**改善案**:
1. `settings` テーブルの `user_id` に UNIQUE インデックスを追加
2. `create` アクション内で既存チェックを追加

### 12. `config.hosts` が未設定（DNS Rebinding 対策）

**対象ファイル**: `config/environments/production.rb:61-67`

**問題**: `config.hosts` がコメントアウトされている。本番デプロイ時に DNS Rebinding 攻撃に対して脆弱。

**改善案**: 本番環境のドメインを設定する。

---

## 優先度: 低

### 13. テストカバレッジのギャップ

以下のシナリオのテストが不足している:

- **ゲストユーザ期限切れ後のアクセス**: 期限切れトークンでのリクエストテスト
- **Settings の重複作成防止**: 同一ユーザが2回 POST した場合のテスト
- **カスケード削除の検証**: Wordbook 削除時に Words/Meanings/Examples が削除されることの request spec
- **不正な JSON ボディ**: `Content-Type: application/json` でパース不能なボディを送った場合
- **`ActionController::ParameterMissing`**: `word` キーなしで POST した場合のテスト

### 14. APIバージョニングのフォールバック

**問題**: `/api/v1/` のみ定義されており、バージョンが指定されていない場合（`/api/wordbooks` 等）は 404 になる。これ自体は問題ないが、将来の v2 導入時の戦略を検討しておくと良い。

### 15. `openapi.yaml` と実装の同期

**問題**: OpenAPI 仕様書が手動管理されている。実装とドキュメントの乖離が発生しやすい。

**改善案**: `rswag` gem を導入し、テストから OpenAPI 仕様を自動生成する、または CI で仕様と実装の整合性をチェックする仕組みを入れる。

### 16. ログ出力の強化

**現状**: Google 認証エラーのみログ出力されている。

**改善案**:
- 認証失敗（401）のログ出力（不正アクセスの検知用）
- リクエストの処理時間ログ（パフォーマンス監視用）
- ゲストマイグレーションの成功/失敗ログ

### 17. `Wordbook.title` / `Word.spelling` の長さ制限

**問題**: バリデーションに `presence: true` のみで、長さ制限がない。極端に長い文字列を保存できる。

**改善案**:

```ruby
validates :title, presence: true, length: { maximum: 255 }
validates :spelling, presence: true, length: { maximum: 255 }
```

### 18. ヘルスチェックの強化

**現状**: `/up` で Rails のデフォルトヘルスチェック（アプリ起動確認のみ）を使用。

**改善案**: データベース接続確認も含めたカスタムヘルスチェックを検討。

```ruby
# /api/v1/health でDB接続も確認
def show
  ActiveRecord::Base.connection.execute("SELECT 1")
  render json: { status: "ok" }
rescue => e
  render json: { status: "error", message: e.message }, status: :service_unavailable
end
```

---

## 良い点（現時点で適切に実装されていること）

- **認証・認可**: JWT + Google ID Token の組み合わせが適切に実装されている
- **スコープ付きクエリ**: 全リソースが `current_user` 経由でフィルタリングされており、他ユーザのデータにアクセスできない
- **Strong Parameters**: 全コントローラで `permit` による明示的なホワイトリスト
- **DB 制約**: CHECK 制約、UNIQUE 制約、NOT NULL 制約が適切に設定されている
- **カスケード削除**: `dependent: :destroy` が正しく設定されている
- **ゲストマイグレーション**: トランザクション内で2つのシナリオ（変換/マージ）が安全に処理されている
- **テスト**: 認証、CRUD、権限チェックの基本的なテストが網羅されている
- **パラメータフィルタリング**: `filter_parameter_logging.rb` で token、email 等がログから除外されている
