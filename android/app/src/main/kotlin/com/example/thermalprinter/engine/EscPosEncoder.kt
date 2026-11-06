package com.example.thermalprinter.engine

import com.example.thermalprinter.models.PrinterProfile
import java.io.ByteArrayOutputStream
import java.nio.charset.Charset

class EscPosEncoder(private val profile: PrinterProfile) {
    private val buffer = ByteArrayOutputStream()

    init {
        // Initialize printer (ESC @)
        buffer.write(byteArrayOf(0x1B.toByte(), 0x40.toByte()))
    }

    fun alignLeft(): EscPosEncoder {
        buffer.write(byteArrayOf(0x1B.toByte(), 0x61.toByte(), 0x00.toByte()))
        return this
    }

    fun alignCenter(): EscPosEncoder {
        buffer.write(byteArrayOf(0x1B.toByte(), 0x61.toByte(), 0x01.toByte()))
        return this
    }

    fun alignRight(): EscPosEncoder {
        buffer.write(byteArrayOf(0x1B.toByte(), 0x61.toByte(), 0x02.toByte()))
        return this
    }

    fun bold(enable: Boolean): EscPosEncoder {
        buffer.write(byteArrayOf(0x1B.toByte(), 0x45.toByte(), if (enable) 0x01.toByte() else 0x00.toByte()))
        return this
    }

    fun textSize(widthMult: Int = 0, heightMult: Int = 0): EscPosEncoder {
        val n = ((widthMult and 0x07) shl 4) or (heightMult and 0x07)
        buffer.write(byteArrayOf(0x1D.toByte(), 0x21.toByte(), n.toByte()))
        return this
    }

    fun text(text: String, lineBreak: Boolean = true): EscPosEncoder {
        buffer.write(text.toByteArray(Charset.forName("ISO-8859-1")))
        if (lineBreak) {
            buffer.write(byteArrayOf(0x0A.toByte()))
        }
        return this
    }

    fun divider(char: Char = '-'): EscPosEncoder {
        val count = profile.charsPerLine
        val line = char.toString().repeat(count)
        alignLeft()
        text(line, true)
        return this
    }

    fun row(col1: String, col2: String, col3: String, flex1: Int = 3, flex2: Int = 1, flex3: Int = 2): EscPosEncoder {
        val total = profile.charsPerLine
        val sumFlex = flex1 + flex2 + flex3

        val w1 = (total * flex1) / sumFlex
        val w2 = (total * flex2) / sumFlex
        val w3 = total - w1 - w2

        val c1 = col1.take(w1).padEnd(w1)
        val c2 = col2.take(w2).padStart(w2)
        val c3 = col3.take(w3).padStart(w3)

        text("$c1$c2$c3", true)
        return this
    }

    fun feed(lines: Int = 3): EscPosEncoder {
        buffer.write(byteArrayOf(0x1B.toByte(), 0x64.toByte(), lines.toByte()))
        return this
    }

    fun cut(): EscPosEncoder {
        feed(3)
        buffer.write(byteArrayOf(0x1D.toByte(), 0x56.toByte(), 0x01.toByte()))
        return this
    }

    fun appendRawBytes(bytes: ByteArray): EscPosEncoder {
        buffer.write(bytes)
        return this
    }

    fun build(): ByteArray = buffer.toByteArray()
}
