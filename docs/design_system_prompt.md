# Design System: Puni-Puni Claymorphism

# このプロンプトは、アプリケーション全体で統一された「プニプニ・クレイモーフィズム」デザインを適用するためのガイドラインです。

## 🎨 デザインコンセプト

**「触りたくなるような、柔らかく、楽しく、温かい（ポップ × リッチ × わくわく） UI」**

- **キーワード:** Claymorphism（クレイモーフィズム）, Soft UI, Puni-Puni（プニプニ感）, Colorful, Tactile（触感）, Rounded

## 🛠️ スタイリングルール (Tailwind CSS)

### 1. 形状 (Shape)

- **角丸:** 基本的に `rounded-3xl` (24px) 以上を使用する。
  - カード: `rounded-[2.5rem]` (40px)
  - ボタン: `rounded-full` (完全な円/カプセル)
  - 入力エリア: `rounded-2xl` ~ `rounded-3xl`
- **意図:** 鋭利な角を排除し、徹底的に「柔らかさ」を強調する。

### 2. 質感と立体感 (Texture & Depth)

Claymorphism の核となる要素。単色の背景ではなく、光と影で形を作る。

#### A. 浮き出し (Floating Elements) - カード、モーダル、ボタン

要素が背景から「プニッ」と浮き出ている表現。

- **Shadow:** 2 つの影を組み合わせる（右下の暗い影 + 左上の白いハイライト）。
- **Border:** 背景と同化しないよう、極薄の白ボーダーを入れる。

```css
/* Tailwind Example */
class="bg-white rounded-[2.5rem] border border-white/60 shadow-[14px_14px_28px_rgba(166,175,195,0.25),-14px_-14px_28px_rgba(255,255,255,0.9)]"
```

#### B. くぼみ (Indented Elements) - 入力フォーム、リアクションエリア

要素が粘土に指で押し込まれたような表現。

- **Shadow:** `shadow-inner` をベースに、内側に影を落とす。
- **Background:** 周囲より少し暗い色、または半透明の背景色。

```css
/* Tailwind Example */
class="bg-slate-50 rounded-3xl shadow-inner border border-black/5"
```

#### C. ドーム状 (Dome Shape) - 重要なアクションボタン（削除など）

おはじきのような、中央が盛り上がった球体表現。

- **Background:** `radial-gradient` で光沢を表現。
- **Shadow:** `inset` シャドウで立体感を強調。

```css
/* Tailwind Example */
style="background: radial-gradient(circle at 30% 30%, #ffffff, #e2e8f0);
       box-shadow: 6px 6px 12px rgba(0,0,0,0.1), -6px -6px 12px rgba(255,255,255,0.9), inset 2px 2px 5px rgba(255,255,255,1);"
```

### 3. 配色 (Color Palette)

感情や状況の「強度」に合わせて彩度を調整する。

- **Base (背景):** `bg-[#fdfbf7]` (Warm White) や `bg-slate-50` など、真っ白すぎない温かみのある色。
- **Pastel (通常):** 淡い色味で優しさを表現。
  - 例: `bg-orange-50`, `bg-blue-50`, `text-orange-600`
- **Vivid (強調):** 強い感情やアクションには、少し濃い色をアクセントに使うが、背景色は淡く保ち、**ボーダーとテキスト色**で強度を出す。
  - 例: `border-purple-400`, `text-purple-800` (背景は `bg-purple-50` 程度に抑える)

### 4. インタラクション (Micro-interactions)

「生きている」ような動きをつける。

- **Hover:** `hover:-translate-y-1` (少し浮く) + `hover:scale-105` (少し膨らむ)
- **Active:** `active:scale-95` (押される) + `active:shadow-inner` (凹む)
- **Animation:** `animate-bounce-slow`, `animate-pulse-slow` など、ゆっくりとした有機的な動き。

## 📝 実装時のプロンプト例

AI にデザインを依頼する際は、以下の指示を含めてください。

> 「UI デザインは『Puni-Puni Claymorphism』テーマを採用してください。
> 具体的には、TailwindCSS を使用して以下の特徴を持たせてください：
>
> 1. 角丸は `rounded-3xl` 以上で大きく取る。
> 2. `box-shadow` を駆使して、粘土のような『浮き出し』と『くぼみ』を表現する（単なるフラットデザイン禁止）。
> 3. ボタンは `rounded-full` で、押すと凹むアニメーションをつける。
> 4. 配色はパステルカラーを基調とし、要素の境界には薄い白のボーダー (`border-white/60`) を入れて質感を高める。」
