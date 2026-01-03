# frozen_string_literal: true

# name: discourse-email-echo
# about: Adds email echo functionality - sends email notifications to post/topic creators (like mailing lists)
# version: 1.0.0
# authors: Discourse Community
# url: https://github.com/discourse/discourse/tree/main/plugins/discourse-email-echo

enabled_site_setting :email_echo_enabled

after_initialize do
  UserUpdater::OPTION_ATTR.push(:email_echo_enabled)

  reloadable_patch do |plugin|
    UserOption.prepend(DiscourseEmailEcho::UserOptionExtension)
    PostAlerter.prepend(DiscourseEmailEcho::PostAlerterExtension)
  end

  add_to_serializer(:user_option, :email_echo_enabled) do
    object.email_echo_enabled
  end

  add_to_serializer(:current_user_option, :email_echo_enabled) do
    object.email_echo_enabled
  end
end

require_relative "lib/discourse_email_echo/user_option_extension"
require_relative "lib/discourse_email_echo/post_alerter_extension"
