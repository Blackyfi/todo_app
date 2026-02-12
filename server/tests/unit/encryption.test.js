const { generateToken, verifyToken, hashToken } = require('../../utils/encryption');

describe('Encryption Utils', () => {
  describe('JWT tokens', () => {
    test('should generate valid JWT token', () => {
      const payload = {
        user_id: 1,
        username: 'testuser',
        device_id: 'device-123',
      };

      const token = generateToken(payload);

      expect(token).toBeDefined();
      expect(typeof token).toBe('string');
      expect(token.split('.').length).toBe(3); // JWT has 3 parts
    });

    test('should verify valid token', () => {
      const payload = {
        user_id: 1,
        username: 'testuser',
      };

      const token = generateToken(payload);
      const decoded = verifyToken(token);

      expect(decoded).toBeDefined();
      expect(decoded.user_id).toBe(1);
      expect(decoded.username).toBe('testuser');
    });

    test('should reject invalid token', () => {
      const decoded = verifyToken('invalid.token.here');

      expect(decoded).toBeNull();
    });
  });

  describe('Token hashing', () => {
    test('should hash token consistently', () => {
      const token = 'my-test-token';

      const hash1 = hashToken(token);
      const hash2 = hashToken(token);

      expect(hash1).toBe(hash2);
      expect(hash1).not.toBe(token);
    });

    test('should produce different hashes for different tokens', () => {
      const hash1 = hashToken('token1');
      const hash2 = hashToken('token2');

      expect(hash1).not.toBe(hash2);
    });
  });
});
