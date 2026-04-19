module Paginatable
  extend ActiveSupport::Concern

  included do
    include Pagy::Backend
  end

  private

  def render_paginated(collection, resource_class, status: :ok, **resource_options)
    pagy_obj, records = pagy(collection)

    render json: {
      data: resource_class.new(records, **resource_options).serializable_hash,
      pagination: {
        current_page: pagy_obj.page,
        total_pages: pagy_obj.pages,
        total_count: pagy_obj.count,
        per_page: pagy_obj.vars[:items]
      }
    }, status: status
  end
end
