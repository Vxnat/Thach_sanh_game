# AGENTS.md — Master Prompt & Hiến Pháp Kỹ Thuật Dự Án

> **Tên làm việc:** *Thạch Sanh: Dị Giới Kỳ Đàm*  
> **Phiên bản tài liệu:** `1.3` (Khép kín kỹ thuật & Sẵn sàng triển khai)  
> **Cảm hứng gốc:** *Thạch Sanh - Xứ sở diệu kỳ* (FPT Mobile, Java J2ME, 2006)  
> **Thể loại:** 2D Pixel Action-Platformer RPG — **Hybrid (70% Kỹ năng hành động – 30% Nhập vai)**  
> **Engine mục tiêu:** Godot Engine **4.3-stable** (`4.3.stable.official.77dcf97d8`)

Tài liệu này là **quy tắc bắt buộc** cho mọi AI agent và lập trình viên làm việc trên mã nguồn dự án. Mọi đoạn code, scene hoặc tài liệu sinh ra phải tuân thủ tuyệt đối các thông số dưới đây để tránh lệch kiến trúc hoặc dùng nhầm API Godot cũ.

---

## 1. Môi Trường & Quy Chuẩn Godot 4.3-stable (BẮT BUỘC)

- **Binary Godot trên máy:** `/home/ubuntu/.local/bin/godot` (Godot `4.3.stable.official.77dcf97d8`).
- **Renderer:** `gl_compatibility` (nhẹ, ổn định cho 2D pixel trên PC và dễ port sang Web/Android sau này).
- **Ngôn ngữ:** GDScript 2.0 với **Static Typing bắt buộc** cho mọi biến, tham số hàm và kiểu trả về:
  - Đúng: `var move_speed: float = 135.0`, `func apply_damage(amount: int, source: Node2D) -> void:`
  - Sai: `var move_speed = 135`, `func apply_damage(amount, source):`
- **Các API Godot 4.3 bắt buộc dùng / CẤM dùng:**
  - **CẤM dùng node `TileMap` cũ.** Bắt buộc dùng **`TileMapLayer`** (mỗi lớp đất, nền hậu cảnh, trang trí, nước/gai là một `TileMapLayer` riêng).
  - Bắt buộc dùng **`@export`** và **`@onready`** (Cấm `export` / `onready` kiểu Godot 3).
  - Di chuyển nhân vật/quái dùng **`CharacterBody2D`** với thuộc tính `velocity` sẵn có và gọi **`move_and_slide()` không tham số**.
  - Kết nối tín hiệu dùng **`signal_name.connect(callable)`** (Cấm `connect("signal_name", self, "method")`).
  - Hiệu ứng chuyển động/mờ/nhấp nháy dùng **`create_tween()`** (Cấm node `Tween` rời của Godot 3).
  - Các lớp dữ liệu dùng **`class_name`** kế thừa **`Resource`** (`.tres`), không hardcode bảng chỉ số dài trong script gameplay.
  - **`Hitstop` & `Pause` không bị treo:** Nếu làm `Hitstop` bằng cách giảm `Engine.time_scale`, **bắt buộc** dùng `get_tree().create_timer(duration, false, false, true)` (`ignore_time_scale = true`) hoặc đóng băng cục bộ `AnimationPlayer`/`State` thay vì `create_timer` mặc định. `PauseMenu` đặt `process_mode = Node.PROCESS_MODE_ALWAYS`, gameplay đặt `PROCESS_MODE_PAUSABLE`.

---

## 2. Thông Số Pixel-Perfect Khóa Cứng

Mọi cấu hình hiển thị trong `project.godot` và toàn bộ asset đều phải bám theo bảng chuẩn sau (xem chi tiết tại [ART_SPEC.md](docs/ART_SPEC.md)):

| Thông số | Giá trị khóa cứng | Ghi chú |
| --- | --- | --- |
| **Viewport Width x Height** | `384 x 216` | Tỷ lệ 16:9 chuẩn pixel; lưới ngang `24` ô, dọc `13.5` ô |
| **Window Override (Test PC)** | `1152 x 648` (`3x` mặc định), `1536 x 864` (`4x`), `1920 x 1080` (`5x`) | **Chỉ dùng bội số nguyên**; tuyệt đối không đặt cửa sổ test ở độ phân giải lẻ |
| **Stretch Mode** | `viewport` | Render đúng độ phân giải pixel gốc `384x216` trước khi phóng |
| **Stretch Scale Mode** | `integer` | Bắt buộc (`display/window/stretch/scale_mode = "integer"`) để không méo pixel trên màn hình lẻ |
| **Stretch Aspect** | `keep` | Giữ đúng tỷ lệ 16:9; GĐ 1–2 để viền đen gọn, GĐ 5 bọc **khung viền họa tiết tre trúc** lấp lề dư trên màn hình lẻ (`1366x768`, `1280x800`...); Full HD `1920x1080` (`5x`) tràn kín 100% |
| **Default Texture Filter** | `Nearest` | Chống mờ/nhòe hạt pixel |
| **Snap 2D Transforms to Pixel** | `true` | Chống rung giật pixel khi camera di chuyển |
| **Snap 2D Vertices to Pixel** | `true` | Giữ cạnh hình học khớp lưới pixel |
| **`Camera2D` bám nhân vật** | `Drag Margin` (tắt Smoothing) | Bật `drag_horizontal_enabled` & `drag_vertical_enabled` với vùng đệm đứng yên nhỏ ở giữa; đặt `position_smoothing_enabled = false` để nền pixel luôn nét căng, không giật nấc |
| **Kích thước 1 ô gạch (Tile Size)** | `16 x 16 px` | Chuẩn nền tảng địa hình |
| **Mật độ hạt pixel (Texel Density)** | `1:1` (`scale = Vector2(1, 1)`) | **Cấm** phóng to/thu nhỏ sprite bằng `scale` lẻ |

> **Quy ước lưới dọc `13.5` hàng tile (`216 px = 13 × 16 px + 8 px`):**
> - Màn hình `384x216` hiển thị `24` cột × `13` hàng tile trọn vẹn cộng thêm `8 px` phần dư theo chiều dọc.
> - Khi dựng màn bằng `TileMapLayer`, luôn đặt lớp đất bề mặt (`Topsoil`) nằm trọn trong vùng hiển thị chuẩn và để **lớp đất lấp đáy (`Sub-ground`)** hoặc viền bầu trời trên cùng hứng phần `8 px` lẻ này.
> - Đặt `Camera2D.limit_bottom` chia hết cho `16` (khớp đáy hàng tile cuối) kết hợp vùng đệm đất đáy ít nhất `1–2` hàng tile để camera không cắt cụt nửa mặt gạch đứng của người chơi.

> **Quy tắc đa kích thước:** Trong cùng mật độ hạt pixel `1:1`, quái nhỏ (`16x16`–`24x24`), nhân vật người (`32x32`–`48x48` hoặc khung `64x64`), vũ khí rời (`16x16`–`32x32`) và Boss lớn (`80x80`–`128x128`) dùng chung hoàn toàn bình thường miễn đều vẽ ở tỷ lệ `1:1`.

---

## 3. Cấu Trúc Thư Mục Dự Án (`res://`)

```text
res://
├── .gitignore                      # Bỏ qua .godot/, builds/, *.tmp, *.bak
├── AGENTS.md                       # File này — Hiến pháp kỹ thuật & Master Prompt
├── project.godot
├── default_bus_layout.tres         # Cấu hình kênh âm thanh: Master <- BGM, SFX, Ambience
├── docs/                           # Tài liệu thiết kế
│   ├── GDD.md                      # Luật chơi, cốt truyện, hệ thống RPG & Platformer
│   ├── ART_SPEC.md                 # Quy chuẩn pixel, Hand-Socket, nguồn Public + AI
│   └── ROADMAP.md                  # Lộ trình phát triển 5 giai đoạn
├── assets/                         # Tài nguyên thô & đã chuẩn hóa
│   ├── CREDITS_AND_LICENSES.md     # Theo dõi nguồn, tác giả & license mọi Asset Public
│   ├── sprites/
│   │   ├── player/                 # Thân Base + Tay trước tách lớp (không vẽ dính vũ khí)
│   │   ├── weapons/                # Ảnh vũ khí rời gắn vào khớp bàn tay
│   │   ├── relics/                 # Pháp bảo (Niêu cơm, Cung tên vàng, Đàn thần)
│   │   ├── enemies/                # Quái thường & Boss
│   │   ├── npcs/                   # Thợ rèn, Cô bé tạp hóa, Xa phu, Tiên ông, Lý Thông
│   │   ├── tilesets/               # Tile 16x16 (Làng, Rừng, Hang, Nước...)
│   │   └── vfx/                    # Spritesheet vệt chém (SlashVFX), bụi, hit spark, đom đóm
│   ├── audio/
│   │   ├── bgm/
│   │   └── sfx/
│   ├── fonts/                      # Font pixel hỗ trợ đầy đủ tiếng Việt có dấu
│   └── ui/                         # Icon HUD, khung thoại, nút bấm
├── data/                           # Dữ liệu tách rời code (dễ mở rộng cốt truyện & đồ)
│   ├── weapons/                    # WeaponData (.tres) từng vũ khí
│   │   └── profiles/               # Các profile dùng chung theo nhóm (Anim/Hitbox/VFX/Combo)
│   ├── items/                      # ItemData (.tres) — bình máu, nguyên liệu
│   ├── enemies/                    # EnemyData (.tres)
│   ├── dialogues/                  # Hội thoại & cắt cảnh (.json)
│   └── quests/                     # Nhiệm vụ & sự kiện mở dần (.json)
├── scenes/
│   ├── autoload/                   # Scene UI kèm Autoload (Transition, HUD nếu cần)
│   ├── player/                     # Player.tscn + Hand-Socket 3 lớp
│   ├── enemies/
│   ├── npcs/
│   ├── levels/
│   │   ├── hub_loc_tri.tscn        # Làng Lộc Trĩ (Hub trung tâm)
│   │   └── stages/                 # Các màn chơi (stage_01_rung_ven_lang.tscn...)
│   ├── props/                      # Rương, Đèn lồng, Nước sâu/Sông, Bệ chuyển màn, Xa phu
│   └── ui/                         # MainMenu, HUD, ShopUI, ForgeUI, DialogueBox, PauseMenu
└── scripts/
    ├── autoload/                   # Bộ Autoload (triển khai tăng dần theo ROADMAP)
    ├── player/                     # Player.gd (controller, di chuyển, SafeAnchor, trang bị)
    ├── enemies/                    # Script quái thường & Boss (DummyEnemy...)
    ├── components/                 # HealthComponent, StatsComponent, HitboxComponent, HurtboxComponent
    ├── states/                     # State Machine cho Player & Enemy
    ├── resources/                  # WeaponData, WeaponAnimProfile, WeaponHitboxProfile,
    │                               # SlashVfxProfile, WeaponComboProfile, ItemData, EnemyData
    └── systems/                    # Các hệ thống dùng chung (HazardRespawn, LootDrop, DayNightLight)
```

---

## 4. Kiến Trúc Kỹ Thuật Cốt Lõi

### 4.1. Bộ `Autoload` Singletons (Kiến trúc đích & Lộ trình đăng ký tăng dần)
> **Nguyên tắc thực dụng:** **Không khởi tạo ồ ạt cả 5 `Autoload` ngay từ bước đầu Giai đoạn 1.** Hãy để Giai đoạn 1 chạy gọn nhẹ và kiểm thử được ngay trên scene `test_sandbox.tscn` cục bộ; sang Giai đoạn 2 (khi dựng Hub Làng Lộc Trĩ, chuyển cảnh, Chu kỳ Sáng–Tối và Lưu game) mới lần lượt đăng ký và kết nối đủ bộ `Autoload` theo đúng thứ tự phụ thuộc dưới đây:

1. **`EventBus`** (`scripts/autoload/event_bus.gd`): Trung tâm phát tín hiệu toàn cục để các hệ thống giao tiếp lỏng lẻo (VD: `player_hp_changed`, `player_mp_changed`, `gold_changed`, `time_phase_changed`, `enemy_killed`, `story_flag_updated`, `dialogue_requested`).
2. **`GameState`** (`scripts/autoload/game_state.gd`): Giữ trạng thái phiên chơi hiện tại — chỉ số Thạch Sanh (Level, EXP, HP/MP, trang bị đang đeo), túi đai lưng (giới hạn bình máu/mana mang ra trận), kho đồ ở làng, Vàng, nguyên liệu, và từ điển `story_flags: Dictionary` (để mở rộng cốt truyện dần theo từng màn).
3. **`TimeManager`** (`scripts/autoload/time_manager.gd`): Chu kỳ ngày đêm trong game (~12–15 phút thực = 1 ngày đêm, chia 4 pha: *Bình minh, Ban ngày, Hoàng hôn, Ban đêm*). Phát tín hiệu đổi ánh sáng và kích hoạt hệ số cường hóa quái / tỷ lệ rơi đồ ban đêm.
4. **`SaveManager`** (`scripts/autoload/save_manager.gd`): Đọc/ghi file lưu JSON vào `user://save_slot_1.json` với các quy chuẩn an toàn dữ liệu bắt buộc:
   - **`save_version: int`:** Mọi file save đều mang số phiên bản (khởi đầu `1`). Khi cấu trúc dữ liệu thay đổi, `SaveManager` chạy hàm `migrate_save_data(data: Dictionary) -> Dictionary` nâng cấp tuần tự thay vì làm crash game cũ.
   - **Lưu theo ID chuỗi ổn định (`StringName`/`String`):** Tuyệt đối không lưu đường dẫn file `res://...` trong save. Mọi vũ khí, vật phẩm, màn chơi, NPC được ánh xạ qua ID ổn định (VD `"weapon_wooden_mallet"`, `"item_hp_pot"`, `"stage_01"`).
   - **Ghi nguyên tử & Backup xoay vòng:** Ghi ra `user://save_slot_1.tmp` trước, kiểm tra hợp lệ rồi mới thay thế `user://save_slot_1.json`, đồng thời giữ bản sao lưu gần nhất tại `user://save_slot_1.bak`.
   - **Phục hồi lỗi / Không tương thích:** Nếu `save_slot_1.json` bị hỏng JSON, thiếu khóa bắt buộc hoặc có `save_version` không hợp lệ, tự động thử nạp lại `save_slot_1.bak`; nếu cả hai đều không dùng được thì báo lỗi nhẹ cho người chơi và khởi tạo dữ liệu mặc định an toàn (không crash).
5. **`SceneRouter`** (`scripts/autoload/scene_router.gd`): Chuyển cảnh mượt (fade đen), đặt nhân vật đúng `SpawnPoint` theo ID cổng/Xa Phu, xử lý đưa về Làng Lộc Trĩ khi hết máu (`0 HP`).

### 4.2. Component Hóa Chiến Đấu & State Machine
- **Nhân vật chính duy nhất:** Chỉ có 1 nhân vật Nam **Thạch Sanh** (`Player.tscn`). Không sinh code chọn giới tính.
- **State Machine cho `Player`:** Node `StateMachine` quản lý các node con kế thừa `PlayerState`: `Idle`, `Run`, `Jump`, `Fall`, `Dash`, `Attack` (combo theo `combo_profile` + hệ thống không chiến riêng 4 nhóm: `HAMMER`/`AXE` có `Air Slam`, `BLADE` liên trảm hãm rơi `Air Stall`, `POLEARM` đâm xuống bật nảy `Pogo Bounce`), `RelicCast` (hiển thị linh ảnh Pháp bảo phát sáng tách khỏi `WeaponPivot`), `Hurt`, `Dead`.
- **Component tái sử dụng cho cả Player và Quái:**
  - `HealthComponent`: Quản lý `max_hp`, `current_hp`, `invincible` (`i-frames`), nhận sát thương và phát `died`.
  - `StatsComponent`: Quản lý Level, chỉ số nền, công kích từ vũ khí đang cầm, hệ số buff ban đêm (đối với quái).
  - `HitboxComponent` (`Area2D`): Mang dữ liệu `damage`, `knockback_force`, `hitstop_duration`, hình dạng/vị trí có thể cập nhật theo `hitbox_profile`.
  - `HurtboxComponent` (`Area2D`): Lắng nghe va chạm từ `HitboxComponent` khác phe và chuyển tiếp vào `HealthComponent`.
- **Quy tắc va chạm Layer/Mask cố định (Xuyên thân vật lý):**
  - Layer 1: `World` (đất, tường, sàn 1 chiều)
  - Layer 2: `PlayerBody` (**`collision_mask = 1`** — chỉ chạm `World`, **không** đẩy cứng vào `EnemyBody` để Dash xuyên quái và không bị kẹt trên đầu quái)
  - Layer 3: `EnemyBody` (**`collision_mask = 1`** — chỉ chạm `World`; sát thương chạm quái đi qua `Hitbox/Hurtbox`)
  - Layer 4: `PlayerHitbox`
  - Layer 5: `EnemyHitbox`
  - Layer 6: `Interactable` (NPC, rương, điểm chuyển màn)
  - Layer 7: `Hazard` (Sông sâu/vực thẳm trừ 80% Max HP, gai)
  - Layer 8: `Pickup` (Vàng, nguyên liệu văng nảy trên đất — tắt nam châm hút từ xa, Player phải chạy tới chạm trực tiếp mới nhặt; rơi xuống sông/vực Hazard sẽ chìm mất)

### 4.3. Kỹ Thuật Vũ Khí "Khớp Bàn Tay" 3 Lớp & Timeline Thống Nhất (Hand-Socket)
- Sprite thân Thạch Sanh **không vẽ sẵn vũ khí**, và tách làm **2 lớp hiển thị** (`BodyBaseSprite` + `FrontArmSprite`) để kẹp chặt cán vũ khí vào đúng bàn tay, giúp tay nắm đè lên cán thay vì vũ khí dán nổi giả tạo lên người.
- Bên trong `Player` có cụm node hiển thị chuẩn sau (**cấm dùng `AnimatedSprite2D` chạy độc lập hoặc `flip_h` rời cho từng sprite con**; lật hướng duy nhất bằng `VisualRoot.scale.x = 1.0` hoặc `-1.0`):
  ```text
  VisualRoot (Node2D)              # Đảo hướng bằng scale.x = 1.0 hoặc -1.0
  ├── BodyBaseSprite (Sprite2D)    # Đầu, thân, chân, cánh tay sau (z_index = 0)
  ├── WeaponPivot (Marker2D)       # Keyframe position, rotation_degrees, z_index (-1 sau thân / +1 trước thân)
  │   └── WeaponSprite (Sprite2D)  # centered = false, offset = -Vector2(grip_point_px)
  ├── FrontArmSprite (Sprite2D)    # Cánh tay & bàn tay trước (z_index = 2, luôn đè lên cán vũ khí)
  ├── SlashVFXSprite (Sprite2D)    # Spritesheet vệt chém điều khiển frame đồng bộ (z_index = 3)
  └── RelicVisual (Node2D)         # Linh ảnh Pháp bảo phát sáng lơ lửng cạnh người khi dùng RelicCast (z_index = 4)
  ```
- **1 Timeline điều khiển thống nhất (`AnimationPlayer`):** Một `AnimationPlayer` duy nhất trên `Player` điều khiển đồng bộ toàn bộ `BodyBaseSprite.frame`, `FrontArmSprite.frame`, `WeaponPivot` (`position`, `rotation_degrees`, `z_index`), `SlashVFXSprite` (`visible`, `frame`), và cửa sổ bật/tắt + kích thước/vị trí `HitboxComponent` (luôn có animation `RESET` tắt sạch hitbox và `SlashVFXSprite` khi bị ngắt đòn bởi `Hurt`/`Dash`/`Hazard`).
- **Không dùng chung 1 chuyển động cho mọi vũ khí:** `WeaponData (.tres)` gắn 5 nhóm cấu hình rõ ràng (`animation_profile`, `grip_offset`, `hitbox_profile`, `slash_vfx_profile`, `combo_profile`) và phân nhóm animation theo 4 họ: **`HAMMER`**, **`AXE`**, **`BLADE`**, **`POLEARM`** (gồm cả 2 nhánh không chiến `air_attack` và `air_down_attack`). Các vũ khí cùng nhóm tái sử dụng bộ animation của nhóm nhưng giữ chỉ số, điểm nắm cán, hitbox, VFX và tốc độ combo riêng.
- **Hiển thị Pháp bảo (`RelicCast`):** Khi tung *Cung Tên Vàng*, *Đàn Thần* hoặc *Niêu Cơm Thần*, không tháo/đổi vũ khí trên `WeaponPivot`; dùng `RelicVisual` chiếu linh ảnh Pháp bảo phát sáng lơ lửng cạnh Thạch Sanh.
- Xem chi tiết tọa độ, quy tắc `z_index` và thông số mẫu trong [ART_SPEC.md](docs/ART_SPEC.md).

### 4.4. Chuẩn Điều Khiển (`Input Map` tách rời phím cứng)
Mọi script chỉ gọi tên action trong `InputMap`, **tuyệt đối không hardcode mã phím (`KEY_...`) trực tiếp trong gameplay scripts** (để sau này gắn nút cảm ứng Mobile hoặc đổi phím cực dễ):
- `move_left`, `move_right`, `move_up`, `move_down` (`A`/`D`/`W`/`S` hoặc Phím mũi tên + D-Pad/Left Stick)
- `jump` (`Space` / `Z` / Nút A tay cầm)
- `dash` (`Shift` / `K` / Nút B hoặc R1 tay cầm)
- `attack` (`J` / `X` / Chuột trái / Nút X tay cầm)
- `relic_1` (`U` / `C` — Cung Tên Vàng), `relic_2` (`I` / `V` — Đàn Thần)
- `heal_pot` (`Q` — Niêu Cơm Thần), `belt_hp` (`1` — Bình HP đai lưng), `belt_mp` (`2` — Bình MP đai lưng)
- `interact` (`E` / `F` / Nút Y tay cầm — Nói chuyện NPC, vào nhà, mở rương, đi Xa Phu). **Cấm gán `W` cho `interact` để tránh trùng với `move_up`.**
- `pause` (`Esc`)

### 4.5. Quy Tắc Đặc Thù Gameplay (Không được phép làm khác)
1. **Rơi xuống sông/vực sâu (`Hazard`, Layer 7) & `SafeAnchor`:**
   - **Mỗi lần rơi chỉ tính sát thương đúng 1 lần duy nhất:** Dùng cờ khóa `_is_resolving_hazard: bool`. Sát thương môi trường trừ thẳng **`int(ceil(max_hp * 0.8))`** (80% Máu tối đa) và **bỏ qua `i-frames` chiến đấu** trước đó để tránh trường hợp nhân vật vừa bị quái đánh văng rồi lọt xuống vực không bị trừ máu hoặc rớt xuyên đáy map.
   - **Ngăn kích hoạt lặp sau khi teleport:** Khi kích hoạt hazard phải triệt tiêu `velocity = Vector2.ZERO`, hủy mọi trạng thái `Dash`/`Attack` đang dở (chạy `RESET` cho `AnimationPlayer`), dịch chuyển ngay về `SafeAnchor` và chỉ mở khóa `_is_resolving_hazard` sau khi `Player` đã thoát hoàn toàn khỏi vùng `Area2D` của hazard ở physics frame an toàn kế tiếp.
   - **Chỉ lưu `SafeAnchor` tại vị trí thực sự an toàn:** Chỉ cập nhật `SafeAnchor` khi `is_on_floor()` ổn định trên **địa hình tĩnh (`TileMapLayer`)**, cả hai tia kiểm tra rìa chân trái và rìa chân phải (`RayCast2D`) đều chạm nền đất an toàn, không đứng trên bục di chuyển/bục sập và không nằm trong vùng đệm sát `Hazard`.
   - **Thứ tự xử lý bắt buộc:** `Khóa hazard` → `Trừ 80% Max HP` → `Kiểm tra current_hp <= 0` (nếu `<= 0` chuyển thẳng sang trạng thái `Dead` về **Làng Lộc Trĩ**) → `Nếu còn sống: đặt lại global_position = SafeAnchor + velocity = Vector2.ZERO` → `Kích hoạt i-frames ngắn (1.2s)` → `Mở khóa hazard khi thoát vùng nguy hiểm`.
2. **Hết máu (`0 HP`):** Tỉnh dậy tại Nhà Tranh ở **Làng Lộc Trĩ**, giữ nguyên Level, vũ khí, pháp bảo và nguyên liệu; chỉ trừ nhẹ một phần Vàng đang mang (mặc định 15%).
3. **Túi đai lưng giới hạn bình thuốc:** Mua thoải mái ở **Cô Bé Tạp Hóa** nhưng khi rời làng chỉ mang được tối đa số ô đai lưng (2–3 bình HP/MP); phần dư nằm trong rương tại Làng.
4. **Hồi MP khi đánh quái:** Mỗi nhát đánh cận chiến trúng quái hồi nhẹ **`2–3 MP`** (khuyến khích áp sát chiến đấu để tích MP dùng Pháp bảo).
5. **Rương bí mật mở 1 lần & Hồi sinh quái:** Quái thường hồi sinh khi vào lại màn để cày cấp/đồ; riêng **Rương giấu ở ngách ẩn chỉ mở 1 lần duy nhất** (lưu danh sách ID `opened_chests` vào `SaveManager`).
6. **Cốt truyện dữ liệu rời:** Không viết cứng đoạn hội thoại trong script cảnh; mọi NPC và cắt cảnh đọc theo `dialogue_id` từ `data/dialogues/*.json` và kiểm tra điều kiện qua `GameState.story_flags`.

---

## 5. Master Prompt Rút Gọn (Dùng để giao việc cho AI ở các phiên sau)

Khi bắt đầu một phiên làm việc mới (tạo tính năng, viết script, dựng màn), hãy dán hoặc trích dẫn đoạn sau cho AI:

```text
Bạn là Senior Godot 4.3 Engineer làm dự án "Thạch Sanh: Dị Giới Kỳ Đàm" — game 2D Pixel Action-Platformer RPG (Hybrid 70% hành động / 30% nhập vai), lấy cảm hứng từ bản Java J2ME 2006 "Thạch Sanh - Xứ sở diệu kỳ".

BẮT BUỘC TUÂN THỦ AGENTS.md, docs/GDD.md, docs/ART_SPEC.md, docs/ROADMAP.md:
1. Engine: Godot 4.3-stable (gl_compatibility), GDScript 2.0 Static Typing 100%, dùng TileMapLayer (CẤM TileMap cũ), CharacterBody2D + move_and_slide(), @export, @onready, create_tween(), signal.connect(). Hitstop giảm time_scale phải dùng create_timer(..., true) (ignore_time_scale = true); PauseMenu dùng PROCESS_MODE_ALWAYS.
2. Pixel-perfect khóa cứng: Viewport 384x216 (24x13.5 ô tile 16x16), Stretch Mode=viewport, Scale Mode=integer, Aspect=keep, Window Test PC chỉ dùng bội số nguyên (3x 1152x648 / 4x 1536x864 / 5x 1920x1080), Texture Filter=Nearest, Snap 2D Transforms/Vertices to Pixel=true, Camera2D dùng Drag Margin (position_smoothing_enabled=false), mật độ hạt 1:1 (cấm scale sprite lẻ). Màn hình lẻ GĐ 5 bọc khung viền tre trúc.
3. Chỉ có 1 nhân vật Nam Thạch Sanh. Vũ khí dùng Hand-Socket 3 lớp (BodyBaseSprite + WeaponPivot/WeaponSprite + FrontArmSprite + SlashVFXSprite) đồng bộ trên 1 timeline AnimationPlayer; dữ liệu dùng WeaponData (.tres) với 5 profile (animation_profile theo 4 nhóm HAMMER/AXE/BLADE/POLEARM, grip_offset, hitbox_profile, slash_vfx_profile, combo_profile). Không chiến tách riêng 4 dòng (chỉ HAMMER/AXE có Air Slam; BLADE hãm rơi Air Stall; POLEARM bật nảy Pogo). Pháp bảo dùng RelicVisual linh ảnh phát sáng tách khỏi WeaponPivot. Layer 1–8 cố định (PlayerBody/EnemyBody đều collision_mask=1 xuyên thân nhau).
4. Giữ đúng luật đặc thù: chu kỳ Sáng-Chiều-Tối ~12-15 phút; rơi sông/vực khóa 1 lần trừ 80% Max HP (còn sống về SafeAnchor an toàn rồi mới bật i-frames, 0 HP về Làng Lộc Trĩ); chém trúng hồi 2-3 MP; rương bí mật chỉ mở 1 lần; giới hạn bình máu đai lưng; SaveManager có save_version, ID chuỗi ổn định và backup .bak.
5. Mọi Input đọc qua InputMap (interact dùng E/F, không trùng W; cấm hardcode phím). Triển khai tăng dần theo từng bước nhỏ trong docs/ROADMAP.md, ưu tiên chạy được trước khi mở rộng Autoload.

Hãy kiểm tra xem dự án đang ở bước nào trong docs/ROADMAP.md và thực hiện đúng bước tiếp theo, giữ code gọn nhẹ, dễ bảo trì.
```
