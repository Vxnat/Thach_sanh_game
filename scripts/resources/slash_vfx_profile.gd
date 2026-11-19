class_name SlashVfxProfile
extends Resource
## Cấu hình vệt sáng chém (SlashVFXSprite) hiển thị đồng bộ theo vũ khí, luôn giữ scale 1:1.

@export var vfx_texture: Texture2D
@export var hframes: int = 3
@export var vframes: int = 4
@export var tint_color: Color = Color(1.0, 0.94, 0.72, 0.9)
@export var local_offset: Vector2 = Vector2(14.0, -16.0)
@export var rotation_deg: float = 0.0

