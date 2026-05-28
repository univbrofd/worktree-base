# worktree-base

旧サイトを URL だけから WordPress に丸ごと再現するためのプロジェクト。
パフォーマンス重視のモダンスタックで構築。

## スタック

| 層 | 採用 | 理由 |
|---|---|---|
| ローカル環境 | **DDEV** (Docker) | nginx + PHP-FPM + MariaDB + Redis を 1 コマンドで起動 |
| WP 構成 | **Bedrock** | Composer で WP コア・プラグインを管理。`.env` 分離、`web/` を public root に |
| テーマ | **Sage 11** | Laravel **Blade** + Tailwind CSS + Vite (HMR 付き) |
| 静的解析 | **PHPCS (WPCS) + PHPStan** | CI で規約違反 / 型エラーを 0 に強制 |
| キャッシュ | **WP Rocket + Redis Object Cache + Cloudflare** | 三段キャッシュで Core Web Vitals 緑 |
| クローン | `.claude/skills/wp-clone` | wget ミラー → スクショ → AI 解析 → Blade 化 → 差分検証 |

## クイックスタート

```bash
./bootstrap.sh                                  # 一度だけ。brew / DDEV / Bedrock / Sage を導入
ddev start
open https://worktree-base.ddev.site
```

旧サイトを取り込む:
```
/wp-clone https://old-internal-site.example.com/
```

詳細は `.claude/skills/wp-clone/SKILL.md` を参照。

## ディレクトリ

```
.
├── bootstrap.sh           # 一発セットアップ
├── .ddev/config.yaml      # ローカル環境定義
├── .env.example           # Bedrock 環境変数テンプレ
├── config/
│   ├── phpcs.xml.dist     # WPCS ルール
│   └── phpstan.neon.dist  # 静的解析設定
├── .github/workflows/
│   └── quality.yml        # CI: phpcs + phpstan
├── CLAUDE.md              # プロジェクト規約 (Claude 用)
├── .claude/skills/wp-clone/
│   ├── SKILL.md           # クローンワークフロー
│   └── references/        # 詳細手順
├── _mirror/               # 旧サイト wget ミラー (git ignore)
├── _screenshots/{old,new} # 差分検証用 (git ignore)
└── web/                   # Bedrock の public root (bootstrap 後に生成)
    └── app/themes/clone-theme/   # Sage テーマ
```

## 品質ゲート

PR マージ前に CI で自動実行:
- `vendor/bin/phpcs` — WPCS 違反 0
- `vendor/bin/phpstan analyse` — PHPStan エラー 0
- `npm run build` — Vite ビルド成功

ローカルでは `composer lint && composer analyse` で同等チェック。
