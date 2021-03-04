require 'net/http'
require 'uri'
require 'json'

def get_stores(zip_code)
  uri = URI.parse("https://www.riteaid.com/services/ext/v2/stores/getStores?address=#{zip_code}&attrFilter=PREF-112&fetchMechanismVersion=2&radius=50")
  request = Net::HTTP::Get.new(uri)
  request["User-Agent"] = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:86.0) Gecko/20100101 Firefox/86.0"
  request["Accept"] = "*/*"
  request["Accept-Language"] = "en-US,en;q=0.5"
  request["X-Requested-With"] = "XMLHttpRequest"
  request["Connection"] = "keep-alive"
  request["Referer"] = "https://www.riteaid.com/pharmacy/apt-scheduler"

  req_options = {
    use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  @all_store_data = JSON.parse(response.body).to_h
  @all_store_data["Data"]["stores"].map { |store| store["storeNumber"]}
end

def check_stores(store_ids)
  store_ids.each do |store_id|
    store_result = check_store(store_id)
    slots = number_of_slots(store_result)
    puts "#{slots} slot(s) available at store ##{store_id} - #{get_address(store_id)}"
  end
end

def check_store(store_id)
  uri = URI.parse("https://www.riteaid.com/services/ext/v2/vaccine/checkSlots?storeNumber=#{store_id}")
  request = Net::HTTP::Get.new(uri)
  request["User-Agent"] = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:86.0) Gecko/20100101 Firefox/86.0"
  request["Accept"] = "*/*"
  request["Accept-Language"] = "en-US,en;q=0.5"
  request["X-Requested-With"] = "XMLHttpRequest"
  request["Connection"] = "keep-alive"
  request["Referer"] = "https://www.riteaid.com/pharmacy/apt-scheduler"

  req_options = {
    use_ssl: uri.scheme == "https",
  }

  response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
    http.request(request)
  end

  JSON.parse(response.body).to_h
end

def number_of_slots(store_result)
  count = 0
  store_result["Data"]["slots"].values.map do |value|
    if value == true
      count += 1
    end
  end

  return count
end

def get_address(store_id)
  store_data = @all_store_data["Data"]["stores"].select {|store| store["storeNumber"] == store_id }[0]
  address = store_data["address"]
  city = store_data["city"]
  state = store_data["state"]
  "#{address}, #{city}, #{state}"
end

zip_code = ARGV[0]
puts "Results within a 50-mile radius of #{zip_code}:\n" 
store_ids = get_stores(zip_code)
results = check_stores(store_ids)
puts "\n\nGo to https://www.riteaid.com/pharmacy/apt-scheduler to book an appointment."
puts "\nThis script is not affiliated with Rite Aid, I just thought their interface could be improved."
