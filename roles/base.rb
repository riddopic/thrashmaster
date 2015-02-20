name        'base'
description 'Example Base Role'

default_attributes chef_client: { init_style: 'none' }

run_list(
  'recipe[chef-client::delete_validation]',
  'recipe[cron]',
  'recipe[chef-client]'
)
