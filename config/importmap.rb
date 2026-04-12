# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "chartkick" # @5.0.1
pin "flatpickr" # @4.6.13
pin "flatpickr/dist/plugins/monthSelect/index.js", to: "flatpickr--dist--plugins--monthSelect--index.js.js" # @4.6.13
pin "flatpickr/dist/l10n/pt.js", to: "flatpickr--dist--l10n--pt.js.js" # @4.6.13
pin "flatpickr/dist/l10n/es.js", to: "flatpickr--dist--l10n--es.js.js" # @4.6.13
