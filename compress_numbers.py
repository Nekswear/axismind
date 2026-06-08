from typing import List


def compress_numbers(arr: List[int]) -> List[int]:
    """
    Удаляет подряд идущие дубликаты из массива чисел.

    Сохраняет первый элемент каждой группы одинаковых чисел,
    идущих подряд. Порядок элементов сохраняется.

    Примеры:
        [1, 1, 2, 2, 3] → [1, 2, 3]
        [0, 0, 1, 1, 0] → [0, 1, 0]
        []              → []
        [5]             → [5]

    Args:
        arr: Исходный массив целых чисел.

    Returns:
        Новый массив без подряд идущих дубликатов.
    """
    if not arr:
        return []

    result = [arr[0]]

    for i in range(1, len(arr)):
        if arr[i] != arr[i - 1]:
            result.append(arr[i])

    return result
