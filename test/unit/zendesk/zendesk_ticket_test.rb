require 'test/unit'
require 'shoulda/context'
require 'zendesk_ticket'
require 'test_data'
require 'ostruct'
require 'date'

class ZendeskTicketTest < Test::Unit::TestCase
  def new_ticket(attributes, type = nil)
    ZendeskTicket.new(OpenStruct.new(attributes), type)
  end

  include TestData
  context "content change request" do
    should "set the requester details correctly" do
      ticket = new_ticket(
        :name => "John Smith",
        :email => "ab@c.com",
        :organisation => "cabinet_office",
        :job => "Developer",
        :phone => "123456"
      )
      assert_equal "John Smith", ticket.name
      assert_equal "ab@c.com", ticket.email
      assert_equal "cabinet_office", ticket.organisation
      assert_equal "Developer", ticket.job
      assert_equal "123456", ticket.phone
    end

    context "with time constraints" do
      should "pass the need_by_date through" do
        time_constraint = OpenStruct.new(needed_by_date: "03-02-2001")
        assert_equal "03-02-2001", new_ticket(time_constraint: time_constraint).needed_by_date
      end

      should "pass the not_before_date through" do
        time_constraint = OpenStruct.new(not_before_date: "03-02-2001")
        assert_equal "03-02-2001", new_ticket(time_constraint: time_constraint).not_before_date
      end
    end

    should "remove spaces from the tel number" do
      assert_equal "12345678", new_ticket(:phone => "1234 5678").phone
    end
  end
end