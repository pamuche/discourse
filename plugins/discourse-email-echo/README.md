# Discourse Email Echo Plugin

This plugin restores the "email echo" functionality that was present in earlier releases of Discourse. This feature works like mailing list echo functionality, where users receive email notifications for their own posts and topics.

## Features

- Adds a user preference checkbox in Email settings
- When enabled, users receive email notifications for their own posts and topics
- Works like traditional mailing list echo functionality
- Can be disabled individually by each user

## Installation

This plugin is included in Discourse. It can be enabled via Admin Settings.

## Usage

1. Administrator enables the plugin in Admin → Settings → Plugins
2. Users can enable/disable email echo in their User Preferences → Email settings
3. When enabled, users will receive email notifications for their own posts, just like in mailing lists

## Configuration

Site Setting: `email_echo_enabled` - Enables the email echo functionality site-wide (default: true)

User Setting: Email echo checkbox in user preferences (default: false)
