package com.example.thermalprinter.engine

class UnicodeRenderer {
    companion object {
        private val devanagariRegex = Regex("[\\u0900-\\u097F]")
        private val emojiRegex = Regex("(\\u00a9|\\u00ae|[\\u2000-\\u3300]|\\ud83c[\\ud000-\\udfff]|\\ud83d[\\ud000-\\udfff]|\\ud83e[\\ud000-\\udfff])")
        private val specialSymbols = listOf("₹", "✓", "✔", "✕", "★", "☆", "♥", "©", "®", "™", "°", "→", "←", "↑", "↓", "•", "🙏")

        fun containsComplexUnicode(text: String): Boolean {
            if (text.isEmpty()) return false
            if (devanagariRegex.containsMatchIn(text)) return true
            if (emojiRegex.containsMatchIn(text)) return true

            for (sym in specialSymbols) {
                if (text.contains(sym)) return true
            }

            for (char in text) {
                if (char.code > 127) return true
            }

            return false
        }
    }
}
