# worktree-base

旧サイトの URL のみから WordPress サイトを丸ごと再現する環境。

## 重要規約

- **wp-admin から直接編集しない**。全変更はコード経由 (Composer / テーマファイル / mu-plugin)
- メインテーマは `web/app/themes/clone-theme/` (Sage 11, Blade)
- 旧サイトのアセットは `_mirror/` 配下、スクショは `_screenshots/{old,new}/` (どちらも git 管理外)
- プラグインは **Composer 経由**で `composer require wpackagist-plugin/<name>` のみ
- 本番環境では `.env` の `DISALLOW_FILE_MODS=true` を必ず設定

## 編集対象の優先

1. `web/app/themes/clone-theme/resources/views/` — Blade テンプレート
2. `web/app/themes/clone-theme/resources/css/app.css` — Tailwind エントリ
3. `web/app/themes/clone-theme/app/` — Sage の PHP (Setup, Filters, Providers)
4. `web/app/mu-plugins/` — サイト固有ロジック (テーマ非依存)

`web/wp/` は WP コア (Composer 管理) なので直接編集禁止。

## 品質ゲート

タスク完了の定義に必ず含める:
- `composer lint` (PHPCS) エラー 0
- `composer analyse` (PHPStan) エラー 0
- `npm run build` (Vite) 成功
- 主要ページの旧/新スクショ差分が許容内

## 使い分け

- 旧サイトを取り込む → `/wp-clone <url>` (skill: `.claude/skills/wp-clone/`)
- 環境を作り直す → `./bootstrap.sh` (idempotent)
- DB を初期化 → `ddev wp db reset --yes && ddev wp core install ...`

## キャッシュ層 (本番で有効化)

- ページキャッシュ: WP Rocket (Composer 導入) or LiteSpeed Cache
- オブジェクトキャッシュ: Redis Object Cache plugin + DDEV/本番に Redis
- CDN: Cloudflare (静的アセット + HTML edge cache)

開発時は全て OFF。本番の WP_ENV で動的に切替。
