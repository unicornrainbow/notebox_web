class ImagesController < ApplicationController

  def index
    @images = Image.page

    # Why does slice throw an exception if the key is missing?
    @options = {
      days_ago: params[:days_ago],
      topic: params[:topic]
    }.delete_if { |k, v| v.nil? }

    date = Date.today - @options[:days_ago].to_i.days

    root_path = "#{IMAGES_ROOT}/captures/"

    today_path = "#{root_path}/#{date.strftime("%Y/%m/%d")}"
    todays_entries = Dir["#{today_path}/*.png"]

    @images = todays_entries.map { |full_path|
      path, ext = full_path.match(/#{root_path}(.*)\.(png)$/).try(:captures)
      created_at = parse_created_at("#{path}.#{ext}")

      attributes = {
        src: "/images/captures#{path}.png"
      }
      OpenStruct.new(attributes)
    }
    @images.reverse!

  end

  def png
    send_file "/Users/blake/images/#{params[:path]}.png"
  end

private

  def parse_created_at(path)
    # Parse created at
    #2013/23/23/23:23:23.txt'
    date, time = path.match(/(\d{2,4}\/\d{1,2}\/\d{1,2})\/(\d{1,2}\:\d{1,2}\:\d{1,2})/).try(:captures)
    Time.parse("#{date} #{time}") # Might need some conrrection for timezone.
  end

end
