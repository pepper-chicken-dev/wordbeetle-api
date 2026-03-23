# ゲストユーザーデータの引き継ぎ（Guest Migration）

## 概要

ゲストユーザーが Google アカウントで本登録する際、ゲスト期間中に作成したデータを引き継ぐ機能。

### 引き継ぎ対象データ

- 単語帳（Wordbooks）
- 単語（Words）— ステータス、次回復習日を含む
- 意味（Meanings）
- 例文（Examples）
- 学習設定（Settings）— 復習間隔のカスタマイズ

## API 仕様

### エンドポイント

`POST /api/v1/auth/google`（既存の Google 認証エンドポイントを拡張）

### リクエスト

```
POST /api/v1/auth/google
Authorization: Bearer <GOOGLE_ID_TOKEN>
Content-Type: application/json

{
  "guest_token": "<GUEST_JWT>"
}
```

- `Authorization` ヘッダー: Google ID トークン（必須、通常の Google 認証と同じ）
- `guest_token`: ゲストユーザーの JWT トークン（オプション。指定時にデータ移行を実行）

### レスポンス

**成功時（200 OK）:**

```json
{
  "user": {
    "email": "user@example.com",
    "name": "User Name",
    "avatar_url": "https://example.com/avatar.jpg"
  },
  "token": "<NEW_JWT>"
}
```

**エラー時:**

| ステータス | 条件 | レスポンス |
|-----------|------|-----------|
| 400 Bad Request | Authorization ヘッダーなし | `{ "error": "Authorization header missing" }` |
| 401 Unauthorized | Google ID トークンが無効 | `{ "error": "Invalid ID token" }` |
| 401 Unauthorized | guest_token が無効 / ゲストユーザーが見つからない | `{ "error": "Invalid guest token" }` |
| 422 Unprocessable Entity | guest_token のユーザーがゲストでない | `{ "error": "User is not a guest" }` |

## 処理フロー

### シナリオ A: インプレース変換（Google アカウント未登録の場合）

最も一般的なケース。ゲストユーザーが初めて Google アカウントを登録する場合。

```
Guest User (id=1, provider="guest")
  ↓ update!
Google User (id=1, provider="google", provider_uid="sub値", email="...")
```

- User レコードの `provider`、`provider_uid`、`email`、`name`、`avatar_url` を更新
- `guest_expires_at` を `nil` に設定
- `user_id` は変わらないため、関連データ（Wordbooks 以下全て）はそのまま保持
- User 数は変化しない

### シナリオ B: マージ（Google アカウント既に存在する場合）

別デバイスで先に Google 登録済みのユーザーがゲスト端末のデータを取り込むケース。

```
Guest User (id=1)              Google User (id=2)
  ├── Wordbook A                 ├── Wordbook X
  ├── Wordbook B                 └── Setting
  └── Setting
          ↓ マージ
Google User (id=2)
  ├── Wordbook X（既存）
  ├── Wordbook A（移行）
  ├── Wordbook B（移行）
  └── Setting（既存を維持）
```

- ゲストの Wordbooks を Google ユーザーに `user_id` を付け替え（`update_all`）
- Words / Meanings / Examples は `wordbook_id` 経由の FK で自動的に追随
- Settings: Google ユーザーに設定がなければ移行、あれば既存を維持
- ゲストユーザーを削除
- User 数が 1 減少

## 実装詳細

### 主要ファイル

| ファイル | 役割 |
|---------|------|
| `app/controllers/concerns/guest_migratable.rb` | 移行ロジック（Concern） |
| `app/controllers/api/v1/auth_controller.rb` | エンドポイント（`google` アクション内で分岐） |

### DB 制約との互換性

インプレース変換時、以下の CHECK 制約はすべて満たされる：

| 制約 | 変換後の状態 | 結果 |
|------|------------|------|
| `provider IN ('google', 'guest')` | `'google'` | OK |
| `provider = 'guest' OR provider_uid IS NOT NULL` | `'google'` + `provider_uid` あり | OK |
| `provider != 'guest' OR guest_expires_at IS NOT NULL` | `'google'` → 条件不問 | OK |
| UNIQUE `(provider, provider_uid)` | 新しい組み合わせ → OK / 既存あり → マージへ | OK |
| UNIQUE `email` | 新しい email → OK / 既存あり → マージへ | OK |

DB マイグレーションは不要。

### トランザクション

全移行処理は `ActiveRecord::Base.transaction` で囲まれており、途中でエラーが発生した場合は全変更がロールバックされる。

## エッジケース

| ケース | 挙動 |
|--------|------|
| ゲストの有効期限切れ | JWT 自体が期限切れのため、`find_guest_user_from_token` で nil → 401 |
| 同じゲストから2回リクエスト | 1回目で provider が `google` に変更済み → 2回目は `find_guest_user_from_token` で guest ユーザーが見つからず 401 |
| Google ユーザーが guest_token を送信 | `find_guest_user_from_token` は `provider: "guest"` で検索するため nil → 401 |
| guest_token なしで通常の Google 認証 | 既存動作がそのまま維持される（回帰なし） |
