# encoding: utf-8

# config/initializers/encryption.rb

module Encryption

  def self.name_for_locale(locale)
    I18n.backend.translate(locale, "i18n.language.name")
  rescue I18n::MissingTranslationData
    locale.to_s
  end

  def self.symmetric_encryption_class(algorithm)

  end

  def self.symmetric_encryption_algorithms
    [:AES256, :AES256IV]
  end

end

# E.g.:
#   I18n.name_for_locale(:en)  # => "English"
