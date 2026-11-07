import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// A stored PIN hash: PBKDF2-HMAC-SHA256 with a random 16-byte salt.
class PinHash {
  final String hash;
  final String salt;
  final int iterations;

  const PinHash(this.hash, this.salt, this.iterations);

  Map<String, Object> toJson() => {
    'hash': hash,
    'salt': salt,
    'iterations': iterations,
  };

  static PinHash fromJson(Map<String, dynamic> j) =>
      PinHash(j['hash'] as String, j['salt'] as String, j['iterations'] as int);
}

/// Hashes and checks PINs and recovery codes with the `cryptography`
/// package's PBKDF2 (no home-made cryptography). Work runs on a background
/// isolate so the PIN pad does not freeze.
class PinHasher {
  /// Iterations for new hashes. Each hash stores its own count, so this can
  /// be raised later without breaking existing PINs.
  final int iterations;

  /// Off in widget tests, whose fake clock does not wait for isolates.
  final bool useIsolate;

  const PinHasher({
    this.iterations = defaultIterations,
    this.useIsolate = true,
  });

  static const int defaultIterations = 60000;

  Future<PinHash> hash(String secret) async {
    final rnd = Random.secure();
    final salt = List<int>.generate(16, (_) => rnd.nextInt(256));
    final bytes = await _derive(secret, salt, iterations, useIsolate);
    return PinHash(base64Encode(bytes), base64Encode(salt), iterations);
  }

  Future<bool> verify(String secret, PinHash stored) async {
    final bytes = await _derive(
      secret,
      base64Decode(stored.salt),
      stored.iterations,
      useIsolate,
    );
    final expected = base64Decode(stored.hash);
    if (bytes.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < bytes.length; i++) {
      diff |= bytes[i] ^ expected[i];
    }
    return diff == 0;
  }

  static Future<List<int>> _derive(
    String secret,
    List<int> salt,
    int iterations,
    bool useIsolate,
  ) {
    Future<List<int>> run() async {
      final kdf = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: 256,
      );
      final key = await kdf.deriveKey(
        secretKey: SecretKey(utf8.encode(secret)),
        nonce: salt,
      );
      return key.extractBytes();
    }

    return useIsolate ? Isolate.run(run) : run();
  }

  /// A recovery code like `7KQ2-M9XD-4TWP` (no 0/O or 1/I to misread).
  static String newRecoveryCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final b = StringBuffer();
    for (var i = 0; i < 12; i++) {
      if (i > 0 && i % 4 == 0) b.write('-');
      b.write(chars[rnd.nextInt(chars.length)]);
    }
    return b.toString();
  }

  /// Upper-cases and drops spaces and dashes, so typing is forgiving.
  static String normalizeRecoveryCode(String s) =>
      s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
}
