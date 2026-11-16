#pragma once

#include <QColor>
#include <QObject>
#include <QSettings>

#if defined(HAVE_KF6_COLORSCHEME)
class KColorSchemeManager;
#endif

// Контроллер темы — полная интеграция с системной темой KDE Plasma (Breeze, Oxygen и др.)
class ThemeController : public QObject {
  Q_OBJECT

  Q_PROPERTY(QString themeMode READ themeMode WRITE setThemeMode NOTIFY themeModeChanged)
  Q_PROPERTY(bool isSystemTheme READ isSystemTheme NOTIFY themeModeChanged)
  Q_PROPERTY(bool darkTheme READ darkTheme WRITE setDarkTheme NOTIFY darkThemeChanged)

  // Системные цвета KDE Plasma (из KColorScheme)
  Q_PROPERTY(QColor systemWindowBackground READ systemWindowBackground NOTIFY paletteChanged)
  Q_PROPERTY(QColor systemViewBackground READ systemViewBackground NOTIFY paletteChanged)
  Q_PROPERTY(QColor systemAlternateBackground READ systemAlternateBackground NOTIFY paletteChanged)
  Q_PROPERTY(QColor systemTextColor READ systemTextColor NOTIFY paletteChanged)
  Q_PROPERTY(QColor systemSubtextColor READ systemSubtextColor NOTIFY paletteChanged)
  Q_PROPERTY(QColor systemHighlightColor READ systemHighlightColor NOTIFY paletteChanged)
  Q_PROPERTY(QColor systemHighlightedTextColor READ systemHighlightedTextColor NOTIFY paletteChanged)
  Q_PROPERTY(QColor systemHoverColor READ systemHoverColor NOTIFY paletteChanged)
  Q_PROPERTY(QColor systemBorderColor READ systemBorderColor NOTIFY paletteChanged)
  Q_PROPERTY(QColor systemDividerColor READ systemDividerColor NOTIFY paletteChanged)
  Q_PROPERTY(QColor systemButtonBackground READ systemButtonBackground NOTIFY paletteChanged)
  Q_PROPERTY(QColor systemButtonText READ systemButtonText NOTIFY paletteChanged)

public:
  explicit ThemeController(QObject *parent = nullptr);
  ~ThemeController() override;

  QString themeMode() const;
  bool isSystemTheme() const;
  bool darkTheme() const;

  Q_INVOKABLE void setThemeMode(const QString &mode);
  Q_INVOKABLE void setDarkTheme(bool dark);

  QColor systemWindowBackground() const;
  QColor systemViewBackground() const;
  QColor systemAlternateBackground() const;
  QColor systemTextColor() const;
  QColor systemSubtextColor() const;
  QColor systemHighlightColor() const;
  QColor systemHighlightedTextColor() const;
  QColor systemHoverColor() const;
  QColor systemBorderColor() const;
  QColor systemDividerColor() const;
  QColor systemButtonBackground() const;
  QColor systemButtonText() const;

signals:
  void themeModeChanged();
  void darkThemeChanged();
  void paletteChanged();

private:
  void reloadColors();

  QString m_themeMode; // "system", "dark", "light"
  bool m_manualDark = false;
#if defined(HAVE_KF6_COLORSCHEME)
  KColorSchemeManager *m_schemeManager = nullptr;
#endif

  QColor m_systemWindowBackground;
  QColor m_systemViewBackground;
  QColor m_systemAlternateBackground;
  QColor m_systemTextColor;
  QColor m_systemSubtextColor;
  QColor m_systemHighlightColor;
  QColor m_systemHighlightedTextColor;
  QColor m_systemHoverColor;
  QColor m_systemBorderColor;
  QColor m_systemDividerColor;
  QColor m_systemButtonBackground;
  QColor m_systemButtonText;
};
