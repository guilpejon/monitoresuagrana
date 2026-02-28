import "@hotwired/turbo-rails"
import "controllers"

import Chartkick from "chartkick"
// window.Chart is the UMD exports object; .Chart is the actual Chart class
Chartkick.use(window.Chart.Chart)
