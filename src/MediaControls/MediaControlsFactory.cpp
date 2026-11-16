#include "MediaControlsFactory.h"

#if defined(Q_OS_ANDROID)
#include "MediaControlsAndroid.h"
#elif defined(Q_OS_MACOS)
#include "MediaControlsMacOS.h"
#elif defined(Q_OS_LINUX)
#include "MediaControlsMPRIS.h"
#elif defined(Q_OS_WIN)
#include "MediaControlsSMTC.h"
#endif

std::unique_ptr<SystemMediaControls> MediaControlsFactory::create(QObject *parent) {
#if defined(Q_OS_ANDROID)
  return std::make_unique<MediaControlsAndroid>(parent);
#elif defined(Q_OS_MACOS)
  return std::make_unique<MediaControlsMacOS>(parent);
#elif defined(Q_OS_LINUX)
  return std::make_unique<MediaControlsMPRIS>(parent);
#elif defined(Q_OS_WIN)
  return std::make_unique<MediaControlsSMTC>(parent);
#else
  (void)parent;
  return nullptr;
#endif
}
