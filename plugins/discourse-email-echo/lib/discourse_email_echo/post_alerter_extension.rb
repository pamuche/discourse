# frozen_string_literal: true

module DiscourseEmailEcho
  module PostAlerterExtension
    def not_allowed?(user, post)
      # If the user has email echo enabled, allow them to receive notifications
      # for their own posts (like mailing list echo functionality)
      return false if user&.user_option&.email_echo_enabled && user.id == post.user_id

      # Otherwise, use the default logic
      super
    end
  end
end
