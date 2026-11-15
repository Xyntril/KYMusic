#include "YandexTokenStorage.h"
#include <QSettings>

namespace {
constexpr const char *OrganizationName = "my.appyamusic";
constexpr const char *ApplicationName = "appYaMusic";
constexpr const char *TokenKey = "yandex/token";
} // namespace

QString YandexTokenStorage::load() {
  QSettings appSettings;
  const QString token = appSettings.value(TokenKey).toString();
  if (!token.isEmpty()) {
    return token;
  }

  QSettings legacySettings(OrganizationName, ApplicationName);
  return legacySettings.value(TokenKey).toString();
}

bool YandexTokenStorage::saveToken(const QString &token) {
  if (token.isEmpty()) {
    return false;
  }

  QSettings appSettings;
  appSettings.setValue(TokenKey, token);
  appSettings.sync();

  QSettings legacySettings(OrganizationName, ApplicationName);
  legacySettings.setValue(TokenKey, token);
  legacySettings.sync();

  return true;
}

bool YandexTokenStorage::clearToken() {
  QSettings appSettings;
  appSettings.remove(TokenKey);
  appSettings.remove("yandex/token");
  appSettings.remove("token");
  appSettings.sync();

  QSettings legacySettings(OrganizationName, ApplicationName);
  legacySettings.remove(TokenKey);
  legacySettings.remove("yandex/token");
  legacySettings.remove("token");
  legacySettings.sync();

  return true;
}