# Tài Liệu Thiết Kế Game (GDD) — *Thạch Sanh: Dị Giới Kỳ Đàm*

> **Phiên bản tài liệu:** `1.3` (Khép kín kỹ thuật & Sẵn sàng triển khai)  
> **Cảm hứng gốc:** *Thạch Sanh - Xứ sở diệu kỳ* (FPT Mobile, Java J2ME 2006)  
> **Thể loại:** 2D Pixel Action-Platformer RPG — **Hybrid (70% Kỹ năng hành động – 30% Nhập vai)**  
> **Nền tảng ưu tiên:** PC (Bàn phím + Tay cầm), thiết kế sẵn kiến trúc để mở rộng sang Android sau này.

---

## 1. Tầm Nhìn & 4 Trụ Cột Thiết Kế

*Thạch Sanh: Dị Giới Kỳ Đàm* không sao chép y nguyên lối đánh đứng chém chậm chạp trên màn hình phím bấm 176x220 của bản 2006, mà **tái hiện lại linh hồn cổ tích Việt Nam năm 2006 trong thân xác một game Action-Platformer 2D hiện đại**:

1. **Cảm giác tay đã & có lực (70% Action):** Chạy, nhảy, lướt né (`Dash`), combo chém có khựng khung hình nhẹ (`hitstop`), rung màn hình nhỏ (`camera shake`) và hiệu ứng vệt sáng.
2. **Chất nhập vai hoài niệm (30% RPG):** Đánh quái cày cấp (Level), nhặt Vàng & nguyên liệu, về **Làng Lộc Trĩ** ghé tiệm **Anh Thợ Rèn**, **Cô Bé Tạp Hóa**, nhờ **Anh Xa Phu** đưa đi các vùng đất, sống trong chu kỳ **Sáng – Chiều – Tối**.
3. **Kho vũ khí đa dạng + Pháp bảo cổ tích:** Vừa có niềm vui chọn mua/rèn nhiều loại vũ khí cận chiến khác nhau (Búa, Rìu, Đao/Kiếm, Thương/Mác) với dáng đánh riêng từng nhóm, vừa có các Pháp bảo đặc trưng tích truyện Thạch Sanh (*Niêu Cơm Thần, Cung Tên Vàng, Đàn Thần*).
4. **Cốt truyện mở để bồi đắp dần:** Chỉ khóa khung mở màn rõ ràng ở Làng Lộc Trĩ; toàn bộ diễn biến các màn sau được xây bằng hệ thống hội thoại & cờ sự kiện tách rời để người phát triển thêm thắt từ từ theo cảm hứng.

---

## 2. Bối Cảnh Mở Đầu: "Cổ Tích Biến Dị" & Cốt Truyện Mở

### 2.1. Điểm khởi đầu (Giống & Mới so với 2006)
- **Phần quen thuộc:** Thạch Sanh sống một mình trong căn nhà tranh ở **Làng Lộc Trĩ**, bắt đầu ở Cấp độ 1 với cây **Búa Gỗ** thô sơ. Ngoài bìa làng là khu rừng dẫn lên **Nhị Trụ Tùng** — nơi **Tiên Ông** ẩn cư.
- **Điểm mới ("Cổ tích biến dị"):** Một vết nứt tà khí kỳ lạ bỗng xé toạc bầu trời xa xăm khiến muông thú quanh làng hóa thành yêu tinh hung dữ; **công chúa Huỳnh Nga** mất tích trên đường du ngoạn; còn người anh kết nghĩa **Lý Thông** bỗng tỏ ra sốt sắng bất thường, liên tục thúc giục Thạch Sanh đi vào những vùng nguy hiểm thay vì tự mình ra mặt.

### 2.2. Kiến trúc Cốt truyện mở (Mở rộng dần khi code)
Thay vì phải viết xong kịch bản cả 9 màn từ ngày đầu, cốt truyện được quản lý qua:
- **Cờ sự kiện (`story_flags`):** Ví dụ `met_tien_ong: false`, `defeated_chan_tinh: false`, `ly_thong_suspicious_01: false`.
- **File hội thoại JSON (`data/dialogues/*.json`):** Mỗi NPC (Tiên Ông, Lý Thông, Thợ Rèn, Cô Bé Tạp Hóa, Xa Phu) có thể kiểm tra `story_flags` để nói lời thoại mới mỗi khi bạn hạ thêm một Boss hoặc mở khóa vùng đất mới. Nhờ vậy bạn có thể tự do nghĩ thêm cú twist cho Lý Thông hay các nhân vật phụ trong quá trình phát triển từng màn.

---

## 3. Nhân Vật Chính & Điều Khiển

- **Nhân vật duy nhất:** Chỉ có 1 nhân vật Nam **Thạch Sanh**.
- **Chuẩn ánh xạ phím (`InputMap`) & Camera:** Mọi hành động đều đọc thông qua `InputMap` trong Godot (không hardcode phím trong script), giữ tách biệt hoàn toàn phím di chuyển lên (`move_up`: `W`/`Mũi tên lên`) và phím tương tác (`interact`: `E`/`F`) để không bị xung đột thao tác. `Camera2D` sử dụng vùng đệm đứng yên nhỏ ở giữa màn hình (`Drag Margin` kiểu *Mario / Celeste*, tắt trượt trễ mềm) giúp né đòn tại chỗ không rung nền và chạy đường dài nét căng.
- **Bộ kỹ năng di chuyển Platformer hiện đại:**
  - **Di chuyển & Nhảy mượt:** Có *Coyote Time* (~0.1s sau khi rời mép đất vẫn nhảy được) và *Jump Buffer* (~0.1s bấm nhảy trước khi chạm đất vẫn nhận lệnh). Giữ phím nhảy lâu để nhảy cao hơn, thả sớm để nhảy thấp.
  - **Lướt né (`Dash`):** Lướt nhanh một đoạn kèm khoảng bất tử ngắn (`i-frames` ~0.18s) để xuyên qua đòn quái hoặc qua khe hẹp; có hồi chiêu ngắn (~0.6s).
  - **Nhảy tụt qua sàn mỏng (`One-way platform`):** Bấm `Xuống + Nhảy` để tụt xuống cầu gỗ/cành cây.
- **Bộ kỹ năng chiến đấu:**
  - **Đánh thường (Combo theo `WeaponData`):** Chuỗi combo (mặc định 2–3 nhịp tùy dòng vũ khí) với tư thế vung, tốc độ, tầm đánh và vệt sáng thay đổi theo nhóm vũ khí đang cầm.
  - **Hệ thống Không chiến riêng theo từng dòng vũ khí:** Chỉ **Búa** và **Rìu** có **`Air Slam`** (bổ dậm đất đúng nghĩa); **Đao/Kiếm** liên trảm 2 nhịp trên không giúp hãm rơi nhẹ (`Air Stall`); **Thương/Mác** có đòn chọc xuống bật nảy ngược lên khi trúng quái (`Pogo Bounce`).
  - **Dùng Pháp bảo (tốn MP):** Bấm phím riêng cho *Cung Tên Vàng* hoặc *Đàn Thần*.
  - **Hồi phục nhanh:** Phím riêng cho *Niêu Cơm Thần* và *Bình HP/MP trên đai lưng*.

---

## 4. Hệ Thống Vũ Khí & Pháp Bảo (Hybrid Tiệm Rèn + Cổ Tích)

### 4.1. Kho vũ khí cận chiến (Mua/Rèn tại Anh Thợ Rèn)
Nhờ kỹ thuật **Khớp Bàn Tay 3 lớp (Hand-Socket)** kết hợp dữ liệu tách biệt theo nhóm, Thạch Sanh có thể trang bị đa dạng các dòng vũ khí mà chuyển động toàn thân vẫn mạnh mẽ, không bị đơ và mỗi dòng có cảm giác tay lẫn kỹ năng không chiến khác hẳn nhau:

| Nhóm vũ khí | Đánh dưới đất | Không chiến (`Đánh` & `Xuống + Đánh` trên không) | Ví dụ tiến cấp trong game |
| --- | --- | --- | --- |
| **Hammer (`HAMMER`)** | Bổ nặng từ trên xuống, sát thương cao, phá giáp, làm choáng (`stun`) tốt | Vung bổ ngắn trên không; **`Xuống + Đánh` = `Air Slam` hạng nặng** lao thẳng đứng xuống dậm đất gây chấn động mạnh | *Búa Gỗ* (mặc định) → *Búa Sắt* (Tiên Ông/Rèn) → *Búa Đá Cổ* |
| **Axe (`AXE`)** | Quét vòng cung rộng chéo/ngang, chém nhiều quái cùng lúc, lực đẩy lùi khá | Quét vòng cung rộng trên không; **`Xuống + Đánh` = `Air Slam` bổ xoáy/bổ chéo** rơi xuống đất (tầm rộng hơn Búa, khựng ngắn hơn) | *Rìu Tiều Phu* → *Rìu Đồng* → *Rìu Thần Lực* |
| **Blade (`BLADE`)** | Chém nhanh linh hoạt, combo 3 nhịp mượt, thu đòn nhanh dễ lướt né (`Dash`) | **Không có `Air Slam` dậm đất**; liên trảm nhanh 2 nhịp giữ người hơi lơ lửng chậm rơi (`Air Stall`) để trị quái bay; `Xuống + Đánh` chém chéo nhanh | *Dao Rựa Rừng* → *Đoản Đao* → *Kiếm Bạch Hổ* |
| **Polearm (`POLEARM`)** | Đâm thẳng tầm xa kết hợp quét giữ khoảng cách an toàn với quái | **Không có `Air Slam` dậm đất**; đánh thường đâm ngang tầm xa; `Xuống + Đánh` chọc mũi thương xuống dưới — trúng đầu quái/vật thể sẽ **bật nảy ngược lên cao (`Pogo Bounce`)** | *Gậy Tre Vót* → *Mác Sắt* → *Thương Long* |

#### Đặc tả dữ liệu `WeaponData (.tres)`
Mỗi cây vũ khí là một Resource `WeaponData` (có `id: StringName` ổn định để lưu game) gồm thông số chiến đấu (`damage`, `crit_chance`, `recipe`) và **5 khối profile kỹ thuật** (cho phép nhiều vũ khí cùng nhóm tái sử dụng chung bộ animation nhưng vẫn chỉnh thông số riêng):
1. **`animation_profile` (`WeaponAnimProfile`):** Khai báo nhóm vũ khí (`HAMMER`, `AXE`, `BLADE`, `POLEARM`), tên chuỗi animation dùng trên `AnimationPlayer` (`attack_1`, `attack_2`, `attack_3`, `air_attack`, `air_down_attack`), và hệ số tốc độ phát (`anim_speed_scale`).
2. **`grip_offset`:** Lưu điểm nắm tay trên cán vũ khí (`grip_point_px: Vector2i`) và góc nghiêng chuẩn hóa (`base_rotation_deg: float`) để cán búa/kiếm/thương luôn khớp chính xác vào lòng bàn tay Thạch Sanh.
3. **`hitbox_profile` (`WeaponHitboxProfile`):** Quy định kích thước vùng đánh (`size`), độ lệch vị trí (`offset`), lực đẩy lùi (`knockback_force`) và thời gian khựng (`hitstop_duration`) riêng cho từng nhịp trong combo mặt đất và không chiến.
4. **`slash_vfx_profile` (`SlashVfxProfile`):** Quy định spritesheet/kiểu vệt sáng (bổ dọc, vòng cung rộng, nhát chém mỏng, mũi đâm xuyên, sóng dậm đất), màu `modulate`, độ lệch vị trí và góc xoay hiển thị.
5. **`combo_profile` (`WeaponComboProfile`):** Quy định số nhịp tối đa (`max_steps`), hệ số sát thương từng nhịp (VD `[1.0, 1.1, 1.4]`), cửa sổ thời gian cho phép nối đòn (`combo_window`), thời gian nhận lệnh sớm (`input_buffer`), khung thời gian được phép hủy đòn sang `Dash` (`cancel_to_dash_time`), và tham số vật lý không chiến (`air_slam_speed` / `air_stall_gravity_scale` / `pogo_bounce_velocity`).

### 4.2. Ba Pháp Bảo Cổ Tích & Cơ Chế Hồi MP Chủ Động
- **Cách hiển thị thống nhất ("Linh ảnh Pháp bảo phát sáng"):** Khi bấm tung Pháp bảo, Thạch Sanh **giữ nguyên vũ khí cận chiến trong tay** (không cần cất búa hay vẽ thêm bộ tay kéo cung/gảy đàn phức tạp), chỉ cần phất tay nhẹ để triệu hồi **linh ảnh Pháp bảo phát hào quang lơ lửng ngay cạnh người** tự thi triển hiệu ứng rồi tan thành hạt sáng.
- **Hồi MP khi chiến đấu:** Mỗi nhát đánh cận chiến trúng quái hồi nhẹ **`2–3 MP`**, khuyến khích người chơi áp sát giao chiến để tích MP tung Pháp bảo, thay vì chỉ chờ uống bình MP trên đai lưng.
1. **Niêu Cơm Thần (Hồi máu cốt lõi):**
   - Dùng miễn phí không tốn MP, giữ tối đa **2–3 lần ăn/chuyến đi** (tăng dần khi nâng cấp).
   - **Tự động đầy lại** mỗi khi Thạch Sanh quay về Làng Lộc Trĩ nghỉ ngơi.
2. **Cung Tên Vàng (Tốn MP):**
   - Triệu hồi linh ảnh Cung Vàng lơ lửng trước mặt, tự giương dây bắn mũi tên ánh sáng tầm xa (thẳng/chéo hoặc tự hướng nhẹ), khắc chế quái bay và Boss *Đại Bàng*.
3. **Đàn Thần (Tốn MP):**
   - Triệu hồi linh ảnh Đàn Thần phát sáng bên cạnh, tự gảy khúc nhạc tạo sóng âm lan rộng quanh Thạch Sanh, làm **choáng & đẩy lùi** quái đang vây quanh, thậm chí đánh rớt đạn của quái.

---

## 5. Nhập Vai, Kinh Tế, Chỉ Số Mốc & Giới Hạn Bình Thuốc

- **Chỉ số mốc Cấp 1 (`Baseline Stats` tham chiếu cân bằng):**
  - **Thạch Sanh (Lv.1):** `Max HP = 100`, `Max MP = 50`, `Base ATK = 5`. Đeo **Búa Gỗ** (`+10 ATK`) gây **`15` sát thương**/nhát đánh thường (và hồi `2–3 MP` mỗi nhát trúng).
  - **Quái thường Màn 1:** `35–45 HP` (~3 nhát Búa Gỗ hạ gục), gây `12–18` sát thương/đòn.
- **Lên cấp (Level & EXP):** Đánh quái nhận `EXP`. Mỗi lần lên cấp tăng nhẹ `Max HP`, `Max MP` và `Base ATK` (giúp người chơi cảm thấy nhân vật khỏe lên rõ rệt, nhưng vẫn không thể đứng yên chịu đòn với Boss).
- **Kinh tế 2 lớp (Vàng + Nguyên liệu):**
  - *Vàng:* Dùng mua bình máu/mana, nâng cấp nhà/túi, mua vũ khí cơ bản, trả phí Xa Phu (hoặc miễn phí sau khi mở tuyến).
  - *Nguyên liệu quái/rương:* Gỗ quý, Quặng sắt, Nanh chằn tinh, Lông đại bàng... dùng để rèn các vũ khí hiếm và nâng cấp Niêu Cơm Thần.
- **Cơ chế Giới Hạn Bình Thuốc (Giữ độ gay cấn):**
  - Tại tiệm **Cô Bé Tạp Hóa**, người chơi có thể mua nhiều bình HP / bình MP dự trữ.
  - Tuy nhiên, khi xuất phát rời Làng Lộc Trĩ, **Túi Đai Lưng chỉ mang theo tối đa 3 bình HP + 2 bình MP** (có thể nâng cấp nhẹ về cuối game). Số dư nằm trong Rương ở Làng.
  - Lý do: Tránh tình trạng "bơm 99 bình máu" đứng tank Boss, giữ nguyên độ căng thẳng của chất Action-Platformer 70%.

---

## 6. Cấu Trúc Thế Giới: Hub Làng Lộc Trĩ & Các Màn Chơi

### 6.1. Làng Lộc Trĩ (Khu vực an toàn trung tâm)
- **Nhà Tranh Thạch Sanh:** Giường ngủ (lưu game thủ công qua `SaveManager` có đánh số `save_version`, lưu ID vật phẩm/vũ khí/rương đã mở ổn định kèm bản sao lưu `.bak` chống hỏng file; hồi đầy HP/MP/Niêu Cơm Thần; cho phép **ngủ để chuyển nhanh Sáng ↔ Đêm**), Rương đồ (lấy bình máu nạp vào đai lưng và cất giữ Vàng dự phòng).
- **Anh Thợ Rèn:** Mua vũ khí mới, rèn vũ khí đặc biệt từ nguyên liệu, cường hóa vũ khí.
- **Cô Bé Tạp Hóa:** Bán bình HP, bình MP và vật phẩm hỗ trợ tạm thời (bùa chống choáng, thuốc tăng tốc).
- **Anh Xa Phu:** Bản đồ dịch chuyển nhanh tới bất kỳ màn chơi nào đã mở khóa (nhiều màn sẽ có bảng chỉ dẫn/cổng lối vào + điểm dừng Xa Phu).
- **Lý Thông & Dân Làng:** Nơi tiếp nhận cốt truyện, nhiệm vụ phụ săn quái/tìm nguyên liệu.

### 6.2. Cấu trúc một Màn chơi (Stage)
- Đi cảnh theo chiều ngang từ điểm xuất phát đến điểm Boss / Cổng kết màn.
- Mỗi màn có **1–2 ngách rẽ phụ hoặc tầng ẩn** (yêu cầu nhảy khéo hoặc dùng *Dash*) giấu rương Vàng và khoáng thạch hiếm để thưởng cho người thích khám phá.
- **Quy tắc hồi sinh quái & Rương bí mật:** Quái thường hồi sinh lại mỗi khi vào lại màn để cày EXP/Vàng/nguyên liệu; riêng **Rương bí mật chỉ mở 1 lần duy nhất** (lưu ID rương vào `SaveManager`, lần sau quay lại sẽ thấy rương đang mở nắp trống).
- Quái vật gồm quái đi tuần trên đất, quái nhảy/lao tới, quái bay và quái bắn tầm xa.

### 6.3. Phác thảo khung 9 Vùng Đất (Mở rộng theo tiến độ)
1. **Màn 1 – Rừng Ven Làng:** Sóc dại, Rắn lục, Bọ gai; cuối màn là đường lên Nhị Trụ Tùng.
2. **Màn 2 – Nhị Trụ Tùng:** Gặp **Tiên Ông**, mở khóa **Búa Sắt** & hướng dẫn Pháp bảo; Mini-boss Khỉ Đá.
3. **Màn 3 – Miếu Hoang & Rừng Sương Mù:** Quái ma trơi/tà khí nhẹ; manh mối đầu tiên về âm mưu của Lý Thông.
4. **Màn 4 – Hang Chằn Tinh:** Mê cung hang tối có đuốc; **Boss lớn 1: Chằn Tinh** (nhận *Cung Tên Vàng* hoặc manh mối cứu công chúa).
5. **Màn 5 – Đèo Lửa / Rừng Cháy:** Địa hình nhảy cột đá; **Boss: Đại Hỏa Hầu**.
6. **Màn 6 – Vực Gió & Tổ Chim:** Nền tảng cao có gió thổi & cầu treo; **Boss: Đại Bàng Khổng Lồ** (cần dùng Cung Tên Vàng bắn rụng).
7. **Màn 7 – Động Đáy Vực:** Tìm thấy công chúa Huỳnh Nga bị giam; bẫy sập & đối đầu phản bội của Lý Thông.
8. **Màn 8 – Thủy Cung Thuồng Luồng:** Bến nước/hang ngập nước nguy hiểm; **Boss: Thuồng Luồng**.
9. **Màn 9 – Vết Nứt Tà Khí:** Màn tổng lực mở khóa *Đàn Thần* toàn lực, trùm cuối nguyên nhân gây biến dị cổ tích.

*(Lưu ý: Thứ tự và tình tiết từ Màn 3 trở đi hoàn toàn linh hoạt, có thể điều chỉnh lại bất cứ lúc nào khi phát triển tới nơi).*

---

## 7. Chu Kỳ Sáng – Chiều – Tối & Luật Sông Sâu / Hết Máu

### 7.1. Chu kỳ Thời Gian (~12–15 phút thực / 1 ngày đêm trong game)
Chia thành 4 giai đoạn chuyển màu ánh sáng mượt mà:
- **Bình Minh (2 phút):** Trời hồng ấm nhẹ.
- **Ban Ngày (6 phút):** Sáng rõ, quái ở trạng thái bình thường, thích hợp khám phá màn mới.
- **Hoàng Hôn (2 phút):** Nhuộm cam tím hoài niệm, nhạc nền chuyển lắng.
- **Ban Đêm (4 phút):**
  - **Trong Làng Lộc Trĩ:** Lên đèn lồng vàng ấm cúng, NPC có thêm lời thoại buổi tối, không khí yên bình.
  - **Ngoài các Màn chiến đấu:** Tầm nhìn thu hẹp hơn một chút (có đom đóm, ánh đèn từ vũ khí/đuốc), **quái hung hãn hơn (~ +20% ATK & tốc độ)** nhưng **rơi nhiều Vàng hơn (~ +35%) và có tỷ lệ rơi nguyên liệu đêm hiếm**.
  - Có thể về Nhà Tranh ngủ để chuyển ngay giữa Sáng và Đêm tùy chiến thuật cày đồ hay đi cốt truyện.

### 7.2. Cơ Chế Rơi Xuống Sông / Vực Sâu (Khắc nghiệt vừa đủ & An toàn kỹ thuật)
Khi Thạch Sanh rơi vào vùng nước sâu (`RiverHazard`) hoặc vực thẳm (`PitHazard`):
- **Chỉ trừ sát thương đúng 1 lần mỗi cú rơi:** Hệ thống khóa xử lý hazard để trừ đúng **80% Máu tối đa (`int(ceil(max_hp * 0.8))`)** một lần duy nhất (kể cả khi Thạch Sanh đang có `i-frames` do bị quái đánh hất xuống sông).
- **Vị trí hồi phục `SafeAnchor` phải thực sự an toàn:** `SafeAnchor` chỉ được ghi nhận khi cả hai bàn chân nhân vật đứng ổn định trên mặt đất tĩnh (`TileMapLayer`) và nằm ngoài vùng đệm sát vực/bẫy; tuyệt đối không ghi đè `SafeAnchor` khi đang đứng mấp mé mép vực, trên bục di chuyển hoặc bục sập.
- **Thứ tự xử lý chuẩn:**
  1. Khóa kích hoạt hazard và tính trừ **80% `Max HP`**.
  2. Nếu `current_hp <= 0`: Chuyển thẳng vào chuỗi thất bại (`Dead`) → cuốn về **Làng Lộc Trĩ** (gợi lại đúng nỗi ám ảnh hài hước của bản 2006 nhưng công bằng hơn nhiều!).
  3. Nếu vẫn còn sống (`current_hp > 0`): Hủy động tác đang dở, triệt tiêu vận tốc về `0`, dịch chuyển về `SafeAnchor` an toàn gần nhất, sau đó mới bật chớp bất tử `i-frames` (~1.2s) và chỉ mở khóa hazard sau khi đã rời hẳn vùng nguy hiểm (chống kích hoạt lặp vô tận).

### 7.3. Hình phạt khi Hết Máu (`0 HP`)
- Thạch Sanh tỉnh dậy tại giường trong Nhà Tranh ở **Làng Lộc Trĩ**, hồi đầy HP, MP và *Niêu Cơm Thần*.
- **Giữ nguyên 100%:** Cấp độ (Level), EXP, toàn bộ vũ khí, pháp bảo, nguyên liệu rèn đồ và tiến độ cốt truyện đã mở.
- **Mất nhẹ:** Rớt lại **15% số Vàng đang cầm trên người** (có thể giữ Vàng an toàn trong Rương ở Nhà Tranh trước khi đi đánh Boss khó).
