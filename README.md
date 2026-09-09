# Carrier Locked → Unlocked 😄

A tiny jailbreak tweak with one tiny job: **SIM locked → No SIM restrictions**.

---

## Tiếng Việt

Một tweak nhỏ với đúng một nhiệm vụ:

```
SIM bị khóa → Không giới hạn SIM
```

Tweak thay đổi dòng **Khóa mạng** tại:

```
Cài đặt → Cài đặt chung → Giới thiệu
```

Không có phép thuật, không hack baseband và chắc chắn không biến máy lock thành máy quốc tế. Trạng thái khóa mạng thật vẫn giữ nguyên — chỉ có dòng chữ trong Settings được thay đổi.

### Có gì bên trong?

- Hướng tới iOS 15.0–17.3.1.
- Hỗ trợ `arm64` và `arm64e`.
- Có thể build cho RootHide, rootless và rootful.
- Tương thích kiến trúc RootHide của Relaxin.
- Chỉ inject vào `com.apple.Preferences`.
- Không sửa file trong `/System`.
- Không chạy nền.
- Không quảng cáo, không theo dõi và không kết nối mạng.

Tweak sử dụng chính chuỗi `CARRIER_LOCK_UNLOCKED` có sẵn trong iOS, vì vậy nội dung có thể tự hiển thị đúng theo ngôn ngữ hệ thống.

### Đã kiểm thử

- ✅ iOS 16.3.1 – RootHide
- 🧪 iOS 15–17.3.1 – được thiết kế để hỗ trợ, cần kiểm thử thêm trên từng jailbreak và thiết bị
- 🧪 Relaxin 17.3.1 – phù hợp kiến trúc RootHide, cần sử dụng đúng bản package

Sau khi reboot về trạng thái stock, tweak sẽ tạm ngừng hoạt động. Chỉ cần kích hoạt lại jailbreak/bootstrap để nó xuất hiện trở lại.

### Cài đặt

Cài đúng file `.deb` dành cho jailbreak của bạn bằng Sileo hoặc Zebra, sau đó mở lại Settings.

Nếu cần:

```sh
killall -9 Preferences
```

### Lưu ý thật lòng

Đây chỉ là một UI tweak vui vẻ, không phải công cụ unlock SIM.

Đừng dùng nó để giới thiệu hoặc bán máy lock như máy quốc tế. Nhà mạng, baseband và hệ thống kích hoạt vẫn biết chính xác trạng thái thật của thiết bị. 😉

---

## English

A tiny jailbreak tweak with one tiny job:

```
SIM locked → No SIM restrictions
```

It changes the **Carrier Lock** text shown under:

```
Settings → General → About
```

No magic, no baseband wizardry, and no real carrier unlock. The device remains locked exactly as before—the Settings text simply looks different.

### What does it offer?

- Designed for iOS 15.0–17.3.1.
- Supports `arm64` and `arm64e`.
- Can be built for RootHide, rootless and rootful environments.
- Compatible with Relaxin's RootHide architecture.
- Injects only into `com.apple.Preferences`.
- Does not modify `/System`.
- No background daemon.
- No analytics, ads, telemetry or network access.

The tweak reuses Apple's existing `CARRIER_LOCK_UNLOCKED` localization, allowing the text to follow the current system language.

### Testing status

- ✅ iOS 16.3.1 – RootHide
- 🧪 iOS 15–17.3.1 – targeted, but individual jailbreak and device testing is still required
- 🧪 Relaxin 17.3.1 – architecture compatible; use the RootHide package

After rebooting into stock iOS, the original status returns until the jailbreak or bootstrap is enabled again.

### Install

Install the correct `.deb` for your jailbreak with Sileo or Zebra, then reopen Settings.

If needed:

```sh
killall -9 Preferences
```

### Honest warning

This is a fun cosmetic UI tweak, not a SIM-unlocking tool.

Please do not use it to misrepresent a carrier-locked device as factory unlocked. The carrier, baseband and activation system still know the device's real status. 😉

---

## Build from source

Use the RootHide fork of Theos, then run:

```sh
export THEOS="$HOME/theos"
make clean package FINALPACKAGE=1
```

The package is emitted under `packages/`.

- Package ID: `com.pank.carrierlocktext`
- Injection target: Settings (`com.apple.Preferences`) only

## Uninstall

Uninstall **Carrier Locked change to Unlocked** in Sileo/Zebra. The original text returns the next time Settings is opened.

## License

[MIT](LICENSE)
