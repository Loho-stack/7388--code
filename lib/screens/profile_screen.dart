import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF0F8FF),
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: Color(0xFF36a4da)),
            onPressed: () {
              // TODO: Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar and Name
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFe85021),
                        width: 4,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=12',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Alex Learner',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const Text(
                    'Grade 4 Explorer',
                    style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                  ),
                ],
              ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            ),
            const SizedBox(height: 32),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(
                  '2450',
                  'Points',
                  Icons.star_rounded,
                  Colors.amber,
                ),
                _buildStatCard(
                  '12',
                  'Books',
                  Icons.menu_book_rounded,
                  const Color(0xFF36a4da),
                ),
                _buildStatCard(
                  '34',
                  'Quests',
                  Icons.local_fire_department_rounded,
                  const Color(0xFFe85021),
                ),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

            const SizedBox(height: 40),

            // Badges Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'My Badges',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.8,
              children: [
                _buildBadge(
                  Icons.science_rounded,
                  Colors.green,
                  'Science Whiz',
                ),
                _buildBadge(
                  Icons.calculate_rounded,
                  Colors.lightBlue,
                  'Math Guru',
                ),
                _buildBadge(
                  Icons.auto_stories_rounded,
                  Colors.orange,
                  'Bookworm',
                ),
                _buildBadge(Icons.emoji_events_rounded, Colors.amber, 'Top 10'),
                _buildBadge(Icons.code_rounded, Colors.purple, 'Coder'),
                _buildBadge(
                  Icons.lock_outline_rounded,
                  Colors.grey.shade400,
                  'Locked',
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color color, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 40),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
