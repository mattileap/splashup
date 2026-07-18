import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/locale_service.dart';
import '../services/theme_service.dart';

/// Pagina "Personalizza esperienza": tema chiaro/scuro, tema colore,
/// font (accessibilità), dimensione testo e lingua.
class CustomizeExperienceScreen extends StatelessWidget {
  const CustomizeExperienceScreen({super.key});

  String _colorThemeLabel(AppLocalizations l10n, AppColorTheme theme) {
    switch (theme) {
      case AppColorTheme.blue:
        return l10n.colorBlue;
      case AppColorTheme.teal:
        return l10n.colorTeal;
      case AppColorTheme.green:
        return l10n.colorGreen;
      case AppColorTheme.coral:
        return l10n.colorCoral;
      case AppColorTheme.purple:
        return l10n.colorPurple;
      case AppColorTheme.pink:
        return l10n.colorPink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeService = context.watch<ThemeService>();
    final localeService = context.watch<LocaleService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.customizeExperience),
      ),
      body: ListView(
        children: [
          // --- TEMA CHIARO/SCURO ---
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: Text(l10n.theme),
            trailing: DropdownButton<ThemeMode>(
              value: themeService.themeMode,
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(l10n.system),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(l10n.light),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(l10n.dark),
                ),
              ],
              onChanged: (ThemeMode? mode) {
                if (mode != null) {
                  themeService.setThemeMode(mode);
                }
              },
            ),
          ),
          const Divider(),

          // --- TEMA COLORE ---
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: Text(l10n.colorTheme),
            subtitle: Text(_colorThemeLabel(l10n, themeService.colorTheme)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AppColorTheme.values.map((colorTheme) {
                final color =
                    isDark ? colorTheme.darkSeed : colorTheme.lightSeed;
                final selected = themeService.colorTheme == colorTheme;
                return Tooltip(
                  message: _colorThemeLabel(l10n, colorTheme),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => themeService.setColorTheme(colorTheme),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color:
                                    Theme.of(context).colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),

          // --- FONT ---
          ListTile(
            leading: const Icon(Icons.text_fields_outlined),
            title: Text(l10n.font),
          ),
          // API RadioGroup (Flutter 3.35+): groupValue/onChanged sui singoli
          // RadioListTile sono deprecati.
          RadioGroup<AppFont>(
            groupValue: themeService.font,
            onChanged: (font) {
              if (font != null) themeService.setFont(font);
            },
            child: Column(
              children: [
                RadioListTile<AppFont>(
                  value: AppFont.standard,
                  title: Text(l10n.fontStandard),
                ),
                RadioListTile<AppFont>(
                  value: AppFont.openDyslexic,
                  title: Text(
                    l10n.fontOpenDyslexic,
                    // Anteprima: l'opzione stessa è mostrata in OpenDyslexic
                    style: const TextStyle(fontFamily: 'OpenDyslexic'),
                  ),
                  subtitle: Text(l10n.fontOpenDyslexicDescription),
                ),
              ],
            ),
          ),
          const Divider(),

          // --- DIMENSIONE TESTO ---
          ListTile(
            leading: const Icon(Icons.format_size_outlined),
            title: Text(l10n.textSize),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SegmentedButton<AppTextSize>(
              segments: [
                ButtonSegment(
                  value: AppTextSize.small,
                  label: Text(l10n.textSizeSmall),
                ),
                ButtonSegment(
                  value: AppTextSize.normal,
                  label: Text(l10n.textSizeNormal),
                ),
                ButtonSegment(
                  value: AppTextSize.large,
                  label: Text(l10n.textSizeLarge),
                ),
              ],
              selected: {themeService.textSize},
              onSelectionChanged: (selection) {
                themeService.setTextSize(selection.first);
              },
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),

          // --- LINGUA ---
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(l10n.language),
            trailing: DropdownButton<String>(
              // 'system' = segui la lingua del dispositivo
              value: localeService.locale?.languageCode ?? 'system',
              items: [
                DropdownMenuItem(
                  value: 'system',
                  child: Text(l10n.system),
                ),
                const DropdownMenuItem(
                  value: 'it',
                  child: Text('Italiano'),
                ),
                const DropdownMenuItem(
                  value: 'en',
                  child: Text('English'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                localeService
                    .setLocale(value == 'system' ? null : Locale(value));
              },
            ),
          ),
          const Divider(),

          // --- ANTEPRIMA ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.preview,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.previewPangram),
                    const SizedBox(height: 8),
                    Text(
                      '01:23.45',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
