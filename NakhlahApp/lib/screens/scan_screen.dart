import 'package:flutter/material.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  bool _flashOn = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _CircleButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Scan Date Fruit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 8,
                              color: Color(0xFFD4A017),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'NAKHLAH AI LIVE',
                              style: TextStyle(
                                color: Color(0xFFD4A017),
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _CircleButton(
                    icon: Icons.help_outline,
                    onTap: () {
                      // Show help dialog
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Gold frame scanner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    height: MediaQuery.of(context).size.height * 0.42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(
                          0xFFD4A017,
                        ).withOpacity(_pulseAnimation.value),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFD4A017,
                          ).withOpacity(_pulseAnimation.value * 0.5),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: Colors.black,
                        // Replace with CameraPreview widget when camera is wired up:
                        // child: CameraPreview(controller)
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Hint text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'Align the date within the gold frame',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),

            const Spacer(),

            // Bottom controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gallery
                  Column(
                    children: [
                      _CircleButton(
                        icon: Icons.photo_library_outlined,
                        size: 52,
                        onTap: () {
                          // Open image picker
                        },
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'GALLERY',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),

                  // Capture button
                  GestureDetector(
                    onTap: () {
                      // Capture & send to API
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF5C3A1E),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4A017).withOpacity(0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.filter_center_focus,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  // Flash
                  Column(
                    children: [
                      _CircleButton(
                        icon: _flashOn ? Icons.flash_on : Icons.flash_off,
                        size: 52,
                        onTap: () => setState(() => _flashOn = !_flashOn),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'FLASH',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Status bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFD4A017),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'OPTIMIZING FOR LIGHTING...',
                      style: TextStyle(
                        color: Color(0xFFD4A017),
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: null, // indeterminate
                      backgroundColor: Colors.white12,
                      color: const Color(0xFF7D5A3C),
                      minHeight: 4,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white12,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.45),
      ),
    );
  }
}
