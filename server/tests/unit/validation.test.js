const {
  isValidUsername,
  isValidEmail,
  isValidPassword,
  getPasswordErrors,
} = require('../../utils/validation');

describe('Validation Utils', () => {
  describe('isValidUsername', () => {
    test('should accept valid usernames', () => {
      expect(isValidUsername('john_doe')).toBe(true);
      expect(isValidUsername('user123')).toBe(true);
      expect(isValidUsername('abc')).toBe(true);
    });

    test('should reject invalid usernames', () => {
      expect(isValidUsername('ab')).toBe(false); // Too short
      expect(isValidUsername('a'.repeat(31))).toBe(false); // Too long
      expect(isValidUsername('user@name')).toBe(false); // Invalid char
      expect(isValidUsername('user name')).toBe(false); // Space
      expect(isValidUsername('')).toBe(false); // Empty
    });
  });

  describe('isValidEmail', () => {
    test('should accept valid emails', () => {
      expect(isValidEmail('test@example.com')).toBe(true);
      expect(isValidEmail('user.name@domain.co.uk')).toBe(true);
    });

    test('should reject invalid emails', () => {
      expect(isValidEmail('notanemail')).toBe(false);
      expect(isValidEmail('missing@domain')).toBe(false);
      expect(isValidEmail('@nodomain.com')).toBe(false);
      expect(isValidEmail('')).toBe(false);
    });
  });

  describe('isValidPassword', () => {
    test('should accept valid passwords', () => {
      expect(isValidPassword('Password123')).toBe(true);
      expect(isValidPassword('MyP@ssw0rd')).toBe(true);
    });

    test('should reject invalid passwords', () => {
      expect(isValidPassword('short1A')).toBe(false); // Too short
      expect(isValidPassword('nouppercase123')).toBe(false); // No uppercase
      expect(isValidPassword('NOLOWERCASE123')).toBe(false); // No lowercase
      expect(isValidPassword('NoNumbers')).toBe(false); // No number
    });
  });

  describe('getPasswordErrors', () => {
    test('should return errors for weak password', () => {
      const errors = getPasswordErrors('weak');

      expect(errors.length).toBeGreaterThan(0);
      expect(errors).toContain('Password must be at least 8 characters long');
    });

    test('should return empty array for strong password', () => {
      const errors = getPasswordErrors('StrongPass123');

      expect(errors.length).toBe(0);
    });
  });
});
