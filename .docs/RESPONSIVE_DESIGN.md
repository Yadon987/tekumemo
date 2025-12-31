# Responsive Design System

## 📱 基本方針

このプロジェクトは**モバイルファースト**のレスポンシブデザインを採用しています。
ターゲットユーザーの大半がスマートフォンユーザーであることを前提に、シンプルで一貫性のある 2 段階設計を実現します。

---

## 🎯 ブレークポイント戦略

### **シンプル 2 段階設計**

複雑なブレークポイントを避け、**「モバイル」と「それ以外」**の 2 パターンに絞ることで、メンテナンス性と一貫性を確保します。

| デバイスカテゴリ      | 画面幅      | Tailwind 記法      | 用途                              |
| :-------------------- | :---------- | :----------------- | :-------------------------------- |
| **📱 スマートフォン** | 0px ~ 639px | プレフィックスなし | **デフォルト**（iPhone, Android） |
| **💻 タブレット/PC**  | 640px 以上  | `sm:`              | タブレット・デスクトップ          |

### **使用するブレークポイント**

- ✅ **`sm:` (640px~)**: 全面的に使用
- ❌ **`md:` (768px~)**: 使用禁止
- ❌ **`lg:` (1024px~)**: 使用禁止
- ❌ **`xl:` (1280px~)**: 使用禁止
- ❌ **`2xl:` (1536px~)**: 使用禁止

**理由:**

- シンプルな設計で保守性向上
- 一貫したユーザー体験
- コード量の削減
- デザインの統一性

---

## 📐 スケーリング比率

スマホから PC/タブレットへの拡大時は、**1.3 ～ 1.6 倍**の範囲で統一することで、自然で違和感のない拡大を実現します。

### **推奨スケール比率**

| 要素                    | スマホ               | PC/タブレット            | 比率         |
| :---------------------- | :------------------- | :----------------------- | :----------- |
| **小さいアイコン**      | `w-7 h-7` (28px)     | `sm:w-10 sm:w-10` (40px) | 1.43 倍      |
| **中アイコン**          | `w-8 h-8` (32px)     | `sm:w-9 sm:h-9` (36px)   | 1.13 倍      |
| **大アイコン**          | `w-12 h-12` (48px)   | `sm:w-14 sm:h-14` (56px) | 1.17 倍      |
| **padding (小)**        | `py-2 px-3` (8×12px) | `sm:py-4 sm:px-4` (16px) | 2 倍/1.33 倍 |
| **ナビゲーション高さ**  | `h-10` (40px)        | `sm:h-16` (64px)         | 1.6 倍       |
| **フォント (見出し)**   | `text-xl` (20px)     | `sm:text-3xl` (30px)     | 1.5 倍       |
| **フォント (本文)**     | `text-base` (16px)   | `sm:text-lg` (18px)      | 1.13 倍      |
| **フォント (アイコン)** | `text-lg` (18px)     | `sm:text-2xl` (24px)     | 1.33 倍      |

---

## 🧩 コンポーネント別ガイドライン

### **1. ヘッダー（Header）**

```erb
<!-- ✅ 正しい例：2段階レスポンシブ -->
<header class="fixed top-0 left-0 right-0 z-50 bg-white/60 dark:bg-slate-950/60 backdrop-blur-xl">
  <div class="grid grid-cols-3 items-center py-2 px-3 sm:py-4 sm:px-4 w-full max-w-2xl mx-auto">
    <!-- スマホ: py-2 px-3 (8×12px) -->
    <!-- PC: py-4 px-4 (16px) -->
  </div>
</header>
```

**調整項目:**

- `padding`: `py-2 px-3` → `sm:py-4 sm:px-4`
- `アイコンサイズ`: `h-7 w-7` → `sm:h-10 sm:w-10`
- `フォントサイズ`: `text-lg` → `sm:text-2xl`

---

### **2. ロゴ・ブランディング**

```erb
<!-- ✅ 正しい例：視認性重視で大きめに -->
<span class="text-xl sm:text-3xl font-bold bg-gradient-to-r from-sky-500 to-blue-600 bg-clip-text text-transparent">
  てくメモ
</span>
```

**調整項目:**

- `フォントサイズ`: `text-xl` (20px) → `sm:text-3xl` (30px)
- `比率`: 1.5 倍（視認性重視）

---

### **3. ボタン**

#### **アイコンのみボタン（FAB 等）**

```erb
<!-- ✅ 正しい例：タップ領域確保 -->
<button class="w-12 h-12 sm:w-14 sm:h-14 rounded-full bg-gradient-to-r from-orange-400 to-pink-500">
  <span class="material-symbols-outlined text-2xl sm:text-3xl">add</span>
</button>
```

**最小サイズ:**

- スマホ: `w-12 h-12` (48px) - タップ領域の最小推奨サイズ
- PC: `sm:w-14 sm:h-14` (56px)

#### **テキスト付きボタン**

```erb
<!-- ✅ 正しい例：パディング調整 -->
<button class="px-4 py-2 sm:px-6 sm:py-3 rounded-full bg-blue-500 text-sm sm:text-base">
  新規作成
</button>
```

**調整項目:**

- `padding`: `px-4 py-2` → `sm:px-6 sm:py-3`
- `フォント`: `text-sm` → `sm:text-base`

---

### **4. カード**

```erb
<!-- ✅ 正しい例：padding と角丸を調整 -->
<div class="p-4 sm:p-6 rounded-[2.5rem] sm:rounded-[3rem] bg-white dark:bg-slate-900/40">
  <!-- 内容 -->
</div>
```

**調整項目:**

- `padding`: `p-4` (16px) → `sm:p-6` (24px)
- `角丸`: `rounded-[2.5rem]` (40px) → `sm:rounded-[3rem]` (48px)

---

### **5. ナビゲーション（ボトムナビ）**

```erb
<!-- ✅ 正しい例：高さとアイコンサイズを調整 -->
<nav class="fixed bottom-0 left-0 right-0 bg-white/60 dark:bg-slate-950/60 backdrop-blur-xl">
  <div class="flex justify-around items-center h-10 sm:h-16 max-w-2xl mx-auto">
    <a href="#" class="flex items-center justify-center w-full">
      <span class="material-symbols-outlined text-lg sm:text-2xl">home</span>
    </a>
  </div>
</nav>
```

**調整項目:**

- `ナビ高さ`: `h-10` (40px) → `sm:h-16` (64px)
- `アイコン`: `text-lg` (18px) → `sm:text-2xl` (24px)

**重要:** ナビの高さが変わる場合、FAB ボタンの位置も調整すること。

---

### **6. モーダル**

```erb
<!-- ✅ 正しい例：幅とパディングを調整 -->
<div class="w-full sm:max-w-md mx-4 sm:mx-auto p-6 sm:p-8 rounded-[2.5rem] sm:rounded-[3.75rem]">
  <!-- モーダル内容 -->
</div>
```

**調整項目:**

- `幅`: スマホは `w-full`、PC は `sm:max-w-md`（最大幅制限）
- `padding`: `p-6` → `sm:p-8`
- `角丸`: `rounded-[2.5rem]` → `sm:rounded-[3.75rem]`

---

### **7. テキスト表示の切り替え**

```erb
<!-- ✅ 正しい例：スマホでは改行、PCではインライン -->
<span class="block sm:inline">お知らせメッセージ</span>

<!-- ✅ 正しい例：スマホでは非表示、PCでは表示 -->
<span class="hidden sm:inline">追加情報</span>

<!-- ✅ 正しい例：スマホでは表示、PCでは非表示 -->
<span class="sm:hidden">省略版</span>
```

---

### **8. 間隔・マージン**

```erb
<!-- ✅ 正しい例：余白を段階的に拡大 -->
<div class="space-y-3 sm:space-y-4">
  <!-- カード一覧 -->
</div>

<div class="mb-4 sm:mb-6">
  <!-- セクション -->
</div>
```

**推奨比率:**

- 小: `space-y-2` → `sm:space-y-3`
- 中: `space-y-3` → `sm:space-y-4`
- 大: `space-y-4` → `sm:space-y-6`

---

## 🚫 アンチパターン（禁止事項）

### **❌ NG 例 1：3 段階以上のブレークポイント使用**

```erb
<!-- ❌ 悪い例：複雑すぎる -->
<div class="text-sm md:text-base lg:text-lg xl:text-xl">
  てくメモ
</div>

<!-- ✅ 良い例：シンプルな2段階 -->
<div class="text-sm sm:text-base">
  てくメモ
</div>
```

### **❌ NG 例 2：統一感のないスケーリング**

```erb
<!-- ❌ 悪い例：バラバラな比率 -->
<div class="w-6 sm:w-16">  <!-- 2.67倍 -->
  <span class="text-xs sm:text-3xl">  <!-- 2.5倍 -->
    アイコン
  </span>
</div>

<!-- ✅ 良い例：統一された比率（1.43倍） -->
<div class="w-7 sm:w-10">
  <span class="text-lg sm:text-2xl">
    アイコン
  </span>
</div>
```

### **❌ NG 例 3：デスクトップファースト**

```erb
<!-- ❌ 悪い例：PCがベース -->
<div class="w-full lg:w-1/2">
  <!-- 内容 -->
</div>

<!-- ✅ 良い例：モバイルがベース -->
<div class="w-full sm:w-1/2">
  <!-- 内容 -->
</div>
```

### **❌ NG 例 4：タップ領域の不足**

```erb
<!-- ❌ 悪い例：スマホでタップしにくい -->
<button class="w-6 h-6 sm:w-10 sm:h-10">
  <!-- 24px × 24px は小さすぎる -->
</button>

<!-- ✅ 良い例：最低48px確保 -->
<button class="w-12 h-12 sm:w-14 sm:h-14">
  <!-- スマホでもタップしやすい -->
</button>
```

**推奨最小サイズ:**

- ボタン・タップ可能要素: `w-12 h-12` (48px) 以上

---

## 📏 レイアウトガイドライン

### **1. コンテンツ最大幅**

すべてのページで統一された最大幅を使用すること。

```erb
<!-- ✅ 推奨：max-w-2xl (672px) -->
<div class="max-w-2xl mx-auto px-4 sm:px-6">
  <!-- メインコンテンツ -->
</div>
```

**理由:**

- タブレット・PC で横幅が広がりすぎるのを防ぐ
- 可読性の維持
- モバイルアプリライクな見た目

### **2. ヘッダー・ナビゲーションの高さに応じた調整**

固定ヘッダー・ナビゲーションの高さが変わる場合、メインコンテンツの `padding-top` / `padding-bottom` も調整すること。

```erb
<!-- ヘッダー -->
<header class="... py-2 sm:py-4">...</header>

<!-- メインコンテンツ（ヘッダー分の余白） -->
<main class="pt-12 sm:pt-20">
  <!-- ヘッダーが py-2 → py-4 に変わるので、padding も調整 -->
</main>

<!-- FABボタン（ボトムナビ分の余白） -->
<div class="... bottom-[65px] sm:bottom-24">
  <!-- ボトムナビが h-10 → h-16 に変わるので、位置も調整 -->
</div>
```

---

## 🎨 デザインシステムとの統合

### **ライトモード・ダークモードとの組み合わせ**

レスポンシブクラスとダークモードクラスは**組み合わせて使用**すること。

```erb
<!-- ✅ 正しい例：レスポンシブ × ダークモード -->
<div class="
  bg-white dark:bg-slate-900/40
  p-4 sm:p-6
  rounded-[2.5rem] sm:rounded-[3rem]
  shadow-clay-card dark:shadow-neon-blue
">
  <!-- スマホ・ライト: bg-white, p-4, rounded-[2.5rem], shadow-clay-card -->
  <!-- スマホ・ダーク: bg-slate-900/40, p-4, rounded-[2.5rem], shadow-neon-blue -->
  <!-- PC・ライト: bg-white, p-6, rounded-[3rem], shadow-clay-card -->
  <!-- PC・ダーク: bg-slate-900/40, p-6, rounded-[3rem], shadow-neon-blue -->
</div>
```

**クラスの順序（推奨）:**

1. レイアウト（`flex`, `grid`, `relative`）
2. サイズ（`w-`, `h-`, `p-`, `m-`）とレスポンシブ
3. 色（ライトモード → ダークモード）
4. その他（`rounded-`, `shadow-`）

---

## 🔧 実装チェックリスト

新しいコンポーネントを作成する際は、以下を確認すること：

### **スマホ対応**

- [ ] タップ領域は最低 `w-12 h-12` (48px) 以上
- [ ] テキストは `text-sm` (14px) 以上
- [ ] 横スクロールが発生しないか確認
- [ ] padding が狭すぎないか（最低 `p-3` 推奨）

### **レスポンシブ対応**

- [ ] `sm:` プレフィックスのみ使用（`md:`, `lg:` は使わない）
- [ ] スケール比率が 1.3 ～ 1.6 倍の範囲内
- [ ] ヘッダー・ナビの高さ変更に応じて、他の要素の位置も調整

### **デザインシステム統合**

- [ ] ライトモード（Crystal Claymorphism）のスタイルを適用
- [ ] ダークモード（Holographic Neon Noir）のスタイルを適用
- [ ] ダークモードクラスが `dark:` プレフィックスで正しく分離されている

### **アクセシビリティ**

- [ ] コントラスト比が十分（WCAG 2.1 Level A）
- [ ] フォーカス表示が明確（`focus:ring-2` など）
- [ ] `aria-label` が適切に設定されている

---

## 📱 対象デバイス一覧

### **スマートフォン（640px 未満）**

- iPhone SE (375px)
- iPhone 12/13/14 (390px)
- iPhone 14 Pro (393px)
- iPhone 14 Pro Max (430px)
- Samsung Galaxy S21 (360px)
- Google Pixel 7 (412px)

### **タブレット/PC（640px 以上）**

- iPad Mini（縦持ち: 768px、横持ち: 1024px）
- iPad Air（縦持ち: 820px、横持ち: 1180px）
- デスクトップ PC（1280px ～）

---

## 🎯 設計思想

この 2 段階レスポンシブ設計は、以下の原則に基づいています：

1. **シンプルさ**: 複雑なブレークポイントを避け、保守性を向上
2. **一貫性**: すべてのコンポーネントで統一されたスケーリング
3. **モバイルファースト**: ターゲットユーザーの大半がスマホユーザー
4. **アプリライク**: モバイルアプリのような UX を提供

---

## 🚀 プロンプト例

AI にコンポーネントを作成してもらう際は、以下のプロンプトを使用してください：

> 「このコンポーネントは、モバイルファースト・2 段階レスポンシブ設計で実装してください。
> 具体的には：
>
> 1. **ブレークポイント**: `sm:` (640px) のみ使用。`md:`, `lg:` は使用禁止。
> 2. **スケール比率**: スマホから PC へは 1.3 ～ 1.6 倍 の範囲で拡大。
> 3. **最小サイズ**: タップ可能要素は `w-12 h-12` (48px) 以上。
> 4. **デザインシステム**: ライトモード（Crystal Claymorphism）とダークモード（Holographic Neon Noir）の両方に対応。
> 5. **クラス順序**: レイアウト → サイズ（レスポンシブ含む） → 色（ライト・ダーク） → その他。
>
> `.docs/RESPONSIVE_DESIGN.md` の指針に厳密に従ってください。」

---

**Last Updated:** 2025-12-30
**Version:** 1.0
