require 'faraday'
require 'faraday/retry'
require 'deep_merge'
require 'yaml'
require 'pry' if ENV['debug'] == 'true'

require_relative 'native_helper'

class WealthSimpleClient
  # import the file containing all the queries needed to get all the transactions from the cash account
  require_relative 'queries'
  # import the file containing all the methods able to interpret appropriately the results from the queries
  require_relative 'items'

  FETCH_ACTIVITY_LIST_API_CUT_OFF_DAY = Date.parse('2023-04-01')

  # to initialize, we always require to input username, password and otp
  def initialize(otp: nil, username: nil, password: nil, access_token: nil)
    # check for mandatory parameters if we are not using cached data
    if ENV['use_cache'] == 'true'
      puts 'Using cache!' if ENV['debug'] == 'true'
      return
    else
      raise 'access token or the combination of username, password and otp are mandatory parameters' unless access_token || (username && password && otp)
    end

    # reading the config file
    @config = YAML.load(File.read('lib/config.yml'))

    # retrieving the body used in the POST request to get the GraphQL token
    @token_body = @config['token_body'].to_sym

    # retrieving the common headers used by all the requests: Token and GraphQL
    @common_headers = @config['common_headers'].to_sym

    # reading the access_token, if available from the method input variables or requesting it
    @access_token = access_token || get_token(otp: otp, username: username, password: password)
    puts @access_token if ENV['debug'] == 'true'
    raise 'Couldn\'t retrieve access token!' unless @access_token

    # retrieving the graphql headers from the config file adding static options and the access_token from above
    @graphql_headers = {
      'accept': '*/*',
      'authorization': "Bearer #{@access_token}",
      'content-type': 'application/json'
    }.deep_merge(@config['graphql_headers'].to_sym)

    # now that we have got the token and all the headers, let's prepare the GraphQL client
    @graphql_client = Faraday.new('https://my.wealthsimple.com') do |f|
      f.request :json # encode req bodies as JSON and automatically set the Content-Type header
      f.request :retry # retry transient failures
      f.response :json # decode response bodies as JSON
      f.adapter :net_http # adds the adapter to the connection, defaults to `Faraday.default_adapter`
      f.headers = @graphql_headers.deep_merge(@common_headers) # merge the @common_headers from above
    end
  end

  # Handles the token request from API
  private_methods def get_token(username:, password:, otp:)
    token_headers = {
      "x-wealthsimple-otp" => otp
    }.deep_merge(@config['token_headers'].to_sym) # merge the @token_headers

    # preparing the token POST request body from the config file adding static options and the credentials
    request_body = {
      grant_type: "password",
      username: username,
      password: password
    }.deep_merge(@token_body).to_json # merge the @token_body

    # preparing the client with all the headers and options needed by the token API
    client = Faraday.new('https://api.production.wealthsimple.com') do |f|
      f.request :json # encode req bodies as JSON and automatically set the Content-Type header
      f.request :retry # retry transient failures
      f.response :json # decode response bodies as JSON
      f.adapter :net_http # adds the adapter to the connection, defaults to `Faraday.default_adapter`
      f.headers = token_headers.deep_merge(@common_headers) # merge the @common_headers
    end

    # and finally, requesting the token using the token body prepared earlier
    response = client.post('/v1/oauth/v2/token') do |req|
      req.body = request_body
    end

    # return immediately if response is not success
    raise "ERROR: Access token couldn't be retrieved! Maybe username, password and/or OTP were incorrect? We got: #{response&.status}" unless response&.status == 200
    # return immediately if body is empty
    raise 'ERROR: Empty body received from auth endpoint!' unless response&.body

    response.body.dig('access_token')
  end

  # Handles GraphQL requests
  private_methods def handle_request(query:, parameters:, page: nil, offset: nil, graphql_headers: nil)
    new_page = (page || offset) ? "(next page: #{page || offset})" : ""
    puts "Retrieving #{query} #{new_page}"

    # since the query methods is passed dynamically, we want to be sure it really exists or return an error straight away
    raise "Unknown query: #{query}" unless methods.private_methods.include?(query.to_sym)

    # get the query body default structure from the file with the definition of the queries
    body = send(query, **parameters)

    # send the GQL query
    response = @graphql_client.post('/graphql') do |req|
      # update headers, if necessary
      req.headers = req.headers.deep_merge(graphql_headers) if graphql_headers

      # add page token if necessary, there are two tokens and three different names because there are two separate implementations with different variables
      if page
        if ['fetch_activity_list_query', 'fetch_activity_feed_items_query'].include?(query)
          # only some pages use cursor as variable
          body[:variables][:cursor] = page
        else
          # all the other APIs with the cursor use 'after'
          body[:variables][:after] = page
        end
      end
      # with the exception of some other APIs that use 'offset'!
      body[:variables][:offset] = offset if offset
      # ensure the body for the POST is in JSON format
      req.body = body.to_json
    end

    # return immediately if response is not success
    raise "ERROR: Unsuccessful query! We got: #{response&.status}" unless response&.status == 200
    # return immediately if body is empty
    raise 'ERROR: Empty body received from GraphQL endpoint!' unless response&.body

    # get the key containing the data, this differs in each GraphQL query response
    return_data_method = response&.body&.dig('data')&.first&.first
    # extract the relevant part (data) of the body
    data = response.body&.dig('data')&.dig(return_data_method)
    # sometimes the data is an array, in this case there is no need to handle pagination as it is not implemented server-side (i.e.: cross_product_account_details)
    unless data.class == Array
      # Ok, it's not an array. Let's handle pagination...

      # method #1: check if there are other pages to fetch
      if data&.dig('pageInfo')&.dig('hasNextPage')
        # get the next cursor
        cursor = data&.dig('pageInfo')&.dig('endCursor')
        # get the data for the next page with a recursive method call
        next_page_data = handle_request(query: query, parameters: parameters, page: cursor)
        # merge the data collected from the next page
        data = data.deep_merge(next_page_data)
      end

      # remove page information unless this is a recursive call; In the latter case, we need the pagination information to handle the recursive call
      data.delete('pageInfo') unless caller_locations(1,1)[0].label == __method__ # is the caller method name the same as this method name? Then it's a recursive call

      # method #2: check if there are other pages to fetch. This happens when the number of results matches the limit used in the parameters. In case the list was really matching the limit (i.e.: limit 100, total transactions 100) the following API request will just return an empty list
      if body[:variables][:limit] && data&.dig('paginatedActivities')&.dig('results')&.count == body[:variables][:limit]
        # set the next cursor
        offset = (body[:variables][:offset] || 0) + body[:variables][:limit]
        # get the data for the next page with a recursive method call
        next_page_data = handle_request(query: query, parameters: parameters, offset: offset)
        # merge the data collected from the next page
        data = data.deep_merge(next_page_data)
      end

      # method #2 doesn't have page information, no need to remove additional data
    end

    # return all the data, if applicable, from all the pages
    data
  end

  # Retrieves all the data related to the cash account
  private_methods def get_data
    # TODO: now WS supports multiple accounts, we can use fetch_all_account_financials_query to find it but we require the IdentityId
    cash_account = ENV['preferred_account']

    submit_query = {
      query: 'cash_account_balance_query',
      parameters: {
        accountId: cash_account
      }
    }
    cash_account_balance = handle_request(query: submit_query[:query], parameters: submit_query[:parameters])
    cash_account = cash_account_balance['id']

    submit_query = {
      query: 'list_activities_for_account_query',
      parameters: {
        accountId: cash_account,
        futureDateString: (Date.today + 2).strftime('%Y-%m-%d')
      }
    }
    list_activities_for_account = handle_request(query: submit_query[:query], parameters: submit_query[:parameters])

    submit_query = {
      query: 'list_deposits_for_account_query',
      parameters: {
        accountId: cash_account
      }
    }
    list_deposits_for_account = handle_request(query: submit_query[:query], parameters: submit_query[:parameters])

    submit_query = {
      query: 'list_withdrawals_for_account_query',
      parameters: {
        accountId: cash_account
      }
    }
    list_withdrawals_for_account = handle_request(query: submit_query[:query], parameters: submit_query[:parameters])

    # submit_query = {
    #   query: 'list_pending_internal_transfers_for_account_query',
    #   parameters: {
    #     accountId: cash_account
    #   }
    # }
    # list_pending_internal_transfers_for_account = handle_request(query: submit_query[:query], parameters: submit_query[:parameters])

    # submit_query = {
    #   query: 'cross_product_account_details_query',
    #   parameters: {
    #     userId: "ENV['ws_user_id']" # TODO: IMPORTANT: userId should be found programmatically. This must arrive coded or at an earlier initialisation stage as it is not visible in the flow
    #   }
    # }
    # cross_product_account_details = handle_request(query: submit_query[:query], parameters: submit_query[:parameters])

    submit_query = {
      query: 'spend_transactions_query',
      parameters: {
        accountId: cash_account
      }
    }
    spend_transactions = handle_request(query: submit_query[:query], parameters: submit_query[:parameters])

    submit_query = {
      query: 'search_funding_intents_query',
      parameters: {
        accountId: cash_account
      }
    }
    search_funding_intents_query = handle_request(query: submit_query[:query], parameters: submit_query[:parameters])

    submit_query = {
      query: 'payments_query',
      parameters: {}
    }
    payments = handle_request(query: submit_query[:query], parameters: submit_query[:parameters])

    submit_query = {
      query: 'fetch_interest_payout_query',
      parameters: {
        accountId: cash_account,
        futureDateString: (Date.today + 2).strftime('%Y-%m-%d')
      }
    }
    fetch_interest_payout_query = handle_request(query: submit_query[:query], parameters: submit_query[:parameters])

    # submit_query = {
    #   query: 'fetch_activity_list_query',
    #   parameters: {
    #     accountIds: [cash_account],
    #     endDate: Time.now.utc.strftime('%FT%T.%LZ')
    #   }
    # }
    # fetch_activity_list_query = handle_request(query: submit_query[:query], parameters: submit_query[:parameters])

    submit_query = {
      query: 'fetch_activity_feed_items_query',
      parameters: {
        accountIds: [cash_account],
        endDate: Time.now.utc.strftime('%FT%T.%LZ')
      },
      graphql_headers: {
        'x-ws-profile': 'trade'
      }
    }
    fetch_activity_feed_items = handle_request(query: submit_query[:query], parameters: submit_query[:parameters])

    # returning results using the old rocket syntax to maintain compatibility with cache and consistency with the rest of the content
    {
      'cash_account_balance' => cash_account_balance,
      'list_activities_for_account' => list_activities_for_account,
      'list_deposits_for_account' => list_deposits_for_account,
      'list_withdrawals_for_account' => list_withdrawals_for_account,
      # 'list_pending_internal_transfers_for_account' => list_pending_internal_transfers_for_account,
      # 'cross_product_account_details' => cross_product_account_details,
      'spend_transactions' => spend_transactions,
      'search_funding_intents' => search_funding_intents_query,
      'fetch_interest_payout' => fetch_interest_payout_query,
      'payments' => payments,
      # 'fetch_activity_list' => fetch_activity_list_query,
      'fetch_activity_feed_items' => fetch_activity_feed_items
    }
  end

  # Generate export with all the transactions from the cash account
  def generate_export(csv_file: 'export.csv', xls_file: 'full.xlsx', cache_file: 'cached-data.json')
    data_hash = if ENV['use_cache'] == 'true'
                  file = File.read(cache_file)
                  JSON.parse(file, { symbolize_names: false })
                else
                  data_hash = get_data
                  File.write(cache_file, JSON.pretty_generate(data_hash))
                  data_hash
                end

    generate_csv_export = ENV['generate_csv_export'] || true
    generate_xls_report = ENV['generate_xls_report'] || true

    # processing the data to extract the relevant info. Reversing the arrays to get an ordering similar to what we get on the app when the dates are the same, mostly helpful to debug
    nodes = []
    nodes += data_hash.dig('list_activities_for_account')&.dig('paginatedActivities')&.dig('results')&.map                { |item| list_activities_for_account_process(item: item) }.reverse
    nodes += data_hash.dig('list_deposits_for_account')&.dig('deposits')&.dig('results')&.map                             { |item| list_deposits_for_account_process(item: item) }.reverse
    nodes += data_hash.dig('list_withdrawals_for_account')&.dig('results')&.map                                           { |item| list_withdrawals_for_account_process(item: item) }.reverse
    # nodes += data_hash.dig('list_pending_internal_transfers_for_account').dig('paginatedActivities').dig('results').map { list_pending_internal_transfers_for_account_process(item: item) } } # TODO: not implemented/needed, it seems returning redundant data
    nodes += data_hash.dig('spend_transactions')&.dig('nodes')&.map                                                       { |item| spend_transactions_process(item: item) }.flatten.reverse # this can generate array of hashes and needs to be flatten
    nodes += data_hash.dig('search_funding_intents')&.dig('edges')&.map                                                   { |item| search_funding_intents_query_process(item: item.dig('node')) }.reverse
    nodes += data_hash.dig('fetch_interest_payout')&.dig('paginatedActivities')&.dig('results')&.map                      { |item| fetch_interest_payout_query_process(item: item) }.reverse # this is fetch_interest_payout_query but returns data under 'account'
    nodes += data_hash.dig('payments')&.dig('nodes')&.map                                                                 { |item| payments_process(item: item) }.reverse
    # nodes += data_hash.dig('fetch_activity_list')&.dig('edges')&.map                                                      { |item| fetch_activity_list_query_process(item: item.dig('node')) }.reverse
    nodes += data_hash.dig('fetch_activity_feed_items')&.dig('edges')&.map                                                { |item| fetch_activity_list_query_process(item: item.dig('node')) }.reverse

    # TODO: We should add this check directly in the items processing AND stop the API fetch pagination once we pass the cutoff
    nodes.map! { |node| (Date.parse(node[:alternative_date].to_s) >= FETCH_ACTIVITY_LIST_API_CUT_OFF_DAY) && node[:source_api] == 'fetch_activity_list_query' ? node : (Date.parse(node[:alternative_date].to_s) < FETCH_ACTIVITY_LIST_API_CUT_OFF_DAY) && node[:source_api] != 'fetch_activity_list_query' ? node : nil }

    # sort by date in place
    nodes.compact!.sort_by! { |node| node[:alternative_date] }

    # get all the possible columns for the data export
    columns = nodes.map { |item| item.transform_keys(&:to_s).keys }.flatten.uniq
    # this is used to add the totals at the bottom of the CSV data export
    index_for_alternative_amount = columns.find_index('alternative_amount')

    # prepare spreadsheet(s). We are going to generate a CSV for import/export use and an Excel file for human consultation
    require 'csv'
    require 'rubyXL'
    workbook = RubyXL::Workbook.new
    worksheet = workbook.worksheets[0]
    worksheet.sheet_name = 'WealthSimple cash account data export'
    row_index = 0

    csv_data = []

    # add spreadsheet headers...
    # ...in the Excel file we use all the possible values appearing in the export...
    columns.each_with_index do |value, index|
      worksheet.add_cell(row_index, index, value)
    end
    # ...and in the CSV we use just the ones for the export
    csv_data << columns.filter { |column| column.start_with?('export_') }.sort if generate_csv_export # to keep it simple, the keys are getting ordered so that the CSV columns are always in the same order

    # iterates nodes
    nodes.each do |node|
      # remove transactions that already appear in other lists
      # only REIMB (monthly interests) have to be added
      next if node[:source_api] == 'list_activities_for_account' && ! ['REIMB'].include?(node[:type])
      # only INT (monthly interests) have to be added
      next if node[:source_api] == 'fetch_interest_payout_query' && ! ['INT'].include?(node[:type])
      # only Deposit (incoming e-transfers) have to be added
      next if node[:source_api] == 'search_funding_intents_query' && ! ['Deposit'].include?(node[:type])

      # moving the spreadsheet row index forward
      row_index += 1

      # iterate the known columns we extracted above and select the data inside the node. This makes the row insert in the spreadsheet much easier because we don't know what data each node contains and in what order it appears
      columns.each_with_index do |column, c_index|
        worksheet.add_cell(row_index, c_index, node[column.to_sym])
      end

      # skip the CSV if it's a non-settled transaction. We want to avoid importing non-settled transactions in budget tools because if it is reversed/voided will generate inconsistent reporting
      csv_data << node.select { |node_key, node_val| node_key.start_with?('export_') }.sort_by { |key, val| key }.map { |k, v| v } unless !generate_csv_export || !node[:export_date]
    end
    # storing the marker aside, this allows to remember in what row the list of our transactions ends
    marker = row_index +=1 # Excel doesn't start from 0 and the next write needs to go to a separate row so we increment both by 1

    # add a total
    worksheet.add_cell(row_index += 1, index_for_alternative_amount - 1, 'Grand total')
    worksheet.add_cell(row_index, index_for_alternative_amount, '', "=SUM(#{(index_for_alternative_amount + 1).to_s26}2:(#{(index_for_alternative_amount + 1).to_s26}#{marker})")
    # add a filtered data total (in case you have filters active in the spreadsheet this will provide the total of the visible data)
    worksheet.add_cell(row_index += 1, index_for_alternative_amount - 1, 'Filtered total')
    worksheet.add_cell(row_index, index_for_alternative_amount, '', "=SUBTOTAL(109, #{(index_for_alternative_amount + 1).to_s26}2:#{(index_for_alternative_amount + 1).to_s26}#{marker})")
    # add the expected total (since there is data filtered out and processed, assuming that we are not extracting a partial date range, we want to be sure that the expected total is matching the sum of the transactions reported on the spreadsheet)
    worksheet.add_cell(row_index += 1, index_for_alternative_amount - 1, 'Current balance')
    worksheet.add_cell(row_index, index_for_alternative_amount, data_hash&.dig('cash_account_balance')&.dig('spendingBalance').to_s&.cents_to_units)

    workbook.write(xls_file) if generate_xls_report

    if generate_csv_export
      CSV.open(csv_file, 'wb') do |csv|
        csv_data.each do |row|
          csv << row
        end
      end
    end

    puts 'Export complete!'
  end
end
