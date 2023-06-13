# variables prefixed with 'export_' are meant to be used if you will import your settled transactions in a separate software (i.e.: Firefly III). This is processed data!
# 'alternative_date' is used to order the list, alternative_amount to calculate the totals

def list_activities_for_account_process(item:)
  effective_date = item['effective_date']
  description = item['description']
  amount = item&.dig('net_cash')&.dig('amount')&.to_f
  export_date = Date.parse(effective_date).strftime('%Y-%m-%d') rescue nil
  process_date = item['process_date']
  source_api = __method__[0...-8]
  id = item['id']

  output = {
    source_api: source_api,
    id: id,
    type: item['type'],
    process_date: process_date,
    effective_date: effective_date,
    amount: item&.dig('net_cash')&.dig('amount')&.to_f,
    currency: item&.dig('net_cash')&.dig('currency'),
    description: description,
    alternative_date: export_date || Date.parse(process_date).strftime('%Y-%m-%d'),
    alternative_amount: amount
  }

  # if the transaction is processed
  unless effective_date.empty?
    output.merge!({
      export_id: "#{source_api}_#{id}",
      export_date: export_date,
      export_description: description,
      export_amount: amount
    })
  end

  output
end

def list_deposits_for_account_process(item:)
  completed_at = item['completed_at']
  description = "Deposit from #{item&.dig('source')&.dig('__typename')} #{item&.dig('source')&.dig('last4')}"
  amount = item&.dig('value')&.dig('amount')&.to_f
  status = item['status']
  export_date = Date.parse(completed_at).strftime('%Y-%m-%d') rescue nil
  created_at = item['created_at']
  source_api = __method__[0...-8]
  id = item['id']

  output = {
    source_api: source_api,
    id: id,
    status: status,
    created_at: created_at,
    completed_at: completed_at,
    amount: amount,
    currency: item&.dig('value')&.dig('currency'),
    source: item&.dig('source')&.dig('__typename'),
    last4: item&.dig('source')&.dig('last4'),
    alternative_date: export_date || Date.parse(created_at).strftime('%Y-%m-%d'),
    alternative_amount: amount
  }

  # if the transaction is processed
  if ['accepted'].include?(status)
    output.merge!({
      export_id: "#{source_api}_#{id}",
      export_date: export_date,
      export_description: description,
      export_amount: amount
    })
  end

  output
end

def list_withdrawals_for_account_process(item:)
  completed_at = item['completed_at']
  description = "#{item&.dig('__typename')} to #{item&.dig('destination')&.dig('__typename')}"
  amount = item&.dig('value')&.dig('amount')&.to_f
  status = item['status']
  created_at = item['created_at']
  export_date = Date.parse(completed_at).strftime('%Y-%m-%d') rescue nil
  alternative_amount = -amount # those are withdrawals and should always be considered negative for transactions list purpose
  source_api = __method__[0...-8]
  id = item['id']

  output = {
    source_api: source_api,
    id: id,
    status: status,
    created_at: created_at,
    completed_at: completed_at,
    amount: amount,
    currency: item&.dig('value')&.dig('currency'),
    source: item&.dig('source')&.dig('id'),
    destination: item&.dig('source')&.dig('bank_account')&.dig('id'),
    alternative_date: export_date || Date.parse(created_at).strftime('%Y-%m-%d'),
    alternative_amount: alternative_amount
  }

  # if the transaction is processed
  if ['accepted'].include?(status)
    output.merge!({
      export_id: "#{source_api}_#{id}",
      export_date: export_date,
      export_description: description,
      export_amount: alternative_amount
    })
  end

  output
end

def spend_transactions_process(item:)
  posted_at = item['postedAt']
  merchant_name = item['merchantName']
  amount = item['amount']
  export_amount = amount&.to_s&.cents_to_units
  reward_amount = item['rewardAmount']
  alternative_reward_amount = reward_amount&.to_s&.cents_to_units
  reward_payout_custodian_account_type = item['rewardPayoutCustodianAccountType']
  status = item['status']
  export_date = Date.parse(posted_at).strftime('%Y-%m-%d')
  source_api = __method__[0...-8]
  id = item['id']

  transaction = {
    source_api: source_api,
    id: id,
    status: status,
    postedAt: posted_at,
    merchantName: item['merchantName'],
    amount: amount,
    rewardAmount: reward_amount,
    rewardPayoutCustodianAccountType: item['rewardPayoutCustodianAccountType'],
    alternative_date: export_date,
    alternative_amount: export_amount
  }

  # if the transaction is processed
  if ['settled'].include?(status)
    transaction.merge!({
      export_id: "#{source_api}_#{id}",
      export_date: export_date,
      export_description: merchant_name.empty? ? 'Missing description. Refund?' : merchant_name, # refunds do not have a description or anything to make them identifiable
      export_amount: export_amount
    })
  
    # if the transaction has cashback in the account itself (for example instead of TSFA or crypto), it won't show a separate transaction (!!!). We need to create a new one!
    if reward_payout_custodian_account_type&.start_with?('ca_cash_')
      transaction = [
        transaction,
        {
          source_api: "internal processing of #{__method__[0...-8]}",
          id: nil,
          status: nil,
          postedAt: nil,
          merchantName: nil,
          amount: nil,
          rewardAmount: nil,
          rewardPayoutCustodianAccountType: nil,
          export_id: "#{source_api}_#{id}_internal",
          export_date: export_date,
          export_description: "Cashback for #{merchant_name} (#{export_amount})",
          export_amount: alternative_reward_amount,
          alternative_date: export_date,
          alternative_amount: alternative_reward_amount
        }
      ]
    end
  end

  transaction
end

def payments_process(item:)
  updated_at = item['updatedAt']
  description = "#{item&.dig('__typename')} to #{item&.dig('receiverContact')&.dig('identifier')} (#{item&.dig('receiverContact')&.dig('name')})"
  amount = item['amount']
  type = item['type']
  status = item['status']
  export_date = Date.parse(updated_at).strftime('%Y-%m-%d') rescue nil
  created_at = item['createdAt']
  export_amount = "#{(type == 'send' ? '-' : '+')}#{amount}"&.cents_to_units # convert to negative if money was sent as it should for transactions list purpose
  source_api = __method__[0...-8]
  id = item['id']

  output = {
    source_api: source_api,
    id: id,
    status: status,
    createdAt: created_at,
    updatedAt: updated_at,
    type: type,
    amount: amount,
    senderName: item&.dig('senderContact')&.dig('name') || item&.dig('senderContact')&.dig('contactee')&.dig('name'),
    receiverName: item&.dig('receiverContact')&.dig('name') || item&.dig('receiverContact')&.dig('contactee')&.dig('name'),
    alternative_date: export_date || Date.parse(created_at).strftime('%Y-%m-%d'),
    alternative_amount: export_amount
  }

  # if the transaction is processed
  if ['accepted'].include?(status)
    output.merge!({
      export_id: "#{source_api}_#{id}",
      export_date: export_date,
      export_description: description,
      export_amount: export_amount
    })
  end

  output
end

def search_funding_intents_query_process(item:)
  updated_at = item['updatedAt']
  description = item&.dig('fundableType') == 'Deposit' ? "Deposit to #{item&.dig('transferMetadata')&.dig('sender_name')}" : item&.dig('fundableType')
  amount = item['fundableDetails']&.dig('amount')&.to_f || item['fundableDetails']&.dig('requestedAmountValue')&.to_f
  type = item['fundableType']
  status = item['state']
  export_date = Date.parse(updated_at).strftime('%Y-%m-%d')
  created_at = item['fundableDetails']&.dig('createdAt')
  export_amount = "#{(type == 'Withdrawal' ? '-' : '+')}#{amount}".to_f # convert to negative if money was sent as it should for transactions list purpose
  source_api = __method__[0...-8]
  id = item['id']

  output = {
    source_api: source_api,
    id: id,
    status: status,
    createdAt: created_at,
    updatedAt: updated_at,
    type: type,
    amount: amount,
    finalAmount: item['fundableDetails']&.dig('finalAmount')&.dig('amount'),
    finalAmountCurrency: item['fundableDetails']&.dig('finalAmount')&.dig('currency'),
    alternative_date: export_date || Date.parse(created_at).strftime('%Y-%m-%d'),
    alternative_amount: export_amount
  }

  # if the transaction is processed
  if ['completed'].include?(status)
    output.merge!({
      export_id: "#{source_api}_#{id}",
      export_date: export_date,
      export_description: description,
      export_amount: export_amount
    })
  end

  output
end

def fetch_interest_payout_query_process(item:)
  description = item['description']
  amount = item&.dig('net_cash')&.dig('amount')&.to_f
  process_date = item['process_date']
  export_date = Date.parse(process_date).strftime('%Y-%m-%d') rescue nil
  source_api = __method__[0...-8]
  id = item['id']

  output = {
    source_api: source_api,
    id: id,
    type: item['type'],
    process_date: process_date,
    amount: item&.dig('net_cash')&.dig('amount')&.to_f,
    currency: item&.dig('net_cash')&.dig('currency'),
    description: description,
    alternative_date: export_date || Date.parse(process_date).strftime('%Y-%m-%d'),
    alternative_amount: amount
  }

  # if the transaction is processed
  unless process_date.empty?
    output.merge!({
      export_id: "#{source_api}_#{id}",
      export_date: export_date,
      export_description: description,
      export_amount: amount
    })
  end

  output
end