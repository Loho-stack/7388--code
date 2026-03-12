class MenuItem {
  final String id;
  final String title;
  final String icon;
  final bool isComingSoon;
  final String? apiEndpoint; // Will be configured later

  MenuItem({
    required this.id,
    required this.title,
    required this.icon,
    this.isComingSoon = false,
    this.apiEndpoint,
  });

  // Predefined menu items (will fetch from API later)
  static List<MenuItem> getDefaultMenuItems() {
    return [
      MenuItem(
        id: 'learning_areas',
        title: 'My Learning Areas',
        icon: '📚',
        isComingSoon: false,
      ),
      MenuItem(
        id: 'interactive_books',
        title: 'Interactive Books',
        icon: '🎮',
        isComingSoon: false,
      ),
      MenuItem(
        id: 'non_interactive_books',
        title: 'Non-Interactive Books',
        icon: '📖',
        isComingSoon: false,
      ),
      MenuItem(
        id: 'data_learning',
        title: 'Dals Learning',
        icon: '📊',
        isComingSoon: false,
      ),
      MenuItem(
        id: 'esoma_kids',
        title: 'Esoma Kids',
        icon: '⭐',
        isComingSoon: false,
      ),
      MenuItem(
        id: 'virtual_labs',
        title: 'Virtual Labs',
        icon: '🔬',
        isComingSoon: false,
      ),
      MenuItem(
        id: 'elimu_quest',
        title: 'Elimu Quest',
        icon: '🎯',
        isComingSoon: false,
      ),
      MenuItem(
        id: 'leaderboard',
        title: 'Leaderboard',
        icon: '🏆',
        isComingSoon: false,
      ),
      MenuItem(
        id: 'loho_tv',
        title: 'Loho TV',
        icon: '📺',
        isComingSoon: false,
      ),
      MenuItem(
        id: 'live_classes',
        title: 'Live Classes',
        icon: '🎓',
        isComingSoon: true,
      ),
      MenuItem(
        id: 'games',
        title: 'Games',
        icon: '🎮',
        isComingSoon: false,
      ),
      MenuItem(
        id: 'my_questions',
        title: 'My Questions',
        icon: '❓',
        isComingSoon: false,
      ),
    ];
  }
}
