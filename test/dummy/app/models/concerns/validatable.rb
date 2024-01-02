module Validatable
  extend ActiveSupport::Concern

  private

  def title_is_quo_vadis?
    return false if self.title.blank?

    self.title == "Quo vadis"
  end

  def title_is_american_psycho?
    return false if self.title.blank?

    self.title == "American Psycho"
  end
end
