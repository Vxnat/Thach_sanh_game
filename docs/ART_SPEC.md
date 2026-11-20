# Quy Chuẩn Đồ Họa, Hand-Socket & Asset Pipeline (`ART_SPEC`)

> **Phiên bản tài liệu:** `1.3` (Khép kín kỹ thuật & Sẵn sàng triển khai)

Tài liệu này khóa chuẩn hiển thị Pixel Art trên Godot 4.3, quy chuẩn **Hand-Socket 3 lớp** đồng bộ timeline, và quy trình xử lý **Asset Public + Asset AI** để game vừa sắc nét, không lỗi viền màu, vừa giữ đồng bộ tạo hình Thạch Sanh qua mọi animation.

---

## 1. Quy Chuẩn Kích Thước, Integer Scale & Lưới `13.5` Hàng Tile

### 1.1. Viewport, Stretch Scale Mode = `integer` và Độ phân giải Test chuẩn
- **Viewport gốc:** `384 x 216 px` (tỷ lệ 16:9).
- **Lưới địa hình (Tile):** `16 x 16 px` (`24` ô ngang × `13.5` ô dọc).
- **Cấu hình Stretch bắt buộc trong Godot 4.3:**
  - `display/window/stretch/mode = "viewport"`
  - `display/window/stretch/scale_mode = "integer"` *(chỉ phóng theo số nguyên `1x, 2x, 3x, 4x, 5x...`; trên màn hình có tỷ lệ lẻ như `1366x768` hoặc `1280x800`, engine sẽ giữ nguyên tỷ lệ nguyên lớn nhất kèm phần lề dư thay vì kéo giãn méo hạt pixel)*.
  - `display/window/stretch/aspect = "keep"`
  - **Khung viền họa tiết tre trúc cho màn hình lẻ:** Trong Giai đoạn 1–2 giữ viền đen mặc định cho gọn nhẹ; sang Giai đoạn 5 (hoàn thiện UI) sẽ bọc khung game `384x216` (`SubViewportContainer`/`SubViewport` giữ nguyên bội số `integer` đặt giữa `Control` toàn cửa sổ) bằng **khung viền họa tiết đốt tre / hoa văn cổ Việt Nam** trầm dịu lấp hai bên lề dư, còn màn hình Full HD `1920x1080` (`5x`) vẫn tự động tràn kín 100% không lộ viền.
  - Texture Filter mặc định: **`Nearest`**, bật **`Snap 2D Transforms to Pixel`** và **`Snap 2D Vertices to Pixel`**.

| Hệ số phóng | Kích thước cửa sổ PC | Mục đích sử dụng |
| --- | --- | --- |
| `1x` (Gốc) | `384 x 216` | Tham chiếu thiết kế asset & lưới camera |
| `3x` *(Mặc định Debug)* | `1152 x 648` | Cửa sổ test PC gọn nhẹ, nét pixel vuông 100% |
| `4x` | `1536 x 864` | Cửa sổ test rộng trên màn hình 2K/Full HD |
| `5x` | `1920 x 1080` | Toàn màn hình Full HD khớp khít 100% không viền |

*(Lưu ý: Không dùng độ phân giải test `1280 x 720` vì `720 / 216 = 3.333` không phải số nguyên; khi chạy `integer` ở 720p game vẫn chỉ hiển thị khung `3x = 1152x648` nằm lọt giữa màn hình).*

### 1.2. Cách xử lý `13.5` hàng tile theo chiều dọc & Thiết lập `Camera2D`
Vì `216` chia `16` bằng `13.5` (dư `8 px`), nếu thiết kế màn chơi thiếu tính toán sẽ dễ bị cắt nửa viên gạch ở mép dưới màn hình:
- **Quy tắc dựng đất đáy:** Vùng mặt đất chính mà nhân vật đi đứng (`Topsoil`) luôn đặt ở tọa độ lưới chia hết cho `16`. Hàng đất đệm bên dưới (`Sub-ground` tối màu hoặc rễ cây/nước) sẽ hứng phần `8 px` thừa ở mép đáy khi camera đứng yên.
- **Quy tắc đặt `Camera2D.limit_bottom`:** Luôn đặt `limit_bottom` khớp bội số `16` ở **đáy của lớp đất đệm** (ví dụ đáy hàng tile thứ 14 = `224 px` hoặc sâu hơn một lớp gạch), tránh đặt sát ngay dưới chân nhân vật làm người chơi không thấy mặt đất.
- **Thiết lập `Camera2D` bám nhân vật (`Drag Margin`):** Bật `drag_horizontal_enabled = true` và `drag_vertical_enabled = true` (với vùng đệm đứng yên nhỏ ở giữa kiểu *Mario / Celeste*), đồng thời đặt **`position_smoothing_enabled = false`**. Khi nhích nhẹ 1–2 bước tại chỗ camera đứng yên hoàn toàn; khi di chuyển qua rìa vùng đệm, camera cuốn theo dứt khoát khớp `Snap 2D Transforms to Pixel = true`, giữ nền pixel sắc nét không bị rung giật.
- **Vùng HUD trên cùng (`24–32 px`):** Thanh máu, mana, đồng hồ ngày đêm đặt gọn vào `2` hàng trên cùng (phần bầu trời thoáng phía trên đầu nhân vật) để tối đa không gian quan sát nhảy và chiến đấu.

### 1.3. Quy tắc mật độ hạt pixel `1:1` (No Mixels)
- Mọi sprite giữ nguyên **`scale = Vector2(1, 1)`** (không kéo giãn ảnh bằng `scale` lẻ).
- **Đa kích thước sống chung mượt mà ở tỷ lệ `1:1`:**
  - Vật phẩm rơi, bình máu, đạn: `12x12` – `16x16 px`
  - Quái nhỏ (sóc, rắn, dơi, slime tà khí): `16x16` – `24x24 px`
  - Vũ khí rời (búa, rìu, đao, thương): `16x16` – `32x32 px`
  - Nhân vật người (**Thạch Sanh, NPC**): Chiều cao thân người thực tế khoảng `26–32 px`, đặt trong khung frame vuông thống nhất `48x48 px` (hoặc `64x64 px` nếu cần biên độ vung tay lớn).
  - Quái vừa (Yêu tinh gác rừng, Khỉ đá): `32x32` – `48x48 px`
  - **Boss lớn** (Chằn Tinh, Đại Hỏa Hầu, Đại Bàng, Thuồng Luồng): `80x80` – `128x128 px` (to gấp 3–4 lần Thạch Sanh trên màn hình `384x216`).

---

## 2. Nâng Cấp Kỹ Thuật Hand-Socket 3 Lớp & Timeline Thống Nhất

Để thay được hàng chục vũ khí tại tiệm **Anh Thợ Rèn** mà bàn tay vẫn **nắm thật lên cán vũ khí** (không bị vũ khí dán đè giả tạo lên người, cũng không bị đơ khi đánh):

### 2.1. Phân chia 3 lớp hiển thị & Thứ tự `z_index`
1. **`BodyBaseSprite (Sprite2D, z_index = 0)`:** Chứa đầu, thân, hai chân và cánh tay sau của Thạch Sanh (vẽ trống phần tay trước để không bị chồng nét).
2. **`WeaponPivot (Marker2D)` → `WeaponSprite (Sprite2D)`:**
   - Gắn vũ khí rời vào giữa cấu trúc lớp người.
   - Tùy góc vung ở từng keyframe trong `AnimationPlayer`, `WeaponPivot.z_index` đổi động:
     - **`z_index = -1`** (nằm sau thân) ở các frame vác búa sau lưng / lấy đà phía sau vai.
     - **`z_index = +1`** (nằm trước thân, nhưng **luôn dưới `FrontArmSprite`**) ở các frame vung chém phía trước mặt.
3. **`FrontArmSprite (Sprite2D, z_index = 2)`:** Chứa riêng cánh tay trước & nắm bàn tay (cùng kích thước canvas `48x48` hoặc `64x64` khớp tọa độ với `BodyBaseSprite`). Vì có `z_index = 2 > 1`, bàn tay trước **luôn nằm đè lên cán vũ khí** tạo cảm giác cầm nắm chắc chắn tự nhiên 100%.
4. **`SlashVFXSprite (Sprite2D, z_index = 3)`:** Vệt sáng chém dùng spritesheet `Sprite2D` (không dùng `AnimatedSprite2D` chạy độc lập).

### 2.2. Cấu trúc Node chuẩn cho `Player.tscn`
```text
Player (CharacterBody2D)
├── CollisionShape2D               # Capsule/Rectangle nhỏ gọn (~12x26 px)
├── VisualRoot (Node2D)            # ĐẢO HƯỚNG DUY NHẤT bằng scale.x = 1.0 hoặc -1.0
│   ├── BodyBaseSprite (Sprite2D)  # z_index = 0 (Thân, đầu, chân, tay sau)
│   ├── WeaponPivot (Marker2D)     # Keyframe position, rotation_degrees, z_index (-1 hoặc +1)
│   │   └── WeaponSprite (Sprite2D)# centered = false, offset = -Vector2(grip_point_px)
│   ├── FrontArmSprite (Sprite2D)  # z_index = 2 (Cánh tay & nắm tay đè lên cán)
│   ├── SlashVFXSprite (Sprite2D)  # z_index = 3 (Vệt chém)
│   └── RelicVisual (Node2D)       # z_index = 4 (Linh ảnh Pháp bảo phát sáng lơ lửng khi thi triển)
├── AnimationPlayer                # 1 TIMELINE DUY NHẤT điều khiển đồng bộ tất cả
├── HitboxComponent (Area2D)       # Bật/tắt & đổi shape/vị trí theo animation & hitbox_profile
├── HurtboxComponent (Area2D)
├── HealthComponent (Node)
├── StatsComponent (Node)
└── StateMachine (Node)
```
> **Quy tắc 1 Timeline thống nhất:** Toàn bộ `BodyBaseSprite.frame`, `FrontArmSprite.frame`, `WeaponPivot` (`position`, `rotation_degrees`, `z_index`), `SlashVFXSprite` (`visible`, `frame`) và trạng thái bật/tắt `HitboxComponent` **bắt buộc điều khiển chung trên 1 `AnimationPlayer`**. Nhờ đó khi thay đổi `speed_scale` theo `WeaponAnimProfile` hoặc đóng băng frame lúc `Hitstop`, mọi lớp khớp chặt tuyệt đối từng mili-giây. Luôn tạo animation `RESET` tắt `HitboxComponent` và ẩn `SlashVFXSprite` để tránh kẹt hitbox khi đòn đánh bị ngắt bởi `Hurt`/`Dash`/`Hazard`.
> **Pháp bảo tách khỏi `WeaponPivot`:** Khi tung *Cung Tên Vàng* hoặc *Đàn Thần*, Thạch Sanh chỉ thực hiện động tác phất tay ngắn trên `BodyBase`/`FrontArm` trong khi `RelicVisual` triệu hồi linh ảnh Pháp bảo phát hào quang lơ lửng cạnh người, không tháo vũ khí đang cầm và không phải vẽ bộ tay kéo cung/gảy đàn riêng.

### 2.3. Cách tính & lưu `grip_offset` cho từng vũ khí
- Trong ảnh gốc mỗi vũ khí (ví dụ `24x24 px` hoặc `32x32 px`), giữ chuẩn hướng vẽ thống nhất (VD: cán ở góc dưới-trái, mũi/đầu vũ khí hướng lên trên-phải `45°` — hoặc dựng thẳng đứng hướng lên `0°`).
- Trên `WeaponSprite`, đặt **`centered = false`**.
- Trong `WeaponData (.tres)`, lưu **`grip_point_px: Vector2i`** (tọa độ pixel chính tâm nắm tay trên cán vũ khí, tính từ góc trên-trái `(0, 0)` của ảnh) và **`base_rotation_deg: float`** (góc bù nếu ảnh vẽ chéo `45°` để quy về trục chuẩn của socket).
- Khi trang bị vũ khí:
  `WeaponSprite.offset = -Vector2(weapon_data.grip_point_px)`
  `WeaponSprite.rotation_degrees = weapon_data.base_rotation_deg`
- Toàn bộ phép xoay khi vung tay lúc đó tác động lên node cha `WeaponPivot`, đảm bảo **mọi cây búa/rìu/kiếm/thương dài ngắn khác nhau đều quay đúng quanh điểm bàn tay nắm cán**.

### 2.4. Không dùng chung 1 chuyển động: Bảng animation & Không chiến 4 nhóm vũ khí
Mỗi vũ khí tham chiếu tới một `WeaponAnimProfile` thuộc một trong 4 nhóm sau:

| Nhóm (`WeaponGroup`) | Chuỗi Animation (`Ground` + `Aerial`) | Chuyển động `BodyBase` + `WeaponPivot` & Không chiến đặc trưng |
| --- | --- | --- |
| **`HAMMER`** (Búa) | `hammer_atk_1`, `hammer_atk_2`, `hammer_air`, **`hammer_slam`** | Giơ cao quá đầu (`z = -1` lúc giơ sau lưng) rồi bổ thẳng mạnh xuống; trên không bấm `Xuống + Đánh` sẽ **`Air Slam`** lao thẳng đứng xuống dậm đất |
| **`AXE`** (Rìu) | `axe_atk_1`, `axe_atk_2`, `axe_atk_3`, `axe_air`, **`axe_slam`** | Vung quét vòng cung rộng chéo từ trên xuống và chém ngang ngược lại; trên không bấm `Xuống + Đánh` sẽ **`Air Slam` bổ xoáy/chéo** xuống đất |
| **`BLADE`** (Đao/Kiếm) | `blade_atk_1`, `blade_atk_2`, `blade_atk_3`, `blade_air_1_2`, `blade_air_down` | Nhát chém nhanh gọn; trên không **không dậm đất** mà liên trảm 2 nhịp kèm hãm rơi nhẹ (`Air Stall`), `Xuống + Đánh` chém chéo nhanh |
| **`POLEARM`** (Thương/Mác) | `pole_atk_1`, `pole_atk_2`, `pole_air`, `pole_pogo_down` | Hạ trọng tâm, đẩy cán ngang hông (`z = +1`) chọc tầm xa; trên không **không dậm đất**, `Xuống + Đánh` chọc thẳng xuống để **`Pogo Bounce`** bật nảy khi trúng mục tiêu |

*Các vũ khí cùng nhóm tái sử dụng bộ animation của nhóm đó, nhưng vẫn khác nhau rõ rệt qua 5 profile của `WeaponData`: `animation_profile` (`anim_speed_scale`), `grip_offset`, `hitbox_profile`, `slash_vfx_profile` và `combo_profile`.*

---

## 3. Hệ Thống Ánh Sáng & Bảng Màu Sáng – Chiều – Tối

Trong Godot 4.3, sử dụng **`CanvasModulate`** toàn màn hình + **`PointLight2D`** (texture ánh sáng dạng gradient tròn hoặc pixel bậc thang để giữ chất retro):

| Pha thời gian | Mã màu `CanvasModulate` gợi ý | Đặc điểm ánh sáng |
| --- | --- | --- |
| **Bình Minh** | `#FFD7BA` (Cam đào nhẹ) | Ánh sáng dịu, sương sớm nhẹ |
| **Ban Ngày** | `#FFFFFF` (Trắng chuẩn) | Hiển thị đúng 100% màu gốc của pixel art |
| **Hoàng Hôn** | `#E89F71` → `#B57BA6` | Nhuộm chiều tà ấm hơi tím |
| **Ban Đêm** | `#4A5685` (Xanh đêm, vẫn đủ nhìn rõ nền) | Bật đèn lồng Làng Lộc Trĩ (`#FFBA69`), đom đóm rừng, mắt quái phát sáng nhẹ |

> **Lưu ý hiệu năng & thẩm mỹ:** Không chỉnh màu đêm quá tối đen (`#111122`) gây mỏi mắt khi nhảy platformer; giữ ở mức xanh lam trung tính `#4A5685` và đặt `HUD` trên `CanvasLayer` riêng để giao diện không bị tối theo trời đêm.

### 3.1. Bảng Màu Khóa Cứng 32 Màu (`Master Folklore Palette`)
Toàn bộ sprite nhân vật, vũ khí, NPC và quái được khóa trong cùng dải `32` màu (`assets/sprites/master_palette_32.png`), dùng chung đường viền tối ấm `#1E1412` để giữ độ nét và sắc thái cổ tích Việt Nam ở cả Ban Ngày lẫn Ban Đêm:

| Nhóm sắc độ | Mã màu Hex | Ứng dụng chính |
| --- | --- | --- |
| **Viền & Trung tính (4)** | `#1E1412`, `#362624`, `#EDE3D2`, `#FFF7E4` | Viền ngoài 1px, tóc đen sâu, đai vải/quạt/nanh trắng, điểm lóe sáng |
| **Da rám nắng (4)** | `#8E5239`, `#BA7550`, `#DF9B6D`, `#F5C193` | Da cơ bắp Thạch Sanh, Thợ Rèn, Xa Phu, dân làng |
| **Gỗ, Tre khô & Lông Sóc (4)** | `#4B2B1B`, `#78472A`, `#A86838`, `#D69456` | Cán búa/rìu, Búa Gỗ, khố Thạch Sanh, tạp dề da, lông Sóc Dại |
| **Chàm & Thép rèn (5)** | `#232B42`, `#394A6D`, `#587299`, `#8BA6C4`, `#C5DBE8` | Quần áo dân làng, tóc đen ánh chàm, đầu Búa Sắt, Đoản Đao, mũi Mác Tre |
| **Đỏ sơn mài & Mắt quái (4)** | `#6E1D24`, `#AC2E31`, `#DE4E46`, `#F28A7E` | Khăn vấn đầu, viền khố, băng cổ tay, tua rua, yếm đào, khăn Thợ Rèn, mắt quái |
| **Đồng Đông Sơn & Vàng (4)** | `#6E4E1E`, `#A67A2B`, `#DBA93E`, `#F7D569` | Lưỡi Rìu Đồng, đai búa, chắn tay đao, nón lá Xa Phu, hào quang Pháp bảo |
| **Lá rừng & Rắn Lục (4)** | `#1E4429`, `#346E38`, `#5CA349`, `#9CD468` | Thân tre, áo xanh cốm Cô Bé Tạp Hóa, vảy & bụng Rắn Lục |
| **Tím than & Mai Bọ Gai (3)** | `#2D1F3D`, `#51386E`, `#835CA8` | Áo dài Lý Thông, mai thép & tà khí Bọ Gai |

---

## 4. Chiến Lược Asset Public & Quy Định Kiểm Tra License

### 4.1. Quy tắc kiểm tra License bắt buộc cho Asset Public
Trước khi đưa bất kỳ tài nguyên miễn phí nào (ảnh, nhạc, SFX, font) từ **itch.io**, **Kenney.nl**, **OpenGameArt** vào thư mục `assets/`, phải kiểm tra rõ giấy phép:
1. **Giấy phép ưu tiên chấp nhận:** `CC0` (Public Domain), `MIT`, `OFL` (cho Font), hoặc `CC-BY 4.0` (cho phép sửa đổi & sử dụng thương mại miễn ghi nguồn).
2. **Giấy phép cần cân nhắc / Hạn chế:** `CC-BY-SA` (bắt buộc chia sẻ cùng giấy phép phần dẫn xuất), `NC` (*Non-Commercial* — **không dùng** nếu dự định phát hành game thương mại hoặc thu phí sau này), `ND` (*No Derivatives* — **cấm dùng** nếu cần cắt ghép/chỉnh màu lại).
3. **Tuyệt đối cấm:** Asset không ghi rõ license hoặc asset rip trái phép từ các game thương mại khác.
4. **Hồ sơ ghi công (`assets/CREDITS_AND_LICENSES.md`):** Mọi gói asset public tải về đều phải ghi ngay 1 dòng gồm: *Tên gói, Tác giả, Link gốc, Loại License, Ngày tải, File sử dụng trong project*.

### 4.2. Phân loại nguồn Asset (Public vs AI tạo)
- **Ưu tiên lấy từ Asset Public (`16x16`):**
  - *Tileset thiên nhiên cơ bản (`16x16`):* Đất cỏ, vách đá, hang động, dòng nước, cầu gỗ, bụi cỏ.
  - *Quái phổ thông:* Sóc/Thú nhỏ, Rắn, Dơi hang, Bộ xương, Ma trơi.
  - *VFX & UI cơ bản:* Vệt chém (`Slash`), khói bụi nhảy, giọt nước bắn, khung gỗ, thanh HP/MP.
  - *Font chữ:* Font pixel hỗ trợ đầy đủ tiếng Việt có dấu (VD *Pixel Operator Việt hóa*, *VT323*, *Silver* bản Việt hóa).
- **Ưu tiên dùng AI tạo + Hậu kỳ (Bản sắc Việt Nam):**
  - *Thạch Sanh (`BodyBase` + `FrontArm` tách lớp):* Cởi trần cơ bắp, đóng khố vải nâu đỏ, khăn vấn đầu, chân trần.
  - *NPC & Kiến trúc Làng Lộc Trĩ:* Nhà tranh vách đất, cổng làng/lũy tre, Anh Thợ Rèn, Cô Bé Tạp Hóa, Anh Xa Phu, Tiên Ông, Lý Thông.
  - *Vũ khí rời & Linh ảnh Pháp bảo:* Búa Gỗ, Búa Sắt, Rìu Đồng, Rìu Thần; các Pháp bảo dạng phát sáng lơ lửng (`Niêu Cơm Thần`, `Cung Tên Vàng`, `Đàn Thần`) không gắn dính vào tay.
  - *UI khung viền màn hình lẻ (GĐ 5):* Khung họa tiết đốt tre / hoa văn cổ Việt Nam trầm dịu bọc ngoài viewport `384x216` trên các màn hình có độ phân giải không chia hết.
  - *Boss cổ tích:* Chằn Tinh, Đại Hỏa Hầu, Đại Bàng Khổng Lồ, Thuồng Luồng.

### 4.3. Quy chuẩn Âm thanh (`Audio Bus Layout`)
- Sử dụng `default_bus_layout.tres` gồm kênh gốc **`Master`** và 3 bus con tách biệt ngay từ đầu: **`BGM`** (nhạc nền), **`SFX`** (hiệu ứng đánh, nhảy, nhặt vàng, giao diện) và **`Ambience`** (tiếng suối, gió rừng, côn trùng ban đêm) để người chơi tùy chỉnh âm lượng độc lập ở `PauseMenu`.

---

## 5. Quy Trình AI Pipeline: Concept → Chuẩn Hóa Pixel → Hậu Kỳ → Import Godot

### 5.1. Bảo đảm tính nhất quán thiết kế Thạch Sanh giữa các frame
Tránh tình trạng mỗi lần AI sinh một frame (`Idle`, `Run`, `Attack`) lại ra gương mặt, màu áo hay tỷ lệ đầu-thân khác nhau:
1. **Khóa Keyframe Gốc (`Idle_0`) & Master Palette:** Chốt trước 1 tấm Thạch Sanh đứng yên chuẩn mực kèm **Bảng màu khóa cứng (12–16 màu)** cho da, tóc, áo nâu, thắt lưng, đường viền tối (`#2B1B17` hoặc `#1A1412`).
2. **Tái sử dụng bộ phận & Reference Image:** Khi làm các frame tiếp theo trong công cụ AI có hỗ trợ *Character Sheet / Reference Image* (hoặc chỉnh trực tiếp trên **LibreSprite / Aseprite**), luôn lấy `Idle_0` làm ảnh tham chiếu giữ cố định chiều cao đầu (`~10 px`), chiều cao thân (`~12 px`), chân (`~8 px`). Thực tế nhanh và đẹp nhất là tạo 1–2 dáng mẫu bằng AI rồi tự chỉnh khớp chân/tay trên lưới `48x48` trong LibreSprite.
3. **Tách lớp `BodyBase` và `FrontArm` trên cùng khung lưới:** Vẽ/xuất cả hai lớp trên cùng canvas `48x48` (hoặc `64x64`), sau đó tách riêng phần cánh tay trước sang layer `FrontArm` để hai sprite khi đặt vào Godot ở tọa độ `(0, 0)` sẽ khớp khít từng pixel.
4. **Căn lề đáy (`Baseline Alignment`):** Bàn chân chạm đúng hàng pixel đáy cố định trong mọi ô frame của spritesheet để nhân vật không bị nhảy độ cao khi chuyển trạng thái.

### 5.2. Master Art Style Prompt mẫu (Tiếng Anh)
```text
16-bit SNES style pixel art sprite, [SUBJECT], side-scroller 2D action platformer view, facing right, crisp clean dark brown-black pixel outline (#1E1412), limited 16-color warm Vietnamese folklore palette, sharp hard pixel edges, no anti-aliasing, no blur, no pillow shading, centered full body on a clean solid flat background, clear silhouette.
```

### 5.3. Tách nền không viền màu (Alpha sạch) & Hậu kỳ 4 bước
1. **Ưu tiên số 1 — Nền trong suốt trực tiếp:** Nếu công cụ hỗ trợ xuất **PNG Transparent Background**, ưu tiên dùng ngay; sau đó ép ngưỡng Alpha nhị phân cứng trên LibreSprite/script (`Alpha < 128 → 0`, `Alpha >= 128 → 255`) để loại bỏ bóng mờ bán trong suốt.
2. **Nếu bắt buộc dùng Chroma Key (nền màu phẳng):**
   - Tránh dùng nền màu quá chói sát tông da/áo hoặc dễ ám hồng viền (`#FF00FF`) nếu công cụ AI có bật khử răng cưa; ưu tiên màu nền phẳng tương phản rõ với chủ thể (VD xanh xám mát `#3A5F6F` cho nhân vật tông nâu đất, hoặc xanh dương nhạt khi không có màu xanh trên áo).
   - Xóa nền bằng công cụ **Contiguous Flood-Fill (`Tolerance = 0–10`)** từ ngoài rìa vào (không xóa màu bên trong viền), sau đó thực hiện **Defringe 1px** (lọc bỏ các pixel lai màu nền dọc rìa) và tô dặm lại đường viền tối (`outline`) cho sắc nét hoàn toàn.
3. **Thu nhỏ chuẩn `Nearest-neighbor`:** Nếu ảnh AI xuất ở kích thước lớn (`512x512` / `1024x1024`), thu về đúng kích thước pixel đích (`24x24`, `48x48`, `96x96`) bằng thuật toán **Nearest-neighbor** (tuyệt đối không dùng Bilinear/Bicubic).
4. **Thiết lập Import trong Godot 4.3:**
   - Chọn ảnh trong `FileSystem` → Tab `Import`:
     - `Compress → Mode`: **`Lossless`** (cấm dùng `VRAM Compressed` hoặc `Lossy` gây bệt màu pixel).
     - `Mipmaps → Generate`: **`Off`**.
     - `Process → Fix Alpha Border`: **`On`** (loại bỏ quầng đen/trắng ở viền trong suốt khi dựng game).
     - Trên `CanvasItem` / Project Settings giữ `Texture Filter = Nearest`.
