# RuboCop 設定ガイド

## 背景

本プロジェクトはもともと `rubocop-rails-omakase`（v1.1.0）を RuboCop の設定として使用していた。
omakase プリセットはフォーマット系の少数の cop のみを有効にし、大半のカテゴリを無効化する設計になっている:

- **Security**: 全 cop 無効
- **Lint**: 3 cop のみ有効（RedundantStringCoercion, RequireParentheses, UriEscapeUnescape）
- **Style**: 約12 cop 有効（主にフォーマット系）
- **Layout**: 約25 cop 有効
- **Rails**: 2 cop のみ有効（AssertNot, RefuteMethods）
- **Performance**: 1 cop のみ有効（FlatMap）
- **Metrics / Naming / Bundler / Gemspec**: 全て無効

これにより、セキュリティやコード正当性に関する静的解析のカバレッジに大きな空白があった。

## 現在の設定

`rubocop-rails-omakase` を標準的な RuboCop gem 群に置き換え、汎用的な設定を構築した。

### 導入 gem

| gem | 用途 |
| --- | --- |
| `rubocop` | Ruby の基本的な lint・スタイルチェック |
| `rubocop-rails` | Rails 固有の cop（ActiveRecord, ルーティング, コントローラーパターン） |
| `rubocop-performance` | パフォーマンス関連の cop（非効率なパターン、不要なメモリ割り当て） |
| `rubocop-rspec` | RSpec 固有の cop（テスト構造、命名、ベストプラクティス） |

### .rubocop.yml の設定内容

#### AllCops

```yaml
AllCops:
  NewCops: enable          # 新バージョンで追加される cop を自動で有効化
  SuggestExtensions: false # 拡張機能の提案メッセージを非表示
  TargetRubyVersion: 3.3   # .ruby-version に合わせる
  Exclude:
    - "bin/**/*"           # 自動生成される binstub
    - "db/schema.rb"       # 自動生成されるスキーマ
    - "vendor/**/*"        # サードパーティコード
    - "node_modules/**/*"  # JS 依存（存在する場合）
```

#### 無効化したカテゴリ

| カテゴリ | 理由 |
| --- | --- |
| `Metrics` | メソッド長、クラス長、循環的複雑度などは誤検知が多く主観的。コードレビューで対応するほうが効果的。 |
| `Naming` | 変数名やメソッド名の規約は主観的で、ドメイン固有の用語と衝突しやすい。 |

#### 無効化した個別 cop

| cop | 理由 |
| --- | --- |
| `Style/Documentation` | API-only アプリであり、クラスごとのドキュメントコメントは不要。 |
| `Style/FrozenStringLiteralComment` | Ruby 3.x では多くの文脈で文字列がデフォルトで frozen になるため、マジックコメントの必要性が低下している。 |

#### RSpec cop（デフォルトを緩和）

RSpec cop のデフォルト閾値は非常に厳しいため、実用的な範囲に緩和した:

| cop | デフォルト | 設定値 | 理由 |
| --- | --- | --- | --- |
| `RSpec/MultipleExpectations` | 1 | 10 | リクエストスペックでは1テストに複数のアサーションが自然 |
| `RSpec/ExampleLength` | 5行 | 15行 | セットアップが多いリクエストスペックにはより多くの行数が必要 |
| `RSpec/MultipleMemoizedHelpers` | 5 | 10 | 複雑なテストシナリオでは let/let! の定義が増える |
| `RSpec/NestedGroups` | 3 | 5 | 認証やネストリソースのスペックではより深いコンテキストが必要 |
| `RSpec/LetSetup` | 有効 | 無効 | `let!` によるセットアップはリクエストスペックで一般的なパターン |

#### マイグレーションの除外

| cop | 理由 |
| --- | --- |
| `Rails/BulkChangeTable` | マイグレーションは一度だけ実行されるため、ALTER 文の最適化のためにリファクタリングする価値は低い。 |
| `Rails/SquishedSQLHeredocs` | マイグレーション内の生 SQL は可読性のために複数行フォーマットを維持するほうが望ましい。 |

## 検出・修正した警告の種類

### Style 系

#### Style/StringLiterals

- **内容**: 文字列補間や特殊文字が不要な場合はシングルクォートを使用する
- **修正前**: `gem "rails", "~> 8.1.0"`
- **修正後**: `gem 'rails', '~> 8.1.0'`
- **影響範囲**: 全 `.rb` ファイル（最も多い修正）

#### Style/SymbolArray

- **内容**: シンボル配列には `%i[]` 記法を使用する
- **修正前**: `only: [ :show, :update, :destroy ]`
- **修正後**: `only: %i[show update destroy]`

#### Style/NumericPredicate

- **内容**: 数値比較の代わりに述語メソッドを使用する
- **修正前**: `value.to_i > 0`
- **修正後**: `value.to_i.positive?`

#### Style/IfUnlessModifier

- **内容**: 単一行の条件文には修飾子形式を使用する
- **修正前**:

  ```ruby
  if includes.any?
    @word = @wordbook.words.includes(*includes.map(&:to_sym)).find(params[:id])
  end
  ```

- **修正後**:

  ```ruby
  @word = @wordbook.words.includes(*includes.map(&:to_sym)).find(params[:id]) if includes.any?
  ```

#### Style/GlobalStdStream

- **内容**: 標準ストリームにはグローバル変数を使用する
- **修正前**: `ActiveSupport::TaggedLogging.logger(STDOUT)`
- **修正後**: `ActiveSupport::TaggedLogging.logger($stdout)`

### Layout 系

#### Layout/LineLength

- **内容**: 1行は120文字以下にする
- **対応**: 長い式をローカル変数に切り出す
- **例**:

  ```ruby
  # 修正前
  error: "This email is already registered with #{existing_user.provider}. Please sign in with #{existing_user.provider}."

  # 修正後
  message = "This email is already registered with #{existing_user.provider}. " \
            "Please sign in with #{existing_user.provider}."
  ```

#### Layout/SpaceInsideArrayLiteralBrackets

- **内容**: 配列ブラケット内にスペースを入れない
- **修正前**: `[ :show, :update, :destroy ]`
- **修正後**: `[:show, :update, :destroy]`

#### Layout/SpaceInsidePercentLiteralDelimiters

- **内容**: パーセントリテラルのデリミタ内にスペースを入れない
- **修正前**: `%i[ windows jruby ]`
- **修正後**: `%i[windows jruby]`

#### Layout/EmptyLineAfterGuardClause

- **内容**: ガード節の後に空行を入れて可読性を向上させる
- **修正前**:

  ```ruby
  return [] if params[:include].blank?
  params[:include].split(',')...
  ```

- **修正後**:

  ```ruby
  return [] if params[:include].blank?

  params[:include].split(',')...
  ```

### Rails 系

#### Rails/StrongParametersExpect

- **内容**: `params.require.permit` の代わりに `params.expect` を使用する（Rails 8.x の新 API）
- **修正前**: `params.require(:word).permit(:spelling, :status)`
- **修正後**: `params.expect(word: %i[spelling status])`
- **補足**: `params.expect` は Rails 8 で導入された Strong Parameters の新しい API

#### Rails/HttpStatusNameConsistency

- **内容**: 非推奨の `:unprocessable_entity` の代わりに `:unprocessable_content`（RFC 9110 準拠の命名）を使用する
- **修正前**: `status: :unprocessable_entity`
- **修正後**: `status: :unprocessable_content`

#### Rails/HasManyOrHasOneDependent

- **内容**: アソシエーションに `:dependent` オプションを必ず指定する
- **対応**: `has_one :first_meaning` に `dependent: nil` を追加（読み取り専用の派生アソシエーション）

#### Rails/InverseOf

- **内容**: カスタムクラス名やスコープを持つアソシエーションに `:inverse_of` を指定する
- **対応**: `has_one :first_meaning` に `inverse_of: :word` を指定。`Meaning#belongs_to :word` は無スコープなので逆方向の指定は安全で、`word.first_meaning.word` が再クエリせずロード済みの `word` を返せる。

#### Rails/SkipsModelValidations

- **内容**: ActiveRecord のバリデーションをスキップするメソッド（`update_all`, `update_column` 等）に対する警告
- **対応**: インライン無効化コメントを追加。ゲスト→Google アカウント移行時のパフォーマンスのため、`update_all`（一括所有権移転）を意図的に使用している。

#### Rails/Pluck

- **内容**: 単一属性の抽出には `map` の代わりに `pluck` を使用する
- **修正前**: `body['meanings'].map { |m| m['definition'] }`
- **修正後**: `body['meanings'].pluck('definition')`

### Lint 系

#### Lint/UselessConstantScoping

- **内容**: `private` キーワードの後に定義された定数は、実際にはパブリックにアクセス可能（Ruby は定数のスコープをアクセス修飾子で制御しない）
- **修正前**:

  ```ruby
  private
  ALLOWED_INCLUDES = %w[meanings examples].freeze
  ```

- **修正後**:

  ```ruby
  ALLOWED_INCLUDES = %w[meanings examples].freeze
  private
  ```

### RSpec 系

#### RSpec/NamedSubject

- **内容**: テストサブジェクトを明示的に参照する場合は名前を付ける
- **修正前**: `expect(subject).to define_enum_for(:provider)...`
- **修正後**:

  ```ruby
  subject(:user) { build(:user) }
  expect(user).to define_enum_for(:provider)...
  ```

## 今後の検討事項

### カテゴリごと無効化した cop について

`Metrics` と `Naming` カテゴリは全体を無効化している。将来的に特定の cop を有効にしたい場合は以下を検討:

- `Metrics/MethodLength`（Max: 20-30）— 長すぎるメソッドを検出
- `Metrics/AbcSize`（Max: 30-40）— 複雑すぎるメソッドを検出
- `Naming/PredicateName` — boolean メソッドに `?` サフィックスを強制

### 新しい cop の追加について

`NewCops: enable` を設定しているため、RuboCop のアップデートで追加される新しい cop は自動的に有効化される。新しい cop で問題が発生した場合:

1. **特定の行のみ無効化**: `# rubocop:disable CopName`
2. **プロジェクト全体で無効化**（`.rubocop.yml` に追加）:

   ```yaml
   CopName:
     Enabled: false
   ```

### RuboCop の実行方法

```bash
# 全ファイルをチェック
bundle exec rubocop

# 安全な自動修正を実行
bundle exec rubocop -a

# 安全でない修正も含めて自動修正を実行
bundle exec rubocop -A

# 特定のファイルをチェック
bundle exec rubocop app/controllers/api/v1/words_controller.rb

# 段階的な導入のための todo ファイルを生成
bundle exec rubocop --auto-gen-config --auto-gen-only-exclude
```

### CI 連携

RuboCop は `.github/workflows/ci.yml` で `bin/rubocop -f github` として CI 上で実行される。PR の diff に直接アノテーションが表示される。
