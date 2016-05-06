require 'csv'
require 'pdfkit'
require 'matrix'

class StationHtmlFactory
  attr_reader :array_robochi, :array_vyhidni, :station, :number, :type, :route
  
  def initialize(args)
    @array_robochi = args[:array_robochi]
    @array_vyhidni = args[:array_vyhidni]
    @station = args[:station]
    @number = args[:number]
    @type = args[:type]
    @route = args[:route]
  end
  
  def html
    head+body
  end
  
  private
  
  def make_hash(array, hash)
    array.each do |r|
      if r.strip=="-"
        puts number
      else
        parts = r.split(":")
        if hash[parts[0]]
          hash[parts[0]] << parts[1]
        else
          hash[parts[0]] = []
          hash[parts[0]] << parts[1]
        end    
      end
    end  
    return hash  
  end
  
  def robochi_hash
    make_hash(array_robochi, {})
  end
  
  def vyhidni_hash
    make_hash(array_vyhidni, {})
  end
  
  def head
    "<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><link rel=\"stylesheet\" type=\"text/css\" href=\"trans.css\"></head>"
  end
  
  def table_robochi
    hours = "<tr  class='hours'>"
    robochi_hash.keys.each do |key|
      hours << "<td>#{key}</td>"
    end
    hours << "</tr>"
    minutes = ""
    max = 0
    robochi_hash.each do |key, array|
      max = array.count if max < array.count
    end
    max.times do |i|
      row = "<tr>"
      robochi_hash.each do |key, array|
        if array[i]
          row << "<td>#{array[i]}</td>"
        else
          row << "<td></td>"
        end
      end 
      row << "</tr>"  
      minutes << row  
    end
    "<table class=\"top\">"+head_robochi+hours+minutes+"</table>"
  end
  
  def table_vyhidni
    hours = "<tr>"
    vyhidni_hash.keys.each do |key|
      hours << "<td class='hours'>#{key}</td>"
    end
    hours << "</tr>"
    minutes = ""
    max = 0
    vyhidni_hash.each do |key, array|
      max = array.count if max < array.count
    end
    max.times do |i|
      row = "<tr>"
      vyhidni_hash.each do |key, array|
        if array[i]
          row << "<td>#{array[i]}</td>"
        else
          row << "<td></td>"
        end
      end 
      row << "</tr>"  
      minutes << row  
    end
    "<table class=\"top\">"+head_vyhidni+hours+minutes+"</table>"
  end
  
  def head_robochi
    "<caption>Робочі дні</caption>"
  end
  
  def head_vyhidni
    "<caption>Святкові та вихідні дні</caption>"
  end
  
  def header
    "<div class=\"header\"><span class='number'>#{number}</span><img src=\"avt.PNG\" /></span><span class='rout'>#{route}</span></div>"
  end
  
  def body
    "<body>"+header+table_robochi+table_vyhidni+"</body></html>"
  end

end

class Transport
  attr_reader :csv_robochi, :csv_vyhidni, :type, :number
  
  def initialize(csv_robochi, csv_vyhidni, type, number)
    @csv_robochi = csv_robochi
    @csv_vyhidni = csv_vyhidni
    @type = type
    @number = number
  end
  
  def single(csv)
    SingleCSV.new(csv)
  end
  
  def stations_there(csv)
    single(csv).stations_there
  end
  
  def stations_backagain(csv)
    single(csv).stations_there
  end
  
  def route_there
    single(csv_robochi).route_there
  end
  
  def stations_there_full
    keys = stations_there(csv_robochi).keys+stations_there(csv_vyhidni).keys
    keys.uniq!
    array = []
    keys.each do |key|
      hash = {}
      hash[:station] = key
      hash[:array_robochi] = stations_there(csv_robochi).fetch(key)
      hash[:array_vyhidni] = stations_there(csv_vyhidni).fetch(key)
      hash[:number] = number
      hash[:type] = type
      hash[:route] = route_there
      array << hash
    end
    return array
  end

  def stations_backagain_full
    keys = stations_backagain(csv_robochi).keys+stations_backagain(csv_vyhidni).keys
    keys.uniq!
    array = []
    keys.each do |key|
      hash = {}
      hash[:station] = key
      hash[:array_robochi] = stations_backagain(csv_robochi).fetch(key)
      hash[:array_vyhidni] = stations_backagain(csv_vyhidni).fetch(key)
      hash[:number] = number
      hash[:type] = type
      hash[:route] = route_there
    end
  end
  
  
end

class SingleCSV
  attr_reader :csv
  
  def initialize(csv)
    @csv = csv
  end
  
  def table
    csv.drop(6)
  end
  
  def route_there
    csv[4][0].strip
  end
  
  def route_backagain
    subroute = route_there.match(/(.*)\s-/)[1].strip!
    csv.reverse_each do |c|
      if c[0]&& c[0].match(subroute)
        route = c[0].strip!
        break
      end
    end
  end
  
  def there
    arr = []
    table.each do |record|
      if record.empty?
        break
      else
        record.compact!
        arr << record
      end
     end
     return arr
  end
  
  def backagain
    arr = []
    table.reverse_each do |record|
      if record.empty?
        next
      elsif record[0].match(route1)
        backagain << record
        break
      else
        record.compact!
        arr << record
      end
    end
    return arr
  end
  
  def m_there
    m_there = Matrix[]
    there.each do |t|
      m_there = Matrix.rows(m_there.to_a << t)      
    end
    return m_there
  end

  def m_backagain
    m_backagain = Matrix[]
    backagain.each do |t|
      m_backagain = Matrix.rows(m_backagain.to_a << t)      
    end 
    return m_backagain
  end
  
  def stations_there
    stations = {}
    (m_there.column_count-1).times do |i|
      a = m_there.column(i+1).to_a  
      stations[a[0]] = a.drop(1)
    end
    return stations
  end
  
  def stations_backagain
    stations = {}
    (m_backagain.column_count-1).times do |i|
      a = m_backagain.column(i+1).to_a 
      stations[a[0]] = a.drop(1)
    end
    return stations
  end

end

class FileMaker
  
  attr_reader :html, :type, :css, :number, :station, :where
  
  def initialize(args)
    @html = args[:html]
    @css = args[:css]
    @type = args[:type]
    @number = args[:number]
    @station = args[:station]
    @where = args[:where]
  end
  
  def mod_station
    station.strip.gsub(/"/,"").gsub(/\s/,"_")
  end
  
  def name
    puts mod_station
    type+"-"+number+"-"+mod_station+"-"+where+".pdf"
  end
  
  def pdf
    kit = PDFKit.new(html, :page_size => 'A4')
    kit.stylesheets << css
    puts kit.stylesheets
    file = kit.to_file("/home/mouse/Projects/SFA/scrapers/kptrans/pdfs/"+name)   
  end
 
end



csv = CSV.read("/home/mouse/Projects/SFA/scrapers/kptrans/schedules/avtobus/robochi/robochi_route11.csv", "r:Windows-1251:UTF-8", {:col_sep => ";", :quote_char => "|"})
csv2 = CSV.read("/home/mouse/Projects/SFA/scrapers/kptrans/schedules/avtobus/vyh/vyhidni_route11.csv", "r:Windows-1251:UTF-8", {:col_sep => ";", :quote_char => "|"})

transport = Transport.new(csv, csv2, "Автобус", 11)

transport.stations_there_full.each do |station|
  #puts station
  factory = StationHtmlFactory.new(station)
  
   File.open('/home/mouse/Projects/SFA/scrapers/kptrans/'+station[:station]+station[:number].to_s+".html", "wb") do |file|
     file.write factory.html
  end
  #filemaker = FileMaker.new(:html=>factory.html, :type=>"avtobus", :css=>"/home/mouse/Projects/SFA/scrapers/kptrans/trans.css", :where=>"there", :station=>station[:station], :number=>"11")
  #filemaker.pdf
end


