module Investments
  class FetchPriceJob < ApplicationJob
    queue_as :default

    def perform(investment_id)
      investment = Investment.find_by(id: investment_id)
      return unless investment&.ticker.present?

      price = case investment.investment_type
              when "stock"
                fetch_stock_price(investment.ticker)
              when "crypto"
                fetch_crypto_price(investment.ticker)
              end

      if price && price > 0
        investment.update!(current_price: price, last_price_update_at: Time.current)
      end
    rescue StandardError => e
      Rails.logger.error "FetchPriceJob error for investment #{investment_id}: #{e.message}"
    end

    private

    def fetch_stock_price(ticker)
      response = HTTParty.get(
        "https://brapi.dev/api/quote/#{ticker.upcase}",
        timeout: 10,
        headers: { "Accept" => "application/json" }
      )
      return nil unless response.success?

      data = response.parsed_response
      data.dig("results", 0, "regularMarketPrice")
    rescue HTTParty::Error, Timeout::Error => e
      Rails.logger.error "Stock price fetch error for #{ticker}: #{e.message}"
      nil
    end

    def fetch_crypto_price(coin_id)
      response = HTTParty.get(
        "https://api.coingecko.com/api/v3/simple/price",
        query: { ids: coin_id.downcase, vs_currencies: "brl" },
        timeout: 10,
        headers: { "Accept" => "application/json" }
      )
      return nil unless response.success?

      data = response.parsed_response
      data.dig(coin_id.downcase, "brl")
    rescue HTTParty::Error, Timeout::Error => e
      Rails.logger.error "Crypto price fetch error for #{coin_id}: #{e.message}"
      nil
    end
  end
end
