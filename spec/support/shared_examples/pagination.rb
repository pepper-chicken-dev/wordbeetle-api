RSpec.shared_examples 'paginated endpoint' do |factory_name, create_options_proc|
  describe 'pagination' do
    it 'returns pagination metadata' do
      get endpoint_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['pagination']).to include(
        'current_page' => 1,
        'per_page' => 20,
        'total_count' => a_kind_of(Integer),
        'total_pages' => a_kind_of(Integer)
      )
    end

    it 'paginates results with page and per_page params' do
      create_options = create_options_proc ? instance_exec(&create_options_proc) : {}
      create_list(factory_name, 3, **create_options)

      get endpoint_path, params: { page: 1, per_page: 2 }, headers: headers

      expect(response.parsed_body['data'].size).to eq(2)
      pagination = response.parsed_body['pagination']
      expect(pagination['current_page']).to eq(1)
      expect(pagination['total_pages']).to eq(2)
      expect(pagination['total_count']).to eq(3)
    end

    it 'returns the second page' do
      create_options = create_options_proc ? instance_exec(&create_options_proc) : {}
      create_list(factory_name, 3, **create_options)

      get endpoint_path, params: { page: 2, per_page: 2 }, headers: headers

      expect(response.parsed_body['data'].size).to eq(1)
      expect(response.parsed_body['pagination']['current_page']).to eq(2)
    end
  end
end
