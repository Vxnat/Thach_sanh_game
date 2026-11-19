class_name ItemData
extends Resource
## Dữ liệu vật phẩm (thuốc hồi phục, nguyên liệu rèn, vật phẩm cốt truyện) dùng ID ổn định.

enum ItemCategory { CONSUMABLE_HP, CONSUMABLE_MP, MATERIAL, KEY_ITEM }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var category: ItemCategory = ItemCategory.MATERIAL
@export var icon: Texture2D
@export var heal_amount: int = 0
@export var buy_price: int = 25
@export var sell_price: int = 10

