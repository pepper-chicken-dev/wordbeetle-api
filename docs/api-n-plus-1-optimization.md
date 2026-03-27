# API N+1 Fetch 最適化提案

フロントエンドで発生している N+1 API fetch パターンを調査し、Rails API 側の改善案をまとめる。

## 概要

| # | パターン | 発生箇所 | 現在のリクエスト数 | 最悪ケース | API 改善案 |
|---|---------|---------|------------------|-----------|-----------|
| 1 | 単語一覧 + 意味 | `components/word/word-list.tsx` | 1 + N | 101回 (100語) | words に first_meaning を含める |
| 2 | 単語詳細 + 意味 + 例文 | `words/[wordId]/` 詳細・編集 | 3 | 3回 | word に meanings, examples を含める |
| 3 | テストページ | `wordbooks/[wordbookId]/test/page.tsx` | 2 + 2N | 42回 (20語) | テスト専用エンドポイント or include パラメータ |

---

## パターン 1: 単語一覧での意味取得 (高優先度) ✅ 実装済み

### 現状

`src/components/word/word-list.tsx`

```typescript
// 1回目: 全単語を取得
const allWords = await listWords(wordbookId);

// N回: 各単語の意味を個別に取得
const meaningEntries = await Promise.all(
  allWords.map(async (word) => {
    const meanings = await listMeanings(wordbookId, word.id);
    const first = meanings.sort(/* display_order */)[0];
    return [word.id, first] as const;
  }),
);
```

一覧画面では各単語の最初の意味（`display_order` 順）だけが必要だが、単語ごとに `GET /wordbooks/:wordbookId/words/:wordId/meanings` を呼んでいる。

### リクエスト数

- **現在:** 1 + N（N = 単語数）
- 100語の単語帳 → **101リクエスト**

### API 改善案

`GET /wordbooks/:wordbookId/words` のレスポンスに `first_meaning` を含める。

```jsonc
// GET /wordbooks/:wordbookId/words
{
  "words": [
    {
      "id": 1,
      "spelling": "apple",
      "status": "not_studied",
      "next_review_at": null,
      // 追加: display_order が最小の meaning を1件だけ含める
      "first_meaning": {
        "id": 10,
        "content": "りんご",
        "display_order": 1
      }
    }
  ]
}
```

`first_meaning` は Rails 側で `has_one :first_meaning, -> { order(:display_order) }, class_name: 'Meaning'` のようなアソシエーションで実装し、`includes(:first_meaning)` で eager load する。

**効果:** 101リクエスト → **1リクエスト**

---

## パターン 2: 単語詳細ページでの関連データ取得 (中優先度) ✅ 実装済み

### 現状

`src/app/(authenticated)/wordbooks/[wordbookId]/words/[wordId]/word-detail-content.tsx`

```typescript
// 1回目: 単語を取得
word = await getWord(wordbookId, wordId);

// 2回目 + 3回目: 意味と例文を並行取得
const [meanings, examples] = await Promise.all([
  listMeanings(wordbookId, wordId),
  listExamples(wordbookId, wordId),
]);
```

同じパターンが編集ページ (`words/[wordId]/edit/page.tsx`) にもある。

### リクエスト数

- **現在:** 3回（毎回固定）
- 詳細ページと編集ページそれぞれで発生

### API 改善案

`GET /wordbooks/:wordbookId/words/:wordId` に `include` パラメータを追加。

```
GET /wordbooks/:wordbookId/words/:wordId?include=meanings,examples
```

```jsonc
// レスポンス
{
  "word": {
    "id": 1,
    "spelling": "apple",
    "status": "not_studied",
    "next_review_at": null,
    // 追加
    "meanings": [
      { "id": 10, "content": "りんご", "display_order": 1 },
      { "id": 11, "content": "果物の一種", "display_order": 2 }
    ],
    // 追加
    "examples": [
      {
        "id": 20,
        "sentence": "An apple a day keeps the doctor away.",
        "translation": "1日1個のりんごで医者いらず。",
        "display_order": 1
      }
    ]
  }
}
```

Rails 側では `includes(:meanings, :examples)` で eager load。`include` パラメータがない場合は既存のレスポンスを維持し、後方互換性を保つ。

**効果:** 3リクエスト → **1リクエスト**

---

## パターン 3: テストページでの単語 + 意味 + 例文取得 (最高優先度) ✅ 実装済み

### 現状

`src/app/(authenticated)/wordbooks/[wordbookId]/test/page.tsx`

```typescript
// 1回目: 単語帳を取得
let wordbook = await getWordbook(wordbookId);

// 2回目: 全単語を取得
const allWords = await listWords(wordbookId);

// フィルタリング: next_review_at が null or 過去の単語を抽出
const reviewWords = allWords.filter(/* ... */);

// 2N回: 各レビュー対象単語の意味と例文を個別に取得
const wordsWithRelations = await Promise.all(
  reviewWords.map(async (word) => {
    const [meanings, examples] = await Promise.all([
      listMeanings(wordbookId, word.id),   // N回
      listExamples(wordbookId, word.id),   // N回
    ]);
    return { word, meanings, examples };
  }),
);
```

### リクエスト数

- **現在:** 2 + 2N（N = レビュー対象の単語数）
- 20語がレビュー対象 → **42リクエスト**

### API 改善案

#### 案 A: テスト専用エンドポイントの新設（推奨）

```
GET /wordbooks/:wordbookId/test/words
```

サーバー側でレビュー対象の単語をフィルタリングし、意味と例文を含めて返す。

```jsonc
// レスポンス
{
  "wordbook": {
    "id": 1,
    "title": "English Vocabulary"
  },
  "words": [
    {
      "id": 1,
      "spelling": "apple",
      "status": "not_studied",
      "next_review_at": null,
      "meanings": [
        { "id": 10, "content": "りんご", "display_order": 1 }
      ],
      "examples": [
        {
          "id": 20,
          "sentence": "An apple a day keeps the doctor away.",
          "translation": "1日1個のりんごで医者いらず。",
          "display_order": 1
        }
      ]
    }
  ]
}
```

レビュー対象のフィルタ条件（`next_review_at IS NULL OR next_review_at <= NOW()`）をサーバー側に移すことで、不要な単語の転送も省ける。

#### 案 B: 既存エンドポイントに include パラメータ追加

```
GET /wordbooks/:wordbookId/words?include=meanings,examples
```

フィルタリングはフロントエンド側で行うが、N+1 は解消される。パターン 1 の改善と組み合わせて `include` パラメータを汎用的に設計できる。

**推奨:** 案 A。テストページはパフォーマンスが特に重要であり、サーバー側フィルタリングにより転送量も削減できる。

**効果:** 42リクエスト → **1リクエスト**

---

## 実装の優先順位

1. **パターン 3（テストページ）** — リクエスト数が最も多く、ユーザーが頻繁に使う機能
2. **パターン 1（単語一覧）** — 単語数に比例してリクエストが増加
3. **パターン 2（単語詳細）** — 固定3リクエストで影響は限定的だが、改善は容易

## N+1 が発生していない箇所

以下の箇所は問題なし:

- **ダッシュボード** — `listWordbooks()` の1回のみ
- **単語帳編集** — `getWordbook()` の1回のみ
- **単語作成** — 単語帳の存在確認のみ
- **設定ページ** — `getSetting()` の1回のみ

## Rails 側の実装メモ

- `includes` / `eager_load` を使い、SQL レベルで N+1 を解消する
- `include` クエリパラメータは後方互換性のためオプショナルにする
- テスト専用エンドポイント（案 A）では `Word.reviewable` スコープを定義し、フィルタ条件をモデルに集約する
- シリアライザ（ActiveModelSerializers / Blueprinter 等）でネスト構造を定義する
