# Creating discourse-email-echo as a Standalone Plugin

This guide explains how to set up the discourse-email-echo plugin as a standalone repository that can be installed like any other Discourse plugin.

## Step 1: Create a New Repository

Create a new repository (e.g., on GitHub) named `discourse-email-echo`.

## Step 2: Initialize the Repository Structure

```bash
mkdir discourse-email-echo
cd discourse-email-echo
git init
```

## Step 3: Create the Plugin Files

Create the following directory structure and files:

### Directory Structure
```
discourse-email-echo/
├── plugin.rb
├── README.md
├── INSTALLATION.md
├── LICENSE (optional)
├── config/
│   ├── settings.yml
│   └── locales/
│       ├── client.en.yml
│       └── server.en.yml
├── db/
│   └── migrate/
│       └── 20260103235132_add_email_echo_enabled_user_option.rb
├── lib/
│   └── discourse_email_echo/
│       ├── post_alerter_extension.rb
│       └── user_option_extension.rb
├── assets/
│   └── javascripts/
│       └── discourse/
│           └── connectors/
│               └── user-preferences-emails-pref-email-settings/
│                   └── preferences-email-echo.gjs
└── spec/
    └── plugin_spec.rb
```

### File Contents

#### `plugin.rb`
```ruby
# frozen_string_literal: true

# name: discourse-email-echo
# about: Adds email echo functionality - sends email notifications to post/topic creators (like mailing lists)
# version: 1.0.0
# authors: Discourse Community
# url: https://github.com/YOUR_USERNAME/discourse-email-echo

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
```

#### `config/settings.yml`
```yaml
plugins:
  email_echo_enabled:
    default: true
    client: true
```

#### `config/locales/client.en.yml`
```yaml
en:
  site_settings:
    email_echo_enabled: "Enable email echo functionality (mailing list mode for own posts)"
  
  js:
    user:
      email_echo_enabled: "Receive email notifications for my own posts and topics (mailing list echo)"
```

#### `config/locales/server.en.yml`
```yaml
en:
  site_settings:
    email_echo_enabled: "Enable email echo functionality (mailing list mode for own posts)"
```

#### `db/migrate/20260103235132_add_email_echo_enabled_user_option.rb`
```ruby
# frozen_string_literal: true
class AddEmailEchoEnabledUserOption < ActiveRecord::Migration[7.2]
  def change
    add_column :user_options, :email_echo_enabled, :boolean, null: false, default: false
  end
end
```

#### `lib/discourse_email_echo/user_option_extension.rb`
```ruby
# frozen_string_literal: true

module DiscourseEmailEcho
  module UserOptionExtension
    extend ActiveSupport::Concern

    # No need to add additional logic here - the boolean field
    # will be automatically accessible via ActiveRecord
  end
end
```

#### `lib/discourse_email_echo/post_alerter_extension.rb`
```ruby
# frozen_string_literal: true

module DiscourseEmailEcho
  module PostAlerterExtension
    def not_allowed?(user, post)
      # If the user has email echo enabled, allow them to receive notifications
      # for their own posts (like mailing list echo functionality)
      # But never allow bots to receive notifications
      return false if user&.user_option&.email_echo_enabled && user.id == post.user_id && !user.bot?

      # Otherwise, use the default logic
      super
    end
  end
end
```

#### `assets/javascripts/discourse/connectors/user-preferences-emails-pref-email-settings/preferences-email-echo.gjs`
```javascript
import PreferenceCheckbox from "discourse/components/preference-checkbox";

const PreferencesEmailEcho = <template>
  <PreferenceCheckbox
    @labelKey="user.email_echo_enabled"
    @checked={{@outletArgs.model.user_option.email_echo_enabled}}
    data-setting-name="email-echo-enabled"
    class="pref-email-echo"
  />
</template>;

export default PreferencesEmailEcho;
```

#### `spec/plugin_spec.rb`
```ruby
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
          allow(user).to receive(:bot?).and_return(true)
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
```

#### `README.md`
```markdown
# Discourse Email Echo Plugin

This plugin restores the "email echo" functionality that was present in earlier releases of Discourse. This feature works like mailing list echo functionality, where users receive email notifications for their own posts and topics.

## Features

- Adds a user preference checkbox in Email settings
- When enabled, users receive email notifications for their own posts and topics
- Works like traditional mailing list echo functionality
- Can be disabled individually by each user

## Installation

Add this line to your `app.yml` file in the plugins section:

\`\`\`yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/YOUR_USERNAME/discourse-email-echo.git
\`\`\`

Then rebuild your container:

\`\`\`bash
./launcher rebuild app
\`\`\`

## Usage

1. Administrator enables the plugin in Admin → Settings → Plugins
2. Users can enable/disable email echo in their User Preferences → Email settings
3. When enabled, users will receive email notifications for their own posts, just like in mailing lists

## Configuration

**Site Setting:** `email_echo_enabled` - Enables the email echo functionality site-wide (default: true)

**User Setting:** Email echo checkbox in user preferences (default: false)

## License

MIT License (or your chosen license)
```

#### `INSTALLATION.md`
Create a detailed installation guide similar to the one previously created.

## Step 4: Commit and Push

```bash
git add .
git commit -m "Initial commit: Email echo plugin"
git remote add origin https://github.com/YOUR_USERNAME/discourse-email-echo.git
git push -u origin main
```

## Step 5: Install in Your Discourse Instance

### Option 1: Using app.yml (Recommended for Docker installations)

Edit your `app.yml` file and add the plugin:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/YOUR_USERNAME/discourse-email-echo.git
```

Then rebuild:

```bash
./launcher rebuild app
```

### Option 2: Manual Installation (Development)

```bash
cd /var/www/discourse/plugins
git clone https://github.com/YOUR_USERNAME/discourse-email-echo.git
cd ..
bundle install
rake db:migrate
```

## Testing

Run the plugin tests:

```bash
bundle exec rspec plugins/discourse-email-echo/spec
```

## Repository URL

Update the `url` field in `plugin.rb` to point to your actual repository URL.

## Notes

- The migration timestamp `20260103235132` should be unique. If you encounter conflicts, you can change it to the current timestamp.
- Make sure to replace `YOUR_USERNAME` with your actual GitHub username in all URLs.
- Consider adding a LICENSE file to your repository.
