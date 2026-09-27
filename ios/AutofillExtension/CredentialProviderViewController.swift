import AuthenticationServices
import LocalAuthentication
import UIKit

/// Bimir Lock's iOS AutoFill provider. iOS shows it when the user taps the key/passwords
/// button above the keyboard in any app or Safari and picks Bimir Lock.
///
/// iOS has no API for a third-party manager to capture NEW passwords typed elsewhere (that
/// only goes to iCloud Keychain), so this extension only FILLS.
///
/// Nothing is shown or decrypted until the user passes Face ID / Touch ID or the device
/// passcode. Every path ends the request exactly once, so the host app is never left waiting.
class CredentialProviderViewController: ASCredentialProviderViewController,
    UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate {

    private enum Mode {
        case list([ASCredentialServiceIdentifier])
        case record(String)
    }

    private var mode: Mode?
    private var started = false
    private var completed = false

    private var suggested: [VaultEntry] = []
    private var others: [VaultEntry] = []
    private var query = ""

    private let table = UITableView(frame: .zero, style: .insetGrouped)
    private let searchBar = UISearchBar()
    private let messageLabel = UILabel()

    // MARK: - Entry points called by iOS

    override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        mode = .list(serviceIdentifiers)
    }

    /// Only reached through QuickType identities. We never fill without the user, so always
    /// ask iOS to bring up our UI instead.
    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        finish(error: .userInteractionRequired)
    }

    @available(iOS 17.0, *)
    override func provideCredentialWithoutUserInteraction(for credentialRequest: ASCredentialRequest) {
        finish(error: .userInteractionRequired)
    }

    override func prepareInterfaceToProvideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        mode = .record(credentialIdentity.recordIdentifier ?? "")
    }

    @available(iOS 17.0, *)
    override func prepareInterfaceToProvideCredential(for credentialRequest: ASCredentialRequest) {
        mode = .record(credentialRequest.credentialIdentity.recordIdentifier ?? "")
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        let bar = UINavigationBar()
        let item = UINavigationItem(title: "Bimir Lock")
        item.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self,
                                                 action: #selector(cancelTapped))
        bar.setItems([item], animated: false)

        searchBar.placeholder = "Search"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        searchBar.autocapitalizationType = .none
        searchBar.isHidden = true

        table.dataSource = self
        table.delegate = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        table.isHidden = true

        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.textColor = .secondaryLabel
        messageLabel.text = "Unlocking…"

        for v in [bar, searchBar, table, messageLabel] as [UIView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }
        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: guide.topAnchor),
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchBar.topAnchor.constraint(equalTo: bar.bottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -8),
            table.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            table.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            table.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 32),
            messageLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -32),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !started else { return }
        started = true
        authenticate()
    }

    // MARK: - Flow

    private func authenticate() {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        var error: NSError?
        // Biometrics OR the device passcode. With neither set up there is no way to prove
        // it's the owner, so filling is refused rather than left open.
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            show("Set a passcode on this iPhone to fill passwords from Bimir Lock.")
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication,
                               localizedReason: "Unlock your saved passwords") { [weak self] ok, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                ok ? self.unlocked() : self.finish(error: .userCanceled)
            }
        }
    }

    private func unlocked() {
        switch mode {
        case .record(let recordId):
            guard let id = Int64(recordId) else {
                finish(error: .credentialIdentityNotFound)
                return
            }
            fill(id: id, fallbackUser: nil)
        case .list(let identifiers):
            loadList(identifiers)
        case .none:
            loadList([])
        }
    }

    private func loadList(_ identifiers: [ASCredentialServiceIdentifier]) {
        let entries: [VaultEntry]
        do {
            entries = try VaultStore.listEntries()
        } catch VaultStoreError.noDatabase {
            show("Open Bimir Lock once to finish setting up AutoFill, then try again.")
            return
        } catch {
            show("Bimir Lock couldn't read your saved passwords right now.")
            return
        }
        if entries.isEmpty {
            show("No saved passwords yet. Add some in Bimir Lock.")
            return
        }
        let keys = identifiers.compactMap { Self.domainCore($0.identifier) }.filter { $0.count >= 3 }
        suggested = entries.filter { e in keys.contains { Self.related(Self.norm(e.title), $0) } }
        let suggestedIds = Set(suggested.map { $0.id })
        others = entries.filter { !suggestedIds.contains($0.id) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        messageLabel.isHidden = true
        searchBar.isHidden = false
        table.isHidden = false
        table.reloadData()
    }

    private func fill(id: Int64, fallbackUser: String?) {
        let entry = (try? VaultStore.listEntries())?.first { $0.id == id }
        do {
            let password = try VaultStore.password(id: id)
            let credential = ASPasswordCredential(user: entry?.userName ?? fallbackUser ?? "",
                                                  password: password)
            completed = true
            extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
        } catch VaultStoreError.keyUnavailable {
            show("Bimir Lock can't unlock this password on this device. Open the app for details.")
        } catch {
            show("Bimir Lock couldn't open that password.")
        }
    }

    @objc private func cancelTapped() {
        finish(error: .userCanceled)
    }

    private func finish(error code: ASExtensionError.Code) {
        guard !completed else { return }
        completed = true
        extensionContext.cancelRequest(withError: NSError(domain: ASExtensionErrorDomain,
                                                          code: code.rawValue))
    }

    private func show(_ message: String) {
        messageLabel.text = message
        messageLabel.isHidden = false
        table.isHidden = true
        searchBar.isHidden = true
    }

    // MARK: - Table

    private func filtered(_ list: [VaultEntry]) -> [VaultEntry] {
        guard !query.isEmpty else { return list }
        return list.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.userName.localizedCaseInsensitiveContains(query)
        }
    }

    private var sections: [(String, [VaultEntry])] {
        [("Suggested", filtered(suggested)), ("All passwords", filtered(others))]
            .filter { !$0.1.isEmpty }
    }

    func numberOfSections(in tableView: UITableView) -> Int { sections.count }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].1.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = sections[indexPath.section].1[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = entry.userName.isEmpty ? "(no username)" : entry.userName
        content.secondaryText = entry.title
        content.image = UIImage(systemName: "key.fill")
        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entry = sections[indexPath.section].1[indexPath.row]
        fill(id: entry.id, fallbackUser: entry.userName)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        query = searchText.trimmingCharacters(in: .whitespaces)
        table.reloadData()
    }

    // MARK: - Matching (same rules as Android's AutofillMatcher)

    private static let secondLevel: Set<String> = ["co", "com", "org", "net", "gov", "edu", "ac"]

    /// "https://accounts.google.com/x" -> "google", "bbc.co.uk" -> "bbc".
    static func domainCore(_ identifier: String) -> String? {
        let host = URL(string: identifier)?.host ?? identifier
        let parts = host.lowercased().split(separator: ".").map(String.init).filter { !$0.isEmpty }
        guard !parts.isEmpty else { return nil }
        guard parts.count >= 2 else { return norm(parts[0]) }
        var i = parts.count - 2
        if secondLevel.contains(parts[i]) && i > 0 { i -= 1 }
        return norm(parts[i])
    }

    static func related(_ title: String, _ key: String) -> Bool {
        guard title.count >= 2 else { return false }
        if title == key || title.contains(key) { return true }
        return title.count >= 4 && key.contains(title)
    }

    static func norm(_ s: String) -> String {
        var t = s.lowercased()
        if t.hasPrefix("www.") { t.removeFirst(4) }
        return String(t.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
    }
}
