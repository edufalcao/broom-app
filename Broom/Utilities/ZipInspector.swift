import Foundation

/// Reads ZIP central directory entry names without decompressing content,
/// so installer archives can be told apart from ordinary zips cheaply.
enum ZipInspector {
    /// Returns the first `maxEntries` entry names of the archive, or nil when
    /// the file is missing, unreadable, or not a ZIP archive.
    static func firstEntryNames(at url: URL, maxEntries: Int = 50) -> [String]? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        guard let eocd = findEndOfCentralDirectory(handle: handle) else { return nil }

        guard let cdData = readData(
            handle: handle,
            offset: eocd.cdOffset,
            length: max(eocd.cdSize, Int64(eocd.entryCount * 128))
        ), cdData.count >= 4 else { return nil }

        var names: [String] = []
        var cursor = 0
        while names.count < min(maxEntries, eocd.entryCount) {
            guard cursor + 46 <= cdData.count else { break }
            guard cdData.readUInt32(at: cursor) == 0x0201_4b50 else { break }

            let nameLength = Int(cdData.readUInt16(at: cursor + 28))
            let extraLength = Int(cdData.readUInt16(at: cursor + 30))
            let commentLength = Int(cdData.readUInt16(at: cursor + 32))

            let nameStart = cursor + 46
            let nameEnd = nameStart + nameLength
            guard nameEnd <= cdData.count else { break }
            names.append(String(data: cdData.subdata(in: nameStart..<nameEnd), encoding: .utf8) ?? "")

            cursor = nameEnd + extraLength + commentLength
        }

        return names
    }

    /// True when the archive's first entries contain an installer-looking
    /// payload (.app, .pkg, .dmg, or .xip component), per the locked
    /// installer sweep direction.
    static func looksLikeInstallerArchive(at url: URL) -> Bool {
        guard let names = firstEntryNames(at: url) else { return false }
        let installerExtensions = [".app", ".pkg", ".dmg", ".xip"]
        for name in names {
            let components = name.split(separator: "/")
            if let first = components.first,
               installerExtensions.contains(where: { first.lowercased().hasSuffix($0) }) {
                return true
            }
        }
        return false
    }

    // MARK: - Format parsing

    private struct EndOfCentralDirectory {
        let entryCount: Int
        let cdSize: Int64
        let cdOffset: Int64
    }

    private static func findEndOfCentralDirectory(handle: FileHandle) -> EndOfCentralDirectory? {
        let windowSize: Int64 = 65_536 + 22
        let fileSize = Int64((try? handle.seekToEnd()) ?? 0)
        let readOffset = fileSize > windowSize ? fileSize - windowSize : 0
        guard let data = readData(handle: handle, offset: readOffset, length: fileSize - readOffset),
              data.count >= 22 else { return nil }

        // Scan backwards for the EOCD signature 0x06054b50 ("PK\05\06").
        var i = data.count - 22
        while i >= 0 {
            if data.readUInt32(at: i) == 0x0605_4b50 {
                let entryCount = Int(data.readUInt16(at: i + 10))
                let cdSize = Int64(data.readUInt32(at: i + 12))
                let cdOffset = Int64(data.readUInt32(at: i + 16))
                return EndOfCentralDirectory(entryCount: entryCount, cdSize: cdSize, cdOffset: cdOffset)
            }
            i -= 1
        }
        return nil
    }

    private static func readData(handle: FileHandle, offset: Int64, length: Int64) -> Data? {
        guard length > 0 else { return nil }
        do {
            try handle.seek(toOffset: UInt64(offset))
            return try handle.read(upToCount: Int(length))
        } catch {
            return nil
        }
    }
}

private extension Data {
    func readUInt16(at offset: Int) -> UInt16 {
        let b0 = UInt16(self[startIndex + offset])
        let b1 = UInt16(self[startIndex + offset + 1])
        return b0 | (b1 << 8)
    }

    func readUInt32(at offset: Int) -> UInt32 {
        let b0 = UInt32(self[startIndex + offset])
        let b1 = UInt32(self[startIndex + offset + 1]) << 8
        let b2 = UInt32(self[startIndex + offset + 2]) << 16
        let b3 = UInt32(self[startIndex + offset + 3]) << 24
        return b0 | b1 | b2 | b3
    }
}
