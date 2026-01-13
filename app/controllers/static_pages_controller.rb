class StaticPagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:privacy]

  def privacy; end
end
