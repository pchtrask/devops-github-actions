from unittest import TestCase
from app import multiply
class TestMultiply(TestCase):
    def test_multiply_integers(self):
        self.assertEqual(multiply(2, 3), 6)

    def test_multiply_floats(self):
        self.assertEqual(multiply(2.5, 4.0), 10.0)

    def test_multiply_integer_and_float(self):
        self.assertEqual(multiply(2, 4.0), 8.0)
    def test_multiply_zero(self):
        self.assertEqual(multiply(0, 5), 0)
        self.assertEqual(multiply(5, 0), 0)
    
    def test_multiply_negative_numbers(self):
        self.assertEqual(multiply(-2, 3), -6)
        self.assertEqual(multiply(2, -3), -6)
        self.assertEqual(multiply(-2, -3), 6)
    def test_multiply_large_numbers(self):
        self.assertEqual(multiply(1000000, 2000000), 2000000000000)
        self.assertEqual(multiply(1e6, 2e6), 2e12)
    def test_multiply_small_numbers(self):
        self.assertEqual(multiply(0.0001, 0.0002), 0.00000002)
        self.assertEqual(multiply(1e-4, 2e-4), 2e-8)
    def test_multiply_with_strings(self):
        with self.assertRaises(TypeError):
            multiply("2", 3)
        with self.assertRaises(TypeError):
            multiply(2, "3")
        with self.assertRaises(TypeError):
            multiply("2", "3")
    def test_multiply_with_lists(self):
        with self.assertRaises(TypeError):
            multiply([1, 2], 3)
        with self.assertRaises(TypeError):
            multiply(2, [3, 4])
        with self.assertRaises(TypeError):
            multiply([1, 2], [3, 4])
    def test_multiply_with_none(self):
        with self.assertRaises(TypeError):
            multiply(None, 3)
        with self.assertRaises(TypeError):
            multiply(2, None)
        with self.assertRaises(TypeError):
            multiply(None, None)

        