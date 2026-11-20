# Lộ Trình Phát Triển Cuốn Chiếu (`ROADMAP`)

> **Phiên bản tài liệu:** `1.3` (Khép kín kỹ thuật & Sẵn sàng triển khai)

**Nguyên tắc triển khai cốt lõi:** *Ưu tiên sản phẩm chạy được và test được từng phần nhỏ trước, mở rộng kiến trúc đúng lúc tính năng cần tới.*  
Không khởi tạo ồ ạt toàn bộ 5 `Autoload` và các hệ thống phức tạp (Save/Time/Router/Dialogue) ngay ở Giai đoạn 1 khi nhân vật còn đang chạy thử trên màn hình sandbox.

---

## Giai đoạn 0: Bộ Hồ Sơ Thiết Kế & Master Prompt *(Đã hoàn thành)*
- [x] Chốt các quyết định thiết kế lõi qua phiên phỏng vấn `/grill-me`.
- [x] Khởi tạo bộ 4 tài liệu nền tảng: `AGENTS.md`, `docs/GDD.md`, `docs/ART_SPEC.md`, `docs/ROADMAP.md`.
- [x] Hoàn tất đợt **Technical Review v1.1** (chuẩn hóa `Integer Scale`, `Hand-Socket 3 lớp` 1 timeline, `WeaponData` 5 profile, sửa xung đột `InputMap`, quy chuẩn `Hazard/SafeAnchor`, `SaveManager` có version/backup, chia nhỏ Giai đoạn 1).
- [x] Chốt bổ sung **v1.2**: khung viền họa tiết tre trúc cho màn hình độ phân giải lẻ; hệ thống không chiến riêng 4 dòng vũ khí (chỉ `HAMMER` & `AXE` có `Air Slam`); Pháp bảo hiển thị bằng linh ảnh phát sáng tách khỏi `WeaponPivot`; `Camera2D` dùng vùng đệm `Drag Margin` và tắt `position_smoothing`.
- [x] Chốt **v1.3**: quy tắc xuyên thân `Layer 2/3` (`collision_mask = 1`), `Layer 8 Pickup`, chống đơ `Hitstop/Pause` (`ignore_time_scale`), `Baseline Stats` Lv.1, đánh trúng hồi `2–3 MP`, rương bí mật chỉ mở 1 lần, `.gitignore` & `default_bus_layout.tres` (`BGM/SFX/Ambience`).

---

## Giai đoạn 1: Khung Project Godot 4.3 & Prototype Chạy Được (Greybox Vertical Core) *(Đã hoàn thành)*
**Mục tiêu:** Dựng lõi điều khiển, chiến đấu, khớp vũ khí và bẫy nước chạy mượt bằng hình khối tạm trên scene thử nghiệm cục bộ (`test_sandbox.tscn`), chưa cần nhồi nhét toàn bộ `Autoload` của game đầy đủ.

### Bước 1.1: Player Movement (Khung dự án & Di chuyển Platformer) *(Đã hoàn thành)*
- **Hạng mục thực hiện:**
  - [x] Khởi tạo `.gitignore`, `default_bus_layout.tres` (3 kênh `BGM`, `SFX`, `Ambience`) và `project.godot` chuẩn Godot 4.3: Renderer `gl_compatibility`, Viewport `384x216`, `Stretch Mode = viewport`, `Scale Mode = integer`, `Aspect = keep`, `Window Override = 1152x648` (`3x`), Filter `Nearest`, bật `Snap 2D Transforms/Vertices to Pixel`.
  - [x] Cấu hình `InputMap` chuẩn (tách riêng `move_up` dùng `W`/`Up` và `interact` dùng `E`/`F`; không hardcode phím trong script).
  - [x] Thiết lập các Collision Layer 1–8 theo `AGENTS.md` (Layer 8: `Pickup`; `PlayerBody` chỉ đặt `collision_mask = 1` xuyên thân quái).
  - [x] Dựng `test_sandbox.tscn` bằng `TileMapLayer` (`16x16 px`) gồm mặt đất tĩnh, tường, bậc nhảy cao và sàn mỏng 1 chiều (`One-way platform`).
  - [x] Lập trình `Player` (`CharacterBody2D` + `StateMachine`: `Idle`, `Run`, `Jump`, `Fall`) với gia tốc/ma sát mượt, *Coyote Time*, *Jump Buffer*, *Variable Jump Height*, tụt sàn mỏng (`Xuống + Nhảy`) và `Camera2D` bám nhân vật dùng `Drag Margin` (vùng đệm đứng yên nhỏ ở giữa, tắt `position_smoothing_enabled = false`).
- **Tiêu chí hoàn thành (DoD):** Nhân vật khối chạy, nhảy, leo bậc và tụt sàn 1 chiều mượt mà ở `60 FPS`, hạt pixel/cạnh hình khối không bị nhòe hay rung giật khi camera di chuyển.
- **Cách kiểm thử:** Mở `test_sandbox.tscn` bằng Godot (`F5` / `F6`), thử nhảy ở sát mép bục (kiểm tra Coyote Time), bấm nhảy ngay trước khi tiếp đất (Jump Buffer), đi nhích qua lại 1–2 bước để kiểm tra `Camera2D` giữ nền đứng yên không rung, kéo/phóng cửa sổ test kiểm tra `integer scale` không làm méo khung hình. *(Đã kiểm thử tự động toàn bộ 8 tiêu chí qua headless physics loop của Godot 4.3).*

### Bước 1.2: Combat Prototype (Hệ thống Component Sát thương & Đánh cơ bản) *(Đã hoàn thành)*
- **Hạng mục thực hiện:**
  - [x] Viết bộ 3 component tái sử dụng: `HealthComponent`, `HitboxComponent` (`Area2D`), `HurtboxComponent` (`Area2D`) với kiểm tra chặn đánh xuyên tường Layer 1 (`World`) và ghi nhận mỗi mục tiêu tối đa 1 lần/nhát chém.
  - [x] Lập trình `DummyEnemy` (bia tập / quái khối đơn giản dùng chỉ số tham chiếu `Baseline Stats` ở `GDD.md`: Thạch Sanh `15 dmg`, quái `45 HP`) có `HealthComponent` + `HurtboxComponent`, đặt `collision_mask = 1` xuyên thân `PlayerBody`, biết nhấp nháy trắng khi trúng đòn, bị đẩy lùi (`knockback`), hồi nhẹ `3 MP` cho `Player` mỗi nhát trúng, và biến mất sạch (`queue_free`) khi về `0 HP`.
  - [x] Thêm trạng thái `Attack` đơn nhịp đầu tiên cho `Player`, bật/tắt `HitboxComponent` thông qua `AnimationPlayer`.
- **Tiêu chí hoàn thành (DoD):** Đánh trúng `DummyEnemy` trừ đúng lượng máu, đẩy lùi đúng hướng nhìn của `Player`, hết máu quái biến mất sạch không báo lỗi null node trong Console.
- **Cách kiểm thử:** Chém `DummyEnemy` từ cả hai phía Trái/Phải; đứng sát ở rìa tầm đánh kiểm tra hitbox không đánh xuyên tường hay tự đánh trúng bản thân; quan sát tab `Output/Debugger` không phát sinh cảnh báo/lỗi. *(Đã kiểm thử tự động 6 ca combat + regression Bước 1.1 trên headless physics loop Godot 4.3).*

### Bước 1.3: Hand-Socket System (Khớp Bàn Tay 3 Lớp & `WeaponData` 5 Profile) *(Đã hoàn thành)*
- **Hạng mục thực hiện:**
  - [x] Dựng cụm `VisualRoot` 3 lớp theo `ART_SPEC.md`: `BodyBaseSprite` (`z=0`), `WeaponPivot/WeaponSprite` (`z=-1/+1`), `FrontArmSprite` (`z=2`), `SlashVFXSprite` (`z=3`), `RelicVisual` (`z=4`).
  - [x] Định nghĩa 5 lớp Resource: `WeaponData`, `WeaponAnimProfile`, `WeaponHitboxProfile`, `SlashVfxProfile`, `WeaponComboProfile`.
  - [x] Tạo bộ 4 `WeaponData (.tres)` mẫu đại diện đủ 4 nhóm: **Búa Gỗ (`HAMMER`)**, **Rìu Đồng (`AXE`)**, **Đoản Đao (`BLADE`)** và **Mác Tre (`POLEARM`, ảnh `32x32`)** với `grip_point_px`, `animation_profile`, `hitbox_profile`, `slash_vfx_profile` và `combo_profile` riêng biệt, kèm nút debug đổi vũ khí (`Tab`) và slow-mo `0.25x` (`F4`).
  - [x] Dựng 1 timeline `AnimationPlayer` đồng bộ cả 3 lớp sprite + `WeaponPivot` (`position`, `rotation_degrees`, `z_index`) + `SlashVFXSprite` + `HitboxComponent` cho `RESET`, `idle`, `run`, `jump`, `fall` và 4 đòn đánh (`hammer_atk_1`, `axe_atk_1`, `blade_atk_1`, `pole_atk_1`).
- **Tiêu chí hoàn thành (DoD):** Đổi qua lại 4 vũ khí ngay trong game thấy dáng đánh và tầm đánh đổi hẳn theo nhóm (`HAMMER`/`AXE`/`BLADE`/`POLEARM`), bàn tay trước luôn đè đúng lên cán vũ khí, gốc xoay vũ khí bám chặt lòng bàn tay ở mọi frame.
- **Cách kiểm thử:** Chậm tốc độ `Engine.time_scale = 0.25` (`F4`) hoặc xem từng bước trên Runtime để kiểm tra vị trí cán vũ khí trong tay và `z_index` trước/sau thân ở cả hướng quay Phải và quay Trái (`VisualRoot.scale.x = -1`). *(Đã kiểm thử tự động 5 nhóm test Hand-Socket, 4 vũ khí khác tầm, Slow-mo/RESET & regression Bước 1.1–1.2 trên Godot 4.3).*

### Bước 1.4: Advanced Combat (Combo, Không Chiến 4 Dòng, Dash, Hurt & Hitstop) *(Đã hoàn thành)*
- **Hạng mục thực hiện:**
  - [x] Hoàn thiện chuỗi `combo_profile` (combo 3 nhịp tăng sát thương & bước tiến theo nhịp cho cả 4 dòng vũ khí, input buffer nối đòn, `combo_window_sec`, hủy đòn sang `Dash`).
  - [x] Triển khai **hệ thống Không chiến riêng theo nhóm vũ khí** (`PlayerAirAttackState`):
    - `HAMMER` & `AXE`: Đánh thường trên không + **`Air Slam` (`Xuống + Đánh`)** lao xuống dậm đất gây chấn động mạnh (`HAMMER` lao thẳng đứng, `AXE` bổ chéo rộng & recovery ngắn hơn).
    - `BLADE`: Liên trảm 2 nhịp trên không (`blade_air_1` -> `blade_air_2`) kèm hãm rơi nhẹ (`Air Stall`) + chém chéo xuống (`blade_air_down`, không có `Air Slam`).
    - `POLEARM`: Đâm ngang trên không (`pole_air`) + đâm thẳng xuống **`Pogo Bounce`** (`pole_pogo_down`) bật nảy ngược lên cao (`-265 px/s`) khi trúng mục tiêu (không có `Air Slam`).
  - [x] Thêm trạng thái `Dash` (`PlayerDashState`: lướt nhanh `300 px/s` trong `0.17s` có `0.22s` `i-frames` xuyên hitbox quái, bóng mờ pixel và hồi chiêu `0.55s`) và `Hurt` (`PlayerHurtState` khi `DummyEnemy.EnemyHitbox` chạm vào `HurtboxComponent`).
  - [x] Bổ sung cảm giác đánh: `Hitstop` cục bộ an toàn (tương thích Slow-Mo `0.25x`), `Camera2D` rung nhẹ làm tròn pixel theo hướng chém/dậm đất, và tia lửa đánh trúng `1:1` (`HitSpark.tscn`).
- **Tiêu chí hoàn thành (DoD):** Thực hiện trọn combo 3 nhịp mượt, 4 dòng vũ khí thể hiện rõ lối đánh trên không khác nhau, ngắt combo giữa chừng bằng `Dash` hoặc bị quái đánh trúng lập tức gọi `RESET` tắt sạch `HitboxComponent` và `SlashVFXSprite`, không bao giờ bị "kẹt hitbox bật vĩnh viễn" hay kẹt trạng thái đứng im.
- **Cách kiểm thử:** Bấm `Attack` liên tục để nối hết 3 nhịp; nhảy thử cả 4 nhánh không chiến (`HAMMER`/`AXE` `Air Slam` dậm đất, `BLADE` `Air Stall`, `POLEARM` `Pogo Bounce` nảy trên đầu `DummyEnemy`); thử bấm `Dash` ngay giữa frame vung búa và kiểm tra không còn gây sát thương sau khi hủy; để quái đánh trúng `Player` giữa lúc đang chém để xác minh `Hurt` khôi phục trạng thái sạch sẽ. *(Đã kiểm thử tự động toàn bộ 5 nhóm test Bước 1.4 & regression Bước 1.2–1.3 trên headless physics loop Godot 4.3: `ALL_STEP_1_4_TESTS_PASSED`).*

### Bước 1.5: Hazard System (Sông Sâu / Vực & `SafeAnchor` An Toàn) *(Đã hoàn thành)*
- **Hạng mục thực hiện:**
  - [x] Tạo vùng `Hazard` (Layer 7) `HazardZone` / `RiverHazard.tscn` cho sông sâu/vực thẳm trong `test_sandbox.tscn` (khe sông rộng `48 px` tại cột `32..34`).
  - [x] Xây dựng hệ thống ghi nhận `SafeAnchor` (chỉ cập nhật khi `is_on_floor()` trên `TileMapLayer` tĩnh — loại trừ `OneWayPlatformLayer`, cả 2 `RayCast2D` `SafeRayLeft/SafeRayRight` rìa chân đều chạm đất liền và nằm ngoài vùng đệm an toàn `hazard_safe_margin_px = 14 px` quanh `Hazard`).
  - [x] Cài đặt quy trình xử lý rơi chuẩn (`notify_hazard_contact` / `_execute_hazard_resolution`): khóa `_is_resolving_hazard` → trừ đúng 1 lần `int(ceil(max_hp * 0.8))` (bỏ qua `i-frames` chiến đấu) → nếu `<= 0 HP` chuyển trạng thái `Dead` (`PlayerDeadState`, log GĐ1 và tự hồi sinh về điểm đầu sandbox sau `1.1s`) → nếu còn sống thì triệt tiêu `velocity` & input buffers, teleport về `SafeAnchor`, bật `i-frames` `1.2s` kèm chớp mờ rồi mở khóa khi rời khỏi `Hazard`.
- **Tiêu chí hoàn thành (DoD):** Rơi xuống sông chỉ trừ đúng 1 lần `80% Max HP`, quay về bờ đất đứng vững, không bị teleport lặp hoặc chết oan ở mép vực 1px.
- **Cách kiểm thử (Bắt buộc test đủ 4 ca biên):**
  1. Đầy 100% HP nhảy xuống nước → tụt còn 20% HP và đứng yên trên bờ đất trước đó.
  2. HP còn `<= 80% Max HP` nhảy xuống nước → tụt về `0 HP` và vào trạng thái `Dead`.
  3. Đang có `i-frames` sau khi bị quái đánh mà rơi xuống nước → vẫn bị tính sát thương hazard bình thường, không rơi lọt đáy map.
  4. Đứng mấp mé nửa chân ở rìa bờ ngay sát vực rồi bước hụt xuống → `SafeAnchor` phải đưa về vị trí đứng vững trên đất liền trước đó, không đưa lại đúng pixel rìa vực làm rơi tiếp lần 2.
  *(Đã kiểm thử tự động đủ cả 4 ca biên + loại trừ sàn 1 chiều & hủy `Air Slam` khi rơi sông trên headless physics loop Godot 4.3: `ALL_STEP_1_5_TESTS_PASSED`).*

---

## Giai đoạn 2: Kiến Trúc Toàn Cục, Làng Lộc Trĩ (Hub) & Vòng Lặp RPG
**Mục tiêu:** Đưa dần bộ 5 `Autoload` vào vận hành thực tế để nối các màn chơi với nhau và đưa phần "hồn" bản 2006 vào game.

### Bước 2.1: Bộ 5 `Autoload`, Dữ liệu Vật phẩm/`WeaponData` Mở Rộng & Kết nối `Player` *(Đã hoàn thành)*
- [x] Đăng ký đủ bộ 5 `Autoload` theo đúng thứ tự phụ thuộc trong `project.godot`: `EventBus`, `GameState` (Registry ID ổn định, Level/EXP, Vàng túi/rương, Đai lưng giới hạn + Rương làng, `story_flags`, `opened_chests`), `TimeManager` (chu kỳ 4 pha Sáng–Chiều–Tối 14 phút, buff ban đêm `1.20x` / rơi vàng `1.35x`, ngủ chuyển Sáng↔Đêm), `SaveManager` (`save_version = 1`, ID chuỗi ổn định không chứa `res://`, ghi nguyên tử `.tmp`, sao lưu xoay vòng `.bak`, tự cứu file lỗi & fallback an toàn khi lệch phiên bản) và `SceneRouter` (fade đen mượt, đặt đúng `SpawnPoint`, phạt `15%` Vàng mang theo khi `0 HP`).
- [x] Tạo `ItemData` + 4 `.tres` vật phẩm (`item_hp_pot`, `item_mp_pot`, `mat_hard_wood`, `mat_iron_ore`), tạo vũ khí thứ 5 **Búa Sắt (`weapon_iron_hammer.tres`, `+16 ATK`)** và `SpawnPoint`.
- [x] Kết nối 2 chiều `Player` ↔ `GameState` / `EventBus` / `SceneRouter`, bổ sung dùng nhanh *Niêu Cơm Thần* (`Q`), *Bình HP/MP Đai Lưng* (`1`/`2`). *(Đã kiểm thử tự động 6 cụm test `ALL_STEP_2_1_TESTS_PASSED`, bao gồm tự phục hồi `.bak`, hỏng version & regression GĐ 1).*

### Bước 2.2: Hub Làng Lộc Trĩ, Ánh sáng Sáng–Tối, Nhà Tranh & `HUD` *(Đã hoàn thành)*
- [x] Dựng `hub_loc_tri.tscn` bằng `TileMapLayer` `16x16` + hệ thống ánh sáng **Sáng – Chiều – Tối** (`CanvasModulate` + `PointLight2D` đèn lồng).
- [x] Dựng Nhà Tranh (giường ngủ chuyển sáng/tối + lưu game bằng `SaveManager`, rương chứa bình thuốc thừa & cất Vàng).
- [x] Dựng khung giao diện `HUD` trên `CanvasLayer` riêng (HP, MP, Level/EXP, Vàng, đồng hồ sáng/tối, ô Niêu Cơm Thần & Đai Lưng giới hạn bình thuốc).
  - *Kiểm chứng:* Bộ test Godot 4.3 headless (`ALL_STEP_2_2_TESTS_PASSED`) vượt qua 5/5 kịch bản: boot `HubLocTri` (`Camera2D.limit_bottom = 224`), `HUD` (`layer = 10`) tách khỏi `DayNightLight`, ngủ tại `CottageBed` chuyển Sáng/Tối + bật 5 đèn lồng `#FFBA69` + hồi HP/MP/Niêu + lưu `SaveManager`, mở `CottageChest`/`StashUI` khóa di chuyển + gửi/rút Vàng & bình thuốc + đóng bằng `Esc`, qua cổng `EastGatePortal` sang `test_sandbox.tscn` và rơi `RiverHazard` 0 HP tự hồi sinh về `SpawnCottageBed` trừ 15% Vàng túi (50 -> 43, giữ nguyên 50 Vàng rương), cùng hồi quy `Tab`/`Q`/`1`/`2`.

### Bước 2.3: Hệ thống Hội thoại JSON & 4 NPC Cốt lõi *(Đã hoàn thành)*
- [x] Dựng `DialogueBox` đọc từ `data/dialogues/*.json` và kiểm tra `story_flags`.
- [x] Triển khai 4 NPC cốt lõi & UI tương ứng:
  1. **Anh Thợ Rèn** (`ForgeUI` — mua/rèn & trang bị vũ khí: Búa Gỗ, Búa Sắt, Rìu Đồng, Đoản Đao, Mác Tre).
  2. **Cô Bé Tạp Hóa** (`ShopUI` — mua bình HP/MP vào Đai Lưng & phần dư cất Rương).
  3. **Anh Xa Phu** (`TravelUI` — dịch chuyển qua lại giữa Làng Lộc Trĩ và màn chơi).
  4. **Lý Thông** (đối thoại mở đầu cốt truyện đọc từ `data/dialogues/`).
- [x] *Kiểm chứng Bước 2.3 & DoD Giai đoạn 2:* Bộ test Godot 4.3 headless (`ALL_STEP_2_3_TESTS_PASSED`) vượt qua 5/5 kịch bản: dấu `!` và hội thoại JSON phân nhánh Ngày/Đêm + `story_flags` của Lý Thông (`met_ly_thong`, `ly_thong_suspicious_01`), khóa input & đệm đóng modal không nhảy/lặp, Cô Bé Tạp Hóa (`ShopUI`) giới hạn Đai Lưng (`3 Đỏ / 2 Thảo`) tự chuyển phần dư về Rương Làng, Anh Thợ Rèn (`ForgeUI`) mua bằng Vàng + rèn từ nguyên liệu + đổi qua lại 5 vũ khí, tự phục hồi từ `.bak` khi file save chính hỏng, và Anh Xa Phu (`TravelUI`) dịch chuyển khứ hồi Làng Lộc Trĩ ↔ `test_sandbox.tscn`; mọi khung UI lọt gọn trong viewport `384x216`.

**Tiêu chí hoàn thành (DoD):** *(Đã đạt)* Đi dạo quanh Làng Lộc Trĩ, chuyển ngày/đêm thấy đèn lồng sáng, mua bình máu (kiểm tra giới hạn đai lưng), đổi vũ khí tại Thợ Rèn, lưu/tải game giữ nguyên đồ (test xóa/làm hỏng file save chính để xác nhận `.bak` tự cứu được dữ liệu), và dùng Xa Phu để chuyển qua lại giữa Làng và Màn chơi.

---

## Giai đoạn 3: Vertical Slice — Màn 1 (Rừng Ven Làng) Hoàn Chỉnh
**Mục tiêu:** Hoàn thiện trọn vẹn 1 màn chơi đầu tiên từ gameplay đến đồ họa & âm thanh theo nguyên tắc *"khóa gameplay bằng placeholder trước → bọc Art đồng bộ sau"*.

### Bước 3.1: Hệ thống Quái Màn 1, Vật phẩm rơi chạm nhặt & Rương bí mật *(Đã hoàn thành)*
- [x] Tạo `EnemyData`, `StatsComponent` (tự động nhận buff ban đêm `+20%` ATK/tốc độ, `+35%` Vàng rơi & tăng tỷ lệ rơi nguyên liệu từ `TimeManager`), cùng 3 quái Màn 1 bằng sprite tạm đúng kích thước (`Sóc Dại`, `Rắn Lục`, `Bọ Gai` với vỏ gai giảm sát thương trừ khi bị Búa/Rìu phá giáp).
- [x] Xây dựng `LootPickup` (Layer 8 `Pickup` — văng nảy trên đất, tắt hút nam châm để Thạch Sanh phải chạy tới chạm trực tiếp mới nhặt, rơi xuống sông/vực `Hazard` Layer 7 sẽ chìm mất) + `LootDropSystem`.
- [x] Dựng `SecretChest` mở **1 lần duy nhất** (lưu `opened_chests` qua `GameState` / `SaveManager`).
  - *Kiểm chứng:* Bộ test Godot 4.3 headless (`ALL_STEP_3_1_TESTS_PASSED`) vượt qua 6/6 kịch bản: `StatsComponent` buff ban đêm (`12/15/17` -> `14/18/20` ATK, tốc độ `1.20x`, Vàng `1.35x`), `LootPickup` tắt nam châm hút (nằm yên trên đất tới khi `Player` chạm vào mới nhặt), `LootPickup` rơi xuống `RiverHazard` chìm mất vĩnh viễn, hạ `GreenViper` lên Level `2` và rớt Vàng vật lý trên đất, `WildSquirrel` nhảy vồ + `ThornBeetle` `SHELL_GUARD` giảm 50% sát thương `Đoản Đao` nhưng bị `Búa Gỗ` (`HAMMER`) phá giáp 100%, và `SandboxSecretChest` mở 1 lần lưu bền vững qua `SaveManager` + tải lại cảnh.

### Bước 3.2: Thiết kế Màn 1 (`stage_01_rung_ven_lang.tscn`) & Kết nối Xa Phu *(Đã hoàn thành)*
- [x] Thiết kế `stage_01_rung_ven_lang.tscn` (Graybox `16x16` chuẩn `camera.limit_bottom` chia hết cho `16`): đường chính + 2 ngách bí mật giấu rương vàng/khoáng thạch (`SecretChest_Canopy` & `SecretChest_Cavern`) + đoạn nhảy qua 2 nhịp suối sâu (`RiverHazard_West`/`RiverHazard_East`, luật `80%` Max HP) có cồn đá `SafeAnchor` ở giữa.
- [x] Bố trí nhóm quái gác cổng cuối màn (`GatekeeperGroup`) để mở `GateBarrier`, mở đường tới **Nhị Trụ Tùng (Tiên Ông)** và mở tuyến dịch chuyển ở **Anh Xa Phu** (`TravelUI` thêm `BtnTravel_stage_02` trỏ tới trạm cuối Đèo Nhị Trụ).
  - *Kiểm chứng:* Bộ test Godot 4.3 headless (`ALL_STEP_3_2_AND_3_3_TESTS_PASSED`) xác minh luồng `EastGatePortal` từ Làng Lộc Trĩ sang `SpawnFromHub` (`80, 208`), `Camera2D` (`limit_bottom = 240`), cồn đá giữa suối cập nhật `SafeAnchor` (`1016, 192`) và rơi `RiverHazard_East` trừ `80%` Max HP (`100 -> 20`) không lặp, mở đủ 2 rương bí mật (nhặt Vàng + `mat_hard_wood` + `mat_iron_ore`), hạ `GatekeeperGroup` mở `GateBarrier`/`OutpostXaPhu`/`NhiTruTungGate`, lưu/tải qua `SaveManager` không chứa `res://` và dịch chuyển nhanh về `SpawnEastOutpost` (`2264, 208`).

### Bước 3.3: Âm thanh nền tảng (BGM & SFX chiến đấu/môi trường) *(Đã hoàn thành)*
- [x] Ghép nhạc nền & SFX cơ bản qua 3 bus `BGM` / `SFX` / `Ambience` (`AudioManager` Autoload, 16 file `.wav` `22050 Hz` PCM `CC0-1.0` trong `assets/audio/`, tự chuyển `amb_forest_day` ↔ `amb_night_crickets`, `StreamAudio` 2D trên `RiverHazard` và đầy đủ SFX vung vũ khí nặng/nhẹ, trúng đòn, phá giáp/dậm đất, nhảy, dash, bị thương, rơi suối, mở rương, nhặt vàng/nguyên liệu).
  - *Kiểm chứng:* Bộ test Godot 4.3 headless (`ALL_STEP_3_2_AND_3_3_TESTS_PASSED`) kiểm tra đủ 4 bus (`Master`, `BGM`, `SFX`, `Ambience`), 16 stream nạp chuẩn + `LOOP_FORWARD`, đổi nhạc nền Hub ↔ Màn 1, đổi môi trường Ngày ↔ Đêm, `StreamAudio` phát trên bus `Ambience`, và xác nhận phát trọn đủ bộ SFX hành động/chiến đấu/nhặt đồ.

### Bước 3.4a (Art Pass Đợt 1): Master Palette, Thạch Sanh 2 lớp, Vũ khí rời, NPC & Quái Màn 1 *(Đã hoàn thành)*
- [x] Khóa bảng màu cổ tích Việt Nam thống nhất (`Master Palette` 32 màu tại `assets/sprites/master_palette_32.png`, viền tối `#1E1412`, ghi vào `docs/ART_SPEC.md` §3.1 & `CREDITS_AND_LICENSES.md`) cho toàn bộ nhân vật & sinh vật.
- [x] Nâng cấp Pixel Art `1:1` (Alpha nhị phân `0/255`, Import `Lossless`, giữ nguyên `Baseline` & tọa độ `WeaponPivot`) cho Thạch Sanh 2 lớp (`BodyBase` + `FrontArm`, `14` frame `672x48` — cởi trần cơ bắp mặc khố, tư thế `Idle` góc `3/4` mặt khôi ngô kèm nhịp thở + chớp mắt và `relic_cast`) và 5 vũ khí rời (`wooden_mallet`, `iron_hammer`, `bronze_axe`, `short_blade`, `bamboo_spear`).
- [x] Nâng cấp chi tiết Pixel Art `1:1` cho 4 NPC Làng Lộc Trĩ (`64x32`, thở lệch pha tự nhiên) và 3 Quái Màn 1 (`96x24`, `4` frame có nhịp thở & bước tuần tra cho *Sóc Dại*, *Rắn Lục*, *Bọ Gai*) để duyệt trực quan trong game trước khi làm môi trường.
  - *Kiểm chứng:* Soi trực quan Contact Sheet `5x` (`preview_step_3_4a.png`) và kiểm tra tự động bằng PIL + Godot 4.3 (`ALL_IDLE_AND_FACE_VERIFICATIONS_PASSED`): kiểm tra kích thước (`672x48`, `96x24`), alpha nhị phân `0/255`, `100%` khớp bảng màu 32 màu, Baseline chạm chân `y = 47`, `hframes = 14` trên `Player` / `hframes = 4` trên 3 quái, và chạy mượt `HubLocTri`, `Stage01`, `TestSandbox` không lỗi runtime.

### Bước 3.4b (Art Pass Đợt 2): Tileset `16x16`, Kiến trúc Làng Lộc Trĩ, Hậu cảnh Màn 1, VFX & Viền UI *(Đã hoàn thành)*
- [x] Tuyển chọn/tích hợp Tileset địa hình rừng-đá-suối `16x16` chuẩn license (`sandbox_tiles_16x16.png` `64x48` & `sandbox_tileset.tres`, ghi đầy đủ vào `assets/CREDITS_AND_LICENSES.md`) kết hợp chỉnh bảng màu đồng bộ, thêm `DecorLayer` cỏ hoa/rêu đá/hàng rào/dây leo (`collision_enabled = false`) nhưng giữ nguyên 100% ô va chạm vật lý (`0:0..3:0`).
- [x] Thay thế toàn bộ khối `ColorRect`/`Polygon2D` tạm ở hậu cảnh & đạo cụ Làng Lộc Trĩ (*Parallax núi đồi, khóm tre, Nhà Tranh, Lò Rèn, Quầy Tạp Hóa, Cây Đa, Cổng Làng, Xe Ngựa, Giường/Rương/Biển chỉ đường/Chó ngủ/Chim sẻ bay*) và Màn 1 (*Parallax 3 lớp núi rừng, cổ thụ tán tầng, hốc hang đá rêu, suối chảy động `RiverHazard`, trụ đá, bia phong ấn, cổng Nhị Trụ Tùng*) bằng Pixel Art `1:1` sắc nét (`alpha 0/255`).
- [x] Làm sắc nét `SlashVFX`, `HitSpark` và icon vật phẩm rơi (`Pickup`), bổ sung hệ thống đom đóm đêm (`NightFireflies`) & chim sẻ ban ngày (`AmbientSkyBirds`), đồng thời đồng bộ viền gỗ lim–đồng Đông Sơn / tre trúc trên `pixel_ui_theme.tres`, `HUD` và toàn bộ 5 cửa sổ UI (`DialogueBox`, `ForgeUI`, `ShopUI`, `StashUI`, `TravelUI`).
  - *Kiểm chứng:* Soi trực quan Contact Sheet (`preview_step_3_4b.png`), kiểm tra tự động mọi PNG mới (`semi_alpha = 0`), và chạy test tự động Godot 4.3 headless (`ALL_STEP_3_4B_TESTS_PASSED`) kiểm tra `GroundLayer`/`OneWayPlatformLayer`/`DecorLayer`, chu kỳ Ngày ↔ Đêm của `VillageLantern`/`NightFireflies`/`AmbientSkyBirds`, cả 6 UI cùng cơ chế mở cổng `Stage01`.

**Tiêu chí hoàn thành (DoD):** Chơi liền mạch vòng lặp: *Khởi đầu ở Làng → Ra Rừng Ven Làng đánh quái lên cấp & cày Vàng/nguyên liệu (ngày & đêm) → Hết máu bị đưa về Làng → Mua thuốc, rèn vũ khí mạnh hơn → Phá đảo Màn 1*.

---

## Giai đoạn 4: Pháp Bảo Cổ Tích & Boss Lớn Đầu Tiên (Màn 2 – Màn 4)
**Mục tiêu:** Mở rộng chiều sâu chiến đấu bằng 3 Pháp bảo cổ tích, phát triển dần cốt truyện nghi vấn Lý Thông và chinh phục Boss lớn đầu tiên (Chằn Tinh).

### Bước 4.1: Hệ Thống 3 Pháp Bảo Cổ Tích (`RelicCast` + `RelicVisual` tách rời `WeaponPivot`), Choáng Quái & `HUD` *(Đã hoàn thành)*
- [x] Vẽ chuẩn Pixel Art `1:1` (`Master Palette` 32 màu, alpha nhị phân `0/255`, Import `Lossless`) cho linh ảnh 3 Pháp bảo (`relic_nieu_com.png`, `relic_cung_ten_vang.png`, `relic_dan_than.png`), đạn `golden_arrow_projectile.png`, sóng âm `dan_than_soundwave.png` (4 frame `96x96`), sao choáng `stun_stars.png` và tổng hợp 3 SFX (`sfx_relic_bow.wav`, `sfx_relic_lute.wav`, `sfx_relic_gourd.wav`).
- [x] Mở rộng `EventBus`, `GameState` (`unlocked_relics`, `unlock_relic`, `upgrade_gourd`, lưu/tải JSON tương thích ngược `save_version = 1` không chứa `res://`) và `AudioManager`.
- [x] Cài đặt cơ chế choáng quái `apply_stun(duration)` + sao choáng overhead trên `StageEnemy`, `ThornBeetle` (phá thế cuộn vỏ gai `SHELL_GUARD`) và `DummyEnemy`.
- [x] Dựng đạn `GoldenArrowProjectile` (xuyên tối đa 2 mục tiêu, bắn ngang hoặc chéo lên khi giữ `move_up`, tự hủy khi đụng tường, không hoàn MP cận chiến) và sóng âm `DanThanSoundwave` (4 frame mở rộng bán kính không đổi `scale`, đẩy lùi hướng tâm, gây choáng `1.8s` và đánh rớt đạn quái thuộc group `enemy_projectiles`).
- [x] Thêm `PlayerRelicCastState` (`RelicCast`) điều khiển `"relic_cast"` + `VisualRoot/RelicVisual` giữ nguyên vũ khí trên `WeaponPivot`, nâng cấp `Q` (*Niêu Cơm Thần*) hiện linh ảnh & âm thanh riêng, cập nhật `HUD` lọt gọn `384x216`.
  - *Kiểm chứng:* Bộ test tự động Godot 4.3 headless (`ALL_STEP_4_1_TESTS_PASSED`) vượt qua 6/6 cụm kiểm thử: nạp đủ 6 sprite `1:1` (`alpha 0/255`, `Lossless`, 100% Master Palette) + 3 SFX bus `SFX`; lưu/tải `unlocked_relics` & `upgrade_gourd` không chứa `res://` và tương thích ngược save `v1` cũ; *Niêu Cơm Thần* `[Q]` ở `Stage01` hồi `50%` HP giữ nguyên `WeaponSprite` trong khi khóa Cung/Đàn và mọi panel `HUD <= 384x40`; *Cung Tên Vàng* `[U]` tốn `12 MP`, bắn ngang/chéo lên trên không, xuyên tối đa 2 mục tiêu không hoàn MP; *Đàn Thần* `[I]` tốn `16 MP`, sóng âm 4 frame đẩy lùi hướng tâm, choáng `1.8s`, phá `SHELL_GUARD` `ThornBeetle` và đánh rớt đạn quái; bị `Hurt` giữa `RelicCast` tắt sạch `RelicVisual` & `HitboxComponent`.

### Bước 4.2: Màn 2 — Nhị Trụ Tùng (`stage_02_nhi_tru_tung.tscn`), Tiên Ông, Quái Mới (`Dơi Hang` & Mini-boss `Khỉ Đá`) & Nghi Vấn Lý Thông
- [ ] Dựng Màn 2 (**Nhị Trụ Tùng**): Gặp **Tiên Ông**, nhận **Búa Sắt**, nâng cấp **Niêu Cơm Thần** & mở khóa **Cung Tên Vàng**; thêm **Dơi Hang** (từ `32x32-bat-sprite.png`) & Mini-boss **Khỉ Đá**; mở rộng thêm tình tiết nghi vấn **Lý Thông** vào `data/dialogues/` và `story_flags`.

### Bước 4.3: Màn 3 — Miếu Hoang & Rừng Sương Mù (`stage_03_mieu_hoang.tscn`), Quái Ma Trơi Tà Khí & Manh Mối Cốt Truyện
- [ ] Dựng Màn 3 (**Miếu Hoang**): quái ma trơi/tà khí bắn đạn (`enemy_projectiles` khắc chế bằng *Đàn Thần*), ngách ẩn & manh mối âm mưu Lý Thông.

### Bước 4.4: Màn 4 — Hang Chằn Tinh (`stage_04_hang_chan_tinh.tscn`) & Boss Lớn Đầu Tiên: Chằn Tinh
- [ ] Dựng Màn 4 (**Hang Chằn Tinh**) với **Boss Chằn Tinh** (thanh máu Boss riêng, nhiều giai đoạn đòn đánh) và mở khóa Pháp bảo **Đàn Thần**.

**Tiêu chí hoàn thành (DoD):** Chiến thắng được Boss Chằn Tinh bằng cách phối hợp lướt né `Dash`, đánh vũ khí Thợ Rèn và dùng Pháp bảo MP.

---

## Giai đoạn 5: Hoàn Thiện Thế Giới 9 Màn, Giao Diện & Đóng Gói
**Mục tiêu:** Đưa toàn bộ hành trình cứu công chúa Huỳnh Nga về đích và sẵn sàng phát hành thử nghiệm.
- Lần lượt dựng tiếp Màn 5 → Màn 9 (Đèo Đại Hỏa Hầu, Vực Đại Bàng, Động Đáy Vực, Thủy Cung Thuồng Luồng, Vết Nứt Tà Khí) theo nhịp cứ xong 1 màn lại thêm dữ liệu cốt truyện cho hoàn chỉnh.
- Tinh chỉnh cân bằng chỉ số Level, giá đồ tiệm Rèn / Tạp Hóa, độ khó Boss.
- Bọc khung hiển thị `384x216` (`SubViewportContainer`/`SubViewport` giữ nguyên `integer scale`) bằng **khung viền họa tiết tre trúc / hoa văn cổ Việt Nam** trầm dịu lấp lề dư trên các màn hình độ phân giải lẻ (`1366x768`, `1280x800`...; Full HD `1920x1080` `5x` vẫn tràn kín 100%).
- (Tùy chọn mở rộng) Thêm lớp nút bấm ảo (`TouchScreenButton`) đọc cùng `InputMap` nếu muốn xuất thêm bản Android.
- Đóng gói bản build PC (Windows/Linux) và/hoặc Web HTML5 để chia sẻ bạn bè chơi thử.
