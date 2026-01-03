# Email Echo Plugin - Installation & Usage Guide

## Overview
The discourse-email-echo plugin restores email echo functionality that existed in earlier versions of Discourse. This feature allows users to receive email notifications for their own posts and topics, similar to traditional mailing list behavior.

## How It Works

### Core Functionality
1. **PostAlerter Extension**: Overrides the `not_allowed?` method in PostAlerter to permit notifications to post creators when they have email echo enabled
2. **User Option**: Adds a boolean field `email_echo_enabled` to the user_options table
3. **User Interface**: Adds a checkbox in User Preferences → Email settings

### File Structure
```
plugins/discourse-email-echo/
├── plugin.rb                           # Main plugin file
├── README.md                           # Documentation
├── config/
│   ├── settings.yml                    # Site-level settings
│   └── locales/
│       ├── client.en.yml              # Client-side translations
│       └── server.en.yml              # Server-side translations
├── db/
│   └── migrate/
│       └── 20260103235132_add_email_echo_enabled_user_option.rb
├── lib/
│   └── discourse_email_echo/
│       ├── post_alerter_extension.rb  # Core logic
│       └── user_option_extension.rb   # User option model extension
├── assets/
│   └── javascripts/
│       └── discourse/
│           └── connectors/
│               └── user-preferences-emails-pref-email-settings/
│                   └── preferences-email-echo.gjs
└── spec/
    └── plugin_spec.rb                 # Test suite
```

## Installation

The plugin is now part of the Discourse repository. After pulling these changes:

1. **Run database migrations**:
   ```bash
   rake db:migrate
   ```

2. **Restart your Discourse instance**:
   ```bash
   # For development
   bin/rails s

   # For production
   systemctl restart discourse
   ```

3. **Enable the plugin** (if needed):
   - Go to Admin → Settings → Plugins
   - Find "email_echo_enabled"
   - Ensure it's set to true (default is true)

## Usage

### For Users
1. Navigate to User Menu → Preferences
2. Go to the "Email" tab
3. Find the checkbox: "Receive email notifications for my own posts and topics (mailing list echo)"
4. Check the box to enable email echo
5. Click "Save Changes"

### For Administrators
- **Site Setting**: `email_echo_enabled` (default: true)
  - Set to false to disable the feature site-wide
  - Located in Admin → Settings → Plugins

## Technical Details

### Database Schema
- **Table**: `user_options`
- **Column**: `email_echo_enabled` (boolean, default: false)

### API Integration
The `email_echo_enabled` field is exposed via:
- `UserOptionSerializer`
- `CurrentUserOptionSerializer`

This allows frontend applications and API clients to read and update the setting.

### Notification Behavior
When a user has `email_echo_enabled = true`:
- They receive notifications for their own posts (mentions, replies, etc.)
- This mimics traditional mailing list behavior where you receive copies of your own messages
- Useful for keeping a complete email thread/archive

When a user has `email_echo_enabled = false` (default):
- Standard Discourse behavior: users don't receive notifications for their own posts

### Security Considerations
- Bots (user_id < 0) are never allowed notifications, even with email echo enabled
- The feature respects all existing notification permissions and privacy settings
- Each user controls their own echo setting - it's not admin-controlled per user

## Testing

Run the test suite:
```bash
bin/rspec plugins/discourse-email-echo/spec/plugin_spec.rb
```

Tests cover:
- PostAlerter extension logic
- Serializer integration
- User option updates via UserUpdater
- Default values for new users
- Integration with notification system

## Troubleshooting

### Email echo not working?
1. Verify the site setting is enabled: Admin → Settings → search "email_echo_enabled"
2. Check user preference: User → Preferences → Email tab
3. Ensure email level settings allow notifications (not set to "never")
4. Check that mailing list mode is not interfering

### Checkbox not appearing?
1. Clear browser cache
2. Restart Discourse server
3. Check browser console for JavaScript errors
4. Verify plugin is loaded: Admin → Plugins → look for "discourse-email-echo"

## Migration Notes

For users upgrading from older Discourse versions that had this feature:
- The default is `false` for existing users
- Users must manually enable the feature in their preferences
- No automatic migration of old settings occurs

## Future Enhancements

Potential improvements:
- Admin option to set default value for new users
- Bulk enable/disable for specific user groups
- Integration with mailing list mode settings
- Additional UI explanations/help text

## Support

For issues or questions:
- Check the README.md in the plugin directory
- Review the test suite for usage examples
- Submit issues to the Discourse repository
