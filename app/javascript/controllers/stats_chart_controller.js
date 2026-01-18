import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js/auto"

// 統計グラフを管理するStimulusコントローラー
// Chart.jsを使ってインタラクティブなグラフを描画します
export default class extends Controller {
  static targets = [
    "dailyCanvas",
    "weeklyCanvas",
    "monthlyCanvas",
    "weekdayCanvas",
    "paceCanvas",
    "caloriesCanvas",
    "timeOfDayCanvas"
  ]

  static values = {
    dailyUrl: String,
    weeklyUrl: String,
    monthlyUrl: String,
    weekdayUrl: String,
    paceUrl: String,
    caloriesUrl: String,
    timeOfDayUrl: String
  }

  // 各グラフのインスタンスを保持
  charts = {}

  connect() {
    console.log("StatsChart controller connected")
    this.initializeCharts()
  }

  disconnect() {
    // メモリリーク防止: グラフインスタンスを破棄
    Object.values(this.charts).forEach(chart => {
      if (chart) chart.destroy()
    })
    this.charts = {}
  }

  // 全グラフの初期化
  async initializeCharts() {
    // 日別距離グラフ
    if (this.hasDailyCanvasTarget) {
      await this.loadChart("daily", this.dailyCanvasTarget, this.dailyUrlValue, "line")
    }

    // 週別距離グラフ
    if (this.hasWeeklyCanvasTarget) {
      await this.loadChart("weekly", this.weeklyCanvasTarget, this.weeklyUrlValue, "line")
    }

    // 月別距離グラフ
    if (this.hasMonthlyCanvasTarget) {
      await this.loadChart("monthly", this.monthlyCanvasTarget, this.monthlyUrlValue, "line")
    }

    // 曜日別平均距離グラフ
    if (this.hasWeekdayCanvasTarget) {
      await this.loadChart("weekday", this.weekdayCanvasTarget, this.weekdayUrlValue, "bar")
    }

    // ペース推移グラフ
    if (this.hasPaceCanvasTarget) {
      await this.loadChart("pace", this.paceCanvasTarget, this.paceUrlValue, "line")
    }

    // カロリー推移グラフ
    if (this.hasCaloriesCanvasTarget) {
      await this.loadChart("calories", this.caloriesCanvasTarget, this.caloriesUrlValue, "line")
    }

    // 時間帯別円グラフ
    if (this.hasTimeOfDayCanvasTarget) {
      await this.loadChart("daypart", this.timeOfDayCanvasTarget, this.timeOfDayUrlValue, "doughnut")
    }
  }

  // グラフデータを読み込んで描画
  async loadChart(chartId, canvas, url, type) {
    try {
      const response = await fetch(url)

      // HTTPステータスコードをチェック
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()

      // サーバー側のエラーレスポンスをチェック
      if (data.error) {
        throw new Error(data.error)
      }

      // データの妥当性をチェック
      if (!this.validateChartData(chartId, data)) {
        throw new Error(`Invalid data structure for ${chartId} chart`)
      }

      // グラフの設定を構築
      const config = this.buildChartConfig(chartId, data, type)

      // データが全て0の場合はメッセージを表示して終了 (円グラフのみ)
      if (chartId === "daypart") {
        const total = data.data.reduce((a, b) => a + b, 0)
        if (total === 0) {
          this.showErrorOnCanvas(canvas, "データがありません")
          return
        }
      }

      // Chart.jsインスタンスを作成
      this.charts[chartId] = new Chart(canvas, config)
    } catch (error) {
      console.error(`Failed to load ${chartId} chart:`, error)
      // キャンバスにエラーメッセージを表示
      this.showErrorOnCanvas(canvas, `グラフの読み込みに失敗しました: ${chartId}`)
    }
  }

  // グラフデータの妥当性をチェック
  validateChartData(chartId, data) {
    if (!data || typeof data !== 'object') return false

    switch(chartId) {
      case "daily":
        return Array.isArray(data.dates) && Array.isArray(data.distances)
      case "weekly":
        return Array.isArray(data.weeks) && Array.isArray(data.distances)
      case "monthly":
        return Array.isArray(data.months) && Array.isArray(data.distances)
      case "weekday":
        return Array.isArray(data.day_names) && Array.isArray(data.average_distances)
      case "pace":
        return Array.isArray(data.dates) && Array.isArray(data.paces)
      case "calories":
        return Array.isArray(data.dates) && Array.isArray(data.calories)
      case "daypart":
        return Array.isArray(data.labels) && Array.isArray(data.data)
      default:
        return false
    }
  }

  // キャンバスにエラーメッセージを表示
  showErrorOnCanvas(canvas, message) {
    const ctx = canvas.getContext('2d')
    ctx.font = '14px sans-serif'
    ctx.fillStyle = '#ef4444' // red-500
    ctx.textAlign = 'center'
    ctx.fillText(message, canvas.width / 2, canvas.height / 2)
  }

  // グラフの設定を構築
  buildChartConfig(chartId, data, type) {
    const baseConfig = {
      type: type,
      data: this.buildChartData(chartId, data),
      options: this.buildChartOptions(chartId)
    }

    return baseConfig
  }

  // グラフのデータ部分を構築
  buildChartData(chartId, data) {
    switch(chartId) {
      case "daily":
        return {
          labels: data.dates,
          datasets: [{
            label: "距離 (km)",
            data: data.distances,
            borderColor: "rgb(59, 130, 246)", // blue-500
            backgroundColor: "rgba(59, 130, 246, 0.1)",
            tension: 0.3,
            fill: true
          }]
        }

      case "weekly":
        return {
          labels: data.weeks,
          datasets: [{
            label: "距離 (km)",
            data: data.distances,
            borderColor: "rgb(16, 185, 129)", // green-500
            backgroundColor: "rgba(16, 185, 129, 0.1)",
            tension: 0.3,
            fill: true
          }]
        }

      case "monthly":
        return {
          labels: data.months,
          datasets: [{
            label: "距離 (km)",
            data: data.distances,
            borderColor: "rgb(168, 85, 247)", // purple-500
            backgroundColor: "rgba(168, 85, 247, 0.1)",
            tension: 0.3,
            fill: true
          }]
        }

      case "weekday":
        return {
          labels: data.day_names,
          datasets: [{
            label: "平均距離 (km)",
            data: data.average_distances,
            backgroundColor: [
              "rgba(239, 68, 68, 0.7)",   // 日曜 red
              "rgba(251, 146, 60, 0.7)",  // 月曜 orange
              "rgba(234, 179, 8, 0.7)",   // 火曜 yellow
              "rgba(34, 197, 94, 0.7)",   // 水曜 green
              "rgba(59, 130, 246, 0.7)",  // 木曜 blue
              "rgba(168, 85, 247, 0.7)",  // 金曜 purple
              "rgba(236, 72, 153, 0.7)"   // 土曜 pink
            ]
          }]
        }

      case "pace":
        return {
          labels: data.dates,
          datasets: [{
            label: "ペース (分/km)",
            data: data.paces,
            borderColor: "rgb(245, 158, 11)", // amber-500
            backgroundColor: "rgba(245, 158, 11, 0.1)",
            tension: 0.3,
            fill: true
          }]
        }

      case "calories":
        return {
          labels: data.dates,
          datasets: [{
            label: "消費カロリー (kcal)",
            data: data.calories,
            borderColor: "rgb(239, 68, 68)", // red-500
            backgroundColor: "rgba(239, 68, 68, 0.1)",
            tension: 0.3,
            fill: true
          }]
        }

      case "daypart":
        return {
          labels: data.labels,
          datasets: [{
            data: data.data,
            backgroundColor: [
              "rgba(16, 185, 129, 0.7)",  // 早朝: emerald-500
              "rgba(245, 158, 11, 0.7)",  // 日中: amber-500
              "rgba(249, 115, 22, 0.7)",  // 夕方: orange-500 (夕焼けイメージ)
              "rgba(30, 58, 138, 0.7)"    // 夜間: blue-900 (深夜)
            ],
            borderColor: [
              "rgb(16, 185, 129)",
              "rgb(245, 158, 11)",
              "rgb(249, 115, 22)",
              "rgb(30, 58, 138)"
            ],
            borderWidth: 1,
            hoverOffset: 4
          }]
        }

      default:
        return {}
    }
  }

  // グラフのオプションを構築
  buildChartOptions(chartId) {
    const baseOptions = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: true,
          position: "top"
        },
        tooltip: {
          mode: "index",
          intersect: false
        }
      },
      interaction: {
        mode: "nearest",
        axis: "x",
        intersect: false
      }
    }

    // グラフタイプ別の追加設定
    if (chartId === "weekday") {
      // 棒グラフの場合
      baseOptions.scales = {
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: "平均距離 (km)"
          }
        }
      }
    } else if (chartId === "daypart") {
      // 円グラフの場合
      // scales と interaction は不要なので削除
      delete baseOptions.interaction

      // ドーナツチャートのカットアウトサイズ
      baseOptions.cutout = '60%'

      // ツールチップのカスタマイズ (パーセンテージ表示など)
      baseOptions.plugins.tooltip = {
        callbacks: {
          label: function(context) {
            let label = context.label || '';
            if (label) {
              label += ': ';
            }
            const value = context.parsed;
            const dataset = context.dataset;
            const total = dataset.data.reduce((acc, data) => acc + data, 0);
            const percentage = total > 0 ? ((value / total) * 100).toFixed(1) + "%" : "0%";
            return `${label}${value}回 (${percentage})`;
          }
        }
      }
    } else {
      // 折れ線グラフの場合
      baseOptions.scales = {
        y: {
          beginAtZero: true,
          title: {
            display: true,
            text: this.getYAxisLabel(chartId)
          }
        },
        x: {
          title: {
            display: false
          }
        }
      }
    }

    return baseOptions
  }

  // Y軸のラベルを取得
  getYAxisLabel(chartId) {
    const labels = {
      daily: "距離 (km)",
      weekly: "距離 (km)",
      monthly: "距離 (km)",
      pace: "ペース (分/km)",
      calories: "消費カロリー (kcal)"
    }
    return labels[chartId] || ""
  }
}
