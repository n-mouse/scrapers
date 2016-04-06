require 'mechanize'
require 'bigdecimal'
require 'csv'

agent = Mechanize.new
BASE_URL="http://vstup.info/2015"
MAIN_URL = "http://vstup.info"


class Uni
  attr_reader :page, :base_url
  
  def initialize(page, base_url)
    @page = page
    @base_url = base_url
  end
  
  def name
    page.css("h3.title-description").text
  end
  
  def den_bac_table_linkparts
      page.css("table#denna1")[0].css("a") unless page.css("table#denna1").empty?
  end
  
  def napryam_links 
     if den_bac_table_linkparts
       den_bac_table_linkparts.map{ |lp| base_url+lp.attr("href")[1..-1] }
     else 
       []
     end
  end
  
  def invalid?
    if napryam_links.empty?
      true
    else
      false
    end
  end
  
end

class Napryam

  attr_reader :page
  
  def initialize(page)
    @page = page
  end
  
  def shortstat
    page.css("table#shortstat td").text
  end
  
  def derzam
    derzam_text = shortstat.match(/Обсяг державного замовлення:\s(\d+)/)
    if derzam_text 
      derzam_text[1].to_i
    else
      0
    end
  end
  
  def winners
    page.css('table.tablesaw-sortable tbody tr').select { |row| row.css('td')[1].attr("style")=="background:#b4caeb" }
  end
  
  def derzh_winners
    winners[0...derzam]
  end
  
  def scores_table_head
    page.css("table.tablesaw-sortable thead th")
  end
  
  def sigma_index
    scores_table_head.index(page.xpath('//th[contains(@title, "Сума всіх балів")]')[0])
  end
  
  def zno_index
    scores_table_head.index(page.xpath('//th[contains(@title, "Бали сертифікатів ЗНО")]')[0])
  end
  
  def sigma_string(row)
    row.css("td")[sigma_index].text
  end
  
  def zno_element(row)
    row.css("td")[zno_index]
  end
  
  def ukrzno_string(row)
    span = zno_element(row).css("span").select{|w| w.attr('title')=="Українська мова та література"}
    if span[0] 
      span[0].text
    else
      nil
    end
  end
  
  def total_derzh_winners
      derzh_winners.inject(BigDecimal.new("0")){ |result, winner| BigDecimal.new(sigma_string(winner)) + result}
  end
  
  def mean_derzh_winners
    total_derzh_winners/BigDecimal.new(derzh_winners.size) unless derzh_winners.empty?
  end
  
  def derzh_ukrzno_total
    total = BigDecimal.new("0")
    derzh_winners.each do |winner|
      if ukrzno_string(winner)
        total += BigDecimal.new(ukrzno_string(winner))
      end
    end
    return total
  end
  
  def derzh_ukrzno_mean
    derzh_ukrzno_total/BigDecimal.new(derzh_winners.size) unless derzh_winners.empty?
  end
  
end


file = File.open("unilinks.txt", "r")
unilinks = file.read[1...-1].split(",")
file.close
unilinks.map!{ |u| u.gsub(/\"/,"") }

CSV.open("vstup2015.csv", "ab") do |row|
  row << ["ВНЗ", "zamovlennya", "suma_mean", "ukrzno_mean"]
  arr = []
  unilinks.each do |unilink|
    uni = Uni.new(agent.get(unilink), BASE_URL)
    if uni.invalid?
      next
    end
    arr[0] = uni.name

    sigma_napryam_means = []
    ukrzno_napryam_means = []
    derzam_all = 0

    uni.napryam_links.each do |nl|
      puts nl
      napryam = Napryam.new(agent.get(nl))
      if napryam.derzam > 0 && !napryam.derzh_winners.empty?
        if !(napryam.total_derzh_winners > 0)
          next
        end
        sigma_napryam_means << napryam.mean_derzh_winners
        if !(napryam.derzh_ukrzno_total>0)
          next
        end
        ukrzno_napryam_means << napryam.derzh_ukrzno_mean
        derzam_all = derzam_all + napryam.derzam
      else
        next
      end  
    end
    if derzam_all==0
      next
    else
      sigma_total = sigma_napryam_means.inject(BigDecimal.new("0")){ |result, mean| mean + result}
      sigma_mean = (sigma_total/sigma_napryam_means.length).to_f
      derzh_ukrzno_total = ukrzno_napryam_means.inject(BigDecimal.new("0")){ |result, mean| mean + result}
      derzh_ukrzno_mean = (derzh_ukrzno_total/ukrzno_napryam_means.length).to_f
       
      arr[1] = derzam_all
      arr[2] = sigma_mean.to_f
      arr[3] = derzh_ukrzno_mean.to_f
      row << arr
    end

    sleep 1
  end
end

