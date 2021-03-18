# ondori-caller-id

Custom caller ID provider for React Native

## Overview

This is a React Native library for providing custom caller ID information to iOS. You can provide a list of contacts, and the library will use it to show the right name when needed.

## Installation

Add this package to your project:

`yarn add git+ssh://git@github.com:mguellsegarra/ondori-caller-id.git`

### iOS specific installation steps

Follow these steps: [iOS specific installation steps](ios.md)

## Setup

Import the package in your component:

`import CallerId from 'ondori-caller-id';`

### iOS

For iOS devices, you must pass the app group identifier, extension id, and data key to the native part:

```
      await CallerId.setDataKey('CALLER_LIST');
      await CallerId.setAppGroup('group.mguellsegarra_callerid');
      await CallerId.setExtensionId(
        'org.reactjs.native.example.caller-id.CallDirectoryHandler',
      );
```

Once this is done, you should check wether the app is enabled as a call blocking app in the iPhone's permissions. You can know this by calling:

```
const extensionEnabled = await CallerId.getExtensionEnabledStatus();

if (!extensionEnabled) {
    // show alert
}
```

User must go to **Settings -> Phone -> Call blocking & identification** and enable our app.

## Usage

### addContactsToCallerList

To provide custom Caller ID data, you should call:

```
    const callers = [
      {
        name: 'Arthas Menethil',
        number: '6505551212',
      },
      {
        name: 'Sylvanas Windrunner',
        number: '34977436370',
      },
    ];

    await CallerId.addContactsToCallerList(callers);
```

### getCallerList

You can also retrieve all the contacts stored in the Caller ID module calling:

```
  const contactsAddedToCallerId = await CallerId.getCallerList();
```

This will return a list of contacts, plus `processed` flag for each entry. This flag will be true after the contact has been successfully added to the Caller ID module. In iOS it will take the time needed for the extension to reload and process the contacts.

### getUnprocessedContacts

If you need only the unprocessed contacts, you can call:

```
  const unprocessedContacts = CallerId.getUnprocessedContacts();
```

### setCallerList

Also, if you need to, you can also overwrite the whole list:

```
  await CallerId.setCallerList([
      {
        name: 'Arthas Menethil',
        number: '6505551212',
        processed: false,
      }]);
```

## Demo app

There's an example demo app in `example` folder on this repository.

First install the dependencies:

```
$ yarn
```

### Demo app iOS

You will have to change bundle identifiers for both app target's and extension target in Xcode. Also, you should adjust your app group with your own, following the same steps described in [Adding app groups](ios.md#2-add-app-groups) and then running `pod install`.

Then, you should edit the `.env` file and change the values to fit yours. You can leave `IOS_DATA_KEY` as it is, or change it if you want to use a different key to store `NSUserDefaults` data.

```
IOS_DATA_KEY=CALLER_LIST
IOS_APP_GROUP=group.mguellsegarra_callerid
IOS_EXTENSION_ID=org.reactjs.native.example.caller-id.CallDirectoryHandler
```

Now you can run the handy script to do the magic:

```
example $ node node_modules/ondori-caller-id/scripts/update_ios_extension.js
```

This script will automagically update `CallDirectoryHandler.m` in order to change `DATA_KEY` and `APP_GROUP`. Use it whenever you change these values in Xcode.

## Pitfalls

### iOS

- You can't test Call Directory Extensions on iOS simulator. You must test it on a real device.
- Be careful with phone number formatting: you must send full numbers, including country code, area code, etc.