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
  { desc: "Sofá",             amount: 416.67,  type: "variable", cat: shopping,      recurring: false, day: 15, card: nil,    payment: "pix",    installments: 3 }
]

# Pre-generate installment group IDs so all installments for the same purchase share one ID
installment_groups = expenses_data.each_with_object({}) do |e, h|
  h[e[:desc]] = SecureRandom.uuid if e[:installments]
end

3.times do |i|
  month_date = Date.current - i.months
  expenses_data.each do |e|
    # Variable expenses cannot be future-dated; skip if the day hasn't arrived yet this month
    expense_day = e[:day]
    next if i == 0 && e[:type] == "variable" && expense_day > Date.current.day

    # For installment expenses each month = one installment; skip months beyond total
    total_inst = e[:installments]
    if total_inst
      installment_num = total_inst - i
      next if installment_num < 1
    end

    Expense.find_or_create_by!(
      user: user,
      description: e[:desc],
      date: month_date.change(day: expense_day)
    ) do |exp|
      base = e[:amount] + rand(-5.0..5.0).round(2)
      exp.amount = [ base, 1.0 ].max
      exp.expense_type = e[:type]
      exp.category = e[:cat]
      exp.credit_card = e[:card]
      exp.recurring = e[:recurring]
      exp.recurrence_day = e[:recurring] ? e[:day] : nil
      exp.payment_method = e[:payment]
      if total_inst
        exp.total_installments = total_inst
        exp.installment_number = installment_num
        exp.installment_group_id = installment_groups[e[:desc]]
      end
    end
  end
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
