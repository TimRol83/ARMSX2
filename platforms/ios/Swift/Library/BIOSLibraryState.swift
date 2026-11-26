// BIOSLibraryState.swift — the BIOS files on disk and the default pick
// SPDX-License-Identifier: GPL-3.0+

import SwiftUI

struct BIOSLibraryEntry: Identifiable, Equatable, Sendable {
    let fileName: String
    let filePath: String
    let regionName: String
    let countryCode: String
    let descriptionText: String
    let valid: Bool

    var id: String { filePath }

    init(_ info: ARMSX2BIOSInfo) {
        fileName = info.fileName
        filePath = info.filePath
        regionName = info.regionName
        countryCode = info.countryCode
        descriptionText = info.descriptionText
        valid = info.valid
    }
}

@MainActor
final class BIOSLibraryState : ObservableObject {
    static let shared = BIOSLibraryState()

    @Published private(set) var entries: [BIOSLibraryEntry] = []
    private(set) var defaultBIOS = ""
    private(set) var hasLoaded = false
    private var refreshTask: Task<Void, Never>?
    private var needsRefresh = true
    private var refreshCompletions:
        [([BIOSLibraryEntry]) -> Void] = []

    private init() {}

    func refreshIfNeeded() {
        guard needsRefresh || !hasLoaded else { return }
        refresh()
    }

    func markNeedsRefresh() {
        needsRefresh = true
    }

    func refresh(
        completion: (([BIOSLibraryEntry]) -> Void)? = nil
    ) {
        if let completion { refreshCompletions.append(completion) }
        guard refreshTask == nil else {
            needsRefresh = true
            return
        }
        needsRefresh = false
        refreshTask = Task { @MainActor [weak self] in
            // BIOS validation reads the files, so keep it off tab and focus animations.
            let loadedEntries = await Task.detached(priority: .userInitiated) {
                ARMSX2Bridge.availableBIOSInfos().map(BIOSLibraryEntry.init)
            }.value
            guard let self, !Task.isCancelled else { return }
            let loadedDefault = ARMSX2Bridge.defaultBIOSName()
            entries = loadedEntries
            defaultBIOS = loadedDefault
            hasLoaded = true
            refreshTask = nil
            if defaultBIOS.isEmpty,
               let firstValid = loadedEntries.first(where: \.valid) {
                select(firstValid)
            }
            if needsRefresh {
                refresh()
                return
            }
            let completions = refreshCompletions
            refreshCompletions.removeAll(keepingCapacity: true)
            completions.forEach { $0(loadedEntries) }
        }
    }

    func select(_ entry: BIOSLibraryEntry) {
        guard entry.valid else { return }
        ARMSX2Bridge.setDefaultBIOS(entry.fileName)
        defaultBIOS = entry.fileName
    }
}
