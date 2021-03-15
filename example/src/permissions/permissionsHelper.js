import {Alert} from 'react-native';
import CallerId from 'ondori-caller-id';

const showPhoneSettingsAlert = () => {
  return new Promise((resolve) => {
    Alert.alert(
      'Enable app in phone settings',
      'In order to use Caller ID features, you must enable this app under Settings -> Phone -> Call blocking & identification',
      [
        {
          text: 'OK',
          onPress: () => {
            CallerId.openSettings();
            resolve();
          },
        },
      ],
      {cancelable: false},
    );
  });
};

const checkAndRequestPermissionsIfNeeded = async () => {
  const iosEnabled = await CallerId.getExtensionEnabledStatus();

  if (!iosEnabled) {
    await showPhoneSettingsAlert();
  }
};

export {checkAndRequestPermissionsIfNeeded};
