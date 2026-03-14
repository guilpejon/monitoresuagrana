# Seeds — Monitore sua Grana
# Creates a demo user with realistic sample data for development

puts "Criando usuário demo..."

user = User.find_or_create_by!(email: "demo@monitoresuagrana.com.br") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.name = "Usuário Demo"
  u.currency = "BRL"
end

puts "User: #{user.email} (categorias criadas automaticamente pelo callback)"

# Cartões de crédito de exemplo
puts "Criando cartões de crédito..."
nubank = CreditCard.find_or_create_by!(user: user, name: "Nubank Roxinho") do |c|
  c.last4 = "1234"
  c.brand = "mastercard"
  c.limit = 5000.00
  c.billing_day = 2
  c.due_day = 10
  c.color = "#6C63FF"
end

inter = CreditCard.find_or_create_by!(user: user, name: "Inter Gold") do |c|
  c.last4 = "5678"
  c.brand = "mastercard"
  c.limit = 3000.00
  c.billing_day = 15
  c.due_day = 25
  c.color = "#F7B731"
end

# Definir cartão padrão
user.update!(default_credit_card: nubank)

# Buscar categorias
housing = user.categories.find_by(name: "Housing")
food = user.categories.find_by(name: "Food")
transport = user.categories.find_by(name: "Transport")
health = user.categories.find_by(name: "Health")
entertainment = user.categories.find_by(name: "Entertainment")
utilities = user.categories.find_by(name: "Utilities")
education = user.categories.find_by(name: "Education")
shopping = user.categories.find_by(name: "Shopping")
other = user.categories.find_by(name: "Other")

# Definir categoria padrão
user.update!(default_category: food)

# Receitas de exemplo (últimos 3 meses)
puts "Criando receitas de exemplo..."
3.times do |i|
  month_date = Date.current - i.months
  Income.find_or_create_by!(
    user: user,
    description: "Salário Mensal",
    date: month_date.change(day: 5)
  ) do |inc|
    inc.amount = 8500.00
    inc.income_type = "salary"
    inc.recurring = true
    inc.recurrence_day = 5
  end

  if i.zero?
    Income.find_or_create_by!(
      user: user,
      description: "Projeto Freelance",
      date: month_date.change(day: 15)
    ) do |inc|
      inc.amount = 2200.00
      inc.income_type = "freelance"
    end
  end
end

# Despesas de exemplo (mês atual + últimos 2)
puts "Criando despesas de exemplo..."
expenses_data = [
  { desc: "Aluguel",          amount: 1800.00, type: "fixed",    cat: housing,       recurring: true,  day: 5,  card: nil,    payment: "pix" },
  { desc: "Internet",         amount: 99.90,   type: "fixed",    cat: utilities,     recurring: true,  day: 10, card: nubank, payment: "credit_card" },
  { desc: "Netflix",          amount: 39.90,   type: "fixed",    cat: entertainment, recurring: true,  day: 12, card: nubank, payment: "credit_card" },
  { desc: "Academia",         amount: 89.90,   type: "fixed",    cat: health,        recurring: true,  day: 1,  card: nil,    payment: "pix" },
  { desc: "Supermercado",     amount: 450.00,  type: "variable", cat: food,          recurring: false, day: 8,  card: inter,  payment: "credit_card" },
  { desc: "Pedido no Rappi",  amount: 68.50,   type: "variable", cat: food,          recurring: false, day: 10, card: nubank, payment: "credit_card" },
  { desc: "Uber",             amount: 35.00,   type: "variable", cat: transport,     recurring: false, day: 9,  card: nil,    payment: "pix" },
  { desc: "Livraria",         amount: 120.00,  type: "variable", cat: education,     recurring: false, day: 11, card: nubank, payment: "credit_card" },
  { desc: "Roupas",           amount: 280.00,  type: "variable", cat: shopping,      recurring: false, day: 7,  card: inter,  payment: "credit_card" },
  { desc: "Conta de Luz",     amount: 145.00,  type: "variable", cat: utilities,     recurring: false, day: 10, card: nil,    payment: "boleto" },
  { desc: "Spotify",          amount: 19.90,   type: "fixed",    cat: entertainment, recurring: true,  day: 3,  card: nubank, payment: "credit_card" },
  { desc: "Farmácia",         amount: 87.30,   type: "variable", cat: health,        recurring: false, day: 6,  card: nil,    payment: "cash" },
  { desc: "Notebook",         amount: 320.00,  type: "variable", cat: education,     recurring: false, day: 5,  card: nil,    payment: "boleto", installments: 6 },
  { desc: "Sofá",             amount: 416.67,  type: "variable", cat: shopping,      recurring: false, day: 15, card: nil,    payment: "pix",    installments: 3 },
  { desc: "TV Samsung 55\"",  amount: 299.90,  type: "variable", cat: shopping,      recurring: false, day: 10, card: nubank, payment: "credit_card", installments: 6 }
]

# Pre-generate installment group IDs so all installments for the same purchase share one ID
installment_groups = expenses_data.each_with_object({}) do |e, h|
  h[e[:desc]] = SecureRandom.uuid if e[:installments]
end

year_start = Date.new(Date.current.year, 1, 1)
all_months = (0..11).map { |i| year_start >> i }

expenses_data.each do |e|
  total_inst = e[:installments]

  if total_inst
    # Installment expenses: start in January, one installment per month
    total_inst.times do |inst_i|
      month_date    = year_start >> inst_i
      expense_date  = month_date.change(day: e[:day])
      installment_num = inst_i + 1

      Expense.find_or_create_by!(user: user, description: e[:desc], date: expense_date) do |exp|
        exp.amount               = e[:amount]
        exp.expense_type         = e[:type]
        exp.category             = e[:cat]
        exp.credit_card          = e[:card]
        exp.recurring            = false
        exp.payment_method       = e[:payment]
        exp.total_installments   = total_inst
        exp.installment_number   = installment_num
        exp.installment_group_id = installment_groups[e[:desc]]
      end
    end
  elsif e[:recurring]
    # Recurring fixed expenses: all 12 months of the year
    all_months.each do |month_date|
      expense_date = month_date.change(day: e[:day])

      Expense.find_or_create_by!(user: user, description: e[:desc], date: expense_date) do |exp|
        exp.amount         = e[:amount]
        exp.expense_type   = e[:type]
        exp.category       = e[:cat]
        exp.credit_card    = e[:card]
        exp.recurring      = true
        exp.recurrence_day = e[:day]
        exp.payment_method = e[:payment]
      end
    end
  else
    # Variable one-off expenses: only months/days that have already passed
    all_months.each do |month_date|
      expense_date = month_date.change(day: e[:day])
      next if expense_date > Date.current

      Expense.find_or_create_by!(user: user, description: e[:desc], date: expense_date) do |exp|
        base               = e[:amount] + rand(-5.0..5.0).round(2)
        exp.amount         = [ base, 1.0 ].max
        exp.expense_type   = e[:type]
        exp.category       = e[:cat]
        exp.credit_card    = e[:card]
        exp.recurring      = false
        exp.payment_method = e[:payment]
      end
    end
  end
end

# Contas bancárias de exemplo
puts "Criando contas bancárias..."
BankAccount.find_or_create_by!(user: user, name: "Nubank Conta") do |b|
  b.bank_name     = "Nubank"
  b.account_type  = "checking"
  b.balance       = 3240.50
  b.rate_type     = "fixed"
  b.interest_rate = 0.0
  b.color         = "#6C63FF"
end

BankAccount.find_or_create_by!(user: user, name: "Inter Reserva") do |b|
  b.bank_name      = "Banco Inter"
  b.account_type   = "savings"
  b.balance        = 12800.00
  b.rate_type      = "cdi_percentage"
  b.cdi_multiplier = 100.0
  b.color          = "#F7B731"
end

BankAccount.find_or_create_by!(user: user, name: "Caixa Conta Corrente") do |b|
  b.bank_name     = "Caixa Econômica Federal"
  b.account_type  = "checking"
  b.balance       = 850.00
  b.rate_type     = "fixed"
  b.interest_rate = 0.0
  b.color         = "#00D4AA"
end

# Bens e patrimônio de exemplo
puts "Criando bens e patrimônio..."
Possession.find_or_create_by!(user: user, name: "Honda Civic 2021") do |p|
  p.possession_type = "vehicle"
  p.purchase_price  = 115_000.00
  p.current_value   = 98_000.00
  p.purchase_date   = Date.new(2021, 6, 15)
  p.color           = "#4A90D9"
end

Possession.find_or_create_by!(user: user, name: "MacBook Pro 14\"") do |p|
  p.possession_type = "electronics"
  p.purchase_price  = 18_500.00
  p.current_value   = 14_000.00
  p.purchase_date   = Date.new(2023, 2, 10)
  p.color           = "#8E8E93"
end

Possession.find_or_create_by!(user: user, name: "iPhone 15 Pro") do |p|
  p.possession_type = "electronics"
  p.purchase_price  = 9_299.00
  p.current_value   = 7_500.00
  p.purchase_date   = Date.new(2023, 11, 20)
  p.color           = "#00D4AA"
end

Possession.find_or_create_by!(user: user, name: "Sofá e Estante") do |p|
  p.possession_type = "furniture"
  p.purchase_price  = 4_200.00
  p.current_value   = 3_000.00
  p.purchase_date   = Date.new(2022, 4, 5)
  p.color           = "#FF9F43"
end

# Investimentos de exemplo
puts "Criando investimentos de exemplo..."
[
  { name: "Petrobras",        ticker: "PETR4",   type: "stock",  qty: 200,    avg: 38.50,  current: 41.20 },
  { name: "Vale",             ticker: "VALE3",   type: "stock",  qty: 100,    avg: 65.00,  current: 68.30 },
  { name: "Bitcoin",          ticker: "bitcoin", type: "crypto", qty: 0.025,  avg: 250000, current: 310000 },
  { name: "Ethereum",         ticker: "ethereum", type: "crypto", qty: 0.5,    avg: 12000,  current: 14500 },
  { name: "Tesouro Selic",    ticker: nil,       type: "fund",   qty: 1,      avg: 1580,   current: 1650 }
].each do |inv|
  Investment.find_or_create_by!(user: user, name: inv[:name]) do |i|
    i.ticker = inv[:ticker]
    i.investment_type = inv[:type]
    i.quantity = inv[:qty]
    i.average_price = inv[:avg]
    i.current_price = inv[:current]
    i.currency = "BRL"
  end
end

puts "\nSeeds concluídos!"
puts "Login: demo@monitoresuagrana.com.br / password"
