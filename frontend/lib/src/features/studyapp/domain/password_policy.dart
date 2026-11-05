import 'package:zxcvbn/zxcvbn.dart';

class PasswordIdentityInput {
  const PasswordIdentityInput({
    required this.email,
    required this.firstName,
    this.lastName,
  });

  final String email;
  final String firstName;
  final String? lastName;
}

class PasswordPolicyEvaluation {
  const PasswordPolicyEvaluation({
    required this.lengthAccepted,
    required this.identityAccepted,
    required this.commonPasswordAccepted,
    required this.score,
    required this.confirmationAccepted,
  });

  final bool lengthAccepted;
  final bool identityAccepted;
  final bool commonPasswordAccepted;
  final int score;
  final bool confirmationAccepted;

  bool get scoreAccepted => score >= PasswordPolicy.minimumScore;
  bool get accepted =>
      lengthAccepted &&
      identityAccepted &&
      commonPasswordAccepted &&
      scoreAccepted &&
      confirmationAccepted;
}

abstract final class PasswordPolicy {
  static const minimumLength = 12;
  static const recommendedLength = 14;
  static const maximumLength = 128;
  static const minimumScore = 3;

  static final Zxcvbn _zxcvbn = Zxcvbn();
  static const _deniedPasswords = {
    'password',
    'password123',
    'password1234',
    '123456789012',
    'qwertyuiop123',
    'administrator',
    'adminadmin123',
    'senha123456',
    'senha12345678',
    'iloveyou123',
  };

  static PasswordPolicyEvaluation evaluate({
    required String password,
    required String confirmation,
    required PasswordIdentityInput identity,
  }) {
    final normalizedPassword = _normalized(password);
    final identityInputs = <String>[
      identity.email,
      identity.firstName,
      if (identity.lastName?.trim().isNotEmpty ?? false) identity.lastName!,
      ..._parts(identity.email),
      ..._parts(identity.firstName),
      ..._parts(identity.lastName ?? ''),
    ].where((value) => value.trim().isNotEmpty).toList(growable: false);
    final identityParts = <String>{
      identity.firstName,
      if (identity.lastName?.trim().isNotEmpty ?? false) identity.lastName!,
      ..._parts(identity.firstName),
      ..._parts(identity.lastName ?? ''),
      ..._parts(identity.email.split('@').first),
    }.map(_normalized).where((value) => value.length >= 3).toSet();

    return PasswordPolicyEvaluation(
      lengthAccepted:
          password.runes.length >= minimumLength &&
          password.runes.length <= maximumLength,
      identityAccepted:
          normalizedPassword != _normalized(identity.email) &&
          !identityParts.any(normalizedPassword.contains),
      commonPasswordAccepted: !_deniedPasswords.contains(normalizedPassword),
      score: password.isEmpty
          ? 0
          : (_zxcvbn.evaluate(password, userInputs: identityInputs).score ?? 0)
                .toInt(),
      confirmationAccepted: password == confirmation,
    );
  }

  static List<String> _parts(String value) =>
      value.split(RegExp(r'[^\p{L}\p{N}]+', unicode: true));

  static String _normalized(String value) {
    const accents = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
    };
    final folded = value.toLowerCase().runes.map((codePoint) {
      final character = String.fromCharCode(codePoint);
      return accents[character] ?? character;
    }).join();
    return folded.replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');
  }
}
