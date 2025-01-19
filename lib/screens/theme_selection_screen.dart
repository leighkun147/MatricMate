import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeSelectionScreen extends StatelessWidget {
  const ThemeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Customize Theme'),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.palette),
                text: 'Colors',
              ),
              Tab(
                icon: const Icon(Icons.text_fields),
                text: 'Typography',
              ),
              Tab(
                icon: const Icon(Icons.style),
                text: 'Style',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ColorSchemeSelector(),
            _TypographySelector(),
            _StyleCustomizer(),
          ],
        ),
      ),
    );
  }
}

class _ColorSchemeSelector extends StatelessWidget {
  const _ColorSchemeSelector();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final themes = ThemeProvider.colorSchemes.keys.toList()
          ..sort((a, b) => a.compareTo(b));
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: themes.length,
          itemBuilder: (context, index) {
            final themeName = themes[index];
            final colorScheme = ThemeProvider.colorSchemes[themeName]!;
            final isSelected = themeName == themeProvider.currentTheme;
            final isDark = themeName.contains('Dark');
            
            return GestureDetector(
              onTap: () => themeProvider.setTheme(themeName),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? colorScheme.primary : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.2),
                      blurRadius: isSelected ? 8 : 0,
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.white30 : Colors.black12,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check,
                              color: colorScheme.onPrimary, size: 30)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      themeName.replaceAll('Light', '').replaceAll('Dark', '').trim(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDark ? 'Dark Mode' : 'Light Mode',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TypographySelector extends StatelessWidget {
  const _TypographySelector();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final fonts = ThemeProvider.fonts.keys.toList();
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: fonts.length,
          itemBuilder: (context, index) {
            final fontName = fonts[index];
            final isSelected = fontName == themeProvider.currentFont;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    'The quick brown fox jumps over the lazy dog',
                    style: TextStyle(
                      fontFamily: fontName == 'Default' ? null : fontName,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        '123456789',
                        style: TextStyle(
                          fontFamily: fontName == 'Default' ? null : fontName,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fontName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  leading: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                    ),
                    child: Icon(
                      isSelected ? Icons.check : Icons.font_download,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onTap: () => themeProvider.setFont(fontName),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StyleCustomizer extends StatelessWidget {
  const _StyleCustomizer();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStyleCard(
              context,
              title: 'Corner Radius',
              icon: Icons.rounded_corner,
              child: Column(
                children: [
                  Slider(
                    value: themeProvider.cornerRadius,
                    min: 0,
                    max: 20,
                    divisions: 20,
                    label: '${themeProvider.cornerRadius.toStringAsFixed(1)}px',
                    onChanged: (value) => themeProvider.setCornerRadius(value),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Square',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('Rounded',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildStyleCard(
              context,
              title: 'Elevation',
              icon: Icons.layers,
              child: Column(
                children: [
                  Slider(
                    value: themeProvider.elevationLevel,
                    min: 0,
                    max: 8,
                    divisions: 8,
                    label: '${themeProvider.elevationLevel.toStringAsFixed(1)}dp',
                    onChanged: (value) => themeProvider.setElevation(value),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Flat',
                            style: Theme.of(context).textTheme.bodySmall),
                        Text('Raised',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildPreviewSection(context),
          ],
        );
      },
    );
  }

  Widget _buildStyleCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sample Card',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text('This is how your cards will look'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            child: const Text('Outlined'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            child: const Text('Elevated'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
