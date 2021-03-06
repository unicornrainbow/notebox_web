require 'yaml'

class Notebox::Box

  def initialize(path)
    @path = path
  end

  def fetch_entries(args={})
    topic = args[:topic]
    date = args[:date]

    # TODO: Watch out for use passing in a relative path that can get out of
    # the directory. I'll have to look into this more.
    root_path = topic ? "#{@path}/#{topic}/entries/" : "#{@path}/entries/"

    today_path = "#{root_path}/#{date.strftime("%Y/%m/%d")}"
    todays_entries = Dir["#{today_path}/*.txt"]

    entries = todays_entries.map { |full_path|
      path, ext = full_path.match(/#{root_path}(.*)\.(txt)$/).try(:captures)
      created_at = parse_created_at("#{path}.#{ext}")

      markdown = File.read(full_path)

      attributes, markdown = extract_attributes(markdown)

      render_checkboxes!(markdown)
      markdown.gsub!(/notebox:\/\/(\S*)/, 'http://localhost:3000/\1')

      html = $markdown.render(markdown)

      # Add lightbox data
      doc = Nokogiri::HTML(html)
      doc.css('img').each do |image|
        image.swap "<a href=\"#{image.attribute("src")}\" class=\"image-link\">#{image}</a>"
      end
      html = doc.to_html

      attributes.merge!(
        path: topic ? "/#{topic}/entries#{path}" : "/entries#{path}",
        markdown: markdown,
        html: html,
        created_at: created_at,
        formatted_date: created_at.strftime('%A, %B %e %Y'),
        formatted_time: created_at.strftime('%I:%M %p'),
        formatted_date_time: created_at.strftime('%A, %B %e, %Y, %l:%M %p'),
      )

      OpenStruct.new(attributes)
    }
    entries.reverse!
    entries
  end

  def search(keyword, options={})
    sanitize_command!(keyword)
    grep_results = `cd "#{@path}" && git grep -i "#{keyword}"`
    grep_results = grep_results.split("\n")

    file_paths = grep_results.map { |r| r.match(/^(.*\.txt):(.*)/).try(:captures).try(:first) }
    file_paths.uniq!

    @results = file_paths.map do |file_path|
      full_path = "#{NOTES_ROOT}/#{file_path}"
      path, ext = file_path.match(/(.*)\.(txt)$/).try(:captures)
      topic = path.match(/\/(.*)\/?entries/).try(:captures).try(:first)

      created_at = parse_created_at("#{path}.#{ext}")

      markdown = File.read(full_path)

      render_checkboxes!(markdown)
      markdown.gsub!(/notebox:\/\/(\S*)/, 'http://localhost:3000/\1')

      html = $markdown.render(markdown)

      # Add lightbox data
      doc = Nokogiri::HTML(html)
      doc.css('img').each do |image|
        image.swap "<a href=\"#{image.attribute("src")}\" class=\"image-link\">#{image}</a>"
      end

      doc.xpath('//text()').each do |el|
        el.swap el.content.gsub(/(#{keyword})/i, '<span class="highlight">\1</span>')
      end

      html = doc.to_html

      attributes = {
        path: topic ? "/#{topic}#{path}" : path,
        markdown: markdown,
        html: html,
        created_at: created_at,
        formatted_date: created_at.strftime('%A, %B %e %Y'),
        formatted_time: created_at.strftime('%I:%M %p'),
        formatted_date_time: created_at.strftime('%A, %B %e, %Y, %l:%M %p')
      }
      OpenStruct.new(attributes)
    end

    @results = @results.sort_by(&:created_at)

    page = options[:page] || 1
    page_size = options[:page_size] || 20
    @results.reverse.take(page*page_size)
  end

private

  def sanitize_command!(command)
    # Whitelist some safe characters
    command.gsub!(/[^a-zA-b 0-9]+/, '')
  end

  def parse_created_at(path)
    # Parse created at
    #2013/23/23/23:23:23.txt'
    date, time = path.match(/(\d{2,4}\/\d{1,2}\/\d{1,2})\/(\d{1,2}\:\d{1,2}\:\d{1,2})/).try(:captures)
    Time.parse("#{date} #{time}") # Might need some conrrection for timezone.
  end

  def render_checkboxes!(markdown)
    markdown.gsub!(/^(  )?\[ \](.*)/, "<input type=\"checkbox\"></input> \\2<br>")
    markdown.gsub!(/^(  )?\[(x|X)\](.*)/, "<input type=\"checkbox\" checked></input> \\3<br>")
  end

  def extract_attributes(content)
    lines = content.lines

    # Only read from matter if --- is first line in the file.
    return [{}, content] unless lines.shift.try(:chomp) == '---'

    attribute_lines = []

    while (line = lines.shift) && line.try(:chomp) != '---'
      attribute_lines << line
    end
    attributes = YAML.load(attribute_lines.join("\n"))
    attributes.symbolize_keys!
    body = lines.join
    [attributes, body]
  end

end
