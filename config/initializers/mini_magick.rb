# MiniMagickの読み込みをオプショナルにして、本番環境でImageMagickがなくてもアプリが起動するようにする
begin
  require "mini_magick"
  Rails.logger.info "MiniMagick loaded successfully"
rescue LoadError => e
  Rails.logger.warn "MiniMagick could not be loaded: #{e.message}"
  Rails.logger.warn "OGP image generation will not be available"
end
