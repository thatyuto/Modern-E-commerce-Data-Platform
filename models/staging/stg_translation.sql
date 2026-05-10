-- extract data from here

select 
    string_field_0,
    string_field_1
from {{ source('olist_raw','product_category_name_translation')}}
