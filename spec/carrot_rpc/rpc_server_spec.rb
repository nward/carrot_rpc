require "spec_helper"
require "carrot_rpc"

RSpec.describe CarrotRpc::RpcServer do
  # Methods

  def delete_queue
    channel = CarrotRpc.configuration.bunny.create_channel
    queue = channel.queue("foo")
    queue.delete
    channel.close
  end

  describe "#process_request" do
    subject(:process_request) {
      rpc_server.process_request(request_message, properties: properties)
    }

    let(:rpc_server) {
      rpc_server_class.new
    }

    let(:rpc_server_class) {
      Class.new(CarrotRpc::RpcServer) do
        queue_name "foo"
      end
    }

    context "with unsupported method" do
      #
      # lets
      #

      let(:properties) {
        {}
      }

      let(:request_message) {
        {
          method: "unknown_method"
        }
      }

      #
      # Callbacks
      #

      before(:each) do
        # Delete queue if another test did not clean up properly, such as due to interrupt
        delete_queue
      end

      after(:each) do
        rpc_server.channel.close

        # Clean up properly
        delete_queue
      end

      it "replies method not found" do
        expect(rpc_server).to receive(:reply).with(
          hash_including(
            properties: properties,
            response_message: hash_including(
              error: {
                code: -32_601,
                message: "Method not found",
                data: {
                  method: request_message.fetch(:method)
                }
              }
            )
          )
        )

        process_request
      end
    end
  end

  describe ".queue_name" do
    let(:server_class) {
      Class.new(CarrotRpc::RpcServer)
    }

    let(:server) {
      server_class.new(block: false)
    }

    it "is readable by queue_name/0" do
      server_class.queue_name "foo"
      expect(server_class.queue_name).to eq "foo"
    end

    context "with server_test_mode set" do
      before :each do
        CarrotRpc.configuration.server_test_mode = true
      end

      after :each do
        CarrotRpc.configuration.server_test_mode = false
      end

      it "appends _test to queue name" do
        server_class.queue_name "foo"
        expect(server.server_queue.name).to eq "foo_test"
      end

      it "fails when queue name is not set" do
        server_class.queue_name nil
        expect { server }.to raise_error CarrotRpc::Exception::InvalidQueueName
      end
    end
  end

  describe ".queue_options" do
    let(:server_class) {
      Class.new(CarrotRpc::RpcServer)
    }

    let(:server) {
      server_class.new(block: false)
    }

    it "is readable by queue_options/0" do
      server_class.queue_options durable: true
      expect(server_class.queue_options).to eq(durable: true)
    end

    it "does returns empty hash as default" do
      expect(server_class.queue_options).to eq({})
    end
  end

  describe "#start" do
    # lets

    let(:client_class) {
      Class.new(CarrotRpc::RpcClient) do
        queue_name "foo"
      end
    }

    let(:client) do
      client_class.new
    end

    let(:server_class) {
      Class.new(CarrotRpc::RpcServer) do
        queue_name "foo"

        # Instance Methods

        def create(params)
          params
        end
      end
    }

    let(:server) {
      server_class.new(block: false)
    }

    # Callbacks

    before(:each) do
      # Delete queue if another test did not clean up properly, such as due to interrupt
      delete_queue
    end

    after(:each) do
      server.channel.close

      # Clean up properly
      delete_queue
    end

    context "with server started" do
      # lets

      let(:payload) do
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

      context "with client configured to underscore keys" do
        before(:each) do
          server.start
          CarrotRpc.configuration.rpc_client_response_key_format = :underscore
        end

        after(:each) do
          CarrotRpc.configuration.rpc_client_response_key_format = :none
        end

        it "parses the payload from json to hash and changes '-' to '_' in the keys" do
          expect(client.create(payload)).to eq result
        end
      end
    end
  end
end
