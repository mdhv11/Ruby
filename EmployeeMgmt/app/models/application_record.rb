class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
  self.implicit_order_column = :created_at

  class << self
    def normalize_enum_attributes(*attributes)
      before_validation do
        attributes.each do |attribute|
          value = public_send(attribute)
          next if value.nil?

          normalized = value.to_s.strip.downcase
          normalized = normalized.tr("-", "_").tr(" ", "_")
          normalized = normalized.gsub(/__+/, "_")

          public_send("#{attribute}=", normalized)
        end
      end
    end
  end
end
