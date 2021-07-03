# Unique header generation
require 'middleman-core/renderers/redcarpet'
require 'digest'
require 'nokogiri'
class UniqueHeadCounter < Middleman::Renderers::MiddlemanRedcarpetHTML
  def initialize
    super
    @head_count = {}
  end
  def header(text, header_level)
    friendly_text = text.gsub(/<[^>]*>/,"").parameterize
    if friendly_text.strip.length == 0
      # Looks like parameterize removed the whole thing! It removes many unicode
      # characters like Chinese and Russian. To get a unique URL, let's just
      # URI escape the whole header
      friendly_text = Digest::SHA1.hexdigest(text)[0,10]
    end
    @head_count[friendly_text] ||= 0
    @head_count[friendly_text] += 1
    if @head_count[friendly_text] > 1
      friendly_text += "-#{@head_count[friendly_text]}"
    end
    return "<h#{header_level} id='#{friendly_text}'>#{text}</h#{header_level}>"
  end
  def find_previous(elem)
    previous = elem.previous
    if !previous.nil?
      if previous.name == "text"
        return find_previous(previous)
      else
        return previous
      end
    end
    return previous # nil
  end
  def find_next(elem)
    nextnode = elem.next
    if !nextnode.nil?
      if nextnode.name == "text"
        return find_next(nextnode)
      else
        return nextnode
      end
    end
    return nextnode # nil
  end
  def has_class(elem, class_name)
    if elem['class'].nil?
      return false
    end
    classes = (elem['class'] || "").split(/\s+/)
    return classes.include? class_name
  end
  def add_css_class( elem, *classes )
    existing = (elem['class'] || "").split(/\s+/)
    elem['class'] = existing.concat(classes).uniq.join(" ")
  end
  def postprocess(document)
    print "postprocess\n"
    # Add first / last to examples
    html_doc = Nokogiri::HTML::DocumentFragment.parse(document)
    html_doc.css("blockquote, .highlight").each do |elem|
      previous = find_previous(elem)
      if !previous.nil?
        if previous.name != "blockquote" && !has_class(previous, "highlight")
          add_css_class(elem, ["first-block"])
        end
      end
      next_node = find_next(elem)
      if !next_node.nil?
        if next_node.name != "blockquote" && !has_class(next_node, "highlight")
          add_css_class(elem, ["last-block"])
        end
      end
    end
    return (html_doc.to_s)
  end
end
