import Foundation
import IOKit

struct DiskStats {
    var bytesRead: Int64 = 0
    var bytesWritten: Int64 = 0
}

struct DiskActivity {
    let name: String
    let isReading: Bool
    let isWriting: Bool
}

class DiskMonitor {
    private var timer: Timer?
    private var previousStats: [String: DiskStats] = [:]

    var onActivity: ((Bool, [DiskActivity]) -> Void)?
    var monitoredDisk: String = "all"

    private(set) var availableDisks: [String] = []

    func start() {
        refreshAvailableDisks()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkActivity()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refreshAvailableDisks() {
        let stats = getCurrentStats()
        availableDisks = Array(stats.keys).sorted()
    }

    private func checkActivity() {
        let currentStats = getCurrentStats()
        var activities: [DiskActivity] = []
        var anyActive = false

        for (diskName, current) in currentStats {
            let previous = previousStats[diskName] ?? DiskStats()
            let isReading = current.bytesRead > previous.bytesRead
            let isWriting = current.bytesWritten > previous.bytesWritten

            if isReading || isWriting {
                anyActive = true
            }
            activities.append(DiskActivity(name: diskName, isReading: isReading, isWriting: isWriting))
        }

        previousStats = currentStats

        if monitoredDisk != "all" {
            let filtered = activities.filter { $0.name == monitoredDisk }
            anyActive = filtered.contains { $0.isReading || $0.isWriting }
            onActivity?(anyActive, filtered)
        } else {
            onActivity?(anyActive, activities)
        }
    }

    private func getCurrentStats() -> [String: DiskStats] {
        var result: [String: DiskStats] = [:]

        guard let matchingDict = IOServiceMatching("IOBlockStorageDriver") else { return result }

        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator) == KERN_SUCCESS else {
            return result
        }
        defer { IOObjectRelease(iterator) }

        var diskIndex = 0
        var service = IOIteratorNext(iterator)

        while service != IO_OBJECT_NULL {
            defer {
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }

            var propsMutable: Unmanaged<CFMutableDictionary>?
            guard IORegistryEntryCreateCFProperties(service, &propsMutable, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                  let dict = propsMutable?.takeRetainedValue() as? [String: Any],
                  let statistics = dict["Statistics"] as? [String: Any] else {
                diskIndex += 1
                continue
            }

            let bytesRead = (statistics["Bytes (Read)"] as? NSNumber)?.int64Value ?? 0
            let bytesWritten = (statistics["Bytes (Write)"] as? NSNumber)?.int64Value ?? 0

            let diskName = resolveDiskName(from: service, fallback: "disk\(diskIndex)")
            result[diskName] = DiskStats(bytesRead: bytesRead, bytesWritten: bytesWritten)
            diskIndex += 1
        }

        return result
    }

    private func resolveDiskName(from driver: io_object_t, fallback: String) -> String {
        // Try to get parent's child IOMedia with BSD Name
        var parent: io_registry_entry_t = 0
        guard IORegistryEntryGetParentEntry(driver, kIOServicePlane, &parent) == KERN_SUCCESS else {
            return fallback
        }
        defer { IOObjectRelease(parent) }

        var childIter: io_iterator_t = 0
        guard IORegistryEntryGetChildIterator(parent, kIOServicePlane, &childIter) == KERN_SUCCESS else {
            return fallback
        }
        defer { IOObjectRelease(childIter) }

        var child = IOIteratorNext(childIter)
        while child != IO_OBJECT_NULL {
            defer {
                IOObjectRelease(child)
                child = IOIteratorNext(childIter)
            }
            if let bsdName = IORegistryEntryCreateCFProperty(
                child, "BSD Name" as CFString, kCFAllocatorDefault, 0
            )?.takeRetainedValue() as? String {
                return bsdName
            }
        }
        return fallback
    }
}
