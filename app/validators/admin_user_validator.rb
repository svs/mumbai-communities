class AdminUserValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil? # allow_nil: true handles this case

    unless value.respond_to?(:admin?) && value.admin?
      record.errors.add(attribute, options[:message] || "must be an admin user")
    end
  end
end