# Convert to Sage

解析結果を Sage 11 (Blade + Tailwind + Vite) テーマに転写する。

## 編集対象パス

ベース: `web/app/themes/clone-theme/`

```
resources/
├── css/app.css                    # Tailwind エントリ + @theme で変数定義
├── js/app.js                      # JS エントリ
├── images/                        # 旧サイトの画像をここに
├── fonts/                         # 旧サイトのフォントをここに
└── views/
    ├── layouts/
    │   └── app.blade.php          # 全体レイアウト (html, head, body)
    ├── sections/
    │   ├── header.blade.php       # 共通ヘッダ
    │   └── footer.blade.php       # 共通フッタ
    ├── components/                # 再利用要素 (card, hero, cta, nav)
    ├── partials/                  # ページ内部品
    ├── front-page.blade.php       # トップページテンプレ
    ├── page.blade.php             # 汎用固定ページ
    ├── single.blade.php           # 単一記事
    └── template-<name>.blade.php  # カスタムテンプレ (管理画面で選択可)
app/
├── setup.php                      # メニュー / サイドバー / 画像サイズ等の登録
├── filters.php                    # フィルタ
└── Providers/                     # サービスプロバイダ
```

## Tailwind / theme.json 連動

`resources/css/app.css` の `@theme` ブロックで色・フォント・余白を定義すると、
ビルド時に `theme.json` (WP エディタ用) も自動生成される (Sage 11 の機能)。

```css
@import "tailwindcss";

@theme {
  --color-brand-primary: #0066cc;
  --color-brand-secondary: #f5a623;
  --font-sans: "Inter", system-ui, sans-serif;
  --font-serif: "Noto Serif JP", serif;
  --spacing-section: 6rem;
}
```

## Blade コンポーネントの基本

`resources/views/components/hero.blade.php`:

```blade
@props(['title', 'subtitle' => null, 'image' => null])

<section class="bg-brand-primary text-white py-section">
  <div class="container mx-auto px-4">
    <h1 class="text-4xl font-bold">{{ $title }}</h1>
    @if($subtitle)
      <p class="mt-4 text-xl opacity-80">{{ $subtitle }}</p>
    @endif
  </div>
</section>
```

呼び出し:

```blade
<x-hero title="社内ポータル" subtitle="再構築版" />
```

## 旧 HTML → Blade への変換ルール

| 旧 | 新 |
|---|---|
| `<head>` の `<title>` | `@php wp_title(); @endphp` or レイアウトの `wp_head()` |
| `<link rel="stylesheet">` | `@vite('resources/css/app.css')` |
| `<script>` | `@vite('resources/js/app.js')` |
| 静的ナビ | `wp_nav_menu(['theme_location' => 'primary'])` (setup.php で登録) |
| サイドバー | `dynamic_sidebar('sidebar-primary')` |
| ベタ書き画像 URL | `@asset('images/foo.png')` |
| 繰り返しブロック | `<x-card ... />` コンポーネント化 |

## ビルド & 反映

```bash
cd web/app/themes/clone-theme
npm run dev          # 開発時 (HMR)
npm run build        # 本番ビルド
```

`vite.config.js` の `base` がテーマ名と一致しているか確認:

```js
base: '/app/themes/clone-theme/public/',
```

## 動作確認

```bash
ddev wp theme list                     # clone-theme が active か
ddev wp option update show_on_front page  # トップを固定ページに
ddev wp option update page_on_front <ID>
```

## 完了条件

- 旧サイトの主要 5 ページが Blade テンプレで描画される
- `npm run build` が警告なく完了
- `composer lint && composer analyse` 0 エラー
- old/new スクショ差分が許容内
