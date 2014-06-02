require 'sidekiq'

class SupportController < AuthorisationController
  include Support::Navigation

  skip_authorization_check
  skip_before_filter :authenticate_support_user!, only: [:queue_status]

  def landing
    @sections =
      (SectionGroups.new(current_user).all_sections + [ FeedexSection.new(current_user) ]).
      select(&:accessible?)
  end

  def acknowledge
    respond_to do |format|
      format.html { render :acknowledge }
      format.json { render nothing: true }
    end
  end

  def queue_status
    status = { queues: {} }

    Sidekiq::Stats.new.queues.each do |queue_name, queue_size|
      status[:queues][queue_name] = {"jobs" => queue_size}
    end

    respond_to do |format|
      format.json do
        render json: status
      end
      format.any do
        render nothing: true, status: 406
      end
    end
  end
end
