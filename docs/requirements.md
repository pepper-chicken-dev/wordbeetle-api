# WordBeetle - 単語帳アプリ

## 概要

WordBeetleは、効率的な単語学習を実現する間隔反復学習機能を搭載した単語帳アプリケーションです。

## 機能要件

### 優先度

- **[P0] High Priority**: 必須機能。
- **[P1] Medium Priority**: 重要機能。初期リリース後、早い段階で実装する。
- **[P2] Low Priority**: あると便利な機能。余裕があれば実装する

<details>
<summary style="font-size: 1.2em; font-weight: bold;">ユーザ管理機能</summary>

### 会員登録・ログイン機能

- 会員登録
  - [p0] Google アカウント連携による登録
  - [p2] ユーザ名、プロフィール画像の設定
  
- **ログイン**
  - [p0] Google アカウント連携によるログイン

### ゲストユーザモード

- **概要**
  - [p0] ログインなしでアプリの主要機能を利用可能
  - [p0] データ保有期間：7日間
  - [p0] 期限切れ後、ゲストユーザとデータを自動削除
  
- **利用可能機能**
  - 単語帳の作成・編集・削除
  - 単語の登録・編集・削除
  - 単語テストの実施
  - 音声再生機能
  
- **制限事項**
  - 複数デバイス間での同期不可
  - 一部の高度な設定機能の制限

### ゲストユーザデータの引き継ぎ

- [p0] ゲストユーザが会員登録を行った際、以下のデータを引き継ぐ
  - 作成した単語帳
  - 登録した単語（例文、意味、ステータス含む）
  - 学習履歴
  - 学習設定

### ユーザプロフィール管理

- [p1] ユーザ名の変更
- [p1] プロフィール画像の変更
- [p1] アカウント削除機能

</details>

<details>
<summary style="font-size: 1.2em; font-weight: bold;">単語帳管理機能</summary>

### 単語帳のCRUD

- **作成（Create）**
  - [p0] 単語帳名の設定
  - [p2] 説明文の設定
  - [p2] カテゴリ/タグの設定
  - [p2] 公開/非公開設定(ユーザ間の単語帳共有)
  
- **閲覧（Read）**
  - [p0] 自分の単語帳一覧表示
  - [p2] 単語帳詳細表示
  - [p0] 単語帳内の単語一覧表示
  - [p2] 単語帳の統計情報表示（総単語数、習得率、次回復習予定単語数など）
  
- **更新（Update）**
  - [p0] 単語帳情報の編集
  
- **削除（Delete）**
  - [p0] 単語帳の削除（単語帳内の全単語も削除）
  - [p0] 削除前の確認ダイアログ表示

### 単語帳の管理機能

- **複数単語帳の管理**
  - [p0] 1ユーザあたり複数の単語帳を作成可能
  - [p2] 単語帳のカテゴリ分類（TOEIC、英検、ビジネス英語など）
  - [p1] 単語帳の検索機能
  - [p1] 単語帳のソート機能（作成日順、更新日順、名前順など）
  
- **単語帳の共有機能**
  - [p2] 単語帳の公開設定
  - [p2] 公開単語帳のURL共有
  - [p2] 他ユーザの公開単語帳を自分の単語帳にコピー

</details>

<details>
<summary style="font-size: 1.2em; font-weight: bold;">単語管理機能</summary>

### 単語のCRUD

- **作成（Create）**
  - [p0] 単語（スペル）の登録
  - [p0] 意味の登録（単数）
  - [p2] 意味の登録（複数）
  - [p0] 例文の登録（単数）
  - [p2] 例文の登録（複数）
  - [p1] 品詞の登録
  - [p2] 発音記号の登録
  - [p2] メモの登録
  - [p2] 画像の登録
  
- **閲覧（Read）**
  - [p0] 単語一覧表示
  - [p0] 単語詳細表示
  - [p0] ステータス別フィルタ表示
  - [p0] 検索機能（単語、意味で検索）
  
- **更新（Update）**
  - [p0] 単語情報の編集
  - [p0] ステータスの手動変更
  
- **削除（Delete）**
  - [p0] 単語の削除
  - [p0] 削除前の確認ダイアログ表示

### 単語登録時のサジェスト機能

- **スペルサジェスト**
  - [p2] ユーザの入力に応じてスペルを自動補完
  - [p2] 外部API（辞書API）を利用した候補表示
  
- **意味サジェスト**
  - [p2] 入力された単語に対する意味を自動提案
  - [p2] 複数の意味がある場合は全て表示
  - [p2] 品詞も同時に取得・表示
  
- **例文サジェスト**
  - [p2] 登録単語を使用した例文の自動生成・提案
  - [p2] 外部API（例文データベース）の活用

### 単語音声機能

- **音声再生**
  - [p0] 単語一覧画面での音声再生
  - [p0] 単語詳細画面での音声再生
  - [p0] 単語登録・編集画面での音声再生
  - [p0] 単語テスト実施中の音声再生
  
- **音声提供方法**
  - [p0] Web Speech API の利用
  - [p2] Text-to-Speech API の利用（AWS Polly など）
  - [p2] 米国英語・英国英語の選択可能
  - [p2] 再生速度の調整機能（0.75x、1x、1.25x、1.5x）

### 単語の理解度ステータス管理

- **ステータス種類（4段階）**
  1. **未学習（Not Studied）**: 一度も学習していない
  2. **難しい（Hard）**: 理解が難しく、頻繁に復習が必要
  3. **曖昧（Uncertain）**: 部分的に理解できているが不安定
  4. **簡単（Easy）**: 完全に理解しており、復習頻度は低い
  
- **ステータス更新**
  - [p0] テスト時の自己評価によって自動更新
  - [p0] 手動でのステータス変更も可能

</details>

<details>
<summary style="font-size: 1.2em; font-weight: bold;">単語テスト機能</summary>

### テストモード

- **学習モード別**
  - [p0] 英単語 → 日本語（意味）
  - [p2] 日本語（意味）→ 英単語
  - [p2] リスニングモード（音声 → 意味）
  - [p2] スペリングモード（音声 → スペル入力）
  
- **出題範囲設定**
  - [p2] 単語帳全体
  - [p2] ステータス別（未学習のみ、難しいのみなど）
  - [p0] 復習期限が来た単語のみ
  - [p2] ランダム出題
  - [p2] 出題数の設定（10問、20問、50問、全問など）

### テスト実施

- **出題形式**
  - [p2] 入力形式
  - [p0] フラッシュカード形式（自己評価）
  
- **テスト中の機能**
  - [p0] 音声再生ボタン
  - [p2] 進捗表示（例：5/20問）
  
- **回答後のフィードバック**
  - [p2] 正誤判定
  - [p0] 正解の表示
  - [p1] 例文の表示
  - [p0] 自己評価の入力（難しい、曖昧、簡単）

</details>

<details>
<summary style="font-size: 1.2em; font-weight: bold;">間隔反復学習（SRS）機能</summary>

### 復習間隔の設定

- **デフォルト設定**
  - [p0] 未学習：即座に出題可能
  - [p0] 難しい：1日後に再出題
  - [p0] 曖昧：3日後に再出題
  - [p0] 簡単：7日後に再出題
  
- **カスタマイズ機能**
  - [p0] ユーザが各ステータスの復習間隔を自由に設定可能
  - 設定例：
    - 難しい：1-5日の範囲で設定
    - 曖昧：3-14日の範囲で設定
    - 簡単：7-30日の範囲で設定

### 復習スケジュール管理
  
- **復習通知**
  - [p2] 復習予定の単語がある場合の通知機能
  - [p2] 通知頻度の設定（毎日、週1回など）
  
- **復習カレンダー**
  - [p2] カレンダー形式での復習予定表示
  - [p2] 日別の復習予定単語数の表示

</details>

<details>
<summary style="font-size: 1.2em; font-weight: bold;">設定機能</summary>

### 学習設定

- [p0] 復習間隔のカスタマイズ
- [p2] デフォルトテストモードの設定
- [p2] 音声言語の設定（米国英語/英国英語）
- [p2] 音声再生速度のデフォルト設定

### 通知設定

- [p2] プッシュ通知のON/OFF
- [p2] 通知時間の設定
- [p2] 通知頻度の設定

### 表示設定

- [p1] テーマ設定（ライト/ダーク）
- [p2] フォントサイズの調整
- [p2] 言語設定（日本語/英語）

</details>

<details>
<summary style="font-size: 1.2em; font-weight: bold;">[p2] 学習記録・統計機能</summary>

### 学習履歴

- **記録内容**
  - 日別の学習時間
  - 日別の学習単語数
  - テスト結果の履歴
  - 正答率の推移
  
- **表示形式**
  - カレンダー形式
  - グラフ形式（折れ線、棒グラフ）
  - リスト形式

### 統計情報

- **全体統計**
  - 総学習時間
  - 総学習単語数
  - 現在の習得単語数
  - 平均正答率
  
- **単語帳別統計**
  - 単語帳ごとの習得率
  - ステータス別単語数
  - 次回復習予定単語数
  
- **期間別統計**
  - 週間レポート
  - 月間レポート
  - 年間レポート

### 学習目標設定

- **目標設定機能**
  - 1日あたりの学習目標単語数
  - 週間学習目標時間
  - 単語帳の習得期限設定
  
- **目標達成状況**
  - 目標達成率の表示
  - 達成バッジ・報酬システム
  - 連続学習日数のカウント

</details>

## 非機能要件

### パフォーマンス

- ページ読み込み時間：3秒以内
- API レスポンスタイム：500ms 以内
- 音声再生の遅延：1秒以内

### セキュリティ

- HTTPS 通信の必須化
- CSRF 対策
- XSS 対策
- SQL インジェクション対策

### 可用性

- システム稼働率：99.9% 以上
- 定期メンテナンス：月1回、深夜時間帯

### 拡張性

- 将来的な多言語対応の考慮

### ユーザビリティ

- レスポンシブデザイン（PC、タブレット、スマートフォン対応）
- 直感的なUI/UX
- アクセシビリティ対応（WCAG 2.1 レベルAA準拠）

### 互換性

- 対応ブラウザ：Chrome、Firefox、Safari、Edge（最新版および1つ前のバージョン）

## データモデル概要

### 優先度

- **[P0] High Priority**: 必須。
- **[P1] Medium Priority**: 初期リリース後、早い段階で実装する。
- **[P2] Low Priority**: 余裕があれば実装する

### エンティティ

#### Users（ユーザ）

- `(provider, provider_uid)` の組み合わせで一意に識別（DBユニーク制約）
- `provider` は `google` または `guest` のみ（DBチェック制約）。今後、他の認証プロバイダ（GitHub、Apple等）が追加される可能性あり
- `guest` ユーザは `guest_expires_at` が必須（モデルバリデーション＋DBチェック制約）
- `email` はユニーク制約あり（nilを許容）

- [P0] id
- [P0] email
- [P0] name
- [P0] avatar_url
- [P0] provider（google / guest）
- [P0] provider_uid（ゲストユーザの識別子も含む）
- [P0] guest_expires_at（ゲストユーザの有効期限）
- [P0] created_at
- [P0] updated_at

#### Wordbooks（単語帳）

- [P0] id
- [P0] user_id
- [P0] title
- [P2] description
- [P2] category
- [P2] is_public
- [P0] created_at
- [P0] updated_at

#### Words（単語）

- `status` と `next_review_at` はSRS（間隔反復学習）のスケジューリングに使用する
- `status` は `not_studied` / `hard` / `uncertain` / `easy` の4値（DBチェック制約）

- [P0] id
- [P0] wordbook_id
- [P0] spelling
- [P2] pronunciation
- [P2] part_of_speech
- [P0] status（not_studied / hard / uncertain / easy）
- [P0] next_review_at
- [P2] image_url
- [P2] memo
- [P0] created_at
- [P0] updated_at

#### Meanings（意味）

- [P0] id
- [P0] word_id
- [P0] content
- [P0] display_order
- [P0] created_at
- [P0] updated_at

#### Examples（例文）

- [P0] id
- [P0] word_id
- [P0] sentence
- [P0] translation
- [P0] display_order
- [P0] created_at
- [P0] updated_at

#### StudyLogs（学習履歴）

- [P2] id
- [P2] user_id
- [P2] word_id
- [P2] wordbook_id
- [P2] study_type（test / review）
- [P2] is_correct
- [P2] self_evaluation（hard / uncertain / easy）
- [P2] study_duration
- [P2] created_at

#### Settings（ユーザ設定）

- SRSの復習間隔を `hard` / `uncertain` / `easy` ごとに保持する
- interval カラムは PostgreSQL の interval 型を使用

- [P0] id
- [P0] user_id
- [P0] hard_interval
- [P0] uncertain_interval
- [P0] easy_interval
- [P2] notification_enabled
- [P2] notification_time
- [P2] voice_language（us / uk）
- [P2] voice_speed
- [P2] theme（light / dark）
- [P0] created_at
- [P0] updated_at

#### StudyGoals（学習目標）

- [P2] id
- [P2] user_id
- [P2] daily_word_count
- [P2] weekly_study_minutes
- [P2] created_at
- [P2] updated_at

## 5. 外部連携

### 5.1 認証

- Google OAuth 2.0

### 5.2 辞書API

- 単語の意味、例文取得
- 候補：Oxford Dictionary API、Merriam-Webster API、Free Dictionary API

### 5.3 音声API

- Text-to-Speech 機能
- 候補：Google Cloud Text-to-Speech、Amazon Polly、Azure TTS

### 5.4 その他

- 画像ストレージ（AWS S3、Cloudinary など）
- プッシュ通知（Firebase Cloud Messaging）

## 6. 画面遷移

```
[ログイン/会員登録画面]
  ├─ [ゲストとして始める]
  └─ [ログイン/会員登録]
      └─ [ホーム画面（単語帳一覧）]
          ├─ [単語帳詳細画面]
          │   ├─ [単語一覧画面]
          │   │   └─ [単語詳細画面]
          │   ├─ [単語登録画面]
          │   └─ [テスト開始画面]
          │       └─ [テスト実施画面]
          │           └─ [テスト結果画面]
          ├─ [学習記録画面]
          ├─ [統計画面]
          ├─ [設定画面]
          └─ [プロフィール画面]
```

## 7. 実装優先度

### Phase 1（MVP: Minimum Viable Product）

1. ユーザ認証（会員登録、ログイン）
2. ゲストユーザモード
3. 単語帳のCRUD
4. 単語のCRUD
5. 基本的な単語テスト機能
6. 理解度ステータス管理（4段階）
7. 基本的なSRS機能

### Phase 2

1. ゲストユーザデータの引き継ぎ
2. 音声再生機能
3. 単語登録時のサジェスト機能
4. 復習間隔のカスタマイズ
5. 学習履歴・統計機能
6. プロフィール管理

### Phase 3

1. 単語帳の共有機能
2. 複数テストモード
3. 学習目標設定
4. 通知機能
5. テーマ設定
6. 詳細な統計機能

### Phase 4

1. モバイルアプリ開発
2. オフライン機能
3. AI による学習レコメンド
4. ソーシャル機能（友達との競争など）
5. 有料プレミアムプラン

## 8. 技術スタック（推奨）

### バックエンド

- Ruby on Rails 7.x
- PostgreSQL
- Redis（キャッシュ、セッション管理）
- Sidekiq（バックグラウンドジョブ）

### フロントエンド

- React / Next.js
- TypeScript
- Tailwind CSS
- Zustand / Redux（状態管理）

### インフラ

- Docker
- AWS / GCP
- Kamal（デプロイ）

### 外部サービス

- Google OAuth
- Dictionary API
- Text-to-Speech API
- S3 / Cloudinary（画像ストレージ）

## 9. 今後の拡張可能性

- AI による単語推薦機能
- 他の学習者とのランキング機能
- コミュニティ機能（フォーラム、Q&A）
- 多言語対応（他言語の学習サポート）
- ゲーミフィケーション要素の強化
- VR/AR での学習体験
- 企業向け法人プラン
- 教育機関向けプラン

---

**最終更新日**: 2026年2月3日
