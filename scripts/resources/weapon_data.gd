class_name WeaponData
extends Resource
## Dữ liệu hoàn chỉnh cho 1 cây vũ khí (tách rời code, dùng ID chuỗi ổn định khi lưu Save).

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var weapon_texture: Texture2D

@export_group("Chỉ số & Kinh tế")
@export var bonus_atk: int = 10
@export var crit_chance: float = 0.05
@export var buy_price: int = 0
@export var craft_recipe: Dictionary = {}

@export_group("Khớp Bàn Tay (Hand-Socket)")
@export var grip_point_px: Vector2i = Vector2i(6, 18)
@export var base_rotation_deg: float = -45.0

@export_group("5 Profile Kỹ thuật")
@export var animation_profile: WeaponAnimProfile
@export var hitbox_profile: WeaponHitboxProfile
@export var slash_vfx_profile: SlashVfxProfile
@export var combo_profile: WeaponComboProfile

