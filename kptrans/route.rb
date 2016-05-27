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
    if array_robochi
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
    else
      ""
    end
  end
  
  def table_vyhidni
    if array_vyhidni
      hours = "<tr  class='hours'>"
      vyhidni_hash.keys.each do |key|
        hours << "<td>#{key}</td>"
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
     else
       ""
     end
  end
  
  def head_robochi
    "<caption>Робочі дні</caption>"
  end
  
  def head_vyhidni
    "<caption>Святкові та вихідні дні</caption>"
  end
  
  def header
    "<div class=\"header\"><span class='number'>#{number}</span><img class='mm' src=\"file:///home/mouse/Projects/SFA/scrapers/kptrans/trol.PNG\" /></span><span class='rout'>#{route}</span></div>"
  end
  
  def footer
    "<p class='footer'><img class='m' src=\"file:///home/mouse/Projects/SFA/scrapers/kptrans/m.PNG\" /><span>Право на розклад <span>від</span> <img class='mm' src='file:///home/mouse/Projects/SFA/scrapers/kptrans/m2.PNG' /></span></p>"
    
  end
  
  def body
    
    "<body>"+header+"<div class='tables'>"+table_robochi+table_vyhidni+"</div>"+footer+"</body></html>"
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
  
  def route_backagain
    single(csv_robochi).route_backagain
  end
  
  def stations_there_full
 

    if !csv_vyhidni

      keys = stations_there(csv_robochi).keys
    elsif !csv_robochi
      keys = stations_there(csv_vyhidni).keys
    else
      
      keys = stations_there(csv_robochi).keys+stations_there(csv_vyhidni).keys
    end
    keys.uniq!
    array = []
    keys.each do |key|
      
      hash = {}
      hash[:station] = key
      if !csv_robochi
        hash[:array_robochi] = nil
      else
        hash[:array_robochi] = stations_there(csv_robochi).fetch(key)
      end
      if !csv_vyhidni
        hash[:array_vyhidni] = nil
      else
        hash[:array_vyhidni] = stations_there(csv_vyhidni).fetch(key)
      end
      hash[:number] = number
      hash[:type] = type
      hash[:route] = route_there
      array << hash
    end
    return array
  end

  def stations_backagain_full

    if !csv_vyhidni
      keys = stations_backagain(csv_robochi).keys
    elsif !csv_robochi
      keys = stations_backagain(csv_vyhidni).keys
    else
      keys = stations_backagain(csv_robochi).keys+stations_backagain(csv_vyhidni).keys
    end
    keys.uniq!
    array = []
    keys.each do |key|
      hash = {}
      hash[:station] = key
      if !csv_robochi
        hash[:array_robochi] = nil
      else
        hash[:array_robochi] = stations_backagain(csv_robochi).fetch(key)
      end
      if !csv_vyhidni
        hash[:array_vyhidni] = nil
      else
        hash[:array_vyhidni] = stations_backagain(csv_vyhidni).fetch(key)
      end
      hash[:number] = number
      hash[:type] = type
      hash[:route] = route_backagain
      array << hash
    end
    return array
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
    csv[4][0].strip.gsub(/"/,"")
  end
  
  def route_backagain
    route_arr = route_there.split(" - ")

    route = route_arr[1]+" - "+route_arr[0]
  end
  
  def there
    arr = []
    table.each do |record|
      if record[0].nil? || record.empty?
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
    station.strip.gsub(/"/,"").gsub(/\s/,"_").gsub(/\//,"")
  end
  
  def name
    type+"-"+number+"-"+mod_station+"-"+where+".pdf"
  end
  
  def pdf
    kit = PDFKit.new(html, :page_size => 'A4',:orientation => 'Landscape', :margin_top => '5mm',  :margin_right => '15mm',:margin_left => '15mm',:margin_bottom => '1mm')
    kit.stylesheets << css
    file = kit.to_file("/home/mouse/Projects/SFA/scrapers/kptrans/pdfs/troleybus/"+where+"/"+name)   
  end
 
end



#for i in (1..50)
for i in ["37а","40к","50к"] 
  csv = nil
  csv2 = nil
  filename1 = "/home/mouse/Projects/SFA/scrapers/kptrans/schedules/troleybus/robochi"+i.to_s+".csv"
  
  filename2 = "/home/mouse/Projects/SFA/scrapers/kptrans/schedules/troleybus/Тролейбус_"+i.to_s+".csv"
  
  if !File.file?(filename1) && !File.file?(filename2)
    next
  end
  if File.file?(filename1)
    puts filename1
    csv = CSV.read(filename1, "r:Windows-1251:UTF-8", {:col_sep => ";",:quote_char => "|"})
    if csv[0][0].match(/,,/)
      csv = CSV.read(filename1, "r:Windows-1251:UTF-8", {:col_sep => ",",:quote_char => "|"})
    end
  end
  if File.file?(filename2)
    puts filename2
    csv2 = CSV.read(filename2, "r:Windows-1251:UTF-8", {:col_sep => ";", :quote_char => "|"}) 
    if csv2[0][0].match(/,,/)
      csv2 = CSV.read(filename2, "r:Windows-1251:UTF-8", {:col_sep => ",",:quote_char => "|"})
    end   
  end  
  
  transport = Transport.new(csv, csv2, "Тролейбус", i)

  transport.stations_backagain_full.each do |station|
    puts station
    factory = StationHtmlFactory.new(station)
    filemaker = FileMaker.new(:html=>factory.html, :type=>"troleybus", :css=>"/home/mouse/Projects/SFA/scrapers/kptrans/trans.css", :where=>"backagain", :station=>station[:station], :number=>i.to_s)
    filemaker.pdf
  end

end






