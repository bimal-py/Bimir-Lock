package com.cklamib.bimirLock.autofill

import android.app.assist.AssistStructure
import android.content.Context
import android.os.Build
import android.text.InputType
import android.util.Pair
import android.view.View
import android.view.autofill.AutofillId
import java.util.ArrayDeque
import java.util.Locale

// Walks an AssistStructure and picks out one username/password pair.
// Used by both onFillRequest (ids only, values are null there) and
// onSaveRequest (ids + values). Nothing here throws: every accessor is
// guarded, because the structure comes from another process.
class ParsedCredential(
    val packageName: String?,
    val webDomain: String?,
    val usernameId: AutofillId?,
    val passwordId: AutofillId?,
    val username: String?,
    val password: String?,
    val ambiguous: Boolean
) {
    val hasPasswordField: Boolean get() = passwordId != null
    val hasCredential: Boolean get() = !ambiguous && !password.isNullOrEmpty()
}

private enum class Kind { USERNAME, PASSWORD, TEXT }

private class Candidate(
    val id: AutofillId,
    val value: String?,
    val kind: Kind,
    val score: Int,
    val confirmish: Boolean,
    val newish: Boolean,
    val domain: String?,
    val order: Int
)

private class Frame(val node: AssistStructure.ViewNode, val depth: Int, val domain: String?)

object StructureParser {

    private const val MAX_NODES = 4000
    private const val MAX_DEPTH = 60
    private const val MAX_WINDOWS = 8
    private const val MAX_CONTEXTS = 8
    private const val MAX_VALUE_LEN = 512
    private const val MAX_USERNAME_LEN = 128
    private const val MAX_TITLE_LEN = 64
    private const val MAX_LABEL_PART = 64
    private const val MAX_HTML_ATTRS = 64

    // Hints, lowercased. Platform names on the left, W3C names Chrome emits on the right.
    // View.AUTOFILL_HINT_USERNAME = "username" (same token as W3C "username").
    private val HINT_USER = setOf("username", "newusername", "user_name", "login")
    // View.AUTOFILL_HINT_EMAIL_ADDRESS = "emailAddress"; W3C is "email".
    private val HINT_EMAIL = setOf("emailaddress", "email")
    // View.AUTOFILL_HINT_PASSWORD = "password"; W3C "current-password";
    // View.AUTOFILL_HINT_PASSWORD_AUTO = "passwordAuto".
    private val HINT_PASSWORD = setOf("password", "current-password", "passwordauto")
    // androidx HintConstants.AUTOFILL_HINT_NEW_PASSWORD = "newPassword"; W3C "new-password".
    private val HINT_NEW_PASSWORD = setOf("newpassword", "new-password")
    // Never a credential: card fields and one-time codes.
    private val HINT_BLOCKED = setOf(
        "smsotpcode", "one-time-code", "cc-number", "cc-csc", "cc-exp",
        "cc-exp-month", "cc-exp-year", "cc-name"
    )

    private val WORDS_USER = arrayOf(
        "username", "user_name", "userid", "user_id", "login", "email",
        "e_mail", "account", "identifier", "phone_or_email"
    )
    private val WORDS_PASSWORD = arrayOf("password", "passwd", "pwd", "passphrase")
    private val WORDS_CONFIRM = arrayOf(
        "confirm", "reenter", "re_enter", "re-enter", "repeat", "retype",
        "again", "verify", "old", "current", "existing"
    )
    private val WORDS_NEW = arrayOf("new_password", "newpassword", "new-password", "register", "signup")
    private val WORDS_SKIP = arrayOf(
        "search", "query", "filter", "otp", "one_time", "onetime", "verification",
        "captcha", "cvv", "cvc", "card_number", "cardnumber", "expiry", "postal", "zip", "pincode"
    )

    // ---- entry points -------------------------------------------------------

    // Parses every FillContext of a request and merges them, so two-step
    // (username screen then password screen) flows still produce a full pair.
    fun parseContexts(structures: List<AssistStructure?>): ParsedCredential? {
        var best: ParsedCredential? = null
        var count = 0
        for (s in structures) {
            if (count++ >= MAX_CONTEXTS) break
            val parsed = parse(s) ?: continue
            best = merge(best, parsed)
        }
        return best
    }

    fun parse(structure: AssistStructure?): ParsedCredential? {
        if (structure == null) return null
        val pkg = try { structure.activityComponent?.packageName } catch (t: Throwable) { null }
        val candidates = ArrayList<Candidate>(32)
        var nodes = 0
        var order = 0
        try {
            // NOTE: getWindowNodeCount() lazily pulls the structure over a binder
            // transaction and can throw IllegalStateException/BadParcelableException.
            val windows = minOf(structure.windowNodeCount, MAX_WINDOWS)
            var w = 0
            while (w < windows) {
                val root = try { structure.getWindowNodeAt(w).rootViewNode } catch (t: Throwable) { null }
                w++
                if (root == null) continue
                val stack = ArrayDeque<Frame>()
                stack.push(Frame(root, 0, null))
                while (stack.isNotEmpty() && nodes < MAX_NODES) {
                    val frame = stack.pop()
                    val node = frame.node
                    nodes++
                    val domain = safeDomain(node) ?: frame.domain
                    val c = classify(node, domain, order)
                    if (c != null) {
                        candidates.add(c)
                        order++
                    }
                    if (frame.depth < MAX_DEPTH) {
                        val childCount = try { node.childCount } catch (t: Throwable) { 0 }
                        var i = childCount - 1
                        while (i >= 0) {
                            val child = try { node.getChildAt(i) } catch (t: Throwable) { null }
                            if (child != null) stack.push(Frame(child, frame.depth + 1, domain))
                            i--
                        }
                    }
                }
            }
        } catch (t: Throwable) {
            // Keep whatever we collected; a partial parse is better than a crash.
        }
        return select(pkg, candidates)
    }

    // True when we must not offer to save anything for this source.
    fun isBlockedSource(context: Context, structure: AssistStructure?, packageName: String?): Boolean {
        if (packageName.isNullOrBlank()) return true
        if (packageName == context.packageName) return true
        if (packageName == "android" || packageName == "com.android.systemui") return true
        val home = try { structure?.isHomeActivity ?: false } catch (t: Throwable) { false }
        return home
    }

    // Web domain wins over the app label: "github.com" beats "Chrome".
    fun credentialTitle(context: Context, parsed: ParsedCredential): String {
        val domain = parsed.webDomain?.trim()?.lowercase(Locale.ROOT)?.removePrefix("www.")
        if (!domain.isNullOrEmpty()) return sanitizeTitle(domain)
        val pkg = parsed.packageName
        if (pkg.isNullOrBlank()) return "Saved password"
        val label = try {
            val pm = context.packageManager
            pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0))?.toString()
        } catch (t: Throwable) {
            null
        }
        if (!label.isNullOrBlank()) return sanitizeTitle(label)
        return sanitizeTitle(prettyPackage(pkg))
    }

    // ---- classification -----------------------------------------------------

    private fun classify(node: AssistStructure.ViewNode, domain: String?, order: Int): Candidate? {
        val id = try { node.autofillId } catch (t: Throwable) { null } ?: return null
        val type = try { node.autofillType } catch (t: Throwable) { View.AUTOFILL_TYPE_NONE }
        if (type != View.AUTOFILL_TYPE_TEXT) return null

        val hints = safeHints(node)
        for (h in hints) {
            if (h in HINT_BLOCKED || h.startsWith("creditcard")) return null
        }

        val inputType = try { node.inputType } catch (t: Throwable) { 0 }
        val html = safeHtml(node)
        val labels = safeLabels(node)
        val value = safeValue(node)

        val htmlType = html?.type ?: ""
        val autocomplete = html?.autocomplete ?: ""
        val htmlNames = html?.names ?: ""
        val blob = labels + " " + htmlNames

        if (htmlType == "hidden" || htmlType == "submit" || htmlType == "button" ||
            htmlType == "checkbox" || htmlType == "radio" || htmlType == "search"
        ) return null
        if (isFilterInputType(inputType)) return null
        if (containsAny(blob, WORDS_SKIP)) return null
        if (isNumericPasswordInputType(inputType) && !hints.any { it in HINT_PASSWORD }) return null

        val confirmish = containsAny(blob, WORDS_CONFIRM)
        val newish = hints.any { it in HINT_NEW_PASSWORD } ||
            autocomplete == "new-password" ||
            containsAny(blob, WORDS_NEW)

        // Strongest signal first.
        if (hints.any { it in HINT_PASSWORD } || hints.any { it in HINT_NEW_PASSWORD }) {
            return Candidate(id, value, Kind.PASSWORD, 100, confirmish, newish, domain, order)
        }
        if (hints.any { it in HINT_USER }) {
            return Candidate(id, value, Kind.USERNAME, 100, confirmish, newish, domain, order)
        }
        if (hints.any { it in HINT_EMAIL }) {
            return Candidate(id, value, Kind.USERNAME, 90, confirmish, newish, domain, order)
        }
        if (autocomplete == "current-password" || autocomplete == "new-password") {
            return Candidate(id, value, Kind.PASSWORD, 90, confirmish, newish, domain, order)
        }
        if (autocomplete == "username" || autocomplete == "email") {
            return Candidate(id, value, Kind.USERNAME, 85, confirmish, newish, domain, order)
        }
        if (html?.tag == "input" && htmlType == "password") {
            return Candidate(id, value, Kind.PASSWORD, 80, confirmish, newish, domain, order)
        }
        if (isTextPasswordInputType(inputType)) {
            return Candidate(id, value, Kind.PASSWORD, 70, confirmish, newish, domain, order)
        }
        if (html?.tag == "input" && htmlType == "email") {
            return Candidate(id, value, Kind.USERNAME, 65, confirmish, newish, domain, order)
        }
        if (isEmailInputType(inputType)) {
            return Candidate(id, value, Kind.USERNAME, 60, confirmish, newish, domain, order)
        }
        if (containsAny(blob, WORDS_PASSWORD)) {
            return Candidate(id, value, Kind.PASSWORD, 40, confirmish, newish, domain, order)
        }
        if (containsAny(blob, WORDS_USER)) {
            return Candidate(id, value, Kind.USERNAME, 40, confirmish, newish, domain, order)
        }
        // Plain editable text: only useful as the "field above the password" fallback.
        return Candidate(id, value, Kind.TEXT, 0, confirmish, newish, domain, order)
    }

    // ---- input type tests ---------------------------------------------------
    // Always compare the VARIATION bits for equality after switching on the
    // CLASS bits. A bitwise "and != 0" test is wrong: WEB_EMAIL_ADDRESS (0xd0)
    // and WEB_EDIT_TEXT (0xa0) both contain the PASSWORD bit (0x80), and
    // TYPE_NUMBER_VARIATION_PASSWORD (0x10) equals TYPE_TEXT_VARIATION_URI (0x10).

    private fun isTextPasswordInputType(inputType: Int): Boolean {
        if ((inputType and InputType.TYPE_MASK_CLASS) != InputType.TYPE_CLASS_TEXT) return false
        return when (inputType and InputType.TYPE_MASK_VARIATION) {
            InputType.TYPE_TEXT_VARIATION_PASSWORD,          // 0x80
            InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD,  // 0x90
            InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD       // 0xe0
            -> true
            else -> false
        }
    }

    private fun isNumericPasswordInputType(inputType: Int): Boolean {
        if ((inputType and InputType.TYPE_MASK_CLASS) != InputType.TYPE_CLASS_NUMBER) return false
        return (inputType and InputType.TYPE_MASK_VARIATION) ==
            InputType.TYPE_NUMBER_VARIATION_PASSWORD          // 0x10
    }

    private fun isEmailInputType(inputType: Int): Boolean {
        if ((inputType and InputType.TYPE_MASK_CLASS) != InputType.TYPE_CLASS_TEXT) return false
        return when (inputType and InputType.TYPE_MASK_VARIATION) {
            InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS,      // 0x20
            InputType.TYPE_TEXT_VARIATION_WEB_EMAIL_ADDRESS   // 0xd0
            -> true
            else -> false
        }
    }

    private fun isFilterInputType(inputType: Int): Boolean {
        if ((inputType and InputType.TYPE_MASK_CLASS) != InputType.TYPE_CLASS_TEXT) return false
        return (inputType and InputType.TYPE_MASK_VARIATION) ==
            InputType.TYPE_TEXT_VARIATION_FILTER              // 0xb0
    }

    // ---- selection ----------------------------------------------------------

    private fun select(pkg: String?, all: List<Candidate>): ParsedCredential? {
        val passwords = all.filter { it.kind == Kind.PASSWORD }
        if (passwords.isEmpty()) return usernameOnly(pkg, all)

        val withValue = passwords.filter { !it.value.isNullOrBlank() }
        val pool = if (withValue.isNotEmpty()) withValue else passwords
        var ambiguous = false

        val chosen: Candidate = if (pool.size == 1) {
            pool[0]
        } else {
            val distinct = pool.mapNotNull { it.value }.distinct()
            val newOnes = pool.filter { it.newish }
            val plain = pool.filter { !it.confirmish }
            when {
                // Sign-up form: "password" + "confirm password" hold the same text.
                withValue.isNotEmpty() && distinct.size <= 1 -> pool[0]
                newOnes.size == 1 -> newOnes[0]
                plain.size == 1 -> plain[0]
                // Fill request: no values yet, take the first and let the save
                // pass decide for real.
                withValue.isEmpty() -> pool[0]
                // change-password form: refuse rather than store the old password
                else -> { ambiguous = true; pool[0] }
            }
        }

        val user = pickUsername(all, chosen)
        val domain = chosen.domain ?: user?.domain ?: all.firstOrNull { it.domain != null }?.domain

        return ParsedCredential(
            packageName = pkg,
            webDomain = domain,
            usernameId = user?.id,
            passwordId = chosen.id,
            username = user?.value,
            password = chosen.value,
            ambiguous = ambiguous
        )
    }

    // A username field with no password on the same screen is the first step of a
    // two-step login. Return the id so the service can keep the session alive; there
    // is no password yet, so hasCredential stays false and nothing gets saved from
    // this screen alone. Only an explicitly classified username counts here -- with no
    // password to anchor against, guessing from plain text would pick up junk fields.
    private fun usernameOnly(pkg: String?, all: List<Candidate>): ParsedCredential? {
        val user = all.filter { it.kind == Kind.USERNAME }
            .maxWithOrNull(compareBy({ it.score }, { -it.order })) ?: return null
        return ParsedCredential(
            packageName = pkg,
            webDomain = user.domain ?: all.firstOrNull { it.domain != null }?.domain,
            usernameId = user.id,
            passwordId = null,
            username = user.value,
            password = null,
            ambiguous = false
        )
    }

    private fun pickUsername(all: List<Candidate>, password: Candidate): Candidate? {
        val users = all.filter { it.kind == Kind.USERNAME }
        val order = compareBy<Candidate>({ it.score }, { it.order })
        users.filter { it.order < password.order }.maxWithOrNull(order)?.let { return it }
        users.minByOrNull { it.order }?.let { return it }
        // Last resort: the nearest editable text field above the password.
        return all.lastOrNull {
            it.kind == Kind.TEXT && it.order < password.order && looksLikeUsername(it.value)
        }
    }

    private fun looksLikeUsername(value: String?): Boolean {
        if (value == null) return true // fill request: values are not populated yet
        val v = value.trim()
        if (v.isEmpty() || v.length > MAX_USERNAME_LEN) return false
        return v.none { it.isWhitespace() }
    }

    private fun merge(a: ParsedCredential?, b: ParsedCredential): ParsedCredential {
        if (a == null) return b
        return ParsedCredential(
            packageName = b.packageName ?: a.packageName,
            webDomain = b.webDomain ?: a.webDomain,
            usernameId = b.usernameId ?: a.usernameId,
            passwordId = b.passwordId ?: a.passwordId,
            username = if (!b.username.isNullOrEmpty()) b.username else a.username,
            password = if (!b.password.isNullOrEmpty()) b.password else a.password,
            ambiguous = a.ambiguous || b.ambiguous
        )
    }

    // ---- guarded accessors --------------------------------------------------

    private fun safeDomain(node: AssistStructure.ViewNode): String? {
        val d = try { node.webDomain } catch (t: Throwable) { null } ?: return null
        val s = d.trim()
        return if (s.isEmpty() || s.length > 253) null else s
    }

    private fun safeValue(node: AssistStructure.ViewNode): String? {
        // getAutofillValue(), not getText(): only the former is guaranteed current.
        val v = try { node.autofillValue } catch (t: Throwable) { null } ?: return null
        if (!v.isText) return null
        val cs = try { v.textValue } catch (t: Throwable) { null } ?: return null
        var s = cs.toString()
        if (s.length > MAX_VALUE_LEN) {
            s = s.substring(0, MAX_VALUE_LEN)
            // never end on half a surrogate pair
            if (s.isNotEmpty() && Character.isHighSurrogate(s[s.length - 1])) {
                s = s.substring(0, s.length - 1)
            }
        }
        return s
    }

    private fun safeHints(node: AssistStructure.ViewNode): List<String> {
        val raw = try { node.autofillHints } catch (t: Throwable) { null } ?: return emptyList()
        val out = ArrayList<String>(4)
        for (h in raw) {
            if (out.size >= 8) break
            if (h == null) continue
            val s = h.trim().lowercase(Locale.ROOT)
            if (s.isNotEmpty() && s.length <= 64) out.add(s)
        }
        return out
    }

    private class Html(val tag: String, val type: String, val autocomplete: String, val names: String)

    private fun safeHtml(node: AssistStructure.ViewNode): Html? {
        val info = try { node.htmlInfo } catch (t: Throwable) { null } ?: return null
        val tag = (try { info.tag } catch (t: Throwable) { null })
            ?.trim()?.lowercase(Locale.ROOT) ?: return null
        var type = ""
        var autocomplete = ""
        val names = StringBuilder(64)
        val attrs: List<Pair<String, String>>? = try { info.attributes } catch (t: Throwable) { null }
        if (attrs != null) {
            val n = minOf(attrs.size, MAX_HTML_ATTRS)
            var i = 0
            while (i < n) {
                val a = try { attrs[i] } catch (t: Throwable) { null }
                i++
                val k = a?.first?.trim()?.lowercase(Locale.ROOT) ?: continue
                val raw = a.second ?: continue
                val v = raw.take(MAX_LABEL_PART).lowercase(Locale.ROOT)
                when (k) {
                    "type" -> type = v
                    "autocomplete" -> autocomplete = v
                    "name", "id", "placeholder", "aria-label" -> names.append(' ').append(v)
                }
            }
        }
        return Html(tag, type, autocomplete, names.toString())
    }

    private fun safeLabels(node: AssistStructure.ViewNode): String {
        val sb = StringBuilder(96)
        append(sb, try { node.idEntry } catch (t: Throwable) { null })
        append(sb, try { node.hint } catch (t: Throwable) { null })
        append(sb, try { node.contentDescription?.toString() } catch (t: Throwable) { null })
        if (Build.VERSION.SDK_INT >= 30) {
            append(sb, try { node.hintIdEntry } catch (t: Throwable) { null })
        }
        return sb.toString().lowercase(Locale.ROOT)
    }

    private fun append(sb: StringBuilder, s: String?) {
        if (s.isNullOrEmpty()) return
        sb.append(' ').append(if (s.length > MAX_LABEL_PART) s.substring(0, MAX_LABEL_PART) else s)
    }

    private fun containsAny(blob: String, words: Array<String>): Boolean {
        for (w in words) if (blob.contains(w)) return true
        return false
    }

    private fun prettyPackage(pkg: String): String {
        val parts = pkg.split('.').filter { it.isNotEmpty() }
        if (parts.isEmpty()) return pkg
        var name = parts.last()
        if (parts.size > 1 && (name == "android" || name == "app" || name == "mobile")) {
            name = parts[parts.size - 2]
        }
        return name.replaceFirstChar { it.uppercaseChar() }
    }

    private fun sanitizeTitle(raw: String): String {
        val sb = StringBuilder(MAX_TITLE_LEN)
        for (c in raw) {
            if (sb.length >= MAX_TITLE_LEN) break
            // Drop control chars and bidi overrides so a hostile label cannot
            // scramble the list UI.
            if (c.isISOControl()) continue
            if (c in '\u200E'..'\u200F' || c in '\u202A'..'\u202E' || c in '\u2066'..'\u2069') continue
            if (c.isWhitespace() && (sb.isEmpty() || sb.last() == ' ')) continue
            sb.append(if (c.isWhitespace()) ' ' else c)
        }
        val out = sb.toString().trim()
        return if (out.isEmpty()) "Saved password" else out
    }
}
