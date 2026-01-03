# frozen_string_literal: true

module DiscourseEmailEcho
  module UserOptionExtension
    extend ActiveSupport::Concern

    # No need to add additional logic here - the boolean field
    # will be automatically accessible via ActiveRecord
  end
end
