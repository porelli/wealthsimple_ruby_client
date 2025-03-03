def list_activities_for_account_query(accountId:, futureDateString:)
  {
    "operationName": "ListActivitiesForAccount",
    "query": "query ListActivitiesForAccount($accountId: ID!, $offset: Int, $limit: Int, $types: [String!], $sortOrder: SortOrder, $sortBy: PaginatedActivitySortBy, $futureDateString: String!) {\n  account(id: $accountId) {\n    id\n    paginatedActivities(\n      offset: $offset\n      limit: $limit\n      types: $types\n      process_date_start: \"2014-01-01\"\n      effective_date_start: \"2014-01-01\"\n      process_date_end: $futureDateString\n      effective_date_end: $futureDateString\n      sort_order: $sortOrder\n      sort_by: $sortBy\n    ) {\n      offset\n      total_count\n      results {\n        id\n        type\n        sub_type\n        effective_date\n        process_date\n        reference_id\n        net_cash {\n          amount\n          currency\n          __typename\n        }\n        description\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n}\n",
    "variables": {
      "accountId": accountId,
      "futureDateString": futureDateString, #"2023-03-20", # TODO: the purpose of this field is unclear, from the conversation flow it appear to be +2 days from the current date
      "limit": 100,
      "offset": 0,
      "sortBy": "process_date",
      "sortOrder": "desc",
      "types": [
        "INT",
        "DEP",
        "WDL",
        "TRFIN",
        "TRFOUT",
        "REFUND",
        "REIMB"
      ]
    }
  }
end

def cash_account_balance_query(accountId: nil)
  {
    "operationName": "CashAccountBalance",
    "query": "query CashAccountBalance($accountId: ID) {\n  cashAccount(id: $accountId) {\n    id\n    spendingBalance\n    __typename\n  }\n}\n",
    "variables": {
      "accountId": accountId
    }
  }
end

def list_deposits_for_account_query(accountId:)
  {
    "operationName": "ListDepositsForAccount",
    "query": "query ListDepositsForAccount($accountId: ID!, $offset: Int, $limit: Int, $statuses: [DepositStatus], $includeCancelled: Boolean) {\n  account(id: $accountId) {\n    id\n    deposits(\n      offset: $offset\n      limit: $limit\n      statuses: $statuses\n      include_cancelled: $includeCancelled\n    ) {\n      offset\n      total_count\n      results {\n        id\n        status\n        display_state\n        cancellable\n        value {\n          amount\n          currency\n          __typename\n        }\n        post_dated\n        created_at\n        completed_at\n        settled_at\n        reject_reason\n        external_reference_id\n        estimated_settlement_date\n        instant_value {\n          amount\n          __typename\n        }\n        source {\n          __typename\n          ... on BankAccountOwner {\n            bank_account {\n              id\n              __typename\n            }\n            __typename\n          }\n          ... on PaymentCard {\n            last4\n            nickname\n            __typename\n          }\n        }\n        card_transaction {\n          approval_code\n          __typename\n        }\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n}\n",
    "variables": {
      "accountId": accountId,
      "includeCancelled": false,
      "limit": 100,
      "offset": 0,
      "statuses": [
        "accepted",
        "pending",
        "pending_custodian_notification",
        "posted"
      ]
    }
  }
end

def list_withdrawals_for_account_query(accountId:)
  {
    "operationName": "ListWithdrawalsForAccount",
    "query": "query ListWithdrawalsForAccount($accountId: String!, $offset: Int, $limit: Int, $statuses: [FundsTransferStatus], $includeCancelled: Boolean) {\n  search_funds_transfers(\n    account_id: $accountId\n    offset: $offset\n    limit: $limit\n    status: $statuses\n    include_cancelled: $includeCancelled\n    typename: Withdrawal\n  ) {\n    offset\n    total_count\n    results {\n      id\n      status\n      cancellable\n      value {\n        amount\n        currency\n        __typename\n      }\n      destination {\n        ...SourceOrDestinationDetails\n        __typename\n      }\n      source {\n        ...SourceOrDestinationDetails\n        __typename\n      }\n      card_transaction {\n        approval_code\n        __typename\n      }\n      external_reference_id\n      post_dated\n      created_at\n      completed_at\n      estimated_settlement_date\n      ... on Withdrawal {\n        reject_reason\n        type\n        reason\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment SourceOrDestinationDetails on FundingSourceOrDestinationUnion {\n  __typename\n  ... on Account {\n    id\n    __typename\n  }\n  ... on BankAccountOwner {\n    bank_account {\n      id\n      __typename\n    }\n    __typename\n  }\n  ... on PaymentCard {\n    id\n    card_type\n    last4\n    nickname\n    __typename\n  }\n}\n",
    "variables": {
      "accountId": accountId,
      "includeCancelled": false,
      "limit": 100,
      "offset": 0,
      "statuses": [
        "pending",
        "accepted",
        "posted",
        "rejected",
        "cancelled"
      ]
    }
  }
end

def list_pending_internal_transfers_for_account_query(accountId:)
  {
    "operationName": "ListPendingInternalTransfersForAccount",
    "query": "query ListPendingInternalTransfersForAccount($accountId: ID!) {\n  accountByAccountId(accountId: $accountId) {\n    id\n    incomingTransfers: incoming_internal_transfers {\n      results {\n        amount\n        currency\n        expectedCompletionDate: expected_completion_date\n        id\n        instantEligibility: instant_eligibility {\n          status\n          __typename\n        }\n        postDated: post_dated\n        sourceAccount: source_account {\n          id\n          __typename\n        }\n        status\n        transferType: transfer_type\n        __typename\n      }\n      __typename\n    }\n    outgoingTransfers: outgoing_internal_transfers {\n      results {\n        amount\n        currency\n        expectedCompletionDate: expected_completion_date\n        id\n        instantEligibility: instant_eligibility {\n          status\n          __typename\n        }\n        postDated: post_dated\n        destinationAccount: destination_account {\n          id\n          __typename\n        }\n        status\n        transferType: transfer_type\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n}\n",
    "variables": {
      "accountId": accountId,
    }
  }
end

def cross_product_account_details_query(userId:)
  {
    "operationName": "CrossProductAccountDetails",
    "query": "query CrossProductAccountDetails($userId: ID!) {\n  accountsByUserId(userId: $userId) {\n    accountOwners {\n      accountNickname\n      __typename\n    }\n    branch\n    currency\n    id\n    type\n    __typename\n  }\n}\n",
    "variables": {
      "userId": userId,
    }
  }
end

def spend_transactions_query(accountId:)
  {
    "operationName": "SpendTransactions",
    "query": "query SpendTransactions($first: Int, $after: String, $accountId: String!) {\n  spendTransactions(first: $first, after: $after, accountId: $accountId) {\n    nodes {\n      id\n      postedAt\n      merchantName\n      status\n      amount\n      hasReward\n      rewardAmount\n      rewardCanonicalId\n      rewardPayoutCustodianAccountId\n      rewardPayoutCustodianAccountType\n      rewardPayoutSecurityId\n      rewardPayoutType\n      roundupAmount\n      __typename\n    }\n    pageInfo {\n      startCursor\n      endCursor\n      hasNextPage\n      hasPreviousPage\n      __typename\n    }\n    __typename\n  }\n}\n",
    "variables": {
      "accountId": accountId,
      #"after": after, # This is for pagination and it's handled in a separate method
      "first": 25
    }
  }
end

def search_funding_intents_query(accountId:)
  {
    "operationName": "SearchFundingIntentsQuery",
    "query": "query SearchFundingIntentsQuery($after: String, $first: Int, $accountId: ID!) {\n  searchFundingIntents: search_funding_intents(\n    sort_order: desc\n    funding_method_type: [WsBankAccount, OnlineBillPayPayee, ETransferCustomer, ETransferFundingSource]\n    after: $after\n    first: $first\n    source_or_destination: {type: Account, id: $accountId}\n  ) {\n    edges {\n      cursor\n      node {\n        ...SearchFundingIntent\n        __typename\n      }\n      __typename\n    }\n    pageInfo {\n      hasNextPage\n      endCursor\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment SearchFundingIntent on FundingIntent {\n  id\n  state\n  createdAt: created_at\n  updatedAt: updated_at\n  fundableType: fundable_type\n  userReferenceId: user_reference_id\n  source {\n    type\n    id\n    __typename\n  }\n  fundableDetails: fundable_details {\n    ...FundingIntentDeposit\n    ...FundingIntentWithdrawal\n    __typename\n  }\n  transferMetadata: transfer_metadata {\n    ...FundingIntentOnlineBillPayMetadata\n    ...ETransferReceiveTransferMetadata\n    ...WsBankAccountTransferMetadata\n    ...ETransferFundingTransferMetadata\n    __typename\n  }\n  __typename\n}\n\nfragment FundingIntentDeposit on FundingIntentDeposit {\n  __typename\n  createdAt: created_at\n  amount\n  currency\n  completedAt: completed_at\n}\n\nfragment FundingIntentWithdrawal on FundingIntentWithdrawal {\n  __typename\n  createdAt: created_at\n  requestedAmountValue: requested_amount_value\n  finalAmount: final_amount {\n    amount\n    currency\n    __typename\n  }\n}\n\nfragment WsBankAccountTransferMetadata on WsBankAccountTransferMetadata {\n  __typename\n  originator_name\n  transaction_code\n  transaction_type\n  transaction_category\n}\n\nfragment ETransferReceiveTransferMetadata on FundingIntentETransferReceiveMetadata {\n  __typename\n  sender_name\n  memo\n}\n\nfragment FundingIntentOnlineBillPayMetadata on FundingIntentOnlineBillPayMetadata {\n  __typename\n  payee {\n    ...BillPayPayee\n    __typename\n  }\n}\n\nfragment BillPayPayee on OnlineBillPayPayee {\n  __typename\n  id\n  state\n  company {\n    ...BillPayCompany\n    __typename\n  }\n  redacted_account_number\n  nickname\n  created_at\n  updated_at\n}\n\nfragment BillPayCompany on OnlineBillPayCompany {\n  __typename\n  id\n  company_name\n  visibility_state\n  account_number_validation_rules {\n    ... on OnlineBillPayAccountNumberLengthRule {\n      __typename\n      exact_length\n      maximum_length\n      minimum_length\n    }\n    __typename\n  }\n}\n\nfragment ETransferFundingTransferMetadata on FundingIntentETransferRequestTransactionMetadata {\n  __typename\n  sourceName: source_name\n  sourceEmail: source_email\n  sourceFinancialInstitution: source_financial_institution\n  sourceExpiryDate: source_expiry_date\n  sourceProviderStatus: source_provider_status\n}\n",
    "variables": {
      "accountId": accountId,
      "first": 25
    }
  }
end

def payments_query
  {
    "operationName": "Payments",
    "query": "query Payments($first: Int, $after: String, $statuses: [String!], $opposingContactIds: [ID!], $opposingUserIds: [ID!]) {\n  p2pPayments(\n    first: $first\n    after: $after\n    statuses: $statuses\n    opposingContactIds: $opposingContactIds\n    opposingUserIds: $opposingUserIds\n  ) {\n    nodes {\n      ...Payment\n      __typename\n    }\n    pageInfo {\n      startCursor\n      endCursor\n      hasNextPage\n      hasPreviousPage\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment Payment on P2PPayment {\n  id\n  __typename\n  createdAt\n  amount\n  status\n  type\n  senderContact {\n    ...Contact\n    __typename\n  }\n  receiverContact {\n    ...Contact\n    __typename\n  }\n  requestMessage\n  initiateMessage\n  acceptMessage\n  cancelledBy\n  fundsAvailable\n  updatedAt\n  acceptableExternallyAs\n  transactionMetadata {\n    securityQuestion\n    securityAnswer\n    firstName\n    lastName\n    name\n    autoDeposit\n    fundingIntentId\n    __typename\n  }\n}\n\nfragment Contact on P2PContact {\n  id\n  identifier\n  identifierType\n  name\n  telephoneHash\n  channelId\n  __typename\n  contactee {\n    ...Profile\n    __typename\n  }\n}\n\nfragment Profile on P2PProfile {\n  __typename\n  id\n  name\n  handle\n  imageUrl\n  color\n  telephoneHash\n}\n",
    "variables": {
        "first": 25
    }
  }
end

def fetch_interest_payout_query(accountId:, futureDateString:)
  {
    "operationName": "FetchInterestPayoutQuery",
    "query": "query FetchInterestPayoutQuery($accountId: ID!, $futureDateString: String!, $sortOrder: SortOrder, $sortBy: PaginatedActivitySortBy) {\n  account(id: $accountId) {\n    id\n    paginatedActivities(\n      offset: 0\n      limit: 10\n      types: [\"INT\", \"REIMB\"]\n      process_date_start: \"2014-01-01\"\n      effective_date_start: \"2014-01-01\"\n      process_date_end: $futureDateString\n      effective_date_end: $futureDateString\n      sort_order: $sortOrder\n      sort_by: $sortBy\n    ) {\n      results {\n        id\n        process_date\n        net_cash {\n          amount\n          currency\n          __typename\n        }\n        description\n        type\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n}\n",
    "variables": {
      "accountId": accountId,
      "futureDateString": futureDateString, #"2023-03-20", # TODO: the purpose of this field is unclear, from the conversation flow it appears to be +2 days from the current date
      "sortBy": "process_date",
      "sortOrder": "desc"
    }
  }
end

def fetch_activity_list_query(accountIds:, endDate:)
  {
    "operationName": "FetchActivityList",
    "variables": {
      "accountIds": accountIds, # [ "", "" ]
      "types": [
        "AFFILIATE",
        "CRYPTO_BUY",
        "CRYPTO_SELL",
        "CRYPTO_TRANSFER",
        "CRYPTO_STAKING_REWARD",
        "DEPOSIT",
        "DIVIDEND",
        "DIY_BUY",
        "DIY_SELL",
        "FEE",
        "FUNDS_CONVERSION",
        "GROUP_CONTRIBUTION",
        "INTEREST",
        "INTERNAL_TRANSFER",
        "INSTITUTIONAL_TRANSFER_INTENT",
        "LEGACY_INTERNAL_TRANSFER",
        "LEGACY_TRANSFER",
        "MANAGED_BUY",
        "MANAGED_SELL",
        "NON_RESIDENT_TAX",
        "OPTIONS_BUY",
        "OPTIONS_SELL",
        "OPTIONS_EXERCISE",
        "OPTIONS_EXPIRY",
        "P2P_PAYMENT",
        "PREPAID_SPEND",
        "PROMOTION",
        "STOCK_DIVIDEND",
        "REFUND",
        "REIMBURSEMENT",
        "RESP_GRANT",
        "SPEND",
        "WITHDRAWAL",
        "WITHHOLDING_TAX",
        "WRITE_OFF"
      ],
      "endDate": endDate, # "2024-01-14T04:59:59.999Z"
      "first": 50
    },
    "query": "query FetchActivityList($first: Int!, $cursor: Cursor, $accountIds: [String!], $types: [ActivityFeedItemType!], $subTypes: [ActivityFeedItemSubType!], $endDate: Datetime!, $securityIds: [String], $startDate: Datetime, $legacyStatuses: [String]) {\n  activities(\n    first: $first\n    after: $cursor\n    accountIds: $accountIds\n    types: $types\n    subTypes: $subTypes\n    endDate: $endDate\n    securityIds: $securityIds\n    startDate: $startDate\n    legacyStatuses: $legacyStatuses\n  ) {\n    edges {\n      node {\n        ...Activity\n        __typename\n      }\n      __typename\n    }\n    pageInfo {\n      hasNextPage\n      endCursor\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment Activity on ActivityFeedItem {\n  accountId\n  aftOriginatorName\n  aftTransactionCategory\n  aftTransactionType\n  amount\n  amountSign\n  assetQuantity\n  assetSymbol\n  canonicalId\n  currency\n  eTransferEmail\n  eTransferName\n  externalCanonicalId\n  identityId\n  institutionName\n  occurredAt\n  p2pHandle\n  p2pMessage\n  spendMerchant\n  securityId\n  billPayCompanyName\n  billPayPayeeNickname\n  redactedExternalAccountNumber\n  opposingAccountId\n  status\n  subType\n  type\n  visible\n  strikePrice\n  contractType\n  expiryDate\n  chequeNumber\n  provisionalCreditAmount\n  primaryBlocker\n  interestRate\n  __typename\n}\n"
  }
end

def fetch_spend_transactions_query(accountId:, transactionIds:)
  {
    "operationName": "FetchSpendTransactions",
    "query": "query FetchSpendTransactions($transactionIds: [String!], $accountId: String!) {\n  spendTransactions(transactionIds: $transactionIds, accountId: $accountId) {\n    edges {\n      node {\n        ...SpendTransaction\n        __typename\n      }\n      __typename\n    }\n    pageInfo {\n      hasNextPage\n      endCursor\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment SpendTransaction on SpendTransaction {\n  id\n  hasReward\n  rewardAmount\n  rewardPayoutType\n  rewardPayoutSecurityId\n  rewardPayoutCustodianAccountId\n  foreignAmount\n  foreignCurrency\n  foreignExchangeRate\n  isForeign\n  __typename\n}\n",
    "variables": {
      "accountId": accountId,
      "transactionIds": transactionIds # [ "", "" ]
    }
  }
end

def cash_pending_balance_query(accountId:)
  {
    "operationName": "CashPendingBalance",
    "query": "query CashPendingBalance($accountId: ID) {\n  cashAccount(id: $accountId) {\n    id\n    pendingBalance\n    __typename\n  }\n}\n",
    "variables": {
        "accountId": accountId
    }
  }
end

def fetch_activity_feed_items_query(accountIds:, endDate:)
  {
    "operationName": "FetchActivityFeedItems",
    "query": "query FetchActivityFeedItems($first: Int, $cursor: Cursor, $condition: ActivityCondition, $orderBy: [ActivitiesOrderBy!] = OCCURRED_AT_DESC) {\n  activityFeedItems(\n    first: $first\n    after: $cursor\n    condition: $condition\n    orderBy: $orderBy\n  ) {\n    edges {\n      node {\n        ...Activity\n        __typename\n      }\n      __typename\n    }\n    pageInfo {\n      hasNextPage\n      endCursor\n      __typename\n    }\n    __typename\n  }\n}\n\nfragment Activity on ActivityFeedItem {\n  accountId\n  aftOriginatorName\n  aftTransactionCategory\n  aftTransactionType\n  amount\n  amountSign\n  assetQuantity\n  assetSymbol\n  canonicalId\n  currency\n  eTransferEmail\n  eTransferName\n  externalCanonicalId\n  identityId\n  institutionName\n  occurredAt\n  p2pHandle\n  p2pMessage\n  spendMerchant\n  securityId\n  billPayCompanyName\n  billPayPayeeNickname\n  redactedExternalAccountNumber\n  opposingAccountId\n  status\n  subType\n  type\n  strikePrice\n  contractType\n  expiryDate\n  chequeNumber\n  provisionalCreditAmount\n  primaryBlocker\n  interestRate\n  frequency\n  counterAssetSymbol\n  rewardProgram\n  counterPartyCurrency\n  counterPartyCurrencyAmount\n  counterPartyName\n  fxRate\n  fees\n  reference\n  transferType\n  __typename\n}",
    "variables": {
      "orderBy":"OCCURRED_AT_DESC",
      "condition": {
        "accountIds": accountIds,
        "endDate": endDate
      },
      "first": 50
    }
  }
end

def fetch_all_account_financials_query(identityId:)
  {
    "operationName": "FetchAllAccountFinancials",
    "query": "query FetchAllAccountFinancials($identityId: ID!, $startDate: Date, $pageSize: Int = 25, $cursor: String, $currency: Currency) {\n  identity(id: $identityId) {\n    id\n    ...AllAccountFinancials\n    __typename\n  }\n}\n\nfragment AllAccountFinancials on Identity {\n  accounts(filter: {}, first: $pageSize, after: $cursor) {\n    pageInfo {\n      hasNextPage\n      endCursor\n      __typename\n    }\n    edges {\n      cursor\n      node {\n        ...AccountWithFinancials\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n  __typename\n}\n\nfragment AccountWithFinancials on Account {\n  ...AccountWithLink\n  ...AccountFinancials\n  __typename\n}\n\nfragment AccountWithLink on Account {\n  ...Account\n  linkedAccount {\n    ...Account\n    __typename\n  }\n  __typename\n}\n\nfragment Account on Account {\n  ...AccountCore\n  custodianAccounts {\n    ...CustodianAccount\n    __typename\n  }\n  __typename\n}\n\nfragment AccountCore on Account {\n  id\n  archivedAt\n  branch\n  closedAt\n  createdAt\n  cacheExpiredAt\n  currency\n  requiredIdentityVerification\n  unifiedAccountType\n  supportedCurrencies\n  compatibleCurrencies\n  nickname\n  status\n  accountOwnerConfiguration\n  accountFeatures {\n    ...AccountFeature\n    __typename\n  }\n  accountOwners {\n    ...AccountOwner\n    __typename\n  }\n  accountEntityRelationships {\n    ...AccountEntityRelationship\n    __typename\n  }\n  type\n  __typename\n}\n\nfragment AccountFeature on AccountFeature {\n  name\n  enabled\n  functional\n  firstEnabledOn\n  __typename\n}\n\nfragment AccountOwner on AccountOwner {\n  accountId\n  identityId\n  accountNickname\n  clientCanonicalId\n  accountOpeningAgreementsSigned\n  name\n  email\n  ownershipType\n  activeInvitation {\n    ...AccountOwnerInvitation\n    __typename\n  }\n  sentInvitations {\n    ...AccountOwnerInvitation\n    __typename\n  }\n  __typename\n}\n\nfragment AccountOwnerInvitation on AccountOwnerInvitation {\n  id\n  createdAt\n  inviteeName\n  inviteeEmail\n  inviterName\n  inviterEmail\n  updatedAt\n  sentAt\n  status\n  __typename\n}\n\nfragment AccountEntityRelationship on AccountEntityRelationship {\n  accountCanonicalId\n  entityCanonicalId\n  entityOwnershipType\n  entityType\n  __typename\n}\n\nfragment CustodianAccount on CustodianAccount {\n  id\n  branch\n  custodian\n  status\n  updatedAt\n  __typename\n}\n\nfragment AccountFinancials on Account {\n  id\n  custodianAccounts {\n    id\n    branch\n    financials {\n      current {\n        ...CustodianAccountCurrentFinancialValues\n        __typename\n      }\n      __typename\n    }\n    __typename\n  }\n  financials {\n    currentCombined(currency: $currency) {\n      id\n      ...AccountCurrentFinancials\n      __typename\n    }\n    __typename\n  }\n  __typename\n}\n\nfragment CustodianAccountCurrentFinancialValues on CustodianAccountCurrentFinancialValues {\n  deposits {\n    ...Money\n    __typename\n  }\n  earnings {\n    ...Money\n    __typename\n  }\n  netDeposits {\n    ...Money\n    __typename\n  }\n  netLiquidationValue {\n    ...Money\n    __typename\n  }\n  withdrawals {\n    ...Money\n    __typename\n  }\n  __typename\n}\n\nfragment Money on Money {\n  amount\n  cents\n  currency\n  __typename\n}\n\nfragment AccountCurrentFinancials on AccountCurrentFinancials {\n  id\n  netLiquidationValueV2 {\n    ...Money\n    __typename\n  }\n  netDeposits: netDepositsV2 {\n    ...Money\n    __typename\n  }\n  simpleReturns(referenceDate: $startDate) {\n    ...SimpleReturns\n    __typename\n  }\n  totalDeposits: totalDepositsV2 {\n    ...Money\n    __typename\n  }\n  totalWithdrawals: totalWithdrawalsV2 {\n    ...Money\n    __typename\n  }\n  __typename\n}\n\nfragment SimpleReturns on SimpleReturns {\n  amount {\n    ...Money\n    __typename\n  }\n  asOf\n  rate\n  referenceDate\n  __typename\n}",
    "variables": {
      "pageSize": 25,
      "identityId": identityId
    }
  }
end

##### Other queries not related to the cash account

