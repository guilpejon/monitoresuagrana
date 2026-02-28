module IconHelper
  ICONS = {
    "home" => '<path d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>',
    "utensils" => '<path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6m0 0v6m0-6h6m-6 0H6"/><circle cx="9" cy="9" r="2"/><circle cx="15" cy="15" r="2"/>',
    "car" => '<rect x="1" y="3" width="15" height="13"/><path d="M16 8h4m-4-2 4 2-4 2M2 7h8"/><circle cx="5.5" cy="16.5" r="1.5"/><circle cx="14.5" cy="16.5" r="1.5"/>',
    "heart-pulse" => '<path d="M22 12h-4l-3 9L9 3l-3 9H2"/>',
    "gamepad-2" => '<line x1="6" x2="10" y1="12" y2="12"/><line x1="8" x2="8" y1="10" y2="14"/><line x1="15" x2="15.01" y1="13" y2="13"/><line x1="18" x2="18.01" y1="11" y2="11"/><rect width="20" height="12" x="2" y="6" rx="2"/>',
    "shopping-cart" => '<circle cx="8" cy="21" r="1"/><circle cx="19" cy="21" r="1"/><path d="M2.05 2.05h2l2.66 12.42a2 2 0 0 0 2 1.58h9.78a2 2 0 0 0 1.95-1.57l1.65-7.43H5.12"/>',
    "book-open" => '<path d="M2 3h6a4 4 0 0 1 4 4v14a3 3 0 0 0-3-3H2z"/><path d="M22 3h-6a4 4 0 0 0-4 4v14a3 3 0 0 1 3-3h7z"/>',
    "zap" => '<polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>',
    "plane" => '<path d="M17.8 19.2 16 11l3.5-3.5C21 6 21 4 19 4c-2 0-4 2-4 2L8.8 7.2l-1.4-5.9L3 3l2.8 6.2L2 12l6 2 2 6 3.2-4.4L20 18l-2.2 1.2zM5 3l1.5 6.3L4 12"/>',
    "circle-dollar-sign" => '<circle cx="12" cy="12" r="10"/><path d="M12 6v12m3-9H9a2 2 0 0 0 0 4h6a2 2 0 0 1 0 4H9"/>',
    "bar-chart-2" => '<line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/>',
    "credit-card" => '<rect width="22" height="16" x="1" y="4" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/>',
    "trending-up" => '<polyline points="23 6 13.5 15.5 8.5 10.5 1 18"/><polyline points="17 6 23 6 23 12"/>',
    "calendar" => '<rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/>',
    "tag" => '<path d="M20.59 13.41l-7.17 7.17a2 2 0 01-2.83 0L2 12V2h10l8.59 8.59a2 2 0 010 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/>',
    "plus" => '<line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>',
    "x" => '<line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>',
    "chevron-left" => '<polyline points="15 18 9 12 15 6"/>',
    "chevron-right" => '<polyline points="9 18 15 12 9 6"/>',
    "chevron-down" => '<polyline points="6 9 12 15 18 9"/>',
    "edit" => '<path d="M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z"/>',
    "trash-2" => '<polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 01-2 2H7a2 2 0 01-2-2V6m3 0V4a1 1 0 011-1h4a1 1 0 011 1v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/>',
    "refresh-cw" => '<polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0114.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0020.49 15"/>',
    "log-out" => '<path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>',
    "user" => '<path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/>',
    "arrow-up" => '<line x1="12" y1="19" x2="12" y2="5"/><polyline points="5 12 12 5 19 12"/>',
    "arrow-down" => '<line x1="12" y1="5" x2="12" y2="19"/><polyline points="19 12 12 19 5 12"/>',
    "filter" => '<polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/>',
    "search" => '<circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/>',
    "menu" => '<line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="18" x2="21" y2="18"/>',
    "wallet" => '<path d="M20 12V22H4a2 2 0 01-2-2V6a2 2 0 012-2h16v4"/><path d="M20 12a2 2 0 000 4h4v-4z"/>',
    "clock" => '<circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>',
    "repeat" => '<polyline points="17 1 21 5 17 9"/><path d="M3 11V9a4 4 0 014-4h14"/><polyline points="7 23 3 19 7 15"/><path d="M21 13v2a4 4 0 01-4 4H3"/>'
  }.freeze

  def svg_icon(name, css_class: "w-5 h-5", stroke: "currentColor", fill: "none")
    path_data = ICONS[name.to_s] || ICONS["circle-dollar-sign"]
    content = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" class="#{css_class}" fill="#{fill}" viewBox="0 0 24 24" stroke="#{stroke}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        #{path_data}
      </svg>
    SVG
    content.html_safe
  end
end
