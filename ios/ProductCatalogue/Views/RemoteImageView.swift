import UIKit

@MainActor
private final class ProductImageLoader {
    static let shared = ProductImageLoader()
    private let cache = NSCache<NSURL, UIImage>()

    private init() { cache.countLimit = 80 }

    func image(for url: URL) async throws -> UIImage? {
        guard let scheme = url.scheme, ["https", "http"].contains(scheme) else { return nil }
        if let image = cache.object(forKey: url as NSURL) { return image }
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode),
              data.count <= 10_000_000, let image = UIImage(data: data) else { return nil }
        cache.setObject(image, forKey: url as NSURL)
        return image
    }
}

final class RemoteImageView: UIImageView {
    private var task: Task<Void, Never>?

    func load(_ url: URL?) {
        task?.cancel()
        image = UIImage(systemName: "photo")
        tintColor = .tertiaryLabel
        guard let url else { return }
        task = Task { [weak self] in
            do {
                let image = try await ProductImageLoader.shared.image(for: url)
                guard !Task.isCancelled, let image else { return }
                self?.image = image
            } catch {
                // Keep the placeholder; image failure must not hide product text.
            }
        }
    }

    deinit { task?.cancel() }
}
