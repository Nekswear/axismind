import '../services/onboarding_service.dart';
import 'package:flutter/material.dart'; // Импортируем стандартную библиотеку Flutter Material для создания интерфейса
import 'package:shared_preferences/shared_preferences.dart'; // Импортируем пакет для работы с локальной памятью устройства
import 'home_screen.dart'; // Импортируем главный экран, на который перейдем после онбординга

// Объявляем Stateful виджет, так как онбординг меняет состояние (перелистывание страниц)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key}); // Конструктор виджета с ключом

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState(); // Создаем состояние для этого виджета
}

// Класс состояния, в котором хранится логика и переменные онбординга
class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController =
      PageController(); // Контроллер для программного управления PageView (перелистывания слайдов)
  int _currentIndex =
      0; // Переменная для хранения индекса текущего активного слайда (начинается с 0)

  // Список данных для каждого слайда (название, описание, иконка)
  final List<OnboardingItem> _items = [
    const OnboardingItem(
      title: 'Осознанность и покой',
      description:
          'Добро пожаловать в AxisMind. Найдите свой внутренний баланс через регулярные практики медитации и фокуса.',
      icon: Icons.self_improvement,
    ),
    const OnboardingItem(
      title: 'Дыхательные практики',
      description:
          'Используйте проверенные техники, такие как Сусокукан, для глубокой концентрации и расслабления.',
      icon: Icons.air,
    ),
    const OnboardingItem(
      title: 'Синхронизация и прогресс',
      description:
          'Отслеживайте статистику сессий, настраивайте таймеры и сохраняйте свой прогресс в облаке.',
      icon: Icons.cloud_done,
    ),
  ];

  // Асинхронная функция завершения онбординга и сохранения флага
  Future<void> _finishOnboarding() async {
    await OnboardingService().markCompleted();

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Базовая структура визуального интерфейса экрана
      body: SafeArea(
        // Обертка, чтобы контент не залезал на системные вырезы экрана (например, камеру)
        child: Column(
          // Верстаем элементы вертикально друг под другом
          children: [
            Align(
              // Выравниваем кнопку «Пропустить» в правый верхний угол
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0), // Отступы вокруг кнопки
                child: TextButton(
                  onPressed:
                      _finishOnboarding, // При нажатии сразу завершаем онбординг
                  child: const Text('Пропустить'), // Текст кнопки
                ),
              ),
            ),
            Expanded(
              // Занимает всё доступное свободное пространство по вертикали
              child: PageView.builder(
                // Виджет для создания пролистываемых вбок страниц
                controller:
                    _pageController, // Подключаем наш контроллер страниц
                itemCount: _items.length, // Общее количество слайдов
                onPageChanged: (index) {
                  // Функция, вызываемая при смене страницы пользователем
                  setState(() {
                    _currentIndex =
                        index; // Обновляем номер текущего слайда в состоянии
                  });
                },
                itemBuilder: (context, index) {
                  // Создаем содержимое для каждого отдельного слайда
                  final item =
                      _items[index]; // Получаем данные текущего слайда по индексу
                  return Padding(
                    padding: const EdgeInsets.all(
                      24.0,
                    ), // Внутренние отступы для содержимого слайда
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment
                          .center, // Выравнивание по центру по вертикали
                      children: [
                        Icon(
                          item.icon, // Иконка слайда
                          size: 100, // Размер иконки
                          color: Theme.of(
                            context,
                          ).primaryColor, // Цвет из общей темы приложения
                        ),
                        const SizedBox(
                          height: 32,
                        ), // Отступ между иконкой и заглавием
                        Text(
                          item.title, // Заголовок слайда
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold, // Жирный шрифт
                          ),
                          textAlign:
                              TextAlign.center, // Выравнивание текста по центру
                        ),
                        const SizedBox(
                          height: 16,
                        ), // Отступ между заголовком и описанием
                        Text(
                          item.description, // Текст описания слайда
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey, // Серый цвет текста
                          ),
                          textAlign:
                              TextAlign.center, // Выравнивание текста по центру
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              // Строка для отображения точек-индикаторов прогресса внизу
              mainAxisAlignment:
                  MainAxisAlignment.center, // Выравнивание точек по центру
              children: List.generate(
                _items.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ), // Отступы между точками
                  width: _currentIndex == index
                      ? 12
                      : 8, // Активная точка шире остальных
                  height: 8, // Высота точки
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? Theme.of(context)
                              .primaryColor // Цвет активной точки
                        : Colors.grey.shade300, // Цвет неактивных точек
                    borderRadius: BorderRadius.circular(
                      4,
                    ), // Скругление краев точки в капсулу
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 32,
            ), // Отступ перед нижней кнопкой управления
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: SizedBox(
                width: double.infinity, // Кнопка на всю ширину экрана
                height: 50, // Фиксированная высота кнопки
                child: ElevatedButton(
                  onPressed: () {
                    // Если это последний слайд — завершаем онбординг, иначе листаем дальше
                    if (_currentIndex == _items.length - 1) {
                      _finishOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(
                          milliseconds: 300,
                        ), // Длительность анимации листинга
                        curve: Curves.easeInOut, // Плавность анимации
                      );
                    }
                  },
                  child: Text(
                    // Меняем текст на кнопке в зависимости от того, последний ли это слайд
                    _currentIndex == _items.length - 1
                        ? 'Начать практику'
                        : 'Далее',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Вспомогательный класс-модель для хранения данных одного слайда онбординга
class OnboardingItem {
  final String title; // Текст заголовка
  final String description; // Текст описания
  final IconData icon; // Иконка

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
  });
}
