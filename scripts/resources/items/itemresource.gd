extends Resource

class_name ItemResource

## The name of the item.
@export var item_name: String
## The point value of this item.
@export var item_cost: int = 0
## The mesh used for this item.
@export var item_mesh: Mesh
## The type of collision shape this item will use as a pickup.
@export var pickup_collision_shape: Shape3D
## Whether or not this item can be bought in the store.
@export var can_purchase: bool = item_cost>0
