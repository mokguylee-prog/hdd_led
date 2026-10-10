import Cocoa
import ServiceManagement

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var diskMonitor: DiskMonitor!

    private var ledStyleWindowController: LEDStyleWindowController?
    private var aboutWindowController: AboutWindowController?

    private var currentStyle: LEDStyle = .greenRed
    private var isActive: Bool = false

    // Menu items that need to be updated
    private var diskMenuItems: [NSMenuItem] = []
    private var loginCheckboxView: CheckboxMenuView!
    private var eyeMenuView: EyeExerciseMenuView!

    override init() {
        super.init()
        diskMonitor = DiskMonitor()
        loadPreferences()
        setupStatusItem()
        setupMenu()
        setupDiskMonitor()
    }

    // MARK: - Setup

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        updateStatusIcon(active: false)
    }

    private func setupMenu() {
        menu = NSMenu()
        menu.autoenablesItems = false

        // About
        let aboutItem = NSMenuItem(title: "About Noti HDD", action: #selector(showAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(.separator())

        // Monitor Disks submenu
        let monitorItem = NSMenuItem(title: "Monitor Disks", action: nil, keyEquivalent: "")
        let diskSubmenu = NSMenu()
        monitorItem.submenu = diskSubmenu
        menu.addItem(monitorItem)

        // "Monitor All Disk" option
        let allDiskItem = NSMenuItem(title: "Monitor All Disk", action: #selector(selectDisk(_:)), keyEquivalent: "")
        allDiskItem.target = self
        allDiskItem.representedObject = "all"
        allDiskItem.state = (diskMonitor.monitoredDisk == "all") ? .on : .off
        diskSubmenu.addItem(allDiskItem)
        diskMenuItems.append(allDiskItem)

        // Populate individual disks
        updateDiskMenuItems()

        // Not Style
        let ledStyleItem = NSMenuItem(title: "Not Style", action: #selector(showLEDStyle), keyEquivalent: "")
        ledStyleItem.target = self
        menu.addItem(ledStyleItem)

        menu.addItem(.separator())

        // 눈운동
        let eyeItem = NSMenuItem()
        let eyeView = EyeExerciseMenuView(
            isChecked:          EyeExerciseManager.shared.isEnabled,
            minutes:            EyeExerciseManager.shared.intervalMinutes,
            speed:              EyeExerciseManager.shared.speed,
            movementMode:       EyeExerciseManager.shared.movementMode,
            rocketSizePercent:  EyeExerciseManager.shared.rocketSizePercent,
            circularEnabled:    EyeExerciseManager.shared.circularDetectorEnabled,
            shakeEnabled:       EyeExerciseManager.shared.shakeDetectorEnabled
        )
        eyeView.onToggle                  = { enabled in EyeExerciseManager.shared.isEnabled = enabled }
        eyeView.onMinutesChange           = { minutes in EyeExerciseManager.shared.intervalMinutes = minutes }
        eyeView.onSpeedChange             = { speed   in EyeExerciseManager.shared.speed = speed }
        eyeView.onPreview                 = { EyeExerciseManager.shared.showOverlay() }
        eyeView.onMovementModeChange      = { mode    in EyeExerciseManager.shared.movementMode = mode }
        eyeView.onRocketSizeChange        = { percent in EyeExerciseManager.shared.rocketSizePercent = percent }
        eyeView.onCircularDetectorChange  = { enabled in EyeExerciseManager.shared.circularDetectorEnabled = enabled }
        eyeView.onShakeDetectorChange     = { enabled in EyeExerciseManager.shared.shakeDetectorEnabled = enabled }
        eyeItem.view = eyeView
        eyeMenuView = eyeView
        menu.addItem(eyeItem)

        menu.addItem(.separator())

        // Open at Login
        let loginItem = NSMenuItem()
        let loginView = CheckboxMenuView(
            frame: NSRect(x: 0, y: 0, width: 240, height: 22),
            title: "Open at Login",
            checked: isLoginItemEnabled()
        )
        loginView.onToggle = { [weak self] enabled in
            self?.setLoginItem(enabled: enabled)
        }
        loginItem.view = loginView
        loginCheckboxView = loginView
        menu.addItem(loginItem)

        menu.addItem(.separator())

        // Rate on App Store
        let rateItem = NSMenuItem(title: "Rate on App Store", action: #selector(rateOnAppStore), keyEquivalent: "")
        rateItem.target = self
        rateItem.isHidden = true
        menu.addItem(rateItem)

        // Support
        let supportItem = NSMenuItem(title: "Support", action: #selector(openSupport), keyEquivalent: "")
        supportItem.target = self
        supportItem.isHidden = true
        menu.addItem(supportItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateDiskMenuItems() {
        guard let monitorItem = menu.item(withTitle: "Monitor Disks"),
              let diskSubmenu = monitorItem.submenu else { return }

        // Remove old individual disk items (keep "Monitor All Disk")
        while diskSubmenu.numberOfItems > 1 {
            diskSubmenu.removeItem(at: 1)
        }
        diskMenuItems = [diskSubmenu.item(at: 0)!]

        let disks = diskMonitor.availableDisks
        for disk in disks {
            let item = NSMenuItem(title: disk, action: #selector(selectDisk(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = disk
            item.state = (diskMonitor.monitoredDisk == disk) ? .on : .off
            item.isEnabled = true
            diskSubmenu.addItem(item)
            diskMenuItems.append(item)
        }

        // Gray out disks > disk1 like the original app
        for (index, item) in diskMenuItems.enumerated() {
            if index >= 3 {
                item.isEnabled = false
            } else {
                item.isEnabled = true
            }
        }
    }

    private func setupDiskMonitor() {
        diskMonitor.onActivity = { [weak self] active, activities in
            DispatchQueue.main.async {
                self?.updateStatusIcon(active: active)
            }
        }
        diskMonitor.start()

        // Refresh disk list after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.diskMonitor.refreshAvailableDisks()
            self?.updateDiskMenuItems()
        }
    }

    // MARK: - Status Icon

    private func updateStatusIcon(active: Bool) {
        isActive = active
        let color = active ? currentStyle.activeColor : currentStyle.inactiveColor
        statusItem.button?.image = makeLEDStatusImage(color: color)
    }

    // MARK: - Menu Actions

    @objc private func showAbout() {
        if aboutWindowController == nil {
            aboutWindowController = AboutWindowController()
        }
        aboutWindowController?.showWindow(nil)
        aboutWindowController?.window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func selectDisk(_ sender: NSMenuItem) {
        let disk = sender.representedObject as? String ?? "all"
        diskMonitor.monitoredDisk = disk

        for item in diskMenuItems {
            item.state = ((item.representedObject as? String) == disk) ? .on : .off
        }

        savePreferences()
    }

    @objc private func showLEDStyle() {
        if ledStyleWindowController == nil {
            ledStyleWindowController = LEDStyleWindowController()
            ledStyleWindowController?.currentStyle = currentStyle
            ledStyleWindowController?.onStyleSelected = { [weak self] style in
                self?.currentStyle = style
                self?.updateStatusIcon(active: self?.isActive ?? false)
                self?.savePreferences()
            }
        }
        ledStyleWindowController?.showWindow(nil)
        ledStyleWindowController?.window?.center()
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func rateOnAppStore() {
        // Placeholder - replace with actual App Store URL
        NSWorkspace.shared.open(URL(string: "https://apps.apple.com")!)
    }

    @objc private func openSupport() {
        NSWorkspace.shared.open(URL(string: "https://github.com")!)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Login Item

    private func isLoginItemEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }

    private func setLoginItem(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set login item: \(error)")
            }
        }
    }

    // MARK: - Preferences

    private func savePreferences() {
        UserDefaults.standard.set(currentStyle.rawValue, forKey: "ledStyle")
        UserDefaults.standard.set(diskMonitor.monitoredDisk, forKey: "monitoredDisk")
    }

    private func loadPreferences() {
        let styleRaw = UserDefaults.standard.integer(forKey: "ledStyle")
        currentStyle = LEDStyle(rawValue: styleRaw) ?? .greenRed

        let disk = UserDefaults.standard.string(forKey: "monitoredDisk") ?? "all"
        diskMonitor.monitoredDisk = disk
    }

    // MARK: - Public

    func stop() {
        diskMonitor.stop()
    }
}
