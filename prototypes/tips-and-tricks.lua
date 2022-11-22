data:extend{
{
  type = "tips-and-tricks-item-category",
  name = "power-overload",
  is_title = true,
  order = "d-[electric-network]-b",
},
{
  type = "tips-and-tricks-item",
  name = "po-main",
  category = "power-overload",
  is_title = true,
  order = "a",
  trigger = {type = "build-entity", entity = "small-electric-pole", match_type_only = true}
},
{
  type = "tips-and-tricks-item",
  name = "po-transformer",
  tag = "[entity=po-transformer]",
  category = "power-overload",
  indent = 1,
  order = "b",
  dependencies = {"po-main"},
},
{
  type = "tips-and-tricks-item",
  name = "po-fuse",
  tag = "[entity=po-medium-electric-fuse]",
  category = "power-overload",
  indent = 1,
  order = "c",
  dependencies = {"po-main"},
},
{
  type = "tips-and-tricks-item",
  name = "po-pole-connections",
  tag = "[entity=big-electric-pole]",
  category = "power-overload",
  indent = 1,
  order = "d",
  dependencies = {"po-main"},
},

}
