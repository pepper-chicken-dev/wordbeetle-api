require 'pagy/extras/items'
require 'pagy/extras/overflow'

Pagy::DEFAULT[:items] = 20
Pagy::DEFAULT[:max_items] = 100
Pagy::DEFAULT[:items_param] = :per_page
Pagy::DEFAULT[:overflow] = :empty_page
