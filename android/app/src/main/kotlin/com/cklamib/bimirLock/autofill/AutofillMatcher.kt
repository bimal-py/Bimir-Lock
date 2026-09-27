package com.cklamib.bimirLock.autofill

import java.util.Locale

// Which saved passwords to suggest for the app or site in front of the user.
//
// Only the SUGGESTIONS come from here. Every fill still needs the user to pick an
// entry and pass biometrics or the screen lock, and the "Choose from Bimir Lock"
// entry reaches everything else. Matching is by name, not by verified app
// signature, so a look-alike app could be offered a real site's entry: the
// suggestion shows which site/app the entry was saved for, so the user can see it.
object AutofillMatcher {

    private const val MAX_SUGGESTIONS = 5

    // Parts of a host or package name that say nothing about who it belongs to.
    private val NOISE = setOf(
        "www", "m", "mobile", "app", "apps", "android", "com", "org", "net", "io", "co",
        "gov", "edu", "ac", "login", "accounts", "account", "auth", "signin", "secure"
    )
    private val SECOND_LEVEL = setOf("co", "com", "org", "net", "gov", "edu", "ac")

    fun suggestions(
        entries: List<PasswordStore.Entry>,
        savedTitle: String,
        packageName: String?,
        webDomain: String?
    ): List<PasswordStore.Entry> = rank(entries, savedTitle, packageName, webDomain)
        .filter { it.second > 0 }
        .take(MAX_SUGGESTIONS)
        .map { it.first }

    // All entries, best matches first. Used by the picker.
    fun ordered(
        entries: List<PasswordStore.Entry>,
        savedTitle: String,
        packageName: String?,
        webDomain: String?
    ): List<PasswordStore.Entry> = rank(entries, savedTitle, packageName, webDomain).map { it.first }

    private fun rank(
        entries: List<PasswordStore.Entry>,
        savedTitle: String,
        packageName: String?,
        webDomain: String?
    ): List<Pair<PasswordStore.Entry, Int>> {
        val exact = norm(savedTitle)
        val core = domainCore(webDomain)
        // A browser reports the real site; with a domain, ignore the browser's own package.
        val tokens = if (core.isEmpty()) packageTokens(packageName) else emptyList()
        return entries
            .map { it to score(norm(it.title), exact, core, tokens) }
            .sortedWith(compareByDescending<Pair<PasswordStore.Entry, Int>> { it.second }
                .thenBy { it.first.title.lowercase(Locale.ROOT) }
                .thenBy { it.first.id })
    }

    private fun score(title: String, exact: String, core: String, tokens: List<String>): Int {
        if (title.length < 2) return 0
        // What our own autofill save names the entry for this app/site.
        if (exact.isNotEmpty() && title == exact) return 100
        if (core.isNotEmpty() && related(title, core)) return 80
        for (token in tokens) if (related(title, token)) return 60
        return 0
    }

    private fun related(title: String, key: String): Boolean {
        if (key.length < 3) return false
        if (title == key || title.contains(key)) return true
        // "gmail" entry for "mail.google.com" is not caught; "face" for "facebook" is.
        return title.length >= 4 && key.contains(title)
    }

    // "accounts.google.com" -> "google", "bbc.co.uk" -> "bbc", "bank.com.np" -> "bank".
    private fun domainCore(domain: String?): String {
        val parts = domain?.lowercase(Locale.ROOT)?.trim()?.trim('.')
            ?.split('.')?.filter { it.isNotEmpty() } ?: return ""
        if (parts.size < 2) return norm(parts.firstOrNull() ?: "")
        var i = parts.size - 2
        if (parts[i] in SECOND_LEVEL && i > 0) i--
        return norm(parts[i])
    }

    // "com.facebook.katana" -> ["facebook", "katana"].
    private fun packageTokens(pkg: String?): List<String> =
        pkg?.lowercase(Locale.ROOT)?.split('.', '_')
            ?.map { norm(it) }
            ?.filter { it.length >= 4 && it !in NOISE }
            ?: emptyList()

    private fun norm(s: String): String =
        s.lowercase(Locale.ROOT).removePrefix("www.").filter { it.isLetterOrDigit() }
}
