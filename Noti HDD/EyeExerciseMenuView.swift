import Cocoa

class EyeExerciseMenuView: NSView, NSTextFieldDelegate {
    var onToggle: ((Bool) -> Void)?
    var onMinutesChange: ((Int) -> Void)?
    var onSpeedChange: ((Int) -> Void)?
    var onPreview: (() -> Void)?
    var onMovementModeChange: ((String) -> Void)?
    var onRocketSizeChange: ((Int) -> Void)?
    var onCircularDetectorChange: ((Bool) -> Void)?
    var onShakeDetectorChange:    ((Bool) -> Void)?

    private let checkBox:       NSButton
    private let minuteField:    NSTextField
    private let minuteStepper:  NSStepper
    private let unitLabel:      NSTextField
    private let previewButton:  NSButton
    private let speedLabel:     NSTextField
    private let speedField:     NSTextField
    private let speedStepper:   NSStepper
    private let speedSlider:    NSSlider
    private let speedHint:      NSTextField
    private let moveLabel:        NSTextField
    private let moveDefaultBtn:   NSButton
    private let moveRandomBtn:    NSButton
    private let sizeSlider:         NSSlider
    private let sizePercentLabel:   NSTextField
    private let circularCheckBox:   NSButton
    private let shakeCheckBox:      NSButton

    // 행 1: Eye Exercises 체크 + 분 설정(3자리) + 바로확인
    // 행 2: 이동 속도 숫자 설정 + 이동 시간 표시
    // 행 2S: 이동 속도 슬라이더
    // 행 S: 로켓크기 슬라이더
    // 행 3: 나로호 [로켓 미리보기]
    // 행 5: 이동: ○ Default  ○ Random
    static let viewWidth:  CGFloat = 260
    static let viewHeight: CGFloat = 184

    private enum R1 {   // Row 1  (y=160..184)
        static let y: CGFloat = 160;  static let h: CGFloat = 24
        static let checkX: CGFloat = 14;  static let checkW: CGFloat = 100
        static let fieldX: CGFloat = 118; static let fieldW: CGFloat = 44
        static let stepX:  CGFloat = 164; static let stepW:  CGFloat = 15
        static let unitX:  CGFloat = 181; static let unitW:  CGFloat = 16
        static let prevX:  CGFloat = 198; static let prevW:  CGFloat = 62
    }
    private enum R2 {   // Row 2  (y=136..158)
        static let y: CGFloat = 136;  static let h: CGFloat = 22
        static let labelX: CGFloat = 18; static let labelW: CGFloat = 52
        static let fieldX: CGFloat = 74; static let fieldW: CGFloat = 30
        static let stepX:  CGFloat = 107; static let stepW: CGFloat = 15
        static let hintX: CGFloat = 127; static let hintW: CGFloat = 126
    }
    private enum R2S {   // Row Speed Slider  (y=112..134)
        static let y: CGFloat = 112; static let h: CGFloat = 22
        static let labelX: CGFloat = 18; static let labelW: CGFloat = 24
        static let sliderX: CGFloat = 46; static let sliderW: CGFloat = 167
        static let fastX: CGFloat = 219
    }
    private enum RS {   // Row Size  (y=88..110)  로켓크기 슬라이더
        static let y: CGFloat = 88;  static let h: CGFloat = 22
        static let labelX:   CGFloat = 18;  static let labelW:   CGFloat = 64
        static let percentX: CGFloat = 84;  static let percentW: CGFloat = 36
        static let sliderX:  CGFloat = 123; static let sliderW:  CGFloat = 126
    }
    private enum RP {   // Row Pause  (y=64..86)  일시정지 트리거
        static let y: CGFloat = 64;  static let h: CGFloat = 22
        static let labelX:  CGFloat = 18; static let labelW:  CGFloat = 50
        static let check1X: CGFloat = 70; static let check1W: CGFloat = 90
        static let check2X: CGFloat = 162; static let check2W: CGFloat = 80
    }
    private enum R3 {   // Row 3  (y=26..62)  나로호 로켓 미리보기
        static let y: CGFloat = 26;  static let h: CGFloat = 36
        static let labelX: CGFloat = 18; static let labelW: CGFloat = 60
        static let imgX: CGFloat = 84; static let imgSize: CGFloat = 32
    }
    private enum R5 {   // Row 5  (y=4..24)  이동 방향
        static let y: CGFloat = 4;  static let h: CGFloat = 20
        static let labelX: CGFloat = 14; static let labelW: CGFloat = 30
        static let btn1X:  CGFloat = 47; static let btnW:   CGFloat = 72
        static let btn2X:  CGFloat = 123
    }

    init(isChecked: Bool, minutes: Int, speed: Int,
         movementMode: String, rocketSizePercent: Int,
         circularEnabled: Bool, shakeEnabled: Bool) {
        checkBox         = NSButton(checkboxWithTitle: "Eye Exercises", target: nil, action: nil)
        minuteField      = NSTextField(frame: .zero)
        minuteStepper    = NSStepper(frame: .zero)
        unitLabel        = NSTextField(labelWithString: "분")
        previewButton    = NSButton(title: "바로확인", target: nil, action: nil)
        speedLabel       = NSTextField(labelWithString: "이동속도:")
        speedField       = NSTextField(frame: .zero)
        speedStepper     = NSStepper(frame: .zero)
        speedSlider      = NSSlider(frame: .zero)
        speedHint        = NSTextField(labelWithString: "")
        moveLabel        = NSTextField(labelWithString: "이동:")
        moveDefaultBtn   = NSButton(radioButtonWithTitle: "Default", target: nil, action: nil)
        moveRandomBtn    = NSButton(radioButtonWithTitle: "Random", target: nil, action: nil)
        sizeSlider       = NSSlider(frame: .zero)
        sizePercentLabel = NSTextField(labelWithString: "\(rocketSizePercent)%")
        circularCheckBox = NSButton(checkboxWithTitle: "원형동작", target: nil, action: nil)
        shakeCheckBox    = NSButton(checkboxWithTitle: "흔들기", target: nil, action: nil)
        super.init(frame: NSRect(x: 0, y: 0, width: Self.viewWidth, height: Self.viewHeight))
        setupRow1(isChecked: isChecked, minutes: minutes)
        setupRow2(speed: speed)
        setupSpeedSlider(speed: speed)
        setupSizeRow(sizePercent: rocketSizePercent)
        setupPauseRow(circularEnabled: circularEnabled, shakeEnabled: shakeEnabled)
        setupRocketRow()
        setupRow5(movementMode: movementMode)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Row 1 (Eye Exercises + 분 + 바로확인)

    private func setupRow1(isChecked: Bool, minutes: Int) {
        let mid = R1.y + (R1.h - 20) / 2

        checkBox.frame  = NSRect(x: R1.checkX, y: mid, width: R1.checkW, height: 20)
        checkBox.font   = NSFont.systemFont(ofSize: 11)
        checkBox.state  = isChecked ? .on : .off
        checkBox.target = self; checkBox.action = #selector(toggled)
        addSubview(checkBox)

        minuteField.frame       = NSRect(x: R1.fieldX, y: mid + 1, width: R1.fieldW, height: 18)
        minuteField.stringValue = "\(max(1, minutes))"
        minuteField.isEditable  = true
        minuteField.isBezeled   = true
        minuteField.bezelStyle  = .roundedBezel
        minuteField.alignment   = .center
        minuteField.font        = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        minuteField.delegate    = self
        minuteField.tag         = 1
        let fmt1 = NumberFormatter(); fmt1.numberStyle = .none
        fmt1.minimum = 1; fmt1.maximum = 480
        minuteField.formatter = fmt1
        addSubview(minuteField)

        minuteStepper.frame        = NSRect(x: R1.stepX, y: mid, width: R1.stepW, height: 20)
        minuteStepper.minValue     = 1; minuteStepper.maxValue = 480
        minuteStepper.increment    = 1; minuteStepper.integerValue = max(1, minutes)
        minuteStepper.valueWraps   = false
        minuteStepper.target       = self; minuteStepper.action = #selector(minuteStepperChanged)
        addSubview(minuteStepper)

        unitLabel.frame     = NSRect(x: R1.unitX, y: mid + 2, width: R1.unitW, height: 16)
        unitLabel.font      = NSFont.systemFont(ofSize: 11)
        unitLabel.textColor = .secondaryLabelColor
        addSubview(unitLabel)

        previewButton.frame      = NSRect(x: R1.prevX, y: mid + 1, width: R1.prevW, height: 18)
        previewButton.bezelStyle = .rounded
        previewButton.font       = NSFont.systemFont(ofSize: 11)
        previewButton.target     = self; previewButton.action = #selector(previewTapped)
        addSubview(previewButton)
    }

    // MARK: - Row 2 (속도)

    private func setupRow2(speed: Int) {
        let mid = R2.y + (R2.h - 16) / 2

        speedLabel.frame     = NSRect(x: R2.labelX, y: mid, width: R2.labelW, height: 16)
        speedLabel.font      = NSFont.systemFont(ofSize: 11)
        speedLabel.textColor = .secondaryLabelColor
        addSubview(speedLabel)

        speedField.frame       = NSRect(x: R2.fieldX, y: R2.y + 2, width: R2.fieldW, height: 18)
        speedField.stringValue = "\(EyeExerciseMotion.clampedSpeed(speed))"
        speedField.isEditable  = true
        speedField.isBezeled   = true
        speedField.bezelStyle  = .roundedBezel
        speedField.alignment   = .center
        speedField.font        = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        speedField.textColor   = .labelColor
        speedField.delegate    = self
        speedField.tag         = 2
        let fmt2 = NumberFormatter(); fmt2.numberStyle = .none
        fmt2.minimum = 1; fmt2.maximum = 10
        speedField.formatter = fmt2
        addSubview(speedField)

        speedStepper.frame        = NSRect(x: R2.stepX, y: R2.y + 1, width: R2.stepW, height: 20)
        speedStepper.minValue     = 1; speedStepper.maxValue = 10
        speedStepper.increment    = 1; speedStepper.integerValue = EyeExerciseMotion.clampedSpeed(speed)
        speedStepper.valueWraps   = false
        speedStepper.target       = self; speedStepper.action = #selector(speedStepperChanged)
        addSubview(speedStepper)

        speedHint.frame     = NSRect(x: R2.hintX, y: mid, width: R2.hintW, height: 16)
        speedHint.font      = NSFont.systemFont(ofSize: 10)
        speedHint.textColor = .secondaryLabelColor
        speedHint.toolTip   = "화면의 긴 방향을 끝에서 끝까지 이동하는 시간입니다. 구간이 짧으면 이동 시간도 짧아집니다."
        speedHint.stringValue = speedDescription(speed)
        addSubview(speedHint)
    }

    private func setupSpeedSlider(speed: Int) {
        for (text, x) in [("느림", R2S.labelX), ("빠름", R2S.fastX)] {
            let label = NSTextField(labelWithString: text)
            label.frame = NSRect(x: x, y: R2S.y + 3, width: R2S.labelW, height: 16)
            label.font = NSFont.systemFont(ofSize: 10)
            label.textColor = .secondaryLabelColor
            addSubview(label)
        }
        speedSlider.frame = NSRect(x: R2S.sliderX, y: R2S.y,
                                   width: R2S.sliderW, height: R2S.h)
        speedSlider.minValue = 1
        speedSlider.maxValue = 10
        speedSlider.numberOfTickMarks = 10
        speedSlider.allowsTickMarkValuesOnly = true
        speedSlider.isContinuous = true
        speedSlider.integerValue = EyeExerciseMotion.clampedSpeed(speed)
        speedSlider.setAccessibilityLabel("눈운동 이동 속도")
        speedSlider.target = self
        speedSlider.action = #selector(speedSliderChanged)
        addSubview(speedSlider)
    }

    private func speedDescription(_ speed: Int) -> String {
        String(format: "한 번 약 %.1f초", EyeExerciseMotion.crossingDuration(speed: speed))
    }

    private func changeSpeed(_ value: Int) {
        let speed = EyeExerciseMotion.clampedSpeed(value)
        speedField.stringValue = "\(speed)"
        speedStepper.integerValue = speed
        speedSlider.integerValue = speed
        speedHint.stringValue = speedDescription(speed)
        onSpeedChange?(speed)
    }

    // MARK: - Row Size (로켓크기 슬라이더)

    private func setupSizeRow(sizePercent: Int) {
        let mid = RS.y + (RS.h - 16) / 2

        let label = NSTextField(labelWithString: "로켓크기:")
        label.frame     = NSRect(x: RS.labelX, y: mid, width: RS.labelW, height: 16)
        label.font      = NSFont.systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        addSubview(label)

        sizePercentLabel.frame     = NSRect(x: RS.percentX, y: mid, width: RS.percentW, height: 16)
        sizePercentLabel.font      = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        sizePercentLabel.alignment = .right
        addSubview(sizePercentLabel)

        sizeSlider.frame           = NSRect(x: RS.sliderX, y: RS.y + 1, width: RS.sliderW, height: 20)
        sizeSlider.sliderType      = .linear
        sizeSlider.minValue        = 10
        sizeSlider.maxValue        = 100
        sizeSlider.intValue        = Int32(sizePercent)
        sizeSlider.target          = self
        sizeSlider.action          = #selector(sizeSliderChanged)
        addSubview(sizeSlider)
    }

    // MARK: - Row Pause (일시정지 트리거)

    private func setupPauseRow(circularEnabled: Bool, shakeEnabled: Bool) {
        let mid = RP.y + (RP.h - 16) / 2

        let label = NSTextField(labelWithString: "일시정지:")
        label.frame     = NSRect(x: RP.labelX, y: mid, width: RP.labelW, height: 16)
        label.font      = NSFont.systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        addSubview(label)

        circularCheckBox.frame  = NSRect(x: RP.check1X, y: mid, width: RP.check1W, height: 18)
        circularCheckBox.font   = NSFont.systemFont(ofSize: 11)
        circularCheckBox.state  = circularEnabled ? .on : .off
        circularCheckBox.target = self; circularCheckBox.action = #selector(circularCheckChanged)
        addSubview(circularCheckBox)

        shakeCheckBox.frame  = NSRect(x: RP.check2X, y: mid, width: RP.check2W, height: 18)
        shakeCheckBox.font   = NSFont.systemFont(ofSize: 11)
        shakeCheckBox.state  = shakeEnabled ? .on : .off
        shakeCheckBox.target = self; shakeCheckBox.action = #selector(shakeCheckChanged)
        addSubview(shakeCheckBox)
    }

    // MARK: - Row 3 (나로호 로켓 미리보기)

    private func setupRocketRow() {
        let label = NSTextField(labelWithString: "나로호")
        label.frame = NSRect(x: R3.labelX, y: R3.y + (R3.h - 16) / 2,
                             width: R3.labelW, height: 16)
        label.font = NSFont.systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        addSubview(label)

        let rocket = RocketView(frame: NSRect(x: R3.imgX, y: R3.y + (R3.h - R3.imgSize) / 2,
                                       width: R3.imgSize, height: R3.imgSize))
        rocket.setAccessibilityRole(.image)
        rocket.setAccessibilityLabel("나로호 로켓 미리보기")
        addSubview(rocket)
    }

    // MARK: - Row 5 (이동 방향)

    private func setupRow5(movementMode: String) {
        let mid = R5.y + (R5.h - 16) / 2

        moveLabel.frame     = NSRect(x: R5.labelX, y: mid, width: R5.labelW, height: 16)
        moveLabel.font      = NSFont.systemFont(ofSize: 11)
        moveLabel.textColor = .secondaryLabelColor
        addSubview(moveLabel)

        moveDefaultBtn.frame  = NSRect(x: R5.btn1X, y: R5.y + 2, width: R5.btnW, height: 18)
        moveDefaultBtn.font   = NSFont.systemFont(ofSize: 11)
        moveDefaultBtn.state  = (movementMode == "default") ? .on : .off
        moveDefaultBtn.target = self; moveDefaultBtn.action = #selector(moveDefaultSelected)
        addSubview(moveDefaultBtn)

        moveRandomBtn.frame  = NSRect(x: R5.btn2X, y: R5.y + 2, width: R5.btnW, height: 18)
        moveRandomBtn.font   = NSFont.systemFont(ofSize: 11)
        moveRandomBtn.state  = (movementMode == "random") ? .on : .off
        moveRandomBtn.target = self; moveRandomBtn.action = #selector(moveRandomSelected)
        addSubview(moveRandomBtn)
    }

    // MARK: - Actions

    @objc private func toggled()       { onToggle?(checkBox.state == .on) }
    @objc private func previewTapped() { onPreview?() }

    @objc private func circularCheckChanged() { onCircularDetectorChange?(circularCheckBox.state == .on) }
    @objc private func shakeCheckChanged()    { onShakeDetectorChange?(shakeCheckBox.state == .on) }

    @objc private func sizeSliderChanged() {
        let v = sizeSlider.integerValue
        sizePercentLabel.stringValue = "\(v)%"
        onRocketSizeChange?(v)
    }

    @objc private func moveDefaultSelected() {
        moveDefaultBtn.state = .on; moveRandomBtn.state = .off
        onMovementModeChange?("default")
    }

    @objc private func moveRandomSelected() {
        moveDefaultBtn.state = .off; moveRandomBtn.state = .on
        onMovementModeChange?("random")
    }

    @objc private func minuteStepperChanged() {
        let v = minuteStepper.integerValue
        minuteField.stringValue = "\(v)"; onMinutesChange?(v)
    }

    @objc private func speedStepperChanged() {
        changeSpeed(speedStepper.integerValue)
    }

    @objc private func speedSliderChanged() { changeSpeed(speedSlider.integerValue) }

    // MARK: - NSTextFieldDelegate

    func controlTextDidEndEditing(_ obj: Notification) {
        guard let field = obj.object as? NSTextField else { return }
        if field.tag == 1 {
            let v = max(1, min(480, Int(field.stringValue) ?? 50))
            field.stringValue = "\(v)"; minuteStepper.integerValue = v
            onMinutesChange?(v)
        } else if field.tag == 2 {
            changeSpeed(Int(field.stringValue) ?? EyeExerciseMotion.defaultSpeed)
        }
    }

    // MARK: - Mouse

    override func mouseDown(with event: NSEvent) {
        let pt = convert(event.locationInWindow, from: nil)
        if minuteField.frame.contains(pt)     { window?.makeFirstResponder(minuteField) }
        else if speedField.frame.contains(pt) { window?.makeFirstResponder(speedField) }
        else { super.mouseDown(with: event) }
    }
}
