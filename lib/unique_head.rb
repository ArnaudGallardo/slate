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
  def table(header, body)
    # Get all columns
    columns = []
    header_html = Nokogiri::HTML::DocumentFragment.parse(header)
    header_html.css("th").each do |elem|
      columns.push(elem.text)
    end
    if columns[0] == "Parameter"
      # Convert to list
      list = ["<ul class=\"params-list\">"]
      desc_index = columns.find_index("Description")
      default_index = columns.find_index("Default")
      body_html = Nokogiri::HTML::DocumentFragment.parse(body)
      body_html.css("tr").each do |elem|
        elem_columns = elem.search('td')
        # Details
        details = []
        # Add default if necessary
        if !default_index.nil?
          details.push("default is #{elem_columns[default_index].text}")
        end
        content = "<li class=\"params-list-item\"><h4><span class=\"params-list-item-name\">#{elem_columns[0].text}</span>"
        if details.length > 0
          content += "<span class=\"params-list-item-detail\">#{details.join(', ')}</span>"
        end
        content += "</h4>"
        if !desc_index.nil?
          content += "<div>#{elem_columns[desc_index].text}</div>"
        end
        content += "</li>"
        list.push(content)
      end
      list.push("</ul>")
      return list.join('')
    elsif columns[0] == "Error Code"
      return "<table><thead>#{header}</thead><tbody>#{body}</tbody></table>"
    else
      return "<table><thead>#{header}</thead><tbody>#{body}</tbody></table>"
    end
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
    # On highlight divs
    html_doc.css(".tabs").each do |elem|
      parent = elem.parent
      previous = find_previous(parent)
      if !previous.nil?
        if previous.name != "blockquote" && (!has_class(previous, "highlight") || has_class(previous, "first-block"))
          # Add class to all tabs before another blockquote
          add_css_class(parent, ["first-block"])
        end
      end
    end
    html_doc.css(".tabs").reverse_each do |elem|
      parent = elem.parent
      next_node = find_next(parent)
      if !next_node.nil?
        if next_node.name != "blockquote" && (!has_class(next_node, "highlight") || has_class(next_node, "last-block"))
          # Add class to all tabs before another blockquote
          add_css_class(parent, ["last-block"])
        end
      end
    end
    # On blockquote
    html_doc.css("blockquote").each do |elem|
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
