require 'test_helper'
require 'active_model/tableless_model'
require 'support/requests/requester'
require 'support/requests/with_requester'
require 'zendesk_ticket'

class TestRequest < ActiveModel::TablelessModel
  include Support::Requests::WithRequester

  attr_accessor :a, :b
  validates_presence_of :a
end

class TestZendeskTicket < ZendeskTicket
  def subject
    "Test request"
  end

  def tags
    ["tag_a", "tag_b"]
  end

  def comment_snippets
    []
  end
end

class TestRequestsController < RequestsController
  def new_request
    TestRequest.new(requester: Support::Requests::Requester.new)
  end

  def zendesk_ticket_class
    TestZendeskTicket
  end

  def parse_request_from_params
    TestRequest.new(params[:test_request])
  end
end

def valid_params_for_test_request
  {
    "test_request" => {
      "a" => "A string", "b" => "Another string",
      "requester_attributes" => {"email" => "abc@d.com"}
    }
  }
end

class RequestsControllerTest < ActionController::TestCase
  setup do
    @logged_in_user_details = { name: "John Smith", email: "john.smith@gov.uk" }
    login_as_stub_user(@logged_in_user_details)

    self.valid_zendesk_credentials = ZENDESK_CREDENTIALS
    zendesk_has_no_user_with_email("john.smith@gov.uk")

    Rails.application.routes.draw do
      match 'new' => "test_requests#new"
      match 'create' => "test_requests#create"
      match "acknowledge" => "support#acknowledge"
    end

    @controller = TestRequestsController.new
    prevent_implicit_rendering
  end

  teardown do
    Rails.application.reload_routes!
  end

  context "a new request" do
    should "render the form" do
      @controller.expects(:default_render)
      get :new
    end

    should "be forbidden if the user has no permission to raise the request" do
      login_as_stub_user(has_permission?: false)
      @controller.expects(:render).with("support/forbidden", has_entry(status: 403))

      get :new
    end

    context "json requests" do
      should "be forbidden if the user has no permission to raise the request" do
        login_as_stub_user(has_permission?: false)
        @controller.expects(:render).with(json: {"errors" => "You have not been granted permission to create these requests."}, status: 403)

        get :new, format: :json
      end
    end
  end

  def prevent_implicit_rendering
    # we're not testing view rendering here,
    # so prevent rendering by stubbing out default_render
    @controller.stubs(:default_render)
  end

  context "a submission of a test request" do
    should "reject invalid parameters" do
      params = valid_params_for_test_request.tap {|p| p["test_request"].merge!("a" => "")}

      @controller.expects(:render).with(:new, has_entry(status: 400))

      post :create, params
    end

    should "be forbidden if the user has no permission to raise the request" do
      login_as_stub_user(has_permission?: false)
      @controller.expects(:render).with("support/forbidden", has_entry(status: 403))

      post :create, valid_params_for_test_request
    end

    should "submit it to Zendesk" do
      stub_ticket_creation = stub_zendesk_ticket_creation(hash_including(tags: ['tag_a', 'tag_b']))

      params = valid_params_for_test_request

      post :create, params

      assert_redirected_to "/acknowledge"
      assert_requested stub_ticket_creation
    end

    should "read the signed-in user's details as the requester" do
      requester_details = { email: @logged_in_user_details[:email], name: @logged_in_user_details[:name] }
      stub_zendesk_ticket_creation(hash_including(requester: hash_including(requester_details)))

      post :create, valid_params_for_test_request
    end

    should "set collaborators if they're set on the request" do
      params = valid_params_for_test_request.tap do |p|
        p["test_request"]["requester_attributes"].merge!("collaborator_emails" => "ab@c.com, def@g.com")
      end
      stub_zendesk_ticket_creation(hash_including(collaborators: ["ab@c.com", "def@g.com"]))

      post :create, params
    end
  end
end
