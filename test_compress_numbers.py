import unittest

from compress_numbers import compress_numbers


class TestCompressNumbers(unittest.TestCase):

    def test_example_1(self):
        """Базовый пример: [1, 1, 2, 2, 3] → [1, 2, 3]"""
        self.assertEqual(compress_numbers([1, 1, 2, 2, 3]), [1, 2, 3])

    def test_example_2(self):
        """Повторяющееся значение после другого: [0, 0, 1, 1, 0] → [0, 1, 0]"""
        self.assertEqual(compress_numbers([0, 0, 1, 1, 0]), [0, 1, 0])

    def test_empty_array(self):
        """Пустой массив → []"""
        self.assertEqual(compress_numbers([]), [])

    def test_single_element(self):
        """Один элемент → [элемент]"""
        self.assertEqual(compress_numbers([5]), [5])

    def test_no_duplicates(self):
        """Нет дубликатов → исходный массив"""
        self.assertEqual(compress_numbers([1, 2, 3, 4]), [1, 2, 3, 4])

    def test_all_same(self):
        """Все элементы одинаковые → [элемент]"""
        self.assertEqual(compress_numbers([7, 7, 7, 7]), [7])

    def test_alternating(self):
        """Чередующиеся значения: [1, 2, 1, 2] → [1, 2, 1, 2] (не удаляются)"""
        self.assertEqual(compress_numbers([1, 2, 1, 2]), [1, 2, 1, 2])

    def test_negative_numbers(self):
        """Отрицательные числа: [-1, -1, 0, -2, -2] → [-1, 0, -2]"""
        self.assertEqual(compress_numbers([-1, -1, 0, -2, -2]), [-1, 0, -2])

    def test_large_consecutive_groups(self):
        """Длинные группы подряд идущих дубликатов"""
        self.assertEqual(
            compress_numbers([1, 1, 1, 1, 2, 2, 3, 3, 3]),
            [1, 2, 3],
        )

    def test_single_group_at_end(self):
        """Группа дубликатов в конце: [1, 2, 3, 3] → [1, 2, 3]"""
        self.assertEqual(compress_numbers([1, 2, 3, 3]), [1, 2, 3])

    def test_single_group_at_start(self):
        """Группа дубликатов в начале: [1, 1, 2, 3] → [1, 2, 3]"""
        self.assertEqual(compress_numbers([1, 1, 2, 3]), [1, 2, 3])

    def test_all_unique(self):
        """Все элементы уникальны → без изменений"""
        input_arr = [0, 5, -3, 100, 42]
        self.assertEqual(compress_numbers(input_arr), input_arr)


if __name__ == '__main__':
    unittest.main()
