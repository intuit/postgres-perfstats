\prompt 'Enter new retention (days): ' new_retention 

select parent_table, retention from partman.part_config where parent_table like 'perfstat.%';

update partman.part_config set retention = :'new_retention' || ' days'
  where parent_table like 'perfstat.%';

select parent_table, retention from partman.part_config where parent_table like 'perfstat.%';
