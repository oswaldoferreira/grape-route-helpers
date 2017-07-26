require 'spec_helper'

describe GrapeRouteHelpers::DecoratedRoute do
  let(:api) { Spec::Support::API }

  let(:routes) do
    api.routes.map do |route|
      described_class.new(route)
    end
  end

  let(:index_route) do
    routes.detect { |route| route.route_namespace == '/cats' }
  end

  let(:show_route) do
    routes.detect { |route| route.route_namespace == '/cats/:id' }
  end

  let(:catch_all_route) do
    routes.detect { |route| route.route_path =~ /\*/ }
  end

  let(:custom_route) do
    routes.detect { |route| route.route_path =~ /custom_name/ }
  end

  let(:ping_route) do
    routes.detect { |route| route.route_path =~ /ping/ }
  end

  describe '#sanitize_method_name' do
    it 'removes characters that are illegal in Ruby method names' do
      illegal_names = ['beta-1', 'name_with_+', 'name_with_(']
      sanitized = illegal_names.map do |name|
        described_class.sanitize_method_name(name)
      end
      expect(sanitized).to match_array(%w(beta_1 name_with__ name_with__))
    end

    it 'only replaces integers if they appear at the beginning' do
      illegal_name = '1'
      legal_name = 'v1'
      expect(described_class.sanitize_method_name(illegal_name)).to eq('_')
      expect(described_class.sanitize_method_name(legal_name)).to eq('v1')
    end
  end

  describe '#helper_names' do
    context 'when a route is given a custom helper name' do
      it 'uses the custom name instead of the dynamically generated one' do
        expect(custom_route.helper_names.first)
          .to eq('my_custom_route_name_path')
      end

      it 'returns the correct path' do
        expect(
          custom_route.my_custom_route_name_path
        ).to eq('/api/v1/custom_name.json')
      end
    end

    context 'when an API has multiple POST routes in a resource' do
      let(:api) { Spec::Support::MultiplePostsAPI }

      it 'it creates a helper for each POST route' do
        expect(routes.size).to eq(2)
      end
    end

    context 'when an API has multiple versions' do
      let(:api) { Spec::Support::APIWithMultipleVersions }

      it "returns the route's helper name for each version" do
        helper_names = ping_route.helper_names

        # Singular #version call on newer Grape versions return the last version on the list.
        expect(helper_names.size).to eq(api.versions.size)
      end
    end

    context 'when an API has one version' do
      it "returns the route's helper name for that version" do
        helper_name = show_route.helper_names.first
        expect(helper_name).to eq('api_v1_cats_path')
      end
    end
  end

  describe '#helper_arguments' do
    context 'when no user input is needed to generate the correct path' do
      it 'returns an empty array' do
        expect(index_route.helper_arguments).to eq([])
      end
    end

    context 'when user input is needed to generate the correct path' do
      it 'returns an array of required segments' do
        expect(show_route.helper_arguments).to eq(['id'])
      end
    end
  end

  describe '#path_segments_with_values' do
    context 'when path has dynamic segments' do
      it 'replaces segments with corresponding values found in @options' do
        opts = { id: 1 }
        result = show_route.path_segments_with_values(opts)
        expect(result).to include(1)
      end

      context 'when options contains string keys' do
        it 'replaces segments with corresponding values found in the options' do
          opts = { 'id' => 1 }
          result = show_route.path_segments_with_values(opts)
          expect(result).to include(1)
        end
      end
    end
  end

  describe '#path_helper_name' do
    it "returns the name of a route's helper method" do
      expect(index_route.path_helper_name).to eq('api_v1_cats_path')
    end

    context 'when the path is the root path' do
      let(:api_with_root) do
        Class.new(Grape::API) do
          get '/' do
          end
        end
      end

      let(:root_route) do
        grape_route = api_with_root.routes.first
        described_class.new(grape_route)
      end

      it 'returns "root_path"' do
        result = root_route.path_helper_name
        expect(result).to eq('root_path')
      end
    end

    context 'when the path is a catch-all path' do
      it 'returns a name without the glob star' do
        result = catch_all_route.path_helper_name
        expect(result).to eq('api_v1_path_path')
      end
    end
  end

  describe '#segment_to_value' do
    context 'when segment is dynamic' do
      it 'returns the value the segment corresponds to' do
        result = index_route.segment_to_value(':version')
        expect(result).to eq('v1')
      end

      context 'when segment is found in options' do
        it 'returns the value found in options' do
          options = { id: 1 }
          result = show_route.segment_to_value(':id', options)
          expect(result).to eq(1)
        end
      end
    end

    context 'when segment is static' do
      it 'returns the segment' do
        result = index_route.segment_to_value('api')
        expect(result).to eq('api')
      end
    end
  end

  describe 'path helper method' do
    context 'when given a "params" key' do
      context 'when value under "params" key is a hash' do
        it 'creates a query string' do
          query = { foo: :bar, baz: :zot }
          path = index_route.api_v1_cats_path(params:  query)
          expect(path).to eq('/api/v1/cats.json?' + query.to_param)
        end
      end

      context 'when value under "params" is not a hash' do
        it 'coerces the value into a string' do
          path = index_route.api_v1_cats_path(params:  1)
          expect(path).to eq('/api/v1/cats.json?1')
        end
      end
    end

    # handle different Grape::Route#route_path formats in Grape 0.12.0
    context 'when route_path contains a specific format' do
      it 'returns the correct path with the correct format' do
        path = index_route.api_v1_cats_path
        expect(path).to eq('/api/v1/cats.json')
      end
    end

    context 'when helper does not require arguments' do
      it 'returns the correct path' do
        path = index_route.api_v1_cats_path
        expect(path).to eq('/api/v1/cats.json')
      end
    end

    context 'when arguments are needed required to construct the right path' do
      context 'when not missing arguments' do
        it 'returns the correct path' do
          path = show_route.api_v1_cats_path(id: 1)
          expect(path).to eq('/api/v1/cats/1.json')
        end
      end
    end

    context "when a route's API has multiple versions" do
      let(:api) { Spec::Support::APIWithMultipleVersions }

      it 'returns a path for each version' do
        expect(ping_route.alpha_ping_path).to eq('/alpha/ping')
        expect(ping_route.beta_ping_path).to eq('/beta/ping')
        expect(ping_route.v1_ping_path).to eq('/v1/ping')
      end
    end

    context 'when a format is given' do
      it 'returns the path with a correct extension' do
        path = show_route.api_v1_cats_path(id: 1, format: '.xml')
        expect(path).to eq('/api/v1/cats/1.xml')
      end
    end
  end
end
