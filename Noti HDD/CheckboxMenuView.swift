import Cocoa

/// 메뉴 아이템용 범용 체크박스 뷰 (우측 보조 뷰 옵션)
class CheckboxMenuView: NSView {
    var onToggle: ((Bool) -> Void)?

    private let checkBox: NSButton

    var isChecked: Bool {
        get { checkBox.state == .on }
        set { checkBox.state = newValue ? .on : .off }
    }

    init(frame: NSRect, title: String, checked: Bool) {
        checkBox = NSButton(checkboxWithTitle: title, target: nil, action: nil)
        super.init(frame: frame)

        checkBox.frame = NSRect(x: 14, y: 1, width: frame.width - 14, height: 20)
        checkBox.state = checked ? .on : .off
        checkBox.target = self
        checkBox.action = #selector(toggled)
        addSubview(checkBox)
    }

    required init?(coder: NSCoder) { fatalError() }

    @objc private func toggled() {
        onToggle?(checkBox.state == .on)
    }
}
