import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Password-protected backup files (`.posbak`).
///
/// Uses the `cryptography` package only: the key comes from the password
/// with PBKDF2-HMAC-SHA256 (random salt), and the data is sealed with
/// AES-256-GCM, which also detects any change to the file. Layout:
///
///     "POSBAK1\n" | header length (4 bytes, big-endian) | header JSON |
///     ciphertext | 16-byte GCM tag
///
/// The header (format, KDF settings, salt, nonce, schema version) is
/// authenticated too, so it cannot be altered without detection.
class BackupCrypto {
  BackupCrypto._();

  static const List<int> magic = [80, 79, 83, 66, 65, 75, 49, 10]; // POSBAK1\n
  static const int defaultIterations = 200000;
  static const int minPasswordLength = 8;

  static bool looksEncrypted(List<int> head) {
    if (head.length < magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (head[i] != magic[i]) return false;
    }
    return true;
  }

  /// Reads the header without the password (for listing backups).
  static Map<String, dynamic>? readHeader(Uint8List bytes) {
    if (!looksEncrypted(bytes) || bytes.length < magic.length + 4) return null;
    final len = ByteData.sublistView(
      bytes,
      magic.length,
      magic.length + 4,
    ).getUint32(0);
    final start = magic.length + 4;
    if (start + len > bytes.length) return null;
    try {
      return jsonDecode(utf8.decode(bytes.sublist(start, start + len)))
          as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List> encrypt(
    Uint8List plain,
    String password, {
    required int schemaVersion,
    int iterations = defaultIterations,
  }) {
    return Isolate.run(() async {
      final rnd = Random.secure();
      final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
      final algo = AesGcm.with256bits();
      final nonce = algo.newNonce();
      final header = utf8.encode(
        jsonEncode({
          'format': 1,
          'cipher': 'AES-256-GCM',
          'kdf': 'PBKDF2-HMAC-SHA256',
          'iterations': iterations,
          'salt': base64Encode(salt),
          'nonce': base64Encode(nonce),
          'schemaVersion': schemaVersion,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      final key = await _key(password, salt, iterations);
      final box = await algo.encrypt(
        plain,
        secretKey: key,
        nonce: nonce,
        aad: header,
      );
      final out = BytesBuilder(copy: false)
        ..add(magic)
        ..add((ByteData(4)..setUint32(0, header.length)).buffer.asUint8List())
        ..add(header)
        ..add(box.cipherText)
        ..add(box.mac.bytes);
      return out.toBytes();
    });
  }

  /// Returns the database bytes. Throws [BackupPasswordException] for a
  /// wrong password or a changed / damaged file.
  static Future<Uint8List> decrypt(Uint8List file, String password) {
    return Isolate.run(() async {
      final header = readHeader(file);
      if (header == null || header['format'] != 1) {
        throw const BackupPasswordException('This is not a POS backup file.');
      }
      final len = ByteData.sublistView(
        file,
        magic.length,
        magic.length + 4,
      ).getUint32(0);
      final start = magic.length + 4;
      final headerBytes = file.sublist(start, start + len);
      final body = file.sublist(start + len);
      if (body.length < 16) {
        throw const BackupPasswordException('The backup file is cut short.');
      }
      final key = await _key(
        password,
        base64Decode(header['salt'] as String),
        header['iterations'] as int,
      );
      try {
        final plain = await AesGcm.with256bits().decrypt(
          SecretBox(
            body.sublist(0, body.length - 16),
            nonce: base64Decode(header['nonce'] as String),
            mac: Mac(body.sublist(body.length - 16)),
          ),
          secretKey: key,
          aad: headerBytes,
        );
        return Uint8List.fromList(plain);
      } on SecretBoxAuthenticationError {
        throw const BackupPasswordException(
          'Wrong password, or the file was changed or damaged.',
        );
      }
    });
  }

  static Future<SecretKey> _key(
    String password,
    List<int> salt,
    int iterations,
  ) => Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
}

class BackupPasswordException implements Exception {
  final String message;

  const BackupPasswordException(this.message);

  @override
  String toString() => message;
}
