---
description: 旧サイトを URL のみから WordPress (Bedrock+Sage) に丸ごと再現するワークフロー。wget ミラー → スクショ → AI 解析 → Blade コンポーネント化 → 差分検証を順に実行する。
---

# wp-clone

旧サイトのソースが失われている時に、URL から視覚的・構造的に同等なサイトを WP 上に再現する。

## 引数

- 最初の非フラグ引数 = 旧サイトのトップ URL (必須)
- 例: `/wp-clone https://old-internal.example.com/`

## 前提

- `./bootstrap.sh` 実行済み (DDEV + Bedrock + Sage 起動)
- `web/app/themes/clone-theme/` が存在
- プロジェクトルート (`worktree-base/`) で起動されている

## フロー

### 1. ミラー取得

詳細: [references/mirror.md](references/mirror.md)

```bash
mkdir -p _mirror && cd _mirror
wget --mirror --page-requisites --convert-links --adjust-extension \
     --no-parent -e robots=off --wait=2 --limit-rate=200k "$URL"
cd ..
find _mirror -name '*.html' | sort > _pages.txt
wc -l _pages.txt
```

JS 描画が多いサイトなら Playwright で `page.content()` 保存に切替。

### 2. スクショ取得 (3 解像度 × フル高さ)

詳細: [references/screenshot.md](references/screenshot.md)

```bash
mkdir -p _screenshots/old
while IFS= read -r html; do
  rel=${html#_mirror/}
  base=$(echo "$rel" | sed 's|/|_|g; s|\.html$||')
  url="$URL/${rel%/index.html}"
  for w in 1440 768 375; do
    shot-scraper "$url" -o "_screenshots/old/${base}_${w}.png" --width "$w" --height 0 || true
  done
done < _pages.txt
```

### 3. AI 解析 (Read で画像 + HTML)

- 全ページのデスクトップ画像を Read で開く
- 共通レイアウト (header / footer / sidebar / nav) を識別
- 繰り返しコンポーネント (card / hero / cta) を抽出して列挙
- カラーパレット / フォントスタック / 余白スケールを抽出
- 結果を `_analysis.md` に記録 (コンポーネント一覧 + Tailwind config 案)

### 4. Sage に転写

詳細: [references/convert-to-sage.md](references/convert-to-sage.md)

順序:
1. Tailwind config 更新 (`resources/css/app.css` の `@theme` ブロック)
2. レイアウト: `resources/views/layouts/app.blade.php`
3. セクション: `resources/views/sections/{header,footer}.blade.php`
4. コンポーネント: `resources/views/components/<name>.blade.php`
5. ページテンプレ: `resources/views/{page,front-page,template-*}.blade.php`
6. アセット: 旧サイトの画像/フォントを `resources/images/` `resources/fonts/` に配置
7. `npm run build` で Vite ビルド

### 5. 差分検証

```bash
mkdir -p _screenshots/new
# 各ページの新サイト URL を撮影 (パスは旧と同等にマッピング)
shot-scraper "https://worktree-base.ddev.site/<path>" \
  -o "_screenshots/new/${base}_1440.png" --width 1440 --height 0
```

Claude が old/new の同名画像ペアを Read で比較 → ズレ箇所をリスト化 → 修正反復。

### 6. 品質ゲート (完了条件)

すべて 0 エラー / 成功:

```bash
composer lint          # PHPCS (WPCS)
composer analyse       # PHPStan
(cd web/app/themes/clone-theme && npm run build)
```

主要ページ (top + 主要下層 5 ページ程度) の old/new デスクトップ差分が許容内。

## 失敗時のリトライ

| 症状 | 対処 |
|---|---|
| wget でページが空 / JS 必須 | Playwright で `page.content()` を保存 |
| スクショで動的要素崩れ | `--wait` 追加 or interaction script |
| 旧サイトの認証必須 | `wget --user --password` or Cookie 渡し |
| 取得後 CSS リンク切れ | wget 再実行時に `--convert-links` を再確認 |

## オプションフラグ

`~/.claude/rules/skill-option-convention.md` 準拠。
このスキル固有フラグなし。共通フラグ (`-codex` 等) は flag-catalog に従う。

## 参照

- [references/mirror.md](references/mirror.md)
- [references/screenshot.md](references/screenshot.md)
- [references/convert-to-sage.md](references/convert-to-sage.md)
- プロジェクト規約: `../../../CLAUDE.md`
