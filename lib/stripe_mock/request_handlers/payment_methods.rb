module StripeMock
  module RequestHandlers
    module PaymentMethods
      def self.included(klass)
        klass.add_handler 'post /v1/payment_methods', :create
        klass.add_handler 'post /v1/payment_methods/([^/]*)', :create
        klass.add_handler 'get /v1/payment_methods/([^/]*)', :get
        klass.add_handler 'get /v1/payment_methods', :list
        klass.add_handler 'post /v1/payment_methods/([^/]*)/attach', :attach
        klass.add_handler 'post /v1/payment_methods/([^/]*)/detach', :detach
      end

      def create(route, method_url, params, headers)
        route =~ method_url
        params[:id] ||= $1 || new_id('pm')

        case params[:type]
        when "card"
          raise Stripe::InvalidRequestError.new("Missing required param: card", nil, http_status: 400) unless params[:card]
        else
          raise Stripe::InvalidRequestError.new("Missing required param: type", nil, http_status: 400)
        end

        payment_method = Data.mock_payment_method(params)
        payment_methods[params[:id]] = payment_method
      end

      def get(route, method_url, params, headers)
        route =~ method_url
        assert_existence :payment_method, $1, payment_methods[$1]
      end

      def list(route, method_url, params, headers)
        customer_id = customer_to_id(params[:customer])

        assert_existence :customer, customer_id, customers[customer_id]

        type = params[:type]

        customer_payment_methods = payment_methods
          .values
          .select { |pm| pm[:type] == type && pm[:customer] == customer_id }

        Data.mock_list_object(customer_payment_methods, params)
      end

      def attach(route, method_url, params, headers)
        route =~ method_url
        payment_method =
          assert_existence :payment_method, $1, payment_methods[$1]

        customer_id = customer_to_id(params[:customer])
        customer =
          assert_existence :customer, customer_id, customers[customer_id]

        payment_method[:customer] = customer_id
        payment_method
      end

      def detach(route, method_url, params, headers)
        route =~ method_url
        payment_method =
          assert_existence :payment_method, $1, payment_methods[$1]

        payment_method[:customer] = nil
        payment_method
      end

      def customer_to_id(customer)
        customer.respond_to?(:to_h) ? customer.to_h[:id] : customer
      end
    end
  end
end
