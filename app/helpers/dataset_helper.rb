module DatasetHelper
  def smart_compare_then_print_diff processed, _raw
    raw = _raw.gsub(/[^\w\s\d]+/, '').gsub(/\s+/, ' ').strip

    haml_concat processed
    if raw != processed
      haml_tag :br
      haml_tag :span, class: 'replaced' do
        haml_concat raw
      end
    end

  end
end
