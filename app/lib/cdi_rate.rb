module CdiRate
  CACHE_KEY = "cdi_rate"
  BCB_URL   = "https://api.bcb.gov.br/dados/serie/bcdata.sgs.11/dados/ultimos/1?formato=json"
  BUSINESS_DAYS_PER_YEAR = 252

  def self.current = Rails.cache.read(CACHE_KEY)&.fetch(:rate)
  def self.cached_info = Rails.cache.read(CACHE_KEY)

  def self.fetch_from_bcb!
    response = HTTParty.get(BCB_URL, timeout: 10, headers: { "Accept" => "application/json" })
    raise "BCB API error: HTTP #{response.code}" unless response.success?
    data = response.parsed_response
    raise "BCB API returned empty data" if data.blank?
    daily = data.first["valor"].to_f
    annual = ((1 + daily / 100) ** BUSINESS_DAYS_PER_YEAR - 1) * 100
    payload = { rate: annual.round(6), date: data.first["data"], updated_at: Time.current }
    Rails.cache.write(CACHE_KEY, payload, expires_in: 12.hours)
    payload[:rate]
  rescue HTTParty::Error, Timeout::Error, StandardError => e
    Rails.logger.error "CdiRate.fetch_from_bcb! error: #{e.message}"
    raise
  end
end
