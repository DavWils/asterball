extends Resource

class_name ItemResource

## The name of the item.
@export var item_name: String
## The cost of this item. If item is -1, not buyable.
@export var item_cost: int = -1
## The mesh used for this item.
@export var item_mesh: Mesh
## The type of collision shape this item will use as a pickup.
@export var pickup_collision_shape: Shape3D
