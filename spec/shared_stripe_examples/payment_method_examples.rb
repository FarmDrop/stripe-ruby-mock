require 'spec_helper'

shared_examples 'Payment Method API' do
  describe '#create' do
    it 'creates a payment method' do
      payment_method = Stripe::PaymentMethod.create(
        type: 'card',
        card: {
          number: "4242424242424242",
          exp_month: 10,
          exp_year: 2030
        }
      )

      expect(payment_method.id).not_to be_nil
    end

    it "fails if type is not sent" do
      expect { Stripe::PaymentMethod.create }
        .to raise_error Stripe::InvalidRequestError
    end

    it "fails if type is card and card is not sent" do
      expect { Stripe::PaymentMethod.create(type: 'card') }
        .to raise_error Stripe::InvalidRequestError
    end
  end

  describe '#retrieve' do
    let(:payment_method) do
      Stripe::PaymentMethod.create(
        type: 'card',
        card: {
          number: "4242424242424242",
          exp_month: 10,
          exp_year: 2030
        }
      )
    end

    it 'gets a payment method' do
      expect(Stripe::PaymentMethod.retrieve(payment_method.id))
        .to eq payment_method
    end

    it "returns a 404 if the payment method doesn't exist" do
      expect { Stripe::PaymentMethod.retrieve("foo") }
        .to raise_error Stripe::InvalidRequestError
    end
  end

  describe '#attach' do
    let(:payment_method) do
      Stripe::PaymentMethod.create(
        type: 'card',
        card: {
          number: "4242424242424242",
          exp_month: 10,
          exp_year: 2030
        }
      )
    end

    let(:customer) { Stripe::Customer.create }

    it "attaches the payment method to the customer" do
      expect { Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id) }
        .to change { Stripe::PaymentMethod.retrieve(payment_method.id).customer }
        .from(nil)
        .to(customer.id)
    end
  end

  describe "#detach" do
    let(:payment_method) do
      Stripe::PaymentMethod.create(
        type: 'card',
        card: {
          number: "4242424242424242",
          exp_month: 10,
          exp_year: 2030
        }
      )
    end

    let(:customer) { Stripe::Customer.create }

    before { Stripe::PaymentMethod.attach(payment_method.id, customer: customer.id) }

    it "detaches the payment method to the customer" do
      expect { Stripe::PaymentMethod.detach(payment_method.id) }
        .to change { Stripe::PaymentMethod.retrieve(payment_method.id).customer }
        .from(customer.id)
        .to(nil)
    end
  end

  describe "#list" do
    let(:customer) { Stripe::Customer.create }

    let(:payment_methods) do
      (1..2).map do |i|
        Stripe::PaymentMethod.create(
          type: 'card',
          card: {
            number: '4242424242424242',
            exp_month: i,
            exp_year: 2030
          }
        )
      end
    end

    before do
      payment_methods.each do |pm|
        Stripe::PaymentMethod.attach(pm.id, customer: customer)
      end
    end

    it 'gets all a customers payment methods' do
      expect(Stripe::PaymentMethod.list(customer: customer, type: 'card').map(&:id))
        .to match_array payment_methods.map(&:id)
    end
  end
end
