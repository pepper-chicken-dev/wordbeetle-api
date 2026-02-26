# Create Pull Request

現在のブランチの変更内容をもとに、Pull Requestを作成します。

## 手順

1. `git log main..HEAD --oneline` で現在のブランチのコミット一覧を確認する
2. 各コミットの差分を `git show` で確認する（CLAUDE.md は除外）
3. 変更内容をもとに英語のPRタイトルと説明文を作成する
4. 作成した内容の**日本語訳**をユーザーに提示して確認を求める
5. ユーザーの確認が取れたら、ブランチをリモートにプッシュしてPRを作成する

## ルール

- PRの説明文（タイトル・body）は**英語**で記述する
- CLAUDE.md はPRの説明に含めない
- PRのbodyには `## Summary` セクションのみ記載する（テスト項目などは含めない）
- `🤖 Generated with [Claude Code](https://claude.com/claude-code)` のフッターは含めない
- コミットメッセージに `Co-Authored-By: Claude` などの文言は含めない
- ユーザーの確認前にプッシュやPR作成を実行しない
