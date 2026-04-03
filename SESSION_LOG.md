# Noti HDD 앱 개발 세션 로그

**날짜**: 2026-03-14
**프로젝트**: `Noti HDD`
**앱**: macOS 메뉴바 앱 (디스크 활동 LED + 눈운동 햄스터 오버레이)

---

## 1. 씨앗 이미지 교체

### 요청
> 씨앗이미지를 교체할꺼야, 사진에서 씨앗만 추출해서 사용하고, 현재 있는 씨앗은 버리지 말고 다른 파일로 저장해둬

### 작업 내용

**배경**
- 기존 씨앗(`SunflowerSeedView`)은 Swift 코드로 직접 그린 Bezier Path 기반
- 사용자가 제공한 해바라기씨 일러스트 이미지 사용 요청

**씨앗 이미지 파일 위치 확인**
- `~/Downloads/1773492538509.jpg` — 사용자가 채팅에 공유한 씨앗 이미지

**배경 제거 과정 (Python/Pillow)**
```python
# 1단계: 흰색 배경 flood fill 제거
# 2단계: 회색 타원형 그림자 제거
# 3단계: 투명 여백 crop
# 결과: 719 x 847 px PNG (투명 배경)
```

**저장 경로**
- 추출된 씨앗: `Noti HDD/Assets.xcassets/sunflower_seed.imageset/sunflower_seed.png`
- 기존 코드 백업: `Noti HDD/SunflowerSeedView_original.swift` (클래스명 `SunflowerSeedView_Original`로 변경)

**코드 변경** (`EyeExerciseOverlay.swift`)
```swift
// placeSeed() 에서 SunflowerSeedView 직접 생성 → makeSeedView() 호출로 변경
private func makeSeedView(frame: NSRect) -> NSView {
    if let img = NSImage(named: "sunflower_seed") {
        let iv = NSImageView(frame: frame)
        iv.image = img
        iv.imageScaling = .scaleProportionallyUpOrDown
        iv.wantsLayer = true
        return iv
    } else {
        return SunflowerSeedView(frame: frame)  // 폴백
    }
}
```

---

## 2. 메뉴 그림/사진 버튼 → 실제 이미지 썸네일로 교체 + 시간 3자리 지원

### 요청
> 그림 바로보기 / 사진 바로보기 로 되어 있는데 내가원하는 것은 버튼이 아니라 실제 이미지가 나와야해
> 그리고 시간설정도 3자리까지 들어갈꺼야 현재 1자리만 보여. 수정 요망

### 작업 내용

**EyeExerciseMenuView.swift 전면 재설계**

| 항목 | 변경 전 | 변경 후 |
|------|--------|--------|
| 그림 행 | "바로확인" 버튼 | HamsterView 60×60 썸네일 |
| 사진 행 | "바로확인" 버튼 | hamster_photo NSImageView 60×60 썸네일 |
| minuteField 너비 | 34px (1~2자리) | 44px (3자리 지원) |
| viewHeight | 122px | 214px |

**레이아웃 구조 (y 좌표는 하단 기준)**
```
R1 (y=190): Eye Exercises ✓  [___44___] ↕ 분  [바로확인]
R2 (y=166): 속도: [__] ↕  1(느림)~10(빠름)
R3 (y=96):  ○ 그림  [HamsterView 60×60]
R4 (y=26):  ○ 사진  [hamster_photo 60×60]
R5 (y=4):   이동: ○ Default  ○ Random
```

---

## 3. 사진 썸네일 꽉차게 (Aspect Fill)

### 요청
> 사진 썸네일 꽉차게 수정해주세요. 한쪽으로 치우쳐있어

### 원인
`scaleProportionallyUpOrDown` 사용 → 세로 사진이 60×60 프레임에서 45×60으로 표시되어 좌우 공백 발생

### 해결
```swift
// 클리핑 컨테이너 + Aspect Fill
let container = NSView(frame: ...)
container.wantsLayer = true
container.layer?.cornerRadius = 8
container.layer?.masksToBounds = true

let scale = max(side / img.size.width, side / img.size.height)
let fw = img.size.width * scale
let fh = img.size.height * scale
let iv = NSImageView(frame: NSRect(
    x: (side - fw) / 2, y: (side - fh) / 2,
    width: fw, height: fh
))
iv.imageScaling = .scaleAxesIndependently
container.addSubview(iv)
```

---

## 4. 코드 햄스터 크기 0.6배

### 요청
> 그림으로된 햄스터가 너무 커, 0.6배로 줄여줘

### 변경
```swift
// EyeExerciseOverlay.swift
private let size: CGFloat = 250  →  private let size: CGFloat = 150  // 250 * 0.6
```

---

## 5. 그림 햄스터 크기를 사진 원본 크기와 동일하게

### 요청
> 그림 이미지의 크기를 사진 원본이미지의 크기와 동일하게 맞춰줘

### 배경
0.6배 변경 시 `size` 변수를 공유해 사진도 같이 150으로 축소됨 → 사진도 의도치 않게 작아진 상태

### 변경
```swift
private let size: CGFloat = 150  →  private let size: CGFloat = 250  // 원래 크기로 복원
```

---

## 6. 코드/사진 햄스터 크기 확인

### 요청
> 코드로 만든 햄스터 그림의 크기를 확인하고 hamster_photo.png 크기를 확인해줘

### 결과
| 항목 | 크기 |
|------|------|
| HamsterView 프레임 | 250 × 250 pt |
| hamster_photo.png 원본 | 3024 × 4032 px |
| hamster_photo.png 오버레이 표시 | 약 188 × 250 pt (비율 유지, 좌우 공백 발생) |

---

## 7. hamster_photo.png 여백 제거 (투명 영역 crop)

### 요청
> hamster_photo.png 파일에서 햄스터만 남도록 여백을 제거해줘

### 작업
```python
# 투명(alpha=0) 여백 자동 crop
img = Image.open(src)
bbox = img.getbbox()   # (1155, 697, 2909, 2862)
cropped = img.crop(bbox)
# 결과: 3024×4032 → 1754×2165
```

**원본 백업**: `hamster_photo_original.png`

---

## 8. hamster_photo.png 정사각형으로 변환 (중앙 정렬)

### 요청
> hamster_photo.png 크기를 가로 2165px 로 변경하고 이미지는 중앙으로 변경해줘

### 작업
```python
# 1754×2165 → 2165×2165 (정사각형, 투명 캔버스에 중앙 배치)
canvas = Image.new('RGBA', (2165, 2165), (0, 0, 0, 0))
x_offset = (2165 - 1754) // 2  # = 205px
canvas.paste(img, (x_offset, 0))
```

**결과**: 햄스터가 좌우 205px 투명 여백으로 중앙 정렬된 2165×2165 정사각형

---

## 9. 메뉴에 햄스터 크기 슬라이더 추가

### 요청
> 매뉴 컨텍스트에 햄스터 키기를 비율로 조절할수 있게 가로 슬라이드 바로 만들어줘, 현재 크기를 50%로해.

### 변경 파일: 4개

**EyeExerciseManager.swift** — 크기 속성 추가
```swift
var hamsterSizePercent: Int = 50 {
    didSet {
        let clamped = max(10, min(100, hamsterSizePercent))
        hamsterSizePercent = clamped
        UserDefaults.standard.set(clamped, forKey: "eyeExerciseHamsterSizePercent")
    }
}
var hamsterSize: CGFloat { CGFloat(hamsterSizePercent) / 100.0 * 400.0 }
// 50% = 200pt, 100% = 400pt, 10% = 40pt
```

**EyeExerciseOverlay.swift** — size를 Manager에서 읽기
```swift
private let size: CGFloat   // 기존 고정값 제거
init(screen: NSScreen, animates: Bool) {
    size = EyeExerciseManager.shared.hamsterSize  // init에서 읽기
    ...
}
```

**EyeExerciseMenuView.swift** — 슬라이더 행(RS) 추가
```
RS (y=168): 크기: [50%] [━━━━━━━━━━━━━━━]
```
```swift
var onHamsterSizeChange: ((Int) -> Void)?
// NSSlider: min=10, max=100, default=50
// 슬라이더 변경 시 퍼센트 레이블 실시간 업데이트
```

**StatusBarController.swift** — 콜백 연결
```swift
eyeView.onHamsterSizeChange = { percent in
    EyeExerciseManager.shared.hamsterSizePercent = percent
}
```

**레이아웃 (업데이트 후, viewHeight=240)**
```
R1 (y=216): Eye Exercises ✓  [___] ↕ 분  [바로확인]
R2 (y=192): 속도: [__] ↕  1(느림)~10(빠름)
RS (y=168): 크기: [50%] [슬라이더━━━━━━━]
R3 (y=96):  ○ 그림  [HamsterView 60×60]
R4 (y=26):  ○ 사진  [hamster_photo 60×60]
R5 (y=4):   이동: ○ Default  ○ Random
```

---

## 10. 마우스 원형 동작 → 오버레이 Pause / 키보드 → Go

### 요청
> 마우스 원형동작을 하면 Overlay Pause 상태로 해주고, 키보드 누르면 go상태로 변경해줘

### 구현 (`EyeExerciseOverlay.swift`)

**추가된 프로퍼티**
```swift
private var mouseMonitor: Any?
private var isPaused = false
private var mousePoints: [NSPoint] = []
private var pauseLabel: NSTextField?
```

**키 모니터 변경**
```swift
keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
    guard let self else { return event }
    if event.keyCode == 53 { self.onDismiss?(); return nil }  // ESC → 종료
    if self.isPaused { self.resumeAnimation(); return nil }   // 아무 키 → GO
    return event
}
```

**원형 감지 알고리즘 (초기)**
```
조건 1: 평균 반지름 > 60px
조건 2: 반지름 변동계수(CV) < 28%
조건 3: 누적 회전각 ≥ 270°
```

**Pause/Resume 메서드**
```swift
func pauseAnimation() {
    isPaused = true
    moveTimer?.invalidate()
    // 화면 중앙에 "⏸ PAUSE" 메시지 표시
}
func resumeAnimation() {
    isPaused = false
    hidePauseIndicator()
    scheduleMoveAfterPause()
}
```

**PAUSE 인디케이터 (화면 중앙)**
```
⏸  PAUSE
마우스 원형 동작 감지됨
키보드를 누르면 재개
```

---

## 11. 원형 감지 조건 완화

### 요청
> 마우스로 원을 그리기는 어려워, 2번 50% 조건으로 변경하면 좀더 원형이 아닌 동작을 인식하는건가?

### 답변
CV 50%로 올리면 타원, 불규칙한 원도 인식됨 → 함께 각도 조건도 완화

| 조건 | 이전 | 변경 |
|------|------|------|
| CV (반지름 변동) | < 28% | < **50%** |
| 회전각 | ≥ 270° | ≥ **200°** |

---

## 12. 감지 방식 교체 — 원형 → 흔들기(Shake) 감지

### 요청
> 현재 마우스 돌리면 마우스 포인터가 확대 되거든 이 이벤트를 받아서 pause 동작을 트리거 시킵시다.

### 배경
macOS의 **"포인터 흔들어 찾기"** 기능과 동일한 감지 조건 사용
→ 빠른 방향 전환(velocity 벡터 반전)을 카운트

### 교체된 알고리즘

**이전**: 복잡한 원형 기하학 계산 (centroid, 반지름, 누적 각도)
**이후**: 속도 벡터 반전 카운트

```swift
private var lastMousePt: NSPoint = .zero
private var prevVelocity: CGPoint = .zero
private var shakeReversals: [Date] = []

func handleMouseMoved(_ pt: NSPoint) {
    let vel = CGPoint(x: pt.x - lastMousePt.x, y: pt.y - lastMousePt.y)
    let speed = hypot(vel.x, vel.y)

    guard speed > 8 else { return }  // 느린 이동 무시

    // 내적 < 0 → 방향 반전
    let dot = vel.x * prevVelocity.x + vel.y * prevVelocity.y
    if hypot(prevVelocity.x, prevVelocity.y) > 8 && dot < 0 {
        shakeReversals.append(Date())
        // 0.6초 이내 반전만 유지
        shakeReversals = shakeReversals.filter { ... < 0.6 }

        if shakeReversals.count >= 3 {
            // → PAUSE 트리거
        }
    }
    prevVelocity = vel
}
```

**감지 조건 요약**
| 조건 | 값 |
|------|-----|
| 최소 이동 속도 | 8px/event |
| 반전 횟수 | 3회 이상 |
| 시간 윈도우 | 0.6초 이내 |

---

## 변경된 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `EyeExerciseOverlay.swift` | Shake 감지, Pause/Resume, 크기 동적 로딩, makeSeedView() |
| `EyeExerciseMenuView.swift` | 썸네일 표시, 슬라이더 행, 3자리 시간 입력 |
| `EyeExerciseManager.swift` | hamsterSizePercent, hamsterSize 추가 |
| `StatusBarController.swift` | 슬라이더 콜백 연결 |
| `SunflowerSeedView_original.swift` | 기존 코드 드로잉 백업 (신규) |
| `Assets.xcassets/sunflower_seed.imageset/` | 씨앗 이미지 에셋 (신규) |
| `Assets.xcassets/hamster_photo.imageset/hamster_photo.png` | 여백 제거, 정사각형 변환 |
| `Assets.xcassets/hamster_photo.imageset/hamster_photo_original.png` | 원본 백업 (신규) |

---

## 앱 구조 요약

```
Noti HDD (macOS Menu Bar App)
├── StatusBarController.swift     — 메뉴바 아이콘, 메뉴 구성
├── DiskMonitor.swift             — 디스크 I/O 모니터링
├── LEDView.swift                 — LED 스타일 뷰
├── EyeExerciseManager.swift      — 눈운동 타이머, 설정 관리
├── EyeExerciseOverlay.swift      — 풀스크린 오버레이 (햄스터 애니메이션)
│   ├── EyeExerciseOverlayWindow  — 오버레이 창
│   ├── SunflowerSeedView         — 씨앗 코드 드로잉 (폴백용)
│   └── HamsterView               — 햄스터 코드 드로잉
├── EyeExerciseMenuView.swift     — 메뉴 커스텀 뷰
└── Assets.xcassets/
    ├── hamster_photo.imageset/   — 실사 햄스터 사진
    └── sunflower_seed.imageset/  — 해바라기씨 이미지
```

---

*Generated: 2026-03-14*
