# Seeds — FinTrack
# Creates a demo user with realistic sample data for development

puts "Creating demo user..."

user = User.find_or_create_by!(email: "demo@fintrack.dev") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
  u.name = "Demo User"
  u.currency = "BRL"
end

puts "User: #{user.email} (categories auto-created via callback)"

# Sample credit cards
puts "Creating credit cards..."
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

# Get categories
housing = user.categories.find_by(name: "Housing")
food = user.categories.find_by(name: "Food")
transport = user.categories.find_by(name: "Transport")
health = user.categories.find_by(name: "Health")
entertainment = user.categories.find_by(name: "Entertainment")
utilities = user.categories.find_by(name: "Utilities")
education = user.categories.find_by(name: "Education")
shopping = user.categories.find_by(name: "Shopping")
other = user.categories.find_by(name: "Other")

# Sample incomes (last 3 months)
puts "Creating sample incomes..."
3.times do |i|
  month_date = Date.current - i.months
  Income.find_or_create_by!(
    user: user,
    description: "Monthly Salary",
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
      description: "Freelance Project",
      date: month_date.change(day: 15)
    ) do |inc|
      inc.amount = 2200.00
      inc.income_type = "freelance"
    end
  end
end

# Sample expenses (current month + last 2)
puts "Creating sample expenses..."
expenses_data = [
  { desc: "Rent",           amount: 1800.00, type: "fixed",    cat: housing,       recurring: true,  day: 5,  card: nil },
  { desc: "Internet",       amount: 99.90,   type: "fixed",    cat: utilities,     recurring: true,  day: 10, card: nubank },
  { desc: "Netflix",        amount: 39.90,   type: "fixed",    cat: entertainment, recurring: true,  day: 12, card: nubank },
  { desc: "Gym",            amount: 89.90,   type: "fixed",    cat: health,        recurring: true,  day: 1,  card: nil },
  { desc: "Supermarket",    amount: 450.00,  type: "variable", cat: food,          recurring: false, day: 8,  card: inter },
  { desc: "Rappi Order",    amount: 68.50,   type: "variable", cat: food,          recurring: false, day: 14, card: nubank },
  { desc: "Uber",           amount: 35.00,   type: "variable", cat: transport,     recurring: false, day: 9,  card: nil },
  { desc: "Book Store",     amount: 120.00,  type: "variable", cat: education,     recurring: false, day: 11, card: nubank },
  { desc: "Clothing",       amount: 280.00,  type: "variable", cat: shopping,      recurring: false, day: 18, card: inter },
  { desc: "Electricity",    amount: 145.00,  type: "fixed",    cat: utilities,     recurring: true,  day: 20, card: nil },
  { desc: "Spotify",        amount: 19.90,   type: "fixed",    cat: entertainment, recurring: true,  day: 3,  card: nubank },
  { desc: "Pharmacy",       amount: 87.30,   type: "variable", cat: health,        recurring: false, day: 16, card: nil },
]

3.times do |i|
  month_date = Date.current - i.months
  expenses_data.each do |e|
    Expense.find_or_create_by!(
      user: user,
      description: e[:desc],
      date: month_date.change(day: e[:day])
    ) do |exp|
      base = e[:amount] + rand(-30.0..30.0).round(2)
      exp.amount = [base, 1.0].max
      exp.expense_type = e[:type]
      exp.category = e[:cat]
      exp.credit_card = e[:card]
      exp.recurring = e[:recurring]
      exp.recurrence_day = e[:recurring] ? e[:day] : nil
    end
  end
end

# Sample investments
puts "Creating sample investments..."
[
  { name: "Petrobras",        ticker: "PETR4",   type: "stock",  qty: 200,    avg: 38.50,  current: 41.20 },
  { name: "Vale",             ticker: "VALE3",   type: "stock",  qty: 100,    avg: 65.00,  current: 68.30 },
  { name: "Bitcoin",          ticker: "bitcoin", type: "crypto", qty: 0.025,  avg: 250000, current: 310000 },
  { name: "Ethereum",         ticker: "ethereum",type: "crypto", qty: 0.5,    avg: 12000,  current: 14500 },
  { name: "Tesouro Selic",    ticker: nil,       type: "fund",   qty: 1,      avg: 1580,   current: 1650 },
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

puts "\nSeeding complete!"
puts "Login: demo@fintrack.dev / password123"
