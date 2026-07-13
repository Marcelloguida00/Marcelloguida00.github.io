import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Foto ricordo di fine partita: file JPEG per data di inizio match.
/// Non usata nella card social; sincronizzata tra dispositivi.
enum MatchPhotoStore {
    nonisolated static let appGroupID = "group.com.MarcelloGuida.SetPoint"

    nonisolated static var photosDirectory: URL {
        let base = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("MatchPhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    nonisolated static func fileName(for matchDate: Date) -> String {
        "\(Int(matchDate.timeIntervalSince1970)).jpg"
    }

    nonisolated static func url(for matchDate: Date) -> URL {
        photosDirectory.appendingPathComponent(fileName(for: matchDate))
    }

    nonisolated static func exists(for matchDate: Date) -> Bool {
        FileManager.default.fileExists(atPath: url(for: matchDate).path)
    }

    #if os(iOS)
    @discardableResult
    static func save(_ image: UIImage, matchDate: Date) -> Bool {
        let resized = image.resized(maxDimension: 2048)
        guard let data = resized.jpegData(compressionQuality: 0.82) else { return false }
        return save(data: data, matchDate: matchDate)
    }
    #endif

    @discardableResult
    nonisolated static func save(data: Data, matchDate: Date) -> Bool {
        do {
            try data.write(to: url(for: matchDate), options: .atomic)
            return true
        } catch {
            return false
        }
    }

    static func load(for matchDate: Date) -> UIImage? {
        #if canImport(UIKit)
        guard let data = try? Data(contentsOf: url(for: matchDate)) else { return nil }
        return UIImage(data: data)
        #else
        return nil
        #endif
    }

    nonisolated static func delete(for matchDate: Date) {
        try? FileManager.default.removeItem(at: url(for: matchDate))
    }
}

#if os(iOS)
private extension UIImage {
    func resized(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        guard let cgImage else { return self }
        let width = Int(newSize.width.rounded())
        let height = Int(newSize.height.rounded())
        guard width > 0, height > 0,
              let context = CGContext(
                  data: nil,
                  width: width,
                  height: height,
                  bitsPerComponent: 8,
                  bytesPerRow: 0,
                  space: CGColorSpaceCreateDeviceRGB(),
                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              )
        else { return self }

        context.interpolationQuality = .medium
        context.draw(cgImage, in: CGRect(origin: .zero, size: newSize))
        guard let output = context.makeImage() else { return self }
        return UIImage(cgImage: output, scale: scale, orientation: imageOrientation)
    }
}
#endif

extension Notification.Name {
    static let matchSavedForPhoto = Notification.Name("matchSavedForPhoto")
    static let matchPhotoUpdated = Notification.Name("matchPhotoUpdated")
}
