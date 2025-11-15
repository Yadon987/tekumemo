// app/javascript/controllers/index.js
import { application } from "./application"

// 明示的にコントローラーを登録
import HelloController from "./hello_controller"
import ThemeController from "./theme_controller"

application.register("hello", HelloController)
application.register("theme", ThemeController)

// 登録確認用のログ
console.log("Stimulus controllers registered:", {
  hello: HelloController,
  theme: ThemeController
})

// デバッグ用
window.stimulusApp = application
