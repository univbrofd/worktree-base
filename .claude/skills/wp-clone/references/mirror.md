# Mirror

旧サイトをローカルに完全コピーする手順。

## 基本: wget (静的サイト向け)

```bash
mkdir -p _mirror && cd _mirror
wget \
  --mirror \
  --page-requisites \
  --convert-links \
  --adjust-extension \
  --no-parent \
  -e robots=off \
  --wait=2 \
  --limit-rate=200k \
  --user-agent="Mozilla/5.0 worktree-base" \
  "$URL"
```

### フラグの意味

| フラグ | 意味 |
|---|---|
| `--mirror` | `-r -N -l inf --no-remove-listing` の総合形 |
| `--page-requisites` | CSS / JS / 画像 / フォントもダウンロード |
| `--convert-links` | リンクを相対パスに書換 (オフライン閲覧可) |
| `--adjust-extension` | content-type に応じて `.html` `.css` 拡張子追加 |
| `--no-parent` | 親階層に上らない (範囲限定) |
| `-e robots=off` | robots.txt を無視 (自社サイトのみ) |
| `--wait=2 --limit-rate=200k` | サーバ負荷を抑える |

## 認証が必要なサイト

```bash
wget --user="$USER" --password="$PASS" ...
# or
wget --load-cookies cookies.txt ...
```

## JS 描画が多いサイト (wget だと空ページ)

Playwright に切替:

```bash
npm install -g playwright
npx playwright install chromium

node -e "
const {chromium} = require('playwright');
const fs = require('fs');
const path = require('path');
(async () => {
  const urls = ['$URL'];  // 増やす
  const browser = await chromium.launch();
  for (const u of urls) {
    const page = await browser.newPage();
    await page.goto(u, { waitUntil: 'networkidle' });
    const html = await page.content();
    const out = path.join('_mirror', new URL(u).pathname.replace(/\/$/, '/index.html'));
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, html);
    await page.close();
  }
  await browser.close();
})();
"
```

## Wayback Machine から取得 (現存しない場合)

```bash
gem install wayback_machine_downloader
wayback_machine_downloader "$URL"
```

## 検収

```bash
find _mirror -name '*.html' | wc -l        # ページ数
du -sh _mirror                              # 容量
find _mirror -name '*.css' | head           # CSS 取得確認
find _mirror -name '*.js'  | head           # JS  取得確認
```
