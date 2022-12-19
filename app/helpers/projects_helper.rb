module ProjectsHelper
  def estimated(story)
    @estimate_id = story.estimate_for(current_user)
    @estimate_id.present?
  end

  private

  def text_content(icon, text)
    return text if icon.nil?

    content_tag(:i, "", class: "fa fa-#{icon}").concat(content_tag(:span, text))
  end
end
