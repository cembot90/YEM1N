import Foundation

// ============================================================
// MARK: - Leitung zum Familien-Dienst
// ============================================================
//
// Die Verbindung zum Familien-Dienst bei Cloudflare (Protokoll 2). Der Dienst läuft in der EU.
// Es gehen nur verschlüsselte Verbindungen (HTTPS) raus, ohne Cookies und ohne Zwischenspeicher.

nonisolated struct FamilienNetz: FamilienLeitung {
    static let adresse = "https://yem1n-server.cemaras-yem1n.workers.dev"

    static let shared = FamilienNetz()

    private let sitzung: URLSession

    init() {
        let k = URLSessionConfiguration.ephemeral
        k.timeoutIntervalForRequest = 20
        k.timeoutIntervalForResource = 40
        k.requestCachePolicy = .reloadIgnoringLocalCacheData
        k.httpCookieStorage = nil
        k.httpShouldSetCookies = false
        k.waitsForConnectivity = false
        sitzung = URLSession(configuration: k)
    }

    func post(pfad: String, kopf: [String: String], body: String) async -> (status: Int, text: String) {
        guard let url = URL(string: Self.adresse + pfad) else { return (0, "") }
        var anfrage = URLRequest(url: url)
        anfrage.httpMethod = "POST"
        anfrage.httpBody = Data(body.utf8)
        for (k, v) in kopf { anfrage.setValue(v, forHTTPHeaderField: k) }
        do {
            let (daten, antwort) = try await sitzung.data(for: anfrage)
            let status = (antwort as? HTTPURLResponse)?.statusCode ?? 0
            return (status, String(decoding: daten, as: UTF8.self))
        } catch {
            return (0, "")
        }
    }
}
