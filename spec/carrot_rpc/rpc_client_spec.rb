require "spec_helper"
require "carrot_rpc"

RSpec.describe CarrotRpc::RpcClient do
  subject(:client) {
    client_class.new
  }

  let(:client_class) {
    Class.new(CarrotRpc::RpcClient)
  }

  describe "#queue_name" do
    it "has a queue name class method" do
      client_class.queue_name "foo"
      expect(client_class.queue_name).to eq "foo"
    end

    context "during #start" do
      # lets

      let(:channel) {
        instance_double(Bunny::Channel, default_exchange: nil)
      }

      # Callbacks

      before(:each) do
        allow(CarrotRpc.configuration.bunny).to receive(:create_channel).and_return(channel)
      end

      it "does not default queue name" do
        expect(channel).to receive(:queue).with(nil, auto_delete: false)

        client.start
      end
    end

    context "with client_test_mode enabled" do
      before :each do
        CarrotRpc.configuration.client_test_mode = true
      end

      after :each do
        CarrotRpc.configuration.client_test_mode = false
      end

      it "modifies the queue name" do
        client_class.queue_name "foo"
        client.start
        expect(client.server_queue.name).to eq "foo_test"
      end

      it "fails if queue name is missing" do
        expect { client.start }.to raise_error CarrotRpc::Exception::InvalidQueueName
      end
    end
  end

  describe "#remote_call" do
    before :each do
      CarrotRpc.configuration.rpc_client_request_key_format = :dasherize
      CarrotRpc.configuration.rpc_client_response_key_format = :underscore

      client_class.queue_name "lannister"
      client.start
    end

    after :each do
      CarrotRpc.configuration.rpc_client_request_key_format = :none
      CarrotRpc.configuration.rpc_client_response_key_format = :none
    end

    it "calls all the important methods needed for a request" do
      allow(client).to receive :start
      allow(client).to receive :subscribe
      allow(client).to receive :publish
      allow(client).to receive :wait_for_result

      correlation_id = "ABC123"
      allow(SecureRandom).to receive(:uuid) { correlation_id }

      expect(client).to receive :start
      expect(client).to receive :subscribe

      method = :foo_bar
      params = {}
      expect(client).to receive(:publish).with(correlation_id: correlation_id, method: method, params: params)
      expect(client).to receive(:wait_for_result).with(correlation_id)

      subject.remote_call(method, params)
    end

    it "does nothing if a Proc is not set" do
      params = { data: { name: "foo" } }
      method = :foo_method
      random_id = SecureRandom.uuid

      allow(SecureRandom).to receive(:uuid) { random_id }
      allow(client).to receive(:publish)
      allow(client).to receive(:wait_for_result)

      result_params = { "data" => { "name" => "foo" } }
      expect(client).to receive(:publish).with(correlation_id: random_id, method: method, params: result_params)
      subject.remote_call(method, params)
    end

    it "passes params to Proc before making a remote call" do
      client_class.before_request proc { |params| params.merge(meta: "foo") }
      params = { data: { name: "foo" } }
      method = :foo_method
      random_id = SecureRandom.uuid

      allow(SecureRandom).to receive(:uuid) { random_id }
      allow(client).to receive(:publish)
      allow(client).to receive(:wait_for_result)

      result_params = { "data" => { "name" => "foo" }, "meta" => "foo" }
      expect(client).to receive(:publish).with(correlation_id: random_id, method: method, params: result_params)
      subject.remote_call(method, params)
    end
  end

  describe "#wait_for_result" do
    before :each do
      client_class.queue_name "lannister"
      client.start
      client.subscribe
    end

    it "raises an exception when timeout is reached and closes the channel" do
      allow(client.channel).to receive(:close)
      expect(client.channel).to receive(:close)

      # I don't feel like waiting for the default 5 seconds...do you?
      CarrotRpc.configuration.rpc_client_timeout = 0.1
      expect { client.wait_for_result("Bogus-123") }.to raise_error CarrotRpc::Exception::RpcClientTimeout
    end

    it "raises an exception when an exception is on the queue" do
      allow(client.channel).to receive(:close)

      # Synthesize the result from #parse_response going in to a queue.
      exception = StandardError.new("Bogus error")
      client.instance_variable_get(:@results)["Bogus-123"].push exception

      expect { client.wait_for_result("Bogus-123") }.to raise_error {|error|
        expect(error).to be_a(StandardError)
        expect(error.message).to eq("Bogus error")
      }
    end
  end

  describe "#subscribe" do
    # Methods

    def delete_queue
      channel = CarrotRpc.configuration.bunny.create_channel
      queue = channel.queue("foo")
      queue.delete
      channel.close
    end

    # lets

    let(:client) {
      client_class.new
    }

    let(:client_class) {
      Class.new(CarrotRpc::RpcClient) do
        queue_name "foo"
      end
    }

    let(:server) {
      server_class.new(block: false)
    }

    let(:server_class) {
      Class.new(CarrotRpc::RpcServer) do
        queue_name "foo"

        # Instance Methods

        def show(_params)
          {
            "foo-baz" => {
              "biz-baz" => {
                "super-duper" => "grovy"
              },
              "fizz-buzz" => "baz",
              "foo-bar" => "biz"
            }
          }
        end
      end
    }

    # Callbacks

    before(:each) do
      CarrotRpc.configuration.rpc_client_response_key_format = :underscore
      # Delete queue if another test did not clean up properly, such as due to interrupt
      delete_queue

      server.start
    end

    after(:each) do
      CarrotRpc.configuration.rpc_client_response_key_format = :none
      server.channel.close

      # Clean up properly
      delete_queue
    end

    context "with client started and configuration set to underscore results" do
      before(:each) do
        CarrotRpc.configuration.rpc_client_response_key_format = :underscore
      end

      after(:each) do
        CarrotRpc.configuration.rpc_client_response_key_format = :none
      end
      # lets

      let(:result) do
        {
          "foo_baz" => {
            "biz_baz" => {
              "super_duper" => "grovy"
            },
            "fizz_buzz" => "baz",
            "foo_bar" => "biz"
          }
        }
      end

      # Callbacks

      it "parses the payload from json to hash and changes '-' to '_' in the keys" do
        expect(client.show({})).to eq result
      end
    end
  end

  describe "#parse_response" do
    it "returns the result data" do
      response = {'jsonrpc': '2.0', 'result': {'foo': 'bar'}, 'id': 1}
      parsed_response = client.send(:parse_response,response)

      expect(parsed_response).to eq('foo': 'bar')
    end

    it "raises an exception for an invalid method error" do
      response = {'jsonrpc': '2.0', 'error': {'code': -32601, 'message': 'Method not found'}, 'id': 1}
      parsed_response = client.send(:parse_response,response)

      expect(parsed_response).to be_a(CarrotRpc::Error)
      expect(parsed_response.code).to eq(-32601)
      expect(parsed_response.message).to eq('Method not found')
    end

    it "raises an exception for a server error with data" do
      response = {'jsonrpc': '2.0', 'error': {'code': -32000, 'message': 'Application specific error', 'data': {'foo': 'bar is not allowed'}}, 'id': 1}
      parsed_response = client.send(:parse_response,response)

      expect(parsed_response).to be_a(CarrotRpc::Error)
      expect(parsed_response.code).to eq(-32000)
      expect(parsed_response.message).to eq('Application specific error')
      expect(parsed_response.data).to eq({'foo': 'bar is not allowed'})
    end

    it "raises an exception for a server error without data" do
      response = {'jsonrpc': '2.0', 'error': {'code': -32000, 'message': 'Application specific error'}, 'id': 1}
      parsed_response = client.send(:parse_response,response)

      expect(parsed_response).to be_a(CarrotRpc::Error)
      expect(parsed_response.code).to eq(-32000)
      expect(parsed_response.message).to eq('Application specific error')
      expect(parsed_response.data).to be_nil
    end

    it "raises an exception for an error with no code or message" do
      response = {'jsonrpc': '2.0', 'error': {}, 'id': 1}
      parsed_response = client.send(:parse_response,response)

      expect(parsed_response).to be_a(CarrotRpc::Exception::InvalidResponse)
    end
  end

  describe ".response_key_formatter" do
    before :each do
      CarrotRpc.configuration.rpc_client_response_key_format = :underscore
    end

    after :each do
      CarrotRpc.configuration.rpc_client_response_key_format = :none
    end

    let(:payload) { { foo: "bar" } }

    context "with a config passed in" do
      let(:config) do
        config = CarrotRpc::Configuration.new
        config.rpc_client_response_key_format = :dasherize
        config
      end

      subject { described_class.new(config) }

      it "overwrites the default config" do
        expect(CarrotRpc::Format).to receive(:keys).with(:dasherize, payload)
        subject.response_key_formatter(payload)
      end
    end

    context "without a config passed" do
      subject { described_class.new }
      it "uses the default config" do
        expect(CarrotRpc::Format).to receive(:keys).with(:underscore, payload)
        subject.response_key_formatter(payload)
      end
    end
  end

  describe ".request_key_formatter" do
    before :each do
      CarrotRpc.configuration.rpc_client_request_key_format = :underscore
    end

    after :each do
      CarrotRpc.configuration.rpc_client_request_key_format = :none
    end

    let(:payload) { { foo: "bar" } }

    context "with a config passed in" do
      let(:config) do
        config = CarrotRpc::Configuration.new
        config.rpc_client_request_key_format = :dasherize
        config
      end

      subject { described_class.new(config) }

      it "overwrites the default config" do
        expect(CarrotRpc::Format).to receive(:keys).with(:dasherize, payload)
        subject.request_key_formatter(payload)
      end
    end

    context "without a config passed" do
      subject { described_class.new }
      it "uses the default config" do
        expect(CarrotRpc::Format).to receive(:keys).with(:underscore, payload)
        subject.request_key_formatter(payload)
      end
    end
  end
end
