# frozen_string_literal: true

RSpec.describe "DiscourseEmailEcho" do
  before { SiteSetting.email_echo_enabled = true }

  fab!(:user) { Fabricate(:user) }
  fab!(:other_user) { Fabricate(:user) }

  describe "PostAlerterExtension" do
    describe "#not_allowed?" do
      let(:post_alerter) { PostAlerter.new }
      fab!(:topic) { Fabricate(:topic, user: user) }
      fab!(:post) { Fabricate(:post, topic: topic, user: user) }

      context "when email echo is disabled for user" do
        before { user.user_option.update!(email_echo_enabled: false) }

        it "prevents user from receiving notifications for their own posts" do
          expect(post_alerter.not_allowed?(user, post)).to eq(true)
        end
      end

      context "when email echo is enabled for user" do
        before { user.user_option.update!(email_echo_enabled: true) }

        it "allows user to receive notifications for their own posts" do
          expect(post_alerter.not_allowed?(user, post)).to eq(false)
        end
      end

      context "when user is not the post creator" do
        it "follows normal notification rules" do
          expect(post_alerter.not_allowed?(other_user, post)).to eq(false)
        end
      end

      context "when user is a bot" do
        before do
          user.update!(id: -1)
          user.user_option.update!(email_echo_enabled: true)
        end

        it "prevents bot from receiving notifications even with email echo enabled" do
          expect(post_alerter.not_allowed?(user, post)).to eq(true)
        end
      end
    end
  end

  describe "serializer extensions" do
    it "includes email_echo_enabled in user_option serializer" do
      user.user_option.update!(email_echo_enabled: true)
      serializer = UserOptionSerializer.new(user.user_option, scope: Guardian.new, root: false)
      json = serializer.as_json

      expect(json[:email_echo_enabled]).to eq(true)
    end

    it "includes email_echo_enabled in current_user_option serializer" do
      user.user_option.update!(email_echo_enabled: false)
      serializer =
        CurrentUserOptionSerializer.new(user.user_option, scope: Guardian.new, root: false)
      json = serializer.as_json

      expect(json[:email_echo_enabled]).to eq(false)
    end
  end

  describe "user option update" do
    it "allows updating email_echo_enabled via UserUpdater" do
      result =
        UserUpdater.new(user, user).update(email_echo_enabled: "true")

      expect(result).to eq(true)
      expect(user.user_option.reload.email_echo_enabled).to eq(true)
    end
  end

  describe "default value" do
    it "defaults to false for new users" do
      new_user = Fabricate(:user)
      expect(new_user.user_option.email_echo_enabled).to eq(false)
    end
  end

  describe "integration with notifications" do
    fab!(:topic) { Fabricate(:topic, user: user) }

    context "when creating a post" do
      before { user.user_option.update!(email_echo_enabled: true) }

      it "user can receive notifications for posts they create when mentioned" do
        post = Fabricate(:post, topic: topic, user: user, raw: "Hello @#{user.username}")
        PostAlerter.post_created(post)

        # The user should be able to receive a mention notification for their own post
        # because email_echo_enabled is true
        notifications =
          Notification.where(
            user_id: user.id,
            notification_type: Notification.types[:mentioned],
            topic_id: topic.id,
          )

        expect(notifications.count).to eq(1)
      end
    end

    context "when email echo is disabled" do
      before { user.user_option.update!(email_echo_enabled: false) }

      it "user does not receive notifications for posts they create" do
        post = Fabricate(:post, topic: topic, user: user, raw: "Hello @#{user.username}")
        PostAlerter.post_created(post)

        # The user should not receive a mention notification for their own post
        # because email_echo_enabled is false
        notifications =
          Notification.where(
            user_id: user.id,
            notification_type: Notification.types[:mentioned],
            topic_id: topic.id,
          )

        expect(notifications.count).to eq(0)
      end
    end
  end
end
