require 'test_helper'

module Support
  module Requests
    module Anonymous
      class ServiceFeedbackAggregatedMetricsTest < Test::Unit::TestCase
        def setup
          create_feedback(service_satisfaction_rating: 1, slug: "abcde", created_at: Date.new(2013,2,10))
          create_feedback(service_satisfaction_rating: 3, slug: "apply-carers-allowance", created_at: Date.new(2013,2,10))
          create_feedback(service_satisfaction_rating: 2, details: "abcde", slug: "apply-carers-allowance", created_at: Date.new(2013,2,10))
          @stats = ServiceFeedbackAggregatedMetrics.new(Date.new(2013,2,10), "apply-carers-allowance").to_h
        end

        def create_feedback(options)
          defaults = {
            slug: "a",
            javascript_enabled: true,
            is_actionable: true,
            service_satisfaction_rating: 3
          }
          f = ServiceFeedback.create!(defaults.merge(options))
          f.update_attribute(:created_at, options[:created_at])
        end

        context "metadata" do
          should "generate an id based on the slug and date" do
            assert_equal "20130210_apply-carers-allowance", @stats["_id"]
          end

          should "set the period to a day" do
            assert_equal "day", @stats["period"]
          end

          should "set the start time correctly" do
            assert_equal "2013-02-10T00:00:00+00:00", @stats["_timestamp"]
          end

          should "contain the slug" do
            assert_equal "apply-carers-allowance", @stats["slug"]
          end
        end

        context "aggregated metrics" do
          should "include rating summaries" do
            assert_equal 0, @stats["rating_1"]
            assert_equal 1, @stats["rating_2"]
            assert_equal 1, @stats["rating_3"]
            assert_equal 0, @stats["rating_4"]
            assert_equal 0, @stats["rating_5"]
            assert_equal 2, @stats["total"]
            assert_equal 1, @stats["comments"]
          end

          should "not include non-actionable comments, such as spam or dupes" do
            ServiceFeedback.delete_all

            create_feedback(
              is_actionable: false,
              reason_why_not_actionable: "abc",
              slug: "apply-carers-allowance",
              created_at: Date.new(2013,2,10)
            )
            stats = ServiceFeedbackAggregatedMetrics.new(Date.new(2013,2,10), "apply-carers-allowance").to_h

            assert_equal 0, stats["total"]
          end
        end
      end
    end
  end
end
