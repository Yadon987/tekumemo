class GeneratePostOgpImageJob < ApplicationJob
  queue_as :default

  # リトライ設定: 指数バックオフで最大3回リトライ
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  # 最終的に失敗した場合の処理
  discard_on ActiveJob::DeserializationError

  def perform(post)
    return if post.ogp_image.attached?

    Rails.logger.info "Starting background OGP generation for Post ID: #{post.id}"

    user = post.user
    walk = post.walk || user.walks.find_by(walked_on: post.created_at.to_date)

    # レベル計算
    level = StatsService.new(user).level

    # 統計情報
    stats = {
      level: level,
      date: walk&.walked_on&.strftime("%Y-%m-%d") || post.created_at.strftime("%Y-%m-%d"),
      label1: "DISTANCE",
      value1: "#{walk&.distance || 0} km",
      label2: "EXP (STEPS)",
      value2: "#{walk&.steps || 0}",
      label3: "LOCATION",
      value3: walk&.location.presence || "TekuMemo"
    }

    image_data = RpgCardGeneratorService.new(
      user: user,
      title: "QUEST COMPLETE",
      message: post.body,
      stats: stats,
      theme: :quest
    ).generate

    # Active Storageに保存
    post.ogp_image.attach(
      io: StringIO.new(image_data),
      filename: "post_#{post.id}_ogp.jpg",
      content_type: "image/jpeg"
    )

    Rails.logger.info "Background OGP generation completed for Post ID: #{post.id}"
  end
end
