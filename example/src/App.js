import React, {Component} from 'react';
import {View, Text, StyleSheet} from 'react-native';
import CallerId from 'ondori-caller-id';
import {checkAndRequestPermissionsIfNeeded} from './permissions/permissionsHelper';

import {IOS_DATA_KEY, IOS_APP_GROUP, IOS_EXTENSION_ID} from '@env';

export default class App extends Component {
  constructor() {
    super();
    this.setupNativeLibrary = this.setupNativeLibrary.bind(this);
    this.setupCallerIds = this.setupCallerIds.bind(this);
  }

  componentDidMount() {
    this.setupNativeLibrary()
      .then(() => {
        return checkAndRequestPermissionsIfNeeded();
      })
      .then(async () => {
        const contactsAddedToCallerId = await CallerId.getCallerList();

        console.log(
          'getCallerList: ' + JSON.stringify(contactsAddedToCallerId, null, 2),
        );

        // You can pass an array of contacts to be removed from caller list
        if (contactsAddedToCallerId.length === 2) {
          const callers = [
            {
              id: 100002,
              name: 'Contact 4',
              number: '34977436370',
              fetched_at: '2020-10-24 13:34:31',
            },
          ];

          await CallerId.removeContactsFromCallerList(callers);

          const newCallerList = await CallerId.getCallerList();
          console.log(
            'newCallerList: ' + JSON.stringify(newCallerList, null, 2),
          );
        }

        // For the first time, check if contacts are empty
        // Second run to add more contacts, check for instance if there are already the previous 2 contacts
        if (contactsAddedToCallerId.length === 0) {
          await this.setupCallerIds();
        }

        // You can manually reload the extension calling:
        await CallerId.reloadExtension();

        const lastAddedContact = await CallerId.getLastAddedContact();
        console.log(
          'Last added contact: ' + JSON.stringify(lastAddedContact, null, 2),
        );

        setInterval(() => {
          CallerId.getUnprocessedContacts().then((list) => {
            if (list.length > 0) {
              console.log(
                'Unprocessed contacts: ' + JSON.stringify(list, null, 2),
              );
            }
          });
        }, 5000);
      })
      .catch((error) => {
        if (__DEV__) console.warn(error);
      });
  }

  async setupNativeLibrary() {
    await CallerId.setDataKey(IOS_DATA_KEY);
    await CallerId.setAppGroup(IOS_APP_GROUP);
    await CallerId.setExtensionId(IOS_EXTENSION_ID);
  }

  async setupCallerIds() {
    const callers = [
      {
        id: 100001,
        name: 'Henry Ford',
        number: '34977436370',
        fetched_at: '2020-10-24 12:34:25',
      },
    ];

    await CallerId.addContactsToCallerList(callers);
  }

  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.text}>ondori-caller-id example app</Text>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'column',
    alignContent: 'center',
    justifyContent: 'center',
  },
  text: {
    textAlign: 'center',
  },
});
