class SecurityInfo {
  final String encryptionAlgorithm;
  final String keyDerivation;
  final String storageMethod;
  final int keySize;
  final int iterations;
  final List<String> militaryUses;
  final List<String> standards;

  const SecurityInfo({
    required this.encryptionAlgorithm,
    required this.keyDerivation,
    required this.storageMethod,
    required this.keySize,
    required this.iterations,
    required this.militaryUses,
    required this.standards,
  });

  static SecurityInfo get aes256 => const SecurityInfo(
        encryptionAlgorithm: 'AES-256-GCM',
        keyDerivation: 'PBKDF2-HMAC-SHA256',
        storageMethod: 'Secure Enclave (iOS) / KeyStore (Android)',
        keySize: 256,
        iterations: 100000,
        militaryUses: [
          'Used by the U.S. National Security Agency (NSA) for TOP SECRET information',
          'Standard encryption for military communications worldwide',
          'Approved for protecting classified information up to TOP SECRET level',
          'Used by NATO forces for secure communications',
          'Deployed in military-grade secure communication systems',
        ],
        standards: [
          'FIPS 140-2 (Federal Information Processing Standard)',
          'NIST (National Institute of Standards and Technology) approved',
          'ISO/IEC 19772 (International Standard)',
          'Common Criteria EAL4+ certified',
          'NSA Suite B Cryptography compliant',
          'GDPR compliant for data protection',
        ],
      );

  String get summary =>
      'Your data is protected with $encryptionAlgorithm encryption, the same military-grade standard used by government agencies and armed forces worldwide to protect TOP SECRET information.';

  String get technicalDetails =>
      '''
Encryption: $encryptionAlgorithm ($keySize-bit key)
Key Derivation: $keyDerivation ($iterations iterations)
Storage: $storageMethod

This configuration makes it computationally infeasible to decrypt your data without the correct password, even with modern supercomputers.
''';
}
