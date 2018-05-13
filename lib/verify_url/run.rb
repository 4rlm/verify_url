require 'curler'

module VerifyUrl
  class Run
    # include Curler

    def initialize
      @dj_on = false
      @dj_count_limit = 0
      @dj_workers = 3
      @obj_in_grp = 10
      @dj_refresh_interval = 10
      @db_timeout_limit = 120
      @cut_off = 10.days.ago
      @formatter = Formatter.new
      @mig = Mig.new
      @current_process = "VerUrl"
    end


  def get_query
    err_sts_arr = ['Error: Timeout', 'Error: Host', 'Error: TCP']
    query = Web.select(:id)
      .where(url_sts: ['Valid', nil])
      .where('url_date < ? OR url_date IS NULL', @cut_off)
        .or(Web.select(:id)
          .where(url_sts: err_sts_arr)
          .where('timeout < ?', @db_timeout_limit)
        ).order("timeout ASC").pluck(:id)
  end

  def start_ver_url
    query = get_query[0..20]
    while query.any?
      setup_iterator(query)
      query = get_query[0..20]
      break unless query.any?
    end
  end

  def setup_iterator(query)
    @query_count = query.count
    (@query_count & @query_count > @obj_in_grp) ? @group_count = (@query_count / @obj_in_grp) : @group_count = 2
    @dj_on ? iterate_query(query) : query.each { |id| template_starter(id) }
  end

  #Call: VerUrl.new.start_ver_url
  def template_starter(id)
    web = Web.find(id)
    web_url = web.url
    db_timeout = web.timeout
    db_timeout == 0 ? timeout = @dj_refresh_interval : timeout = (db_timeout * 3)

    begin
      formatted_url = @formatter.format_url(web_url)
      if !formatted_url.present?
          web.update!(url_sts_code: nil, url_sts: 'Invalid', url_date: Time.now, wx_date: Time.now, timeout: timeout)
      elsif formatted_url != web_url
        fwd_web_obj = Web.find_by(url: formatted_url)
        AssocWeb.transfer_web_associations(web, fwd_web_obj) if fwd_web_obj&.url.present?
      end

      ####### CURL-BEGINS - FORMATTED URLS ONLY!! #######
      #Call: VerUrl.new.start_ver_url
      if formatted_url.present?
        curl_hsh = start_curl(formatted_url, timeout)
        err_msg = curl_hsh[:err_msg]
        if !err_msg.present?
          update_db(web, curl_hsh)
        elsif err_msg == "Error: Timeout" || err_msg == "Error: Host"
          puts "err_msg: #{err_msg}"
          web.update!(url_sts: err_msg, url_date: Time.now, timeout: timeout)
        else
          web.update!(url_sts_code: nil, url_sts: err_msg, url_date: Time.now, timeout: 0)
        end
      end
    rescue
      web = delete_duplicates(web_url)
    end

  end

  def update_db(web, curl_hsh)
    web_url = web.url
    url_sts_code = curl_hsh[:url_sts_code]
    curl_url = curl_hsh[:curl_url]
    print_curl_results(web_url, curl_url, url_sts_code)

    begin
      if !curl_url.present?
        web.update!(url_sts: "Error: Nil", url_sts_code: nil, url_date: Time.now, timeout: 0)
      elsif curl_url.present? && curl_url == web_url
          web.update!(url_sts: 'Valid', url_sts_code: url_sts_code, url_date: Time.now, timeout: 0)
      elsif curl_url.present? && curl_url != web_url
        fwd_web_obj = Web.find_or_create_by(url: curl_url)
        AssocWeb.transfer_web_associations(web, fwd_web_obj) if fwd_web_obj&.url.present?
      end
    rescue
      original_web_obj = delete_duplicates(original_web_obj.url)
    end
  end


  def delete_duplicates(web_url)
    duplicate_web_objs = Web.where(url: web_url).order("id ASC")
    duplicate_web_objs.last.destroy if duplicate_web_objs.count > 1
    non_duplicate_web_obj = duplicate_web_objs.first
    non_duplicate_web_obj
  end

  def print_curl_results(web_url, curl_url, url_sts_code)
    puts "=================================="
    puts "W: #{web_url}"
    puts "C: #{curl_url}"
    puts "S: #{url_sts_code}\n\n\n"
  end




  end

end
