# Screenshot

ページを 3 解像度 × フル高さで撮影し、AI 視覚解析の入力にする。

## ツール: shot-scraper (推奨)

```bash
pipx install shot-scraper
shot-scraper install   # 内部で playwright + chromium をセットアップ
```

## 単発

```bash
shot-scraper "https://example.com/" \
  -o out.png \
  --width 1440 \
  --height 0          # 0 = フルページ高さ
```

## 全ページバッチ (3 解像度)

```bash
mkdir -p _screenshots/old
while IFS= read -r html; do
  rel=${html#_mirror/}                       # 例: example.com/about/index.html
  base=$(echo "$rel" | sed 's|/|_|g; s|\.html$||')
  url="https://${rel%/index.html}"
  for w in 1440 768 375; do
    shot-scraper "$url" \
      -o "_screenshots/old/${base}_${w}.png" \
      --width "$w" --height 0 \
      --wait 1000 \
      || echo "FAIL: $url ($w)"
  done
done < _pages.txt
```

## インタラクション後の状態を撮る (メニュー展開等)

```bash
shot-scraper "$URL" -o out.png \
  --javascript "document.querySelector('.menu-toggle').click(); await new Promise(r => setTimeout(r, 500));"
```

## 比較撮影 (新サイト)

```bash
mkdir -p _screenshots/new
NEW_BASE="https://worktree-base.ddev.site"
# 旧 URL → 新 URL のパスマッピングを決めて撮影
shot-scraper "$NEW_BASE/about/" -o "_screenshots/new/about_1440.png" --width 1440 --height 0
```

## AI による視覚比較

old/new の同名 PNG を Read で開いて差分指摘:

- レイアウト崩れ (要素位置 / サイズ)
- 色 / フォント / 余白の違い
- 欠落しているセクション
- 過剰に追加されている要素

Claude に渡す時は **同じ width / height の組を並べる**こと。違う解像度で比べない。

## トラブルシュート

| 症状 | 対処 |
|---|---|
| 動的要素が読込未完了 | `--wait 3000` で待機を延長 |
| フォントがフォールバックに | `--wait` + `document.fonts.ready` JS を実行 |
| Cookie バナーが被る | `--javascript` で閉じる JS を流す |
| 横スクロール発生 | `--width` を実機ブレークポイントに合わせる |
