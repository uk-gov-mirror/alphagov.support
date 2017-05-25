module Support
  module Requests
    class TechnicalFaultReport < Request
      attr_accessor :fault_context, :fault_specifics, :actions_leading_to_problem, :what_happened, :what_should_have_happened

      validates_presence_of :fault_context, :fault_specifics, :actions_leading_to_problem, :what_happened, :what_should_have_happened
      validate do |report|
        if report.fault_context and not report.fault_context.valid?
          errors[:base] << "The source of the fault is not set."
        end
      end

      def initialize(opts = {})
        super
        self.fault_context ||= Support::GDS::UserFacingComponent.new
      end

      def fault_context_attributes=(attr)
        self.fault_context = Support::GDS::UserFacingComponents.find(attr)
      end

      def fault_context_options
        Support::GDS::UserFacingComponents.all
      end

      def inside_government_related?
        fault_context and fault_context.inside_government_related?
      end

      def self.label
        "Report a technical fault to GDS"
      end

      def self.description
        "Report something that is not working with any publishing application, eg Whitehall, finders or specialist publisher. Also use for any urgent technical changes"
      end
    end
  end
end
