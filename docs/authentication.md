# 認証・認可

## 認証フロー概要

```
[クライアント] --Google ID Token--> POST /api/v1/auth/google --> [JWT発行]
[クライアント] ----------------------> POST /api/v1/auth/guest  --> [JWT発行]
[クライアント] --Bearer JWT---------> GET /api/v1/wordbooks    --> [リソース返却]
```

1. **Google認証**: クライアントがGoogle ID tokenを`Authorization: Bearer <id_token>`で送信。サーバーがトークンを検証し、ユーザーを検索または作成してJWTを返却。
2. **ゲスト認証**: クライアントがPOSTリクエストを送信。サーバーがゲストユーザーを作成してJWTを返却。
3. **APIアクセス**: 以降のリクエストでは`Authorization: Bearer <jwt>`ヘッダーでJWTを送信。

## JWTの構造

アルゴリズム: HS256（HMAC-SHA256）

### ペイロード（クレーム）

| クレーム | 説明 |
|---------|------|
| `sub` | ユーザーID（`users.id`） |
| `exp` | 有効期限（Unix timestamp） |
| `iat` | 発行日時（Unix timestamp） |

### 署名鍵

`Rails.application.secret_key_base`を使用。

## 有効期限

| 認証方法 | 有効期限 |
|---------|---------|
| Google認証 | 30日（発行時点から） |
| ゲスト認証 | 7日（`guest_expires_at`と一致） |

ゲスト認証のJWT有効期限は、ユーザーレコードの`guest_expires_at`と同一の値を使用。これによりDBとトークンの有効期限が一致することを保証。

## 認可（リソーススコーピング）

全リソースエンドポイントは`current_user`を起点にスコーピング:

| リソース | スコーピング方法 |
|---------|----------------|
| Wordbooks | `current_user.wordbooks` |
| Words | `Word.joins(:wordbook).where(wordbooks: { user_id: current_user.id })` |
| Meanings | `Meaning.joins(word: :wordbook).where(wordbooks: { user_id: current_user.id })` |
| Examples | `Example.joins(word: :wordbook).where(wordbooks: { user_id: current_user.id })` |
| Settings | `current_user.setting` |

他ユーザーのリソースにアクセスした場合は`404 Not Found`を返却（リソースの存在を漏らさないため）。

## エラーレスポンス

| ステータス | 条件 | レスポンス |
|-----------|------|-----------|
| 401 Unauthorized | トークンなし / 無効なトークン / 期限切れ | `{ "error": "Unauthorized" }` |
| 404 Not Found | リソースが存在しない / 他ユーザーのリソース | `{ "error": "Not found" }` |
