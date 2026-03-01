module BankAccounts
  class FetchCdiRateJob < ApplicationJob
    queue_as :default

    def perform
      CdiRate.fetch_from_bcb!
    rescue StandardError => e
      Rails.logger.error "FetchCdiRateJob error: #{e.message}"
    end
  end
end
