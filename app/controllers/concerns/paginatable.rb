module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100
  private_constant :DEFAULT_PER_PAGE, :MAX_PER_PAGE

  private

  def paginate(collection)
    per = per_page_param
    total_count = collection.count
    total_pages = [(total_count.to_f / per).ceil, 1].max
    current_page = page_param.clamp(1, total_pages)

    records = collection.offset((current_page - 1) * per).limit(per)
    meta = {
      current_page: current_page,
      total_pages: total_pages,
      total_count: total_count,
      per_page: per
    }
    [records, meta]
  end

  def page_param
    val = params[:page].to_i
    val.positive? ? val : 1
  end

  def per_page_param
    val = params[:per_page].to_i
    val.positive? && val <= MAX_PER_PAGE ? val : DEFAULT_PER_PAGE
  end
end
