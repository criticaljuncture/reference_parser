class ReferenceParser::Email < ReferenceParser::Base
  AUTO_EMAIL_LOCAL_RE = /[\w.!#\$%&'*\/=?^`{|}~+-]/  
  replace /(?<email>(?<!#{AUTO_EMAIL_LOCAL_RE})[\w.!#\$%+-]\.?#{AUTO_EMAIL_LOCAL_RE}*@[\w-]+(?:\.[\w-]+)+)/

  def link_to(text, citation, options={})
    content_tag(:a, citation[:email], {href: "mailto:#{citation[:email]}", class: "email"})
  end
end
